/**
 * @author         Ramón Prades
 * @date           March 2026
 * @group          CMS
 *
 * Class: CMS_ProductOrchestrator
 *
 * Purpose:
 *   Selects the media that must be synchronized for a single SKU and dispatches the queueable chain.
 *
 * Notes:
 *   - This class works on a single SKU.
 *   - Product selection and batch execution belong to higher-level launchers.
 *   - Media group duplicate control is currently applied at group level.
 */
public class CMS_ProductOrchestrator {

    private static final Integer MAX_DETAIL_IMAGES = 6;
    private static final String IMAGE_TYPE_CATALOG = 'CATALOG';
    private static final String IMAGE_TYPE_SETTING = 'SETTING';
    private static final String IMAGE_TYPE_OTHER = 'OTHER';
    public static final String MODE_REPLACE_EXISTING = 'REPLACE_EXISTING';
    public static final String MODE_INSERT_MISSING = 'INSERT_MISSING';

    private String sku;
    private Id workspaceId;
    private Boolean autoPublish = true;
    private Boolean extendedLog = false;
    private String mode = MODE_REPLACE_EXISTING;
    private CMS_ProductMediaService mediaService;
    @TestVisible private ExistingMediaDTO testExistingMedia;

    /* ========================================================= */
    /* PUBLIC DTOs                                               */
    /* ========================================================= */

    public class ResultDTO {
        public String sku;
        public Id productId;
        public Boolean productFound = false;
        public Boolean listImageSkipped = false;
        public Boolean detailImagesSkipped = false;
        public Boolean attachmentsSkipped = false;
        public String selectedListUrl;
        public List<String> selectedDetailUrls = new List<String>();
        public List<String> selectedAttachmentUrls = new List<String>();
        public Integer listUploads = 0;
        public Integer detailUploads = 0;
        public Integer attachmentUploads = 0;
        public List<String> errors = new List<String>();
        public List<String> debugLines = new List<String>();
    }

    /* ========================================================= */
    /* CONSTRUCTORS                                              */
    /* ========================================================= */

    public CMS_ProductOrchestrator(String sku, Id workspaceId) {
        this.sku = sku;
        this.workspaceId = workspaceId;
        this.mediaService = new CMS_ProductMediaService();
    }

    public void setAutoPublish(Boolean value) {
        this.autoPublish = value;
    }

    public void setExtendedLog(Boolean value) {
        this.extendedLog = value;
    }

    public void setMode(String value) {
        if (String.isBlank(value)) {
            return;
        }
        this.mode = value.trim().toUpperCase();
    }

    @TestVisible
    public void setTestExistingMedia(Boolean hasListImage, Boolean hasDetailImages, Boolean hasAttachments) {
        this.testExistingMedia = new ExistingMediaDTO();

        if (hasListImage) {
            this.testExistingMedia.listRecords.add(new ProductMedia());
        }
        if (hasDetailImages) {
            this.testExistingMedia.detailRecords.add(new ProductMedia());
        }
        if (hasAttachments) {
            this.testExistingMedia.attachmentRecords.add(new ProductMedia());
        }
    }

    /* ========================================================= */
    /* PUBLIC API                                                */
    /* ========================================================= */

    public ResultDTO execute() {
        ResultDTO result = new ResultDTO();
        result.sku = this.sku;

        Product2 product = this.loadProduct();
        if (product == null) {
            result.errors.add('Product not found for SKU ' + this.sku);
            return result;
        }

        result.productId = product.Id;
        result.productFound = true;

        List<PIMProductImage__c> pimImages = this.loadPIMImages();
        if (pimImages.isEmpty()) {
            this.addDebug(result, 'No PIM images found for SKU ' + this.sku);
            return result;
        }

        ExistingMediaDTO existingMedia = this.loadExistingMedia(product.Id);
        SelectedMediaDTO selectedMedia = this.selectMedia(pimImages, result);
        this.applyMode(selectedMedia, existingMedia, result);
        this.resolveManagedContent(selectedMedia, result);
        this.deleteExistingProductMedia(selectedMedia, existingMedia, result);
        List<CMS_ProductMediaQueueable.MediaJobDTO> mediaJobs = this.buildMediaJobs(selectedMedia);

        result.listUploads = selectedMedia.listImage == null ? 0 : 1;
        result.detailUploads = selectedMedia.detailImages.size();
        result.attachmentUploads = selectedMedia.attachments.size();

        if (!Test.isRunningTest() && !mediaJobs.isEmpty()) {
            System.enqueueJob(new CMS_ProductMediaQueueable(mediaJobs, this.workspaceId, this.autoPublish));
        }

        return result;
    }

