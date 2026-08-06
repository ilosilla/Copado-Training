@IsTest(IsParallel=false)  public class MasterProductSyncJobTest {

    private static final String GRUPO_ARTICULOS = 'PT0001';
    private static String MARCA = 'P';

    @testSetup private static void testSetup() {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        Product2[] products = DataFactoryProduct.createProducts();  
        ItemGroup__c item = new ItemGroup__c();
        item.CatalogCategory__c = PicklistCommons.getKeysList(ItemGroup__c.CatalogCategory__c)[0];
        item.Name = 'Test Group';
        item.SAPGroup__c = GRUPO_ARTICULOS;
        insert item;
    }

    @IsTest
    public static void testUpdateFields() {        
        
        List<ZSFMatBase__x> sapProducts = getSAPProducts();
        Product2[] products = [select Id, SAPItemGroup__c, ProductCode from Product2];
        Assert.isNull(products[0].SAPItemGroup__c, 'Item Group should be null');

        Test.startTest();
            MasterProductSyncJob job = new MasterProductSyncJob();
            job.setUpdateMode();
            job.setMaxInfo(true);
            job.start(null);
            job.execute(null,sapProducts);
            job.finish(null);
        Test.stopTest();

        Product2 p2 = [select Id, SAPItemGroup__c, SAPMake__c from Product2 limit 1];
        Assert.isNotNull(p2.SAPItemGroup__c, 'ItemGroup should not be null');
        Assert.areEqual(MARCA, p2.SAPMake__c, 'Wrong make');           
    }


    @IsTest
    public static void testBatchProcess() {        
        
        List<ZSFMatBase__x> sapProducts = getSAPProducts();
        
        // Force this one to be set as inactive
        sapProducts[9].GrupoArticulos__c = null;
        sapProducts[9].IsSample__c = false;
        sapProducts[9].IsSampleAccessory__c = false;
        String inactiveProductCode = sapProducts[9].Material__c;

        Test.startTest();
            MasterProductSyncJob job = new MasterProductSyncJob();
            job.setStandardMode();
            job.setDeleteDuplicates(true);
            job.setMaxInfo(true);
            job.start(null);
            job.execute(null,sapProducts);
            job.finish(null);
        Test.stopTest();

        ItemGroup__c itemGroup = [select Id from ItemGroup__c limit 1];
        Product2 p2 = [select Id, SAPItemGroup__c, SAPMake__c from Product2 limit 1];
        Assert.areEqual(itemGroup.Id, p2.SAPItemGroup__c, 'ItemGroup should not be null');
        Assert.areEqual(MARCA, p2.SAPMake__c, 'Wrong make');   
        
        // Check product inactive
        Product2 p3 = [select Id, isActive from Product2 where StockKeepingUnit = :inactiveProductCode limit 1];
        Assert.isFalse(p3.isActive, 'Product should be inactive');
    }

    @isTest public static void  testMaintenance() {        
        Product2[] products = new Product2[]{};
        Test.startTest();
            MasterProductSyncJob job = new MasterProductSyncJob();
            job.setMaintenaceMode();
            job.setMaxInfo(true);
            Database.queryLocator query = job.start(null);
            Database.QueryLocatorIterator it = query.iterator();
            while (it.hasNext()) {
                Product2 p = (Product2)it.next();
                products.add(p);
            }
            System.assertNotEquals(0, products.size(), 'No products selected for test');
            job.execute(null,products);
            job.finish(null);
        Test.stopTest();          
    } 

    @isTest public static void  testActive() {        
        Product2[] products = new Product2[]{};
        Test.startTest();
            MasterProductSyncJob job = new MasterProductSyncJob();
            job.setActiveMode();
            Database.queryLocator query = job.start(null);
            Database.QueryLocatorIterator it = query.iterator();
            while (it.hasNext()) {
                Product2 p = (Product2)it.next();
                products.add(p);
            }
            System.assertNotEquals(0, products.size(), 'No products selected for test');
            job.execute(null,products);
            job.finish(null);
        Test.stopTest();  
        Product2[] actives = [select Id from Product2 where IsActive = true];
        Assert.areEqual(0, actives.size(), 'All products should be inactive becasue they are created without make and so on');        
    } 
 

 
    @isTest public static void  testConversion() {        
        Product2[] products = [select Id, ProductCode from Product2];
        
        List<ZSFMatBase__x> sapProducts = new List<ZSFMatBase__x>();
        for (Integer i = 0; i < 10; i++) {
            ZSFMatBase__x productExternalObj = new ZSFMatBase__x();
            productExternalObj.Altura__c = 1.0;
            productExternalObj.Ancho__c = 20.0;
            productExternalObj.CurrencyIsoCode = 'EUR';
            productExternalObj.DisplayUrl = 'https://desmobile.porcelanosagrupo.com:44301/sap/opu/odata/SAP/Z31SD_T_SF_INTERF_SRV/ZSFMatBaseSet(\'100000837\')';
            productExternalObj.ExternalId = products[i].ProductCode;
            productExternalObj.GrupoArticulos__c = 'PT0097';
            productExternalObj.Jerarquia__c = '000010010700000468';
            productExternalObj.Longitud__c = 10.0;
            productExternalObj.Marca__c = 'URBATEK';
            productExternalObj.Material__c = products[i].ProductCode;
            productExternalObj.Modificado__c = Date.Today();
            productExternalObj.Nombre__c = 'RETRO BLANCO 10X20(A)'+1;
            productExternalObj.Ramo__c = 'Z';
            productExternalObj.UmbCj__c = 50.0;
            productExternalObj.UmbKg__c = 3.937;
            productExternalObj.UmbMt2__c = 50.0; 
            productExternalObj.UmbPal__c = 3000.0;
            productExternalObj.Umb__c = 'PZS';
            productExternalObj.Umv__c = 'PZS';
            productExternalObj.PzsCj__c = 50;
            productExternalObj.Mt2Cj__c = 6.66;
            productExternalObj.CjPal__c = 60;
            sapProducts.add(productExternalObj);
        } // end for

        sapProducts[9].Umb__c = 'EWE';

        Test.startTest();
            MasterProductSyncJob job = new MasterProductSyncJob();
            job.setConversionMode();
            job.setMaxInfo(true);
            job.start(null);
            job.execute(null,sapProducts);
            job.finish(null);
        Test.stopTest();

        // Usamos sapProducts[0] para test
        Product2 pr2 = [select Id, ProductCode, M2XBox__c from Product2 where ProductCode = :sapProducts[0].Material__c limit 1];
        System.assertEquals(sapProducts[0].Mt2Cj__c, pr2.M2XBox__c, 'Wrong conversion field');
        
        pr2 = [select Id, ProductCode, M2XBox__c, StockUnit__c from Product2 where ProductCode = :sapProducts[9].Material__c limit 1];
        System.assertEquals('UN', pr2.StockUnit__c, 'Wrong unit');

    } 

    private static List<ZSFMatBase__x> getSAPProducts() {
        Product2[] products = [select Id, ProductCode from Product2];
        List<ZSFMatBase__x> sapProducts = new List<ZSFMatBase__x>();
        for (Integer i = 0; i < 10; i++) {
            ZSFMatBase__x productExternalObj = new ZSFMatBase__x();
            productExternalObj.Altura__c = 1.0;
            productExternalObj.Ancho__c = 20.0;
            productExternalObj.CurrencyIsoCode = 'EUR';
            productExternalObj.DisplayUrl = 'https://desmobile.porcelanosagrupo.com:44301/sap/opu/odata/SAP/Z31SD_T_SF_INTERF_SRV/ZSFMatBaseSet(\'100000837\')';
            productExternalObj.ExternalId = products[i].ProductCode;
            productExternalObj.GrupoArticulos__c = GRUPO_ARTICULOS;
            productExternalObj.Jerarquia__c = '000010010700000468';
            productExternalObj.Longitud__c = 10.0;
            productExternalObj.Marca__c = 'URBATEK';
            productExternalObj.Material__c = products[i].ProductCode;
            productExternalObj.Modificado__c = Date.Today();
            productExternalObj.Nombre__c = 'RETRO BLANCO 10X20(A)'+1;
            productExternalObj.Ramo__c = 'Z';
            productExternalObj.UmbCj__c = 50.0;
            productExternalObj.UmbKg__c = 3.937;
            productExternalObj.UmbMt2__c = 50.0;
            productExternalObj.UmbPal__c = 3000.0;
            productExternalObj.Umb__c = 'PZS';
            productExternalObj.Umv__c = 'PZS';
            productExternalObj.Materia__c = MARCA;
            productExternalObj.IsSample__c = false;
            productExternalObj.IsSampleAccessory__c = false;
            productExternalObj.TipoMaterial__c = '';
            sapProducts.add(productExternalObj);
        } // end for
        return sapProducts;
    }


} // class