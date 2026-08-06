({
    getRecordTypeDefault : function(cmp) {
        var action = cmp.get("c.getDefaultRecordType");
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            
            if(state === "SUCCESS"){
                var serverResponse = response.getReturnValue();
                console.log("serverResponse: " + serverResponse);
                
                cmp.set("v.recordTypeId", serverResponse);
                cmp.find("recordTypeEditor").reloadRecord();
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
                else if(state === "ERROR"){
                    
                    var errors = response.getError();
                    console.log( errors );
                    
                }
            
        });
        
        $A.enqueueAction(action);
    },
    
    createRecordWithDefault : function(cmp) {
        
        console.log("createRecordWithDefault");
        
        var defaultFieldValues = {};
        var simpleRecord = cmp.get("v.simpleRecord");
        var recordTypeFields = cmp.get("v.recordTypeFields");
        
        if (recordTypeFields != null) {
            if(simpleRecord.IsPersonAccount){
                defaultFieldValues.AccountId = cmp.get("v.recordId");
                defaultFieldValues.ContactId__c = simpleRecord.PersonContactId;
                defaultFieldValues.countryCode__c = simpleRecord.PersonMailingCountryCode;
                defaultFieldValues.Address__c = simpleRecord.PersonMailingStreet;
                defaultFieldValues.City__c = simpleRecord.PersonMailingCity;
                defaultFieldValues.Postcode__c = simpleRecord.PersonMailingPostalCode;
            } else {
                if(recordTypeFields.DeveloperName == "Project_retail"){
                    defaultFieldValues.AccountId = cmp.get("v.recordId");
                    defaultFieldValues.countryCode__c = simpleRecord.BillingCountryCode;
                    defaultFieldValues.Address__c = simpleRecord.BillingStreet;
                    defaultFieldValues.City__c = simpleRecord.BillingCity;
                    defaultFieldValues.Postcode__c = simpleRecord.BillingPostalCode;
                } else {
                    defaultFieldValues.AccountId = cmp.get("v.recordId");
                    defaultFieldValues.countryCode__c = simpleRecord.Owner.CountryCode;
                }
            }
        }
        
        //console.log("defaultFieldValues " + JSON.stringify(defaultFieldValues));
        
        var createAcountContactevt = $A.get("e.force:createRecord");
        createAcountContactevt.setParams({
            "entityApiName": "Opportunity",
            "defaultFieldValues": defaultFieldValues,
            "recordTypeId": cmp.get("v.recordTypeId")
        });                
        createAcountContactevt.fire();
    }
})