/**
    * Type: Apex batch class
    * Name: NBK_ImportMediaConNBK_ProductImportDTOtentBatch
    * @author: Adrián Petit
    * Company: Nubika S.L.
    * Date: 04/08/2023
    * @description Class definition for the Import Product JSON
    * @version 1.0
*/
public with sharing class NBK_ProductImportDTO {
    private ImportConfiguration importConfiguration;

    /**
	 * @description empty constructor to start the batch
	 * @param importMediaMDT metadata with the information ID
     * @param contentVersionId contentVersionId generated on a previous callout
	 */ 
    public NBK_ProductImportDTO(Porcelanosa_B2B_Portal__mdt importMediaMDT, String contentVersionId){
        this.importConfiguration = new NBK_ProductImportDTO.ImportConfiguration();
        this.importConfiguration.importSource = new NBK_ProductImportDTO.ImportSource();
        this.importConfiguration.importSettings = new NBK_ProductImportDTO.ImportSettings();
        this.importConfiguration.importSettings.category = new NBK_ProductImportDTO.Category();
        this.importConfiguration.importSettings.media = new NBK_ProductImportDTO.Media();

        this.importConfiguration.importSettings.category.productCatalogId = importMediaMDT.Catalog_Id__c;
        this.importConfiguration.importSettings.media.cmsWorkspaceId = importMediaMDT.CMS_Id__c;
        this.importConfiguration.importSource.contentVersionId = contentVersionId;
    }

    private class ImportConfiguration {
        private ImportSource importSource; 
        private ImportSettings importSettings;
    }

    private class ImportSource {
        private String contentVersionId;
    }

    private class ImportSettings {
        private Category category;
        private Media media;
    }

    private class Category {
        private String productCatalogId;
    }

    private class Media {
        private String cmsWorkspaceId; 
    }
}