/**
 * @author         Ramón Prades
 * @date           May 2025
 * @description    SAP Cases email services helper class
 * 
 * Translation prefix: tr0006
*/
@SuppressWarnings('PMD.UnusedLocalVariable') 
public class SAPCasesMailerHelper {

    public static final String SAT_FACTORY_KEY = 'SAT-FACTORY-MAIL';
    public static final String SAT_FACTORY_DEFAULT = 'DEFAULT';
    public static final String RETURN_APPROVER_KEY = 'CASE_RETURN_APPROVER'; 

    public static String[] getSATFactoryEmail(String factoryContact, String sapSalesOrg) {
        String salesOrgCode = BusinessStructureCommons.getRedirectedSalesOrg(sapSalesOrg);
        Sales_Org__c[] orgs = new SalesOrgsSelector().selectBySAPId(new Set<String>{salesOrgCode});
        String country = '';
        
        String pattern = factoryContact + '-%';
        if (orgs.size() > 0) {
            country = orgs[0].CountryCode__c;
        } 
        PorcelanosaSetting__c[] settings = [SELECT Id, Key__c, SUbkey__c, Value1__c FROM PorcelanosaSetting__c WHERE
                                            Key__c = :SAT_FACTORY_KEY and Subkey__c like :pattern];
        String emails = null;
        for (PorcelanosaSetting__c setting : settings) {
            if (String.isBlank(emails) && setting.Subkey__c.contains(factoryContact + '-' + SAT_FACTORY_DEFAULT)) {
                emails = setting.Value1__c;
            }
            if (setting.Subkey__c.contains(factoryContact + '-' + country)) {
                emails = setting.Value1__c;
            }
        }
        return emails?.split(';') ?? new List<String>();
    }
    
    public static String getReturnsApprover(Id userId) {
        User u = [SELECT Id, Sales_Office__c from User WHERE Id = :userId LIMIT 1];
        if (u == null || String.isBlank(u.Sales_Office__c)) {
            return null;
        }
        String result = null;
        try {
            PorcelanosaSetting setting = new PorcelanosaSetting(RETURN_APPROVER_KEY, u.Sales_Office__c);
            if (setting.isActive) {
                result = setting.value1;
                result = result + (String.IsNotBlank(setting.value2) ? setting.value2 : '');
                result = result + (String.IsNotBlank(setting.value3) ? setting.value3 : '');
                result = result + (String.IsNotBlank(setting.value4) ? setting.value4 : '');
            }
        } catch(ObjectNotFoundException onf) {
            result = null;
        }        
        return result;
    }

    public static String getLinkedFilesText(List<Mail.DownloadLinkInfo> links, String linksLabel) {
        String result = '';
        if (links.size() > 0) {
            result = linksLabel + '<ul>';
            for (Mail.DownloadLinkInfo info : links) {
                result += '<li><a href="' + info.url + '">' + info.fileName + '</a></li>';
            }
            result += '</ul>';
        }
        return result;
    }

}