    /* ========================================================= */
    /* PRIVATE HELPERS                                           */
    /* ========================================================= */

    private Product2 loadProduct() {
        Product2[] products = [
            SELECT Id, StockKeepingUnit
            FROM Product2
            WHERE StockKeepingUnit = :this.sku
            LIMIT 1
        ];
        return products.isEmpty() ? null : products[0];
    }

    private ExistingMediaDTO loadExistingMedia(Id productId) {
        if (Test.isRunningTest() && this.testExistingMedia != null) {
            return this.testExistingMedia;
        }

        ExistingMediaDTO existing = new ExistingMediaDTO();
        Set<Id> validGroups = new Set<Id>{
            this.mediaService.getMediaGroupId(CMS_ProductMediaService.PRODUCT_LIST_IMAGE),
            this.mediaService.getMediaGroupId(CMS_ProductMediaService.PRODUCT_DETAIL_IMAGE),
            this.mediaService.getMediaGroupId(CMS_ProductMediaService.PRODUCT_ATTACHMENT)
        };
        validGroups.remove(null);

        if (validGroups.isEmpty()) {
            return existing;
        }

        for (ProductMedia media : [
            SELECT Id, ElectronicMediaGroupId, ElectronicMediaId
            FROM ProductMedia
            WHERE ProductId = :productId
              AND ElectronicMediaGroupId IN :validGroups
        ]) {
            if (media.ElectronicMediaGroupId == this.mediaService.getMediaGroupId(CMS_ProductMediaService.PRODUCT_LIST_IMAGE)) {
                existing.listRecords.add(media);
            } else if (media.ElectronicMediaGroupId == this.mediaService.getMediaGroupId(CMS_ProductMediaService.PRODUCT_DETAIL_IMAGE)) {
                existing.detailRecords.add(media);
            } else if (media.ElectronicMediaGroupId == this.mediaService.getMediaGroupId(CMS_ProductMediaService.PRODUCT_ATTACHMENT)) {
                existing.attachmentRecords.add(media);
            }
        }
        return existing;
    }

    private List<PIMProductImage__c> loadPIMImages() {
        return [
            SELECT Id, StockKeepingUnit__c, ImageType__c, Square__c, Xlarge__c, ElementUrl__c
            FROM PIMProductImage__c
            WHERE StockKeepingUnit__c = :this.sku
              AND IsDeleted = false
            ORDER BY ImageType__c
        ];
    }

    private SelectedMediaDTO selectMedia(List<PIMProductImage__c> pimImages, ResultDTO result) {
        SelectedMediaDTO selected = new SelectedMediaDTO();

        String plpSquareUrl = null;
        String plpDetailUrl = null;

        List<String> detailUrls = new List<String>();
        Set<String> detailUrlSet = new Set<String>();
        Set<String> attachmentUrlSet = new Set<String>();

        for (PIMProductImage__c image : pimImages) {
            String imageType = image.ImageType__c == null ? '' : image.ImageType__c.trim().toUpperCase();

            if (imageType == IMAGE_TYPE_OTHER) {
                if (!String.isBlank(image.ElementUrl__c) && attachmentUrlSet.add(image.ElementUrl__c)) {
                    selected.attachments.add(this.newMediaFile(result.productId, CMS_ProductMediaQueueable.ROLE_ATTACHMENT, image.ElementUrl__c));
                    result.selectedAttachmentUrls.add(image.ElementUrl__c);
                    this.addDebug(result, 'Attachment selected: ' + URLCommons.extractFileName(image.ElementUrl__c));
                }
                continue;
            }

            if (imageType != IMAGE_TYPE_CATALOG && imageType != IMAGE_TYPE_SETTING) {
                this.addDebug(result, 'Image ignored because type is not supported: ' + imageType);
                continue;
            }

            if (!String.isBlank(image.Xlarge__c) && detailUrlSet.add(image.Xlarge__c)) {
                detailUrls.add(image.Xlarge__c);
                this.addDebug(result, 'PDP candidate selected: ' + URLCommons.extractFileName(image.Xlarge__c));
            }

            if (!String.isBlank(image.Square__c) && plpSquareUrl == null) {
                plpSquareUrl = image.Square__c;
                plpDetailUrl = image.Xlarge__c;
                this.addDebug(result, 'Initial PLP candidate selected: ' + URLCommons.extractFileName(image.Square__c));
            }

            if (
                imageType == IMAGE_TYPE_CATALOG &&
                !String.isBlank(image.Square__c) &&
                !image.Square__c.toUpperCase().contains('.AMB.')
            ) {
                plpSquareUrl = image.Square__c;
                plpDetailUrl = image.Xlarge__c;
                this.addDebug(result, 'Preferred PLP selected from CATALOG without .AMB.: ' + URLCommons.extractFileName(image.Square__c));
            }
        }

        if (!String.isBlank(plpSquareUrl)) {
            selected.listImage = this.newMediaFile(result.productId, CMS_ProductMediaQueueable.ROLE_LIST, plpSquareUrl);
            result.selectedListUrl = plpSquareUrl;
        }

        {
            List<String> orderedDetailUrls = new List<String>();
            Set<String> orderedDetailUrlSet = new Set<String>();

            if (!String.isBlank(plpDetailUrl) && orderedDetailUrlSet.add(plpDetailUrl)) {
                orderedDetailUrls.add(plpDetailUrl);
            }

            for (String detailUrl : detailUrls) {
                if (orderedDetailUrlSet.add(detailUrl)) {
                    orderedDetailUrls.add(detailUrl);
                }
            }

            for (String detailUrl : orderedDetailUrls) {
                if (selected.detailImages.size() >= MAX_DETAIL_IMAGES) {
                    this.addDebug(result, 'PDP image limit reached. Remaining images are ignored.');
                    break;
                }
                selected.detailImages.add(this.newMediaFile(result.productId, CMS_ProductMediaQueueable.ROLE_DETAIL, detailUrl));
                result.selectedDetailUrls.add(detailUrl);
            }
        }

        return selected;
    }

