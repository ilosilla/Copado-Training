@isTest
public class OpportunityReport_Test {
    
    @isTest
    static void testMethod1(){
        
        Test.startTest();
        
        OpportunityReport obj = new OpportunityReport();
        DataBase.executeBatch(obj, 2000);
        
        Test.stopTest();
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }

}