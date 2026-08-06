/*-----------------------------------------------------------------------------------------
     Apex Class:        Nb2b_ProductsSelector
     Created Date:      05/01/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Query collection of object Product2
------------------------------------------------------------------------------------------*/

public with sharing class Nb2b_ProductsSelector {

    /*public static List<Product2DataTranslation> selectProductDtByExternalId(Set<String> extProductsDtId){
        return [
            SELECT CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted, Id, ParentId, Language, IsOutOfDate,
                    Name, Description, URL_Photo_1__c, URL_Photo_2__c, URL_Photo_3__c, URL_Photo_4__c, URL_PDF__c, URL_Photo_5__c, URL_Photo_6__c, 
                    Jerarquia__c, Marca__c,  Ramo__c, Umb__c,  Umv__c , Parent.ExternalId, Modificado__c 
                    FROM Product2DataTranslation
                    WHERE Parent.ExternalId IN : extProductsDtId//Preguntar con que campo del Product2DataTranslation comparar
        ];
    }*/
    
    public static List<Product2DataTranslation> selectProductDtBySku(List<String> extProductsDtId){
        return [
            SELECT CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted, Id, ParentId, Language, IsOutOfDate,
                    Name, Description, URL_Photo_1__c, URL_Photo_2__c, URL_Photo_3__c, URL_Photo_4__c, URL_PDF__c, URL_Photo_5__c, URL_Photo_6__c, 
                     Jerarquia__c, Marca__c, Ramo__c, Umb__c, Umv__c , Parent.ExternalId, Modificado__c 
                    FROM Product2DataTranslation
                    WHERE Parent.StockKeepingUnit IN : extProductsDtId//Preguntar con que campo del Product2DataTranslation comparar
        ];
    }

    public static List<Product2> selectProductByExternalId(List<String> extProductsId){
        return [
            SELECT CreatedById,CreatedDate,CurrencyIsoCode,Description,DisplayUrl, Modificado__c,
                    ExternalDataSourceId,ExternalId,Family,Id,IsActive,IsArchived,IsDeleted, Marca__c, Ramo__c,
                    LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Name,ProductClass, Umb__c, 
                    ProductCode,QuantityUnitOfMeasure,StockKeepingUnit,SystemModstamp,Type,URL_PDF__c, Jerarquia__c,
                    URL_Photo_1__c,URL_Photo_2__c,URL_Photo_3__c,URL_Photo_4__c,URL_Photo_5__c,URL_Photo_6__c
                    FROM Product2
                    WHERE ExternalId IN : extProductsId
        ];
    }
    
 	public static List<Product2> selectProductById(Set<String> idSet){
        return [
            SELECT CreatedById,CreatedDate,CurrencyIsoCode,Description,DisplayUrl, Modificado__c,
                    ExternalDataSourceId,ExternalId,Family,Id,IsActive,IsArchived,IsDeleted, Marca__c, Ramo__c,
                    LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Name,ProductClass, Umb__c, UmbKg__c,
                    ProductCode,QuantityUnitOfMeasure,StockKeepingUnit,SystemModstamp,Type,URL_PDF__c, Jerarquia__c,
                    URL_Photo_1__c,URL_Photo_2__c,URL_Photo_3__c,URL_Photo_4__c,URL_Photo_5__c,URL_Photo_6__c,Umv__c,UmbCj__c,UmbPal__c,UmbMt2__c,
            		UnitWeight__C, PcsXBox__c,BoxXPal__c, M2XBox__c, PesoUMV__c, UnitsXM2__c
                    FROM Product2
                    WHERE Id IN : idSet
        ];
    }

    public static List<Product2> selectProductBySKU(List<String> materialList){
        return [
            SELECT CreatedById,CreatedDate,CurrencyIsoCode,Description,DisplayUrl, Modificado__c,
                    ExternalDataSourceId,ExternalId,Family,Id,IsActive,IsArchived,IsDeleted, Marca__c, Ramo__c,
                    LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Name,ProductClass, Umb__c, 
                    ProductCode,QuantityUnitOfMeasure,StockKeepingUnit,SystemModstamp,Type,URL_PDF__c, Jerarquia__c,
                    URL_Photo_1__c,URL_Photo_2__c,URL_Photo_3__c,URL_Photo_4__c,URL_Photo_5__c,URL_Photo_6__c,Umv__c,UmbCj__c,UmbPal__c,UmbMt2__c
                    FROM Product2
                    WHERE StockKeepingUnit IN : materialList 
        ];
    }

    //GetMetadata from ProductTranslation
    public static List<N2B2_LanguageTraduction__mdt> getTranslationMetadata(){
        return [
            SELECT Id, Country__c, Language__c 
            FROM N2B2_LanguageTraduction__mdt
        ];
    }
}