    private void applyMode(SelectedMediaDTO selectedMedia, ExistingMediaDTO existingMedia, ResultDTO result) {
        if (this.mode == MODE_INSERT_MISSING) {
            if (selectedMedia.listImage != null && !existingMedia.listRecords.isEmpty()) {
                selectedMedia.listImage = null;
                result.selectedListUrl = null;
                result.listImageSkipped = true;
                this.addDebug(result, 'PLP skipped because product already has list image.');
            }

            if (!selectedMedia.detailImages.isEmpty() && !existingMedia.detailRecords.isEmpty()) {
                selectedMedia.detailImages.clear();
                result.selectedDetailUrls.clear();
                result.detailImagesSkipped = true;
                this.addDebug(result, 'PDP skipped because product already has detail images.');
            }

            if (!selectedMedia.attachments.isEmpty() && !existingMedia.attachmentRecords.isEmpty()) {
                selectedMedia.attachments.clear();
                result.selectedAttachmentUrls.clear();
                result.attachmentsSkipped = true;
                this.addDebug(result, 'Attachments skipped because product already has attachments.');
            }
            return;
        }

        result.listImageSkipped = selectedMedia.listImage == null;
        result.detailImagesSkipped = selectedMedia.detailImages.isEmpty();
        result.attachmentsSkipped = selectedMedia.attachments.isEmpty();
    }

    private void resolveManagedContent(SelectedMediaDTO selectedMedia, ResultDTO result) {
        Set<String> fileNames = new Set<String>();

        if (selectedMedia.listImage != null && String.isNotBlank(selectedMedia.listImage.fileName)) {
            fileNames.add(selectedMedia.listImage.fileName);
        }

        for (MediaFileDTO file : selectedMedia.detailImages) {
            if (String.isNotBlank(file.fileName)) {
                fileNames.add(file.fileName);
            }
        }

        for (MediaFileDTO file : selectedMedia.attachments) {
            if (String.isNotBlank(file.fileName)) {
                fileNames.add(file.fileName);
            }
        }

        if (fileNames.isEmpty()) {
            return;
        }

        Map<String, Id> managedContentByName = new Map<String, Id>();
        for (ManagedContent content : [
            SELECT Id, Name
            FROM ManagedContent
            WHERE AuthoredManagedContentSpaceId = :this.workspaceId
              AND Name IN :fileNames
        ]) {
            if (!managedContentByName.containsKey(content.Name)) {
                managedContentByName.put(content.Name, content.Id);
            }
        }

        this.resolveManagedContentForFile(selectedMedia.listImage, managedContentByName, result);

        for (MediaFileDTO file : selectedMedia.detailImages) {
            this.resolveManagedContentForFile(file, managedContentByName, result);
        }

        for (MediaFileDTO file : selectedMedia.attachments) {
            this.resolveManagedContentForFile(file, managedContentByName, result);
        }
    }

