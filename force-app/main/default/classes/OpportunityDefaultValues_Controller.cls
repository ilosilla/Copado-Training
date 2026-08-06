public class OpportunityDefaultValues_Controller {
    /*
    @AuraEnabled
    public static String getAccountInfo(String recordId){
        return [SELECT Name FROm Account WHERE Id =: recordId].Name;
    }*/
    
    @AuraEnabled
    public static String getDefaultRecordType(){
        
        Schema.DescribeSObjectResult dsr = Opportunity.SObjectType.getDescribe();
        String defaultRecordType;
        
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti.getRecordTypeId();
            }
        }
        
        return defaultRecordType;
    }

}