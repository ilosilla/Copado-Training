/*-----------------------------------------------------------------------------------------
Author:         Jose Manuel Martin Fluxa
Company:        Neoris
Date:			05-03-2019
Description:    
Test Class:     UserHandlerTest
History
<Date>            <Author>              <Change Description>
25-03-2019		Juan Manuel Martinez	Verificar que el usuario tenga completado el campo Default_Sales_Organization__c
12-04-2019		Juan Manuel Martinez	Verificar que el usuario tenga completado el campo Country
03-05-2019		Juan Manuel Martinez	Verificar que el usuario tenga completado el campo Distribution_channel_default__c

-----------------------------------------------------------------------------------------*/

public without sharing class UserHandler implements ITrigger2{
    
    // Variable member that stores the identifiers 
    // User with works our business logic
    List<Master_relations__c> masterRelList;
    
    public void bulkBefore() {
        if( Trigger.isInsert || Trigger.isUpdate ){
            masterRelList = 
                [SELECT SalesOrg_code__c, DistributionChannel_code__c, SalesOffice_code__c FROM Master_relations__c];
        }
    }
    
    // Certain business checks are performed on
    // the IDs we have previously obtained
    
    public void beforeDelete(SObject so) {}      
    public void bulkAfter(){}
    public void beforeInsert(SObject so){
        User u = (User) so;
        Boolean resultCheck = checkUser(u);
        if(resultCheck){
            check_dependencies(u);
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so){
        User u = (User) so;
        Boolean resultCheck = checkUser(u);        
        if(resultCheck){
            check_dependencies(u);
        }        
    }
    
    public void afterInsert(SObject so){}
    public void afterUpdate(SObject oldSo, SObject so){}
    public void afterDelete(SObject so){}
    
    public void andFinally(){
    }
    
    private Boolean checkUser(User u){
        Boolean result = true;
        
        if( u.Country == null ){
            u.Country.addError(Label.User_SelectCountry);
            result = false;
        }
        
        if(String.isBlank(u.Sales_Org__c)){
            u.Sales_Org__c.addError(Label.User_SelectSalesOrg);
            result = false;
            
        } else if(String.isBlank(u.Default_Sales_Organization__c)){
            u.Default_Sales_Organization__c.addError(Label.User_SelectDefaultSalesOrg);
            result = false;
            
        } else if(!u.Sales_Org__c.contains( u.Default_Sales_Organization__c ) ){
            u.Default_Sales_Organization__c.addError(Label.User_SalesOrgMismatch);
            result = false;
            
        } else {
            u.SalesOrg_Text__c = getLabels(u.Sales_Org__c, 'Sales_Org__c');
        }
        
        if( String.isBlank(u.Distribution_channel__c) ){
            u.Distribution_channel__c.addError(Label.User_SelectDistChannel);
            result = false;
            
        } else if(String.isBlank(u.Distribution_channel_default__c)){
            u.Distribution_channel_default__c.addError(Label.User_DefaultDistChannel);
            result = false;
            
        } else if(!u.Distribution_channel__c.contains( u.Distribution_channel_default__c ) ){
            u.Distribution_channel_default__c.addError(Label.User_DistChannelMismatch);
            result = false;
            
        } else {
            u.DistributionChannel_Text__c = getLabels(u.Distribution_channel__c, 'Distribution_channel__c');
        }
        
        if( String.isBlank(u.Sales_Office__c)){
            u.Sales_Office__c.addError(Label.User_SelectSalesOffice);
            result = false;
        } else {
            u.Sales_Office_Text__c = getLabels(u.Sales_Office__c, 'Sales_Office__c');
        }
        return result;
    }
    
    private void check_dependencies(User triggerUser){
        
        if(String.isNotBlank(triggerUser.Sales_Org__c) && String.isNotBlank(triggerUser.Distribution_channel__c)){
            List<String> userSalesOrgs = triggerUser.Sales_Org__c.split(';');
            List<String> userDistChannels = triggerUser.Distribution_channel__c.split(';');
            
            String defaultSalesOrg = triggerUser.Default_Sales_Organization__c;
            String defaultDistChannel = triggerUser.Distribution_channel_default__c ;
            String defaultSalesOffice = triggerUser.Sales_Office__c;
            Boolean checkDefaultComb = false;
            
            for(String salesOrg : userSalesOrgs){
                for(integer i= userDistChannels.size()-1; i>=0; i--){ //String disChannel : userDistChannels
                    Boolean distChannelFound = false;
                    
                    for( Master_relations__c masterRel : masterRelList  ){
                        
                        if( defaultSalesOrg == masterRel.SalesOrg_code__c && 
                           defaultDistChannel == masterRel.DistributionChannel_code__c  &&
                           defaultSalesOffice == masterRel.SalesOffice_code__c){
                               checkDefaultComb = true;
                               if(distChannelFound){
                                   break;
                               }
                           }
                        
                        if( masterRel.SalesOrg_code__c == salesOrg && masterRel.DistributionChannel_code__c == userDistChannels[i]){
                            distChannelFound = true;
                            
                        }
                    }
                    
                    if(distChannelFound){
                        userDistChannels.remove(i);
                    }
                }
            }
            
            if(!userDistChannels.isEmpty()){
                triggerUser.Distribution_channel__c.addError(Label.User_WrongDistChannel + String.join(userDistChannels, ', ') + '.' );
            } else if(!checkDefaultComb){
                triggerUser.Sales_Office__c.addError( String.format(Label.User_InvalidCombination, new List<string>{defaultSalesOrg, defaultDistChannel, defaultSalesOffice}) );
            }
            
        }
        
    }
    
    private String getLabels(String values, String fieldName){
        
        List<Schema.PicklistEntry> ple = new List<Schema.PicklistEntry>();
        
        if(fieldName == 'Sales_Org__c'){
            ple = User.Sales_Org__c.getDescribe().getPicklistValues();
        	
        } else if(fieldName == 'Distribution_channel__c'){
            ple = User.Distribution_channel__c.getDescribe().getPicklistValues();
        } else if(fieldName == 'Sales_Office__c'){
            ple = User.Sales_Office__c.getDescribe().getPicklistValues();
        }
        
        List<String> labelsList = new List<String>();
        
        for( Schema.PicklistEntry f : ple){
            if(values.contains(f.getValue())){
                labelsList.add(f.getLabel());
            }
        }
        
        return String.join(labelsList, ';');
        
    }
    
}