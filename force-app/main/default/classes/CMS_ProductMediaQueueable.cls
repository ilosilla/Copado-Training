/**
 * @author         Ramón Prades
 * @date           March 2026
 * @group          CMS
 *
 * Class: CMS_ProductMediaQueueable
 *
 * Purpose:
 *   Processes one media file per transaction and chains the next item when needed.
 */
public class CMS_ProductMediaQueueable implements Queueable, Database.AllowsCallouts {

    private static final String LOG_SCENARIO = 'PIM-IMG-QUEUABLE';
    public static final String ROLE_LIST = 'LIST';
    public static final String ROLE_DETAIL = 'DETAIL';
    public static final String ROLE_ATTACHMENT = 'ATTACHMENT';
    private static final String CONTENT_TYPE_DOCUMENT = 'sfdc_cms__document';

    private List<MediaJobDTO> jobs;
    private Integer index;
    private Id workspaceId;
    private Boolean autoPublish;

    @TestVisible private static String testManagedContentId;

    public class MediaJobDTO {
        public Id productId;
        public String sku;
        public String role;
        public String url;
        public String fileName;
        public String managedContentId;
        public Integer sequence;
    }

    public CMS_ProductMediaQueueable(List<MediaJobDTO> jobs, Id workspaceId, Boolean autoPublish) {
        this(jobs, 0, workspaceId, autoPublish);
    }

    public CMS_ProductMediaQueueable(List<MediaJobDTO> jobs, Integer index, Id workspaceId, Boolean autoPublish) {
        this.jobs = jobs == null ? new List<MediaJobDTO>() : jobs;
        this.index = index == null ? 0 : index;
        this.workspaceId = workspaceId;
        this.autoPublish = autoPublish;
    }

    public void execute(QueueableContext context) {
        if (this.jobs.isEmpty() || this.index >= this.jobs.size()) {
            return;
        }

        MediaJobDTO job = this.jobs[this.index];
        SystemLog logger = new SystemLog(LOG_SCENARIO);
        logger.setTag('CMS-MEDIA');
        logger.addInfo('Processing queueable media job');
        logger.addInfo('SKU = ' + job.sku);
        logger.addInfo('Role = ' + job.role);
        logger.addDebug('URL = ' + job.url);

        try {
            String managedContentId = job.managedContentId;
            String fileName = this.buildFileName(job.role, job.fileName, job.sequence);

            if (String.isBlank(managedContentId)) {
                CMS_UrlDownloader.DownloadResult downloadResult = CMS_UrlDownloader.download(job.url);
                if (String.isBlank(fileName)) {
                    fileName = this.buildFileName(job.role, downloadResult.fileName, job.sequence);
                }
                managedContentId = this.upload(job.role, fileName, downloadResult);
                logger.addInfo('FileName = ' + fileName);
                logger.addInfo('ManagedContentId = ' + managedContentId);
            } else {
                logger.addInfo('ManagedContentId reused = ' + managedContentId);
                logger.addInfo('FileName = ' + fileName);
            }

            this.associate(job, managedContentId);
            logger.setSummary('OK ' + job.role + ' ' + job.sku);
        } catch (Exception ex) {
            logger.setSummary('ERROR ' + job.role + ' ' + job.sku);
            logger.addError(ex);
            logger.addError('Role = ' + job.role + ', SKU = ' + job.sku + ', URL = ' + job.url);
        }

        logger.saveLog(true);

        if (this.index + 1 < this.jobs.size()) {
            System.enqueueJob(new CMS_ProductMediaQueueable(this.jobs, this.index + 1, this.workspaceId, this.autoPublish));
        }
    }

    @TestVisible
    private String upload(String role, String fileName, CMS_UrlDownloader.DownloadResult downloadResult) {
        CMS_Uploader uploader = new CMS_Uploader(this.workspaceId);
        uploader.AutoPublish = this.autoPublish;

        String managedContentId;

        if (role == ROLE_ATTACHMENT) {
            CMS_Uploader.FileDescriptorDTO dto = new CMS_Uploader.FileDescriptorDTO();
            dto.fileName = fileName;
            dto.title = fileName;
            dto.mimeType = String.isBlank(downloadResult.mimeType) ? URLCommons.inferMimeType(fileName) : downloadResult.mimeType;
            dto.contentType = CONTENT_TYPE_DOCUMENT;
            dto.content = downloadResult.content;
            managedContentId = uploader.upload(dto)?.managedContentId;
        } else {
            managedContentId = uploader.uploadImage(fileName, downloadResult.content)?.managedContentId;
        }

        if (Test.isRunningTest() && String.isBlank(managedContentId) && String.isNotBlank(testManagedContentId)) {
            managedContentId = testManagedContentId;
        }

        return managedContentId;
    }

    private void associate(MediaJobDTO job, String managedContentId) {
        if (String.isBlank(managedContentId)) {
            return;
        }

        CMS_ProductMediaService service = new CMS_ProductMediaService();
        CMS_ProductMediaService.ProductMediaDTO dto = new CMS_ProductMediaService.ProductMediaDTO();
        dto.productId = job.productId;
        dto.managedContentId = (Id) managedContentId;

        if (job.role == ROLE_LIST) {
            service.addProductListImages(new List<CMS_ProductMediaService.ProductMediaDTO>{ dto });
            return;
        }

        if (job.role == ROLE_DETAIL) {
            service.addProductDetailImages(new List<CMS_ProductMediaService.ProductMediaDTO>{ dto });
            return;
        }

        service.addProductAttachments(new List<CMS_ProductMediaService.ProductMediaDTO>{ dto });
    }

    private String buildFileName(String role, String originalFileName, Integer sequence) {
        if (String.isNotBlank(originalFileName)) {
            return originalFileName;
        }
        if (role == ROLE_LIST) {
            return 'plp.bin';
        }
        if (role == ROLE_DETAIL) {
            return 'pdp-' + String.valueOf(sequence) + '.bin';
        }
        return 'att-' + String.valueOf(sequence) + '.bin';
    }
}