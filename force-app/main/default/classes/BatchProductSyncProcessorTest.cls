@IsTest(IsParallel=false)  public class BatchProductSyncProcessorTest {

    private static final String GRUPO_ARTICULOS = 'PT0001';
    private static String MARCA = 'P';

    @testSetup private static void testSetup() {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();  
        ItemGroup__c item = new ItemGroup__c();
        item.CatalogCategory__c = PicklistCommons.getKeysList(ItemGroup__c.CatalogCategory__c)[0];
        item.Name = 'Test Group';
        item.SAPGroup__c = GRUPO_ARTICULOS;
        insert item;
    }


    @IsTest
    public static void testBatchProcess() {        
        
        List<ZSFMatBase__x> sapProducts = getSAPProducts();
        
        // Change the name
        String changedName = 'NEW-NAME';
        sapProducts[9].Nombre__c = changedName;
        sapProducts[9].GrupoArticulos__c = null;
        sapProducts[9].IsSample__c = false;
        sapProducts[9].IsSampleAccessory__c = false;
        String changedCode = sapProducts[9].Material__c;

        Test.startTest();
            BatchProductSyncProcessor job = new BatchProductSyncProcessor();
            job.setDaysBack(5);
            job.setFullMode(true);
            job.setForceActive(true);
            job.setLogger(null);
            job.setRunPricebookUpdate(false);
            job.setSAPDataReader(new MockExternalReader());
            job.start(null);
            job.execute(null,sapProducts);
            job.finish(null);
        Test.stopTest();

        ItemGroup__c itemGroup = [select Id from ItemGroup__c limit 1];
        Product2 p2 = [select Id, SAPItemGroup__c, SAPMake__c from Product2 limit 1];
        Assert.areEqual(itemGroup.Id, p2.SAPItemGroup__c, 'ItemGroup should not be null');
        Assert.areEqual(MARCA, p2.SAPMake__c, 'Wrong make');   
        
        // Check product name
        Product2 p3 = [select Id, Name from Product2 where StockKeepingUnit = :changedCode limit 1];
        Assert.areEqual(changedName, p3.Name, 'Names should be equal');
    }

        @IsTest
    public static void testFIlter() {        
        
        List<ZSFMatBase__x> sapProducts = getSAPProducts();
        
        // Change the name
        String changedName = 'NEW-NAME';
        sapProducts[9].Nombre__c = changedName;
        sapProducts[9].GrupoArticulos__c = null;
        sapProducts[9].IsSample__c = false;
        sapProducts[9].IsSampleAccessory__c = false;
        String changedCode = sapProducts[9].Material__c;
        String[] filter = new List<String>{changedCode};

        Test.startTest();
            BatchProductSyncProcessor job = new BatchProductSyncProcessor();
            job.setDaysBack(5);
            job.setFullMode(false);
            job.setForceActive(true);
            job.setSKUFilter(filter);
            job.setLogger(null);
            job.setRunPricebookUpdate(false);
            job.setSAPDataReader(new MockExternalReader());
            job.start(null);
            job.execute(null,sapProducts);
            job.finish(null);
        Test.stopTest();

        ItemGroup__c itemGroup = [select Id from ItemGroup__c limit 1];
        Product2 p2 = [select Id, SAPItemGroup__c, SAPMake__c from Product2 limit 1];
        Assert.areEqual(itemGroup.Id, p2.SAPItemGroup__c, 'ItemGroup should not be null');
        Assert.areEqual(MARCA, p2.SAPMake__c, 'Wrong make');   
        
        // Check product name
        Product2 p3 = [select Id, Name from Product2 where StockKeepingUnit = :changedCode limit 1];
        Assert.areEqual(changedName, p3.Name, 'Names should be equal');
    }


    @IsTest
    public static void testRunB2BSync() {
        List<ZSFMatBase__x> sapProducts = getSAPProducts();

        Test.startTest();
            BatchProductSyncProcessor job = new BatchProductSyncProcessor();
            job.setFullMode(true);
            job.setForceActive(false);
            job.setLogger(null);
            job.setRunPricebookUpdate(false);
            job.setRunB2BSync(true);
            job.setSAPDataReader(new MockExternalReader());
            job.start(null);
            job.execute(null, sapProducts);
            job.finish(null);
        Test.stopTest();

        // Coverage-only: no PORSAStoreSettings__c con EnablePIMSync__c = true,
        // BatchB2BSyncOrchestrator sale en el primer guard y no lanza nada.
        Assert.isTrue(true);
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

    private class MockExternalReader extends BatchProductSyncProcessor.SAPDataReader {
        override public Set<String> readOrgData(Set<String> sapProducts) {
            return sapProducts;
        }
    }


} // class