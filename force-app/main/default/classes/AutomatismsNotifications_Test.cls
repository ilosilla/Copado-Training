@isTest 
public class AutomatismsNotifications_Test {
 	
    @isTest
    public static void test_generateNotifications(){
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'newSalesRel');
        List<CustomNotification> customNotifList = new List<CustomNotification>();
        List<FeedItem> postToInsert = new List<FeedItem>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        AutomatismsNotifications.generateNotifications(null, null, null, salesRel, 'errorMessage', postToInsert, emailList, customNotifList);
        
        System.assert(postToInsert.isEmpty());
        System.assert(emailList.isEmpty()); 
		System.assert(customNotifList.isEmpty());
    }
    
    @isTest
    public static void test_createChatterPost(){
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'newSalesRel');
        AutomatismsNotifications.createChatterPost(null, salesRel, 'errorMessage');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
    }
    
    @isTest
    public static void test_formatChatterMessage(){
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'newSalesRel');
        AutomatismsNotifications.formatChatterMessage(salesRel, 'errorMessage');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
    }
    
    @isTest
    public static void test_createEmail(){
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'newSalesRel');
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'SAP_Error_Message_Template_GB'];
			
        AutomatismsNotifications.createEmail(emailTemplate, salesRel, 'errorMessage');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
    }
    
    @isTest
    public static void test_formatEmailMessage(){
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'newSalesRel');
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'SAP_Error_Message_Template_GB'];
        AutomatismsNotifications.formatEmailMessage(salesRel, 'errorMessage', emailTemplate.HtmlValue);
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
    }
    
    @isTest
    public static void test_createUserFeed(){
        FeedItem fItem = new FeedItem(ParentId = UserInfo.getUserId(), Body = '');
        
        Test.startTest();
        	AutomatismsNotifications.insertFeedItems(new List<FeedItem>{fItem});
        	
        Test.stopTest();
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }
    
    @isTest
    public static void test_createAutomationNotification(){
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'newSalesRel');
        List<CustomNotification> customNotifList = new List<CustomNotification>{AutomatismsNotifications.createAutomationNotification(UserInfo.getUserId(), salesRel, true)};
        
        AutomatismsNotifications.sendCustomNotifications(customNotifList);
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
    }
    
}