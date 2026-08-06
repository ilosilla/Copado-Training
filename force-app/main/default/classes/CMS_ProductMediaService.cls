/**
 * @author         Ramón Prades
 * @date           August 2025
 * @group          CMS
 *
 * Class: CMS_ProductMediaService
 * Prefix CMS_ = Content/Commerce Media Suite
 *
 * Purpose:
 *   Manages the association of uploaded CMS Managed Content with Salesforce Products
 *   through the ProductMedia object and predefined ElectronicMediaGroups.
 *
 * Responsibilities:
 *   - Retrieve ElectronicMediaGroup Ids for supported media groups (detail, list, attachment).
 *   - Provide convenience methods to add media into products by category:
 *       • Product Detail Images
 *       • Product List Images
 *       • Product Attachments
 *   - Abstract the creation of ProductMedia records linking Product2 with CMS content.
 *
 * Usage Example:
 *   CMS_ProductMediaService service = new CMS_ProductMediaService();
 *   List<CMS_ProductMediaService.ProductMediaDTO> media = new List<CMS_ProductMediaService.ProductMediaDTO>();
 *
 *   CMS_ProductMediaService.ProductMediaDTO dto = new CMS_ProductMediaService.ProductMediaDTO();
 *   dto.productId = '01tXX00000A1BCD';        // Product2 Id
 *   dto.managedContentId = '0g1XX0000008XYZ'; // Managed Content Id from CMS_Uploader
 *   media.add(dto);
 *
 *   service.addProductDetailImages(media);
 *
 * Notes:
 *   - ElectronicMediaGroups must exist in the org with DeveloperNames:
 *       • productDetailImage
 *       • productListImage
 *       • attachment
 *   - This class does not handle uploading files; it assumes media already exists
 *     in CMS (e.g., via CMS_Uploader).
 *   - Designed for bulk operations; accepts lists of DTOs to minimize DML.
 */
public class CMS_ProductMediaService {

    public static final String PRODUCT_DETAIL_IMAGE = 'productDetailImage';
    public static final String PRODUCT_LIST_IMAGE = 'productListImage';
    public static final String PRODUCT_ATTACHMENT = 'attachment';

    Map<String, Id> mediaGroups;

    public CMS_ProductMediaService() {
        ElectronicMediaGroup[] groups = [SELECT Id, DeveloperName FROM ElectronicMediaGroup where DeveloperName in (:PRODUCT_DETAIL_IMAGE, :PRODUCT_LIST_IMAGE, :PRODUCT_ATTACHMENT)];
        this.mediaGroups = new Map<String, Id>();
        for (ElectronicMediaGroup gr : groups) {
            this.mediaGroups.put(gr.DeveloperName.toUpperCase(), gr.Id);
        }
    }

    public Id getMediaGroupId(String developerName) {
        return this.mediaGroups.get(developerName.toUpperCase());
    }

    public void addProductDetailImages(List<ProductMediaDTO> media) {
        Id groupId = this.getMediaGroupId(PRODUCT_DETAIL_IMAGE.toUpperCase());
        for (ProductMediaDTO dto : media) {
            dto.mediaGroupId = groupId;
        }
        this.adddMediaToProducts(media);
    }

    public void addProductListImages(List<ProductMediaDTO> media) {
        Id groupId = this.getMediaGroupId(PRODUCT_LIST_IMAGE.toUpperCase());
        for (ProductMediaDTO dto : media) {
            dto.mediaGroupId = groupId;
        }
        this.adddMediaToProducts(media);
    }

        public void addProductAttachments(List<ProductMediaDTO> media) {
        Id groupId = this.getMediaGroupId(PRODUCT_ATTACHMENT.toUpperCase());
        for (ProductMediaDTO dto : media) {
            dto.mediaGroupId = groupId;
        }
        this.adddMediaToProducts(media);
    }

    public void adddMediaToProducts(List<ProductMediaDTO> media) {
        ProductMedia[] records = new List<ProductMedia>();
        for (ProductMediaDTO dto : media) {
            ProductMedia record = new ProductMedia();
            record.ProductId = dto.productId;
            record.ElectronicMediaGroupId = dto.mediaGroupId;
            record.ElectronicMediaId = dto.managedContentId;
            records.add(record);
        }
        if (records.size() > 0) {
            insert records;
        }
    }

    public class ProductMediaDTO {
        public Id productId;
        public Id managedContentId;
        public String mediaGroupId; 
    }
}