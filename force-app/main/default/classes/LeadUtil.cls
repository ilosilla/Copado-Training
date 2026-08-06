/**
* @author 			Ramón Prades
* @date 			February-2021
* @group 			Leads
* @group-content 	../../ApexDocContent/Leads.htm
* @description 	    Utility methods for Leads
*                    @deprecated
*/

public class LeadUtil {

    public static Boolean isWebRequest(Id leadId) {
        List<Lead> leads = [select Id, Source__c, RecordTypeId from Lead where Id =: leadId];
        if (leads.size() == 0) {
            throw new ObjectNotFoundException('Wrong lead id ' + leadId);
        }
        return isWebRequest(leads[0]);
    }
    
    public static Boolean isUSWebRequest(Id leadId) {
        List<Lead> leads = [select Id, Source__c, RecordTypeId from Lead where Id =: leadId];
        if (leads.size() == 0) {
            throw new ObjectNotFoundException('Wrong lead id ' + leadId);
        }
        return isUSWebRequest(leads[0]);
    }


    public static Boolean isWebRequest(lead theLead) {         
        return (thelead.Source__c == 'WEB' || theLead.RecordTypeId == RecordTypeLibrary.Lead_WebRequest);
    }
    
    public static Boolean isUSWebRequest(lead theLead) {         
        return (thelead.Source__c == 'USW' || theLead.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest);
    }

    public static String getLeadVariant(lead theLead) {
        if (theLead.Source__c == 'WEB') {
            return 'EU';
        } else if (theLead.Source__c == 'USW') {
            return 'US';
        } else {
            return null;
        }
    }
    
    /**
     * Checks if the lead should be converted to a person account
     */
    public static Boolean convertToPersonAccount(Lead lead) {
        return (String.IsBlank(lead.Company));
    } // convertToPersonAccount
    
    public static List<Lead> getData(Set<Id> leadsId) {
        String objectName = 'Lead';
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet());
        String queryString  = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + ' WHERE Id IN :leadsId';

        return Database.query(queryString);
	}

    public static Lead getData(Id leadId) {
        List<Lead> listLeads = getData(new Set<Id>{leadId});

        if (listLeads.size() == 1) {
            return listLeads[0];
        }
        return null;
	}
} // class