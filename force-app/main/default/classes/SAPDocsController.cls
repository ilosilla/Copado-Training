/**
* @author 			Ramón Prades
* @date 			November-2020
* @group 			Accounts
* @group-content 	../../ApexDocContent/Accounts.htm
* @description 	    Apex Controller for SAPDocs component (displays the list of sap docs of an account)
*/
public with sharing class SAPDocsController {

    private static String userSalesOrgs;
    
    @AuraEnabled 
    public static SAPDocsDTO getSAPDocuments(String docType, String accountId, String salesOrg) {        
        Account account = [Select Id, Name, SAP_Id__c from Account where Id = :accountId][0];
        List<sObject> theList = new List<sObject>();
        switch on docType.toUppercase() {
            when 'Q' {
                theList = readQuotes(account.SAP_Id__c, salesOrg);
            }
            when 'O' {
                theList = readOrders(account.SAP_Id__c, salesOrg);
            }
            when 'I' {
                theList = readInvoices(account.SAP_Id__c, salesOrg);
            }
        }
        SAPDocsDTO dto = new SAPDocsDTO();
        dto.variant = 'ACC';
        dto.accountId = accountId;
        dto.breadcrumb1 = account.Name;
        dto.breadcrumb2 = OrganizationUtil.getSalesOrgName(salesOrg);
        dto.sapId = account.SAP_Id__c;
        dto.items = (List<sObject>) theList;
        return dto;            
    } // getSAPDocuments

    @AuraEnabled 
    public static SAPDocsDTO getOPPDocuments(String docType, String opportunityId, String salesOrg) {
        Opportunity opp = [select Id, Name from Opportunity where Id = :opportunityId limit 1];
        SAPDocsDTO dto = new SAPDocsDTO();
        dto.permissionErrors = new List<String>();
        dto.breadcrumb1 = opp.Name;                
        dto.breadcrumb2 = '';
        dto.userSalesOrgs = [select Sales_Org__c from User where Id = :UserInfo.getUserId() limit 1].Sales_Org__c;
        switch on docType.toUppercase() {
            when 'Q' {
               readOppQuotes(opportunityId, dto);
            }
            when 'O' {
                readOppOrders(opportunityId, dto);
            }
            when 'I' {
                readOppInvoices(opportunityId, dto);
            }
        }
        removeDuplicatedErrors(dto);
        return dto;     
    } // getSAPDocuments



    /*************************************************************/

    private static List<Facturas_cabeceraSet__x> readInvoices(String sapId, String salesOrg) {
        List<Facturas_cabeceraSet__x> theList = new List<Facturas_cabeceraSet__x>();
        for (Facturas_cabeceraSet__x hdr :[select
            BillTo__c, Distchannel__c, Ordernum__c, Orderdate__c, Refer__c,
            Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c,
            Sfopportunity__c From Facturas_cabeceraSet__x
            where BillTo__c = :sapId and salesOrg__c = :salesOrg and Paid__c = ' ' order by Orderdate__c, Ordernum__c]
        ) {
            theList.add(hdr);
        }
        return theList;
    } // readInvoices

    private static List<Ofertas_cabeceraSet__x> readQuotes(String sapId, String salesOrg) {
        String completed = 'C';
        List<Ofertas_cabeceraSet__x> theList = new List<Ofertas_cabeceraSet__x>();
        for (Ofertas_cabeceraSet__x hdr :[select
                BillTo__c, Distchannel__c, Ordernum__c, Orderdate__c, Refer__c,
                Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c,
                Salesoffic__c, Sfopportunity__c 
            From Ofertas_cabeceraSet__x
            where BillTo__c = :sapId and salesOrg__c = :salesOrg and openf__c != :completed 
            order by Orderdate__c, Ordernum__c]
        ) {
            theList.add(hdr);
        }    
        return theList;
    } // readQuotes

    private static List<Pedidos_cabeceraSet__x> readOrders(String sapId, String salesOrg) {
        String completed = 'C';
        List<Pedidos_cabeceraSet__x> theList = new List<Pedidos_cabeceraSet__x>();
        for (Pedidos_cabeceraSet__x hdr :[select
                BillTo__c, Distchannel__c, Ordernum__c, Orderdate__c, Refer__c,
                Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c,
                Salesoffic__c, Sfopportunity__c 
            From Pedidos_cabeceraSet__x 
            where BillTo__c = :sapId and salesOrg__c = :salesOrg and openf__c != :completed 
            order by Orderdate__c, Ordernum__c]
        ) {
            theList.add(hdr);
        }
         System.debug('RPR Pues la lista tiene ' + theList.size());
        return theList;
    } // readQuotes

    private static void readOppQuotes(String oppId, SAPDocsDTO dto) {
        String completed = 'C';
        List<Ofertas_cabeceraSet__x> theList = new List<Ofertas_cabeceraSet__x>();
        for (Ofertas_cabeceraSet__x hdr :[select
                BillTo__c, Distchannel__c, Ordernum__c, Orderdate__c, Refer__c,
                Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c,
                Salesorg__c, Salesoffic__c, Sfopportunity__c 
            From Ofertas_cabeceraSet__x
            where Sfopportunity__c = :oppId and openf__c != :completed 
            order by Orderdate__c, Ordernum__c]
        ) {
            if (dto.userSalesOrgs.contains(hdr.Salesorg__c)) {
                theList.add(hdr);
            } else {
                dto.permissionErrors.add(hdr.Salesorg__c);
            }
        }    
        dto.items = (List<sObject>) theList;
    } // readOppQuotes

    private static void readOppOrders(String oppId, SAPDocsDTO dto) {
        String completed = 'C';
        List<pedidos_cabeceraSet__x> theList = new List<Pedidos_cabeceraSet__x>();
        for (Pedidos_cabeceraSet__x hdr :[select
                BillTo__c, Distchannel__c, Ordernum__c, Orderdate__c, Refer__c,
                Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c,
                Salesorg__c, Salesoffic__c, Sfopportunity__c 
            From Pedidos_cabeceraSet__x
            where Sfopportunity__c = :oppId and openf__c != :completed 
            order by Orderdate__c, Ordernum__c]
        ) {
            if (dto.userSalesOrgs.contains(hdr.Salesorg__c)) {
                theList.add(hdr);
            } else {
                dto.permissionErrors.add(hdr.Salesorg__c);
            }
        }    
        dto.items = (List<sObject>) theList;
    } // readOppOrders

    private static void readOppInvoices(String oppId, SAPDocsDTO dto) {
        String completed = 'C';
        List<Facturas_cabeceraSet__x> theList = new List<Facturas_cabeceraSet__x>();
        for (Facturas_cabeceraSet__x hdr :[select
                BillTo__c, Distchannel__c, Ordernum__c, Orderdate__c, Refer__c,
                Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c,
                Salesorg__c, Salesoffic__c, Sfopportunity__c 
            From Facturas_cabeceraSet__x
            where Sfopportunity__c = :oppId 
            order by Orderdate__c, Ordernum__c]
        ) {
            if (dto.userSalesOrgs.contains(hdr.Salesorg__c)) {
                theList.add(hdr);
            } else {
                dto.permissionErrors.add(hdr.Salesorg__c);
            }
        }    
        dto.items = (List<sObject>) theList;
    } // readOppInvoices


    private static void removeDuplicatedErrors(SAPDocsDTO dto) {
        if (dto.permissionErrors.size()>1) {
            Set<String> mySet = new Set<String>();
            mySet.addAll(dto.permissionErrors);
            dto.permissionErrors.clear();
            dto.permissionErrors.addAll(mySet);
        }
    }   

    // Data transfer object for sales documents (all the same)
    public class SAPDocsDTO {
        @AuraEnabled public String variant;        
        @AuraEnabled public String breadcrumb1;
        @AuraEnabled public String breadcrumb2;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String sapId;
        @AuraEnabled public List<sObject> items = new List<sObject>();
        @AuraEnabled public String userSalesOrgs;
        @AuraEnabled public List<String> permissionErrors = new List<String>();
    } // SAPDocDTO

}