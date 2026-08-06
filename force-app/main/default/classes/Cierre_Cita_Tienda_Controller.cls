public class Cierre_Cita_Tienda_Controller {
    
    @AuraEnabled 
    public static void saveRecord(String recordId, String companyComboboxValue, String salesOrgComboboxValue, String salesOfficeComboboxValue, DateTime dateTimeValue){
        
        Opportunity currentOpp = [SELECT Name, Company_Date__c, Sales_Org_Date__c, Sales_Office_Date__c
                                  FROM Opportunity
                                  WHERE Id =: recordId];
		
        // Obtención de nombres API
        String companyApiName, salesOrgApiName, salesOfficeApiName;
        
        // Company_Date__c
      	Schema.DescribeFieldResult companyDescribe = Opportunity.Company_Date__c.getDescribe();        
        for (Schema.PicklistEntry ple : companyDescribe.getPicklistValues()){
            
            if(ple.getLabel() == companyComboboxValue){
                companyApiName = ple.getValue();
                break;
            }
            
        }
        
        // Sales_Org_Date__c
      	Schema.DescribeFieldResult salesOrgDescribe = Opportunity.Sales_Org_Date__c.getDescribe();
        for (Schema.PicklistEntry ple : salesOrgDescribe.getPicklistValues()){
            
            if(ple.getLabel() == salesOrgComboboxValue){
                salesOrgApiName = ple.getValue();
                break;
            }            
            
        }
        
        // Sales_Office_Date__c
      	Schema.DescribeFieldResult salesOfficeDescribe = Opportunity.Sales_Office_Date__c.getDescribe();
        for (Schema.PicklistEntry ple : salesOfficeDescribe.getPicklistValues()){
           
            if(ple.getLabel() == salesOfficeComboboxValue){
                salesOfficeApiName = ple.getValue();
                break;
            }
            
        }
        
        currentOpp.Company_Date__c = companyApiName;
        currentOpp.Sales_Org_Date__c = salesOrgApiName;
        currentOpp.Sales_Office_Date__c = salesOfficeApiName;
        
        /*String hour = timeValue.substringBefore(':');
        String minutes = timeValue.substringAfter(':');
        
        System.debug(hour + minutes);
        
        Time myTime = Time.newInstance(Integer.valueOf(hour), Integer.valueOf(minutes), 0, 0);
        Date myDate = Date.valueOf(dateValue);
        
        System.debug(myTime);

        currentOpp.FechaHoraCita__c = DateTime.newInstance(myDate, myTime);*/
        
        currentOpp.Appointment_Date__c = dateTimeValue.date();
        
        //System.debug(currentOpp.Appointment_Date__c);
        
        currentOpp.Request_Store_Appointment__c = Date.today();
    
        update currentOpp;
        
    }
    
    @AuraEnabled 
    public static Map<String, List<String>> getDependentMap(String recordId, String controlFieldApiName, String dependentFieldApiName) {
        System.debug('update');
        String controllingField = controlFieldApiName.toLowerCase();
        String dependentField = dependentFieldApiName.toLowerCase();
        
        // Obtener SObjectType a partir del Id
        Id recId = Id.valueOf(recordId);
        String sObjectTypeName = recId.getSObjectType().getDescribe().getName();
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectTypeName.toLowerCase());

        System.debug(sObjectType);
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        if (sObjectType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = sObjectType.getDescribe().fields.getMap();
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;
        }
        
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        Schema.SObjectField depField = objFieldMap.get(dependentField);
        
        List<Schema.PicklistEntry> ctrlEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(depField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : ctrlEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        System.debug('objResults: ' + objResults);
        return objResults;
        
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
        
    }

}