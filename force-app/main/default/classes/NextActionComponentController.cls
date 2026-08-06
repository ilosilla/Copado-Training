public class NextActionComponentController {
	@AuraEnabled
    public static Map<String,String> getLabel(Id recordId) {
        Map<String,String> result = new Map<String, String>();
        result.put('stageLabel', null);
        result.put('labelAPI', null);
        String objectParam = null;
        String stageFieldName = null;
        String statusParam = null;
        List<String> possibleStageFieldNames = new List<String>{'Stage__c', 'State__c'};
            
        try {
            String objectName = recordId.getSObjectType().getDescribe().getName().toUpperCase();
            if (objectName != null) {
                objectParam = objectName.toUpperCase();
                if (objectParam.endsWith('__C') == true) {
                    for (String elem : possibleStageFieldNames) {
                        if (doesFieldExist(objectName, elem)) {
                            stageFieldName = elem;
                            break;
                        }
                    }
                } else {
                    switch on objectParam {
                        when 'OPPORTUNITY' {
                            stageFieldName = 'StageName';
                        }
                        when 'ORDER' {
                            stageFieldName = 'Status';
                        }
                    }
                }
    
                if (stageFieldName != null) {
                    List<SObject> aux = Database.query('SELECT Id, ' + stageFieldName + ', toLabel(' + stageFieldName + ') stageLabel FROM ' + objectName + ' WHERE Id = \'' + recordId + '\'');
                    if (aux.size() > 0) {
                        statusParam = (String)aux[0].get(stageFieldName);
                        result.put('stageLabel', (String)aux[0].get('stageLabel'));
                    }
                }          
            }
        } catch (ContextException exc) {}
        if (objectParam != null && statusParam != null) {
            // We get the value of the label from the NextActionText Table 
            List<NextActionText__c> aux = [SELECT Id, Label__c from NextActionText__c where Object__c =: objectParam and Status__c =: statusParam LIMIT 1];
            if (aux.size() > 0) {
                result.put('labelAPI', aux[0].Label__c);
            } else {
                result.put('labelAPI', null);
            }
        }
        return result;
    }
    
    private static boolean doesFieldExist(String objName, string fieldName)
    {
        try {
            SObject so = Schema.getGlobalDescribe().get(objName).newSObject();
            return so.getSobjectType().getDescribe().fields.getMap().containsKey(fieldName);
        }
        catch(Exception ex) {}
         
        return false;
    }
}