    private void resolveManagedContentForFile(MediaFileDTO file, Map<String, Id> managedContentByName, ResultDTO result) {
        if (file == null || String.isBlank(file.fileName)) {
            return;
        }

        if (managedContentByName.containsKey(file.fileName)) {
            file.managedContentId = managedContentByName.get(file.fileName);
            this.addDebug(result, 'ManagedContent reused by name in target workspace for file: ' + file.fileName);
            return;
        }

        this.addDebug(result, 'ManagedContent not found. Upload required for file: ' + file.fileName);
    }

    private void deleteExistingProductMedia(SelectedMediaDTO selectedMedia, ExistingMediaDTO existingMedia, ResultDTO result) {
        if (this.mode != MODE_REPLACE_EXISTING) {
            return;
        }

        List<ProductMedia> recordsToDelete = new List<ProductMedia>();

        if (selectedMedia.listImage != null && !existingMedia.listRecords.isEmpty()) {
            recordsToDelete.addAll(existingMedia.listRecords);
            this.addDebug(result, 'Deleting existing PLP ProductMedia records: ' + existingMedia.listRecords.size());
        }

        if (!selectedMedia.detailImages.isEmpty() && !existingMedia.detailRecords.isEmpty()) {
            recordsToDelete.addAll(existingMedia.detailRecords);
            this.addDebug(result, 'Deleting existing PDP ProductMedia records: ' + existingMedia.detailRecords.size());
        }

        if (!selectedMedia.attachments.isEmpty() && !existingMedia.attachmentRecords.isEmpty()) {
            recordsToDelete.addAll(existingMedia.attachmentRecords);
            this.addDebug(result, 'Deleting existing attachment ProductMedia records: ' + existingMedia.attachmentRecords.size());
        }

        if (!recordsToDelete.isEmpty()) {
            if (Test.isRunningTest() && this.testExistingMedia != null) {
                return;
            }
            delete recordsToDelete;
        }
    }

    private List<CMS_ProductMediaQueueable.MediaJobDTO> buildMediaJobs(SelectedMediaDTO selectedMedia) {
        List<CMS_ProductMediaQueueable.MediaJobDTO> jobs = new List<CMS_ProductMediaQueueable.MediaJobDTO>();

        if (selectedMedia.listImage != null) {
            selectedMedia.listImage.sequence = 1;
            jobs.add(this.newJob(selectedMedia.listImage));
        }

        Integer detailIndex = 0;
        for (MediaFileDTO detailImage : selectedMedia.detailImages) {
            detailIndex++;
            detailImage.sequence = detailIndex;
            jobs.add(this.newJob(detailImage));
        }

        Integer attachmentIndex = 0;
        for (MediaFileDTO attachment : selectedMedia.attachments) {
            attachmentIndex++;
            attachment.sequence = attachmentIndex;
            jobs.add(this.newJob(attachment));
        }

        return jobs;
    }

    private CMS_ProductMediaQueueable.MediaJobDTO newJob(MediaFileDTO file) {
        CMS_ProductMediaQueueable.MediaJobDTO job = new CMS_ProductMediaQueueable.MediaJobDTO();
        job.productId = file.productId;
        job.sku = this.sku;
        job.role = file.role;
        job.url = file.url;
        job.fileName = file.fileName;
        job.managedContentId = file.managedContentId == null ? null : String.valueOf(file.managedContentId);
        job.sequence = file.sequence;
        return job;
    }

    private MediaFileDTO newMediaFile(Id productId, String role, String url) {
        MediaFileDTO file = new MediaFileDTO();
        file.role = role;
        file.url = url;
        file.productId = productId;
        file.fileName = URLCommons.extractFileName(url);
        return file;
    }

    private void addDebug(ResultDTO result, String text) {
        if (this.extendedLog && String.isNotBlank(text)) {
            result.debugLines.add(text);
        }
    }

    /* ========================================================= */
    /* PRIVATE DTOs                                              */
    /* ========================================================= */

    private class SelectedMediaDTO {
        public MediaFileDTO listImage;
        public List<MediaFileDTO> detailImages = new List<MediaFileDTO>();
        public List<MediaFileDTO> attachments = new List<MediaFileDTO>();
    }

    private class ExistingMediaDTO {
        public List<ProductMedia> listRecords = new List<ProductMedia>();
        public List<ProductMedia> detailRecords = new List<ProductMedia>();
        public List<ProductMedia> attachmentRecords = new List<ProductMedia>();
    }

    private class MediaFileDTO {
        public Id productId;
        public String role;
        public String url;
        public String fileName;
        public Id managedContentId;
        public Integer sequence = 1;
    }
}