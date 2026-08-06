/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-20-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class NBK_personalInfoForm_Controller {

    @AuraEnabled
    public static list<picklistWrapper> getPicklistValues(String field){
        Schema.DescribeFieldResult picklistField;
        Schema.sObjectField picklistDescribed;
        if(field == 'customerProfile'){
            picklistField = Lead.Profile__c.getDescribe();
            picklistDescribed = picklistField.getSObjectField();
        } else if (field == 'hearAbout'){
            picklistField = Lead.ReferredBy__c.getDescribe();
            picklistDescribed = picklistField.getSObjectField();
        } else if (field == 'country') {
            picklistField = PorcelanosaAddress__c.NBK_Address__CountryCode__s.getDescribe();
            picklistDescribed = picklistField.getSObjectField();
        } else if (field == 'states') {
            picklistField = PorcelanosaAddress__c.NB2B_States__c.getDescribe();
            picklistDescribed = picklistField.getSObjectField();
        } else if (field == 'appointmentType') {
            picklistField = Lead.AppointmentType__c.getDescribe();
            picklistDescribed = picklistField.getSObjectField();
        }

        Map<String, String> picklistValues = PicklistCommons.getValues(picklistDescribed);
        system.debug('# Obtengo mapa de valores ' + picklistValues);

        list<picklistWrapper> values = new list<picklistWrapper>();
        for(String val : picklistValues.keySet()){
            picklistWrapper ps = new picklistWrapper(val, val);
            values.add(ps);
        }
        system.debug(' # Retorno lista de wrapper ' + values);
        return values;
    }

    public class picklistWrapper{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public picklistWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}