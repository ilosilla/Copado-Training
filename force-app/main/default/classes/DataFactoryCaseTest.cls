@isTest public class DataFactoryCaseTest {

    @TestSetup static void makeData() {
    }

    @isTest private static void testCreateCollection() {
        DataFactoryCase.createCollections(5);        
        Case[] cases = [select Id from Case where IsCollection__c = true];
        Assert.areEqual(5, cases.size(), '5 collections expected' );
    }

    @isTest private static void testCreateClaims() {
        DataFactoryCase.createClaims(5);        
        Case[] cases = [select Id from Case where IsClaim__C = true];
        Assert.areEqual(5, cases.size(), '5 claims expected' );
    }

}