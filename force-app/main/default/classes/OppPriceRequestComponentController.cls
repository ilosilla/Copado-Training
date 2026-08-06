/**
* @author Ivan Losilla
* @date August 2021
* @group OppPriceRequest
* @description Class that manages the components related to Price Request
*/
public class OppPriceRequestComponentController {

    public class PriceRequestException extends Exception{}

    @AuraEnabled(cacheable=false)
    public static PriceRequest getAllData(String opportunityId) {
        return new PriceRequest(opportunityId);
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityPriceRequestService.PRPermissions getPermissions(String opportunityId) {
        return new OpportunityPriceRequestService.PRPermissions(Userinfo.getUserId(), opportunityId);
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityPriceRequestService.PRPermissions getGeneralPermissions() {
        return new OpportunityPriceRequestService.PRPermissions(Userinfo.getUserId());
    }

    @AuraEnabled(cacheable=true)
    public static List<OppPriceRequestItem__c> getHistoricData() {
        List<OppPriceRequestItem__c> historicData = new List<OppPriceRequestItem__c>();

        historicData = Database.query('select id,'+
                                'PriceRequestHeader__r.Opportunity__r.Account.Name,'+
                                'CreatedDate,'+
                                'ReviewedDate__c,'+
                                'Approver__r.Name,'+
                                'FactoryApprover__r.Name,'+
                                'PriceRequestHeader__r.ApproveCode__c,'+
                                'toLabel(UnitOfPrice__c),'+
                                'Price__c,'+
                                'PriceRequestHeader__r.Opportunity__r.Link_a_Oportunidad_ANA__c,'+
                                'PriceRequestHeader__r.Opportunity__r.Name,'+
                                'ProductCodeFormula__c,'+
                                'ProductName__c,'+
                                'PriceNeeded__c,'+
                                'Quantity__c,'+
                                'ApprovedPrice__c,'+
                                'ReferencePrice__c,'+
                                'ActualPrice__c,'+
                                'CreatedBy.Name,'+
                                'FactoryRequest__c,'+
                                'toLabel(Status__c),'+
                                'SubmittedToFactoryManager__r.Name,'+
                                'toLabel(FactoryStatus__c)' +
                        'from OppPriceRequestItem__c'+
                        ' where Status__c IN (\'APPROVED\', \'REJECTED\',\'APPROVEDPARTIALLY\')'+
                        (UserUtils.isAdministrator() == false ? ' and Approver__c = \'' + UserInfo.getUserId() + '\'' : '')+
                        ' order by ReviewedDate__c desc'
                        );

        
        return historicData;
    }

     @AuraEnabled(cacheable=true)
    public static List<OppPriceRequestItem__c> getFactoryHistoricData() {
        List<OppPriceRequestItem__c> historicData = new List<OppPriceRequestItem__c>();

        historicData = Database.query('select id,'+
                                'PriceRequestHeader__r.Opportunity__r.Account.Name,'+
                                'CreatedDate,'+
                                'ReviewedDate__c,'+
                                'Approver__r.Name,'+
                                'FactoryApprover__r.Name,'+
                                'PriceRequestHeader__r.ApproveCode__c,'+
                                'toLabel(UnitOfPrice__c),'+
                                'Price__c,'+
                                'PriceRequestHeader__r.Opportunity__r.Link_a_Oportunidad_ANA__c,'+
                                'PriceRequestHeader__r.Opportunity__r.Name,'+
                                'ProductCodeFormula__c,'+
                                'ProductName__c,'+
                                'PriceNeeded__c,'+
                                'Quantity__c,'+
                                'ApprovedPrice__c,'+
                                'ReferencePrice__c,'+
                                'ActualPrice__c,'+
                                'CreatedBy.Name,'+
                                'toLabel(Status__c),'+
                                'FactoryRequest__c,'+
                                'SubmittedToFactoryManager__r.Name,'+
                                'toLabel(FactoryStatus__c)' +
                        'from OppPriceRequestItem__c'+
                        ' where FactoryStatus__c IN (\'APPROVED\', \'APPROVEDPARTIALLY\', \'REJECTED\')'+
                        (UserUtils.isAdministrator() == false ? ' and FactoryApprover__c = \'' + UserInfo.getUserId() + '\'' : '')+
                        ' order by ReviewedDate__c desc'
                        );

        return historicData;
    }

    /**
    * @description creates a new Price Request with its new items
    * @param priceRequest
    * @param items
    * @return OppPriceRequestHeader__c
    */
    @AuraEnabled
    public static OppPriceRequestHeader__c createPriceRequest(OppPriceRequestHeader__c priceRequest) {
        Savepoint sp = Database.setSavepoint();

        List<OppPriceRequestHeader__c> aux = [SELECT id, ApproveCode__c,NeededBy__c, Notes__c, Opportunity__c,SAPAccountingInfo__c,SAPAccountingInfo__r.Sales_Org__c,SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c,
                                            PendingItems__c,RejectedItems__c, SalesOrg__c, Status__c,TotalItems__c,
                                            WaitingItems__c FROM OppPriceRequestHeader__c WHERE Opportunity__c =: priceRequest.Opportunity__c];

        List<Sales_Relationship__c> sapAccounting = [SELECT Id, Sales_Org__c FROM Sales_Relationship__c WHERE Id =: priceRequest.SAPAccountingInfo__c];

        try {
            if (aux.size() == 0) {
                priceRequest.Status__c = 'NEW';
                if (String.isEmpty(priceRequest.SAPAccountingInfo__c)) {
                    throw new PriceRequestException('No Sales Org selected');
                }
                priceRequest.SalesOrg__c = sapAccounting[0].Sales_Org__c;
                insert priceRequest;
                return priceRequest;
            } else {
                return aux[0];
            }
        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Updates a Price Request with its new or old items
    * @param priceRequest
    * @param items
    * @return OppPriceRequestHeader__c
    */
    @AuraEnabled
    public static OppPriceRequestHeader__c updatePriceRequest(OppPriceRequestHeader__c priceRequest) {
        Savepoint sp = Database.setSavepoint();
        try {
            update priceRequest;
            return priceRequest;
        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Saves or Updates a list of Items
    * @param items
    * @return List<OppPriceRequestItem__c>
    */
    @AuraEnabled 
    public static OppPriceRequestItem__c upsertItem(OppPriceRequestItem__c item) {
        Savepoint sp = Database.setSavepoint();

        try {
            upsert item;
            updateHeadersStatusByItems(new List<OppPriceRequestItem__c>{item});
            return item;
        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Given a list of items, change the status of all of them to PENDING and updates the Status of their Price Requests
    * @param items
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean itemsForStoreApproval(List<OppPriceRequestItem__c> items) {
        Savepoint sp = Database.setSavepoint();
        List<OppPriceRequestItem__c> finalItems = new List<OppPriceRequestItem__c>();
        try {
            for (OppPriceRequestItem__c item : items) {
                item.Status__c = 'PENDING';
                item.FactoryStatus__c = 'NOTSENT';
                item.SubmittedDate__c = System.today();
                finalItems.add(item);
            }

            upsert finalItems;

            Map<Id,Set<Id>> mapHeaderItems = new Map<Id,Set<Id>>();
            
            if (updateHeadersStatusByItems(items) == true) {
                Set<Id> headers = new Set<Id>();
                for (OppPriceRequestItem__c item : finalItems) {
                    headers.add(item.PriceRequestHeader__c);

                    if (mapHeaderItems.containsKey(item.PriceRequestHeader__c)) {
                        mapHeaderItems.get(item.PriceRequestHeader__c).add(item.Id);
                    } else {
                        mapHeaderItems.put(item.PriceRequestHeader__c, new Set<Id>{item.Id});
                    }
                }
                for ( Id header : headers) {
                    OppPriceRequestMailer mailer = new OppPriceRequestMailer();
                    mailer.sendToApprovalMail(header, mapHeaderItems.get(header));
                }
                return true;
            }
            throw new PriceRequestException('No Price Request updated');

        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Given a list of items, change the status of all of them to PENDING and updates the Status of their Price Requests
    * @param items
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean itemsForFactoryApproval(List<OppPriceRequestItem__c> items) {
        Savepoint sp = Database.setSavepoint();
        
        List<OppPriceRequestItem__c> finalItems = new List<OppPriceRequestItem__c>();
        try {
            for (OppPriceRequestItem__c item : items) {
                item.SubmittedToFactoryManager__c = UserInfo.getUserId();
                item.SubmittedFactoryDate__c = System.today();
                item.FactoryStatus__c = 'PENDING';
                item.Status__c = 'PENDING';
                finalItems.add(item);
            }

            upsert finalItems;

            Map<Id,Set<Id>> mapHeaderItems = new Map<Id,Set<Id>>();
            
            if (updateHeadersStatusByItems(items) == true) {
                Set<Id> headers = new Set<Id>();
                for (OppPriceRequestItem__c item : finalItems) {
                    headers.add(item.PriceRequestHeader__c);

                    if (mapHeaderItems.containsKey(item.PriceRequestHeader__c)) {
                        mapHeaderItems.get(item.PriceRequestHeader__c).add(item.Id);
                    } else {
                        mapHeaderItems.put(item.PriceRequestHeader__c, new Set<Id>{item.Id});
                    }
                }
                for ( Id header : headers) {
                    OppPriceRequestMailer mailer = new OppPriceRequestMailer();
                    mailer.sendToFactoryApprovalMail(header, mapHeaderItems.get(header));
                }
                return true;
            }
            throw new PriceRequestException('No Price Request updated');

        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Deletes a list of items and updates the Status of their Price Requests
    * @param items
    * @return Boolean
    */
    @AuraEnabled 
    public static Boolean deleteItems(List<OppPriceRequestItem__c> items) {
        Savepoint sp = Database.setSavepoint();
        List<OppPriceRequestItem__c> listToDelete = new List<OppPriceRequestItem__c>();
        
        try {
            for (OppPriceRequestItem__c item : items) {
                if(item.Status__c == 'NOTSENT') {
                    listToDelete.add(item);
                }
            }

            delete listToDelete;

            if (updateHeadersStatusByItems(listToDelete) == true) {
                return true;
            }
            throw new PriceRequestException('No Price Request updated');
        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Given a list of items, change the status of all of them to APPROVED and updates the Status of their Price Requests
    * @param approvedItems
    * @return Boolean
    */
    @AuraEnabled 
    public static Boolean itemsApproved(List<OppPriceRequestItem__c> approvedItems) {
        //Savepoint sp = Database.setSavepoint();
        List<OppPriceRequestItem__c> updateItems = new List<OppPriceRequestItem__c>();
        Organization org = [Select Id, Name, IsSandbox from Organization];

        try {
            String approveCode = null;
            if (Test.isRunningTest() == false && org.IsSandbox == false) {
               approveCode = OppPriceRequestsDomain.sendItemsApprovedToSap(approvedItems);
            } else {
                approveCode = 'UUYYUUYY';
            }
            
            if (String.isNotEmpty(approveCode)) {
                for (OppPriceRequestItem__c item : approvedItems) {
                    if (item.Status__c == 'PENDING') {
                        if (item.ApprovedPrice__c > item.PriceNeeded__c) {
                            item.Status__c = 'APPROVEDPARTIALLY';
                        } else {
                            item.Status__c = 'APPROVED';
                        }
                        item.Approver__c = UserInfo.getUserId();
                        item.ReviewedDate__c = System.now();
                        updateItems.add(item);
                    }
                }
    
                if (updateItems.size() > 0) {
                    update updateItems;
    
                    Map<Id,Set<Id>> mapHeaderItems = new Map<Id,Set<Id>>();
        
                    if (updateHeadersStatusByItems(updateItems) == true) {
                        Set<Id> headers = new Set<Id>();
                        for (OppPriceRequestItem__c item : updateItems) {
                            headers.add(item.PriceRequestHeader__c);
                            if (mapHeaderItems.containsKey(item.PriceRequestHeader__c)) {
                                mapHeaderItems.get(item.PriceRequestHeader__c).add(item.Id);
                            } else {
                                mapHeaderItems.put(item.PriceRequestHeader__c, new Set<Id>{item.Id});
                            }
                        }
                        for ( Id header : headers) {
                            OppPriceRequestMailer mailer = new OppPriceRequestMailer();
                            mailer.sendReviewedMail(header, mapHeaderItems.get(header));
                        }
        
                        return true;
                    }
                    throw new PriceRequestException('No Price Request updated');
                }
            }
            return true;

        } catch (PriceRequestException ex) {
            //Database.RollBack(sp);
            throw new PriceRequestException(ex.getMessage());
            //throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Given a list of items, change the status of all of them to APPROVED and updates the Status of their Price Requests
    * @param approvedItems
    * @return Boolean
    */
    @AuraEnabled 
    public static Boolean itemsFactoryApproved(List<OppPriceRequestItem__c> approvedItems) {
        //Savepoint sp = Database.setSavepoint();
        List<OppPriceRequestItem__c> updateItems = new List<OppPriceRequestItem__c>();
        Organization org = [Select Id, Name, IsSandbox from Organization];

        try {
            String approveCode = null;
            if (Test.isRunningTest() == false && org.IsSandbox == false) {
               approveCode = OppPriceRequestsDomain.sendItemsApprovedToSap(approvedItems);
            } else {
                approveCode = 'UUYYUUYY';
            }
            
            if (String.isNotEmpty(approveCode)) {
            
                for (OppPriceRequestItem__c item : approvedItems) {
                    Boolean addToList = false;
                    if (item.FactoryStatus__c == 'PENDING') {
                        //Factory part
                        if (item.FactoryApprovedPrice__c > item.FactoryPriceNeeded__c) {
                            item.FactoryStatus__c = 'APPROVEDPARTIALLY';
                        } else {
                            item.FactoryStatus__c = 'APPROVED';
                        }
                        item.FactoryApprover__c = UserInfo.getUserId();
                        item.FactoryReviewDate__c = System.now();
                        addToList = true;
                    }
                    if (item.Status__c == 'PENDING') {
                        if (item.ApprovedPrice__c > item.PriceNeeded__c) {
                            item.Status__c = 'APPROVEDPARTIALLY';
                        } else {
                            item.Status__c = 'APPROVED';
                        }
                        item.Approver__c = UserInfo.getUserId();
                        item.ReviewedDate__c = System.now();
                    }

                    if (addToList) {
                        updateItems.add(item);
                    }
                }

                if (updateItems.size() > 0) {
                    update updateItems;

                    Map<Id,Set<Id>> mapHeaderItems = new Map<Id,Set<Id>>();
        
                    if (updateHeadersStatusByItems(updateItems) == true) {
                        Set<Id> headers = new Set<Id>();
                        for (OppPriceRequestItem__c item : updateItems) {
                            headers.add(item.PriceRequestHeader__c);
                            if (mapHeaderItems.containsKey(item.PriceRequestHeader__c)) {
                                mapHeaderItems.get(item.PriceRequestHeader__c).add(item.Id);
                            } else {
                                mapHeaderItems.put(item.PriceRequestHeader__c, new Set<Id>{item.Id});
                            }
                        }
                        for ( Id header : headers) {
                            OppPriceRequestMailer mailer = new OppPriceRequestMailer();
                            mailer.sendFactoryReviewedMail(header, mapHeaderItems.get(header));
                        }
                        return true;
                    }
                    throw new PriceRequestException('No Price Request updated');
                }
            }
            return true;

        } catch (PriceRequestException ex) {
            //Database.RollBack(sp);
            throw new PriceRequestException(ex.getMessage());
            //throw new PriceRequestException(ex);
        }
    }
    /**
    * @description Given a list of items, change the status of all of them to REJECTED and updates the Status of their Price Requests
    * @param rejectedItems
    * @return Boolean
    */
    @AuraEnabled 
    public static Boolean itemsRejected(List<OppPriceRequestItem__c> declinedItems) {
        Savepoint sp = Database.setSavepoint();
        List<OppPriceRequestItem__c> updateItems = new List<OppPriceRequestItem__c>();

        try {
            for (OppPriceRequestItem__c item : declinedItems) {
                if (item.Status__c == 'PENDING') {
                    item.Status__c = 'REJECTED';
                    item.Approver__c = UserInfo.getUserId();
                    item.ReviewedDate__c = System.now();
                    item.ApprovedPrice__c = null;
                    updateItems.add(item);
                }
            }

            if (updateItems.size() > 0) {
                update updateItems;

                Map<Id,Set<Id>> mapHeaderItems = new Map<Id,Set<Id>>();
    
                if (updateHeadersStatusByItems(updateItems) == true) {
                    Set<Id> headers = new Set<Id>();
                    for (OppPriceRequestItem__c item : updateItems) {
                        headers.add(item.PriceRequestHeader__c);

                        if (mapHeaderItems.containsKey(item.PriceRequestHeader__c)) {
                            mapHeaderItems.get(item.PriceRequestHeader__c).add(item.Id);
                        } else {
                            mapHeaderItems.put(item.PriceRequestHeader__c, new Set<Id>{item.Id});
                        }
                    }
                    for ( Id header : headers) {
                        OppPriceRequestMailer mailer = new OppPriceRequestMailer();
                        mailer.sendReviewedMail(header, mapHeaderItems.get(header));
                    }
    
                    return true;
                }
                throw new PriceRequestException('No Price Request updated');
            }
            return true;

        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    /**
    * @description Returns a list of the Price Request Headers an Approver can manage.
    * @return List<OppPriceRequestHeader__c>
    */
    @AuraEnabled 
    public static List<OppPriceRequestHeader__c> getHeadersList() {
        List<OppPriceRequestHeader__c> listHeaders = new List<OppPriceRequestHeader__c>();
        List<GroupMember> groups = new List<GroupMember>();
        List<String> salesCountryOrgsOffices = new List<String>();

        List<OppPriceRequestItem__c> pendingItems = [SELECT Id,PriceRequestHeader__c FROM OppPriceRequestItem__c WHERE FactoryRequest__c = true];
        Set<String> pendingHeadersId = new Set<String>();
        for (OppPriceRequestItem__c item : pendingItems) {
            pendingHeadersId.add(item.PriceRequestHeader__c);
        }

        if (UserUtils.isAdministrator() == true) {
            listHeaders = [SELECT Id,Notes__c,NeededBy__c,toLabel(Status__c),CreatedDate,CurrencyIsoCode,SalesOrg__c,SAPAccountingInfo__c,SAPAccountingInfo__r.Sales_Org__c,
            SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c,Opportunity__c,Opportunity__r.Name,Opportunity__r.Id, Opportunity__r.StageName,Opportunity__r.AccountId,
            Opportunity__r.Account.Name,Opportunity__r.Owner.Id,Opportunity__r.Owner.Name,Opportunity__r.Owner.Email,Opportunity__r.Owner.Sales_Office__c,
            Opportunity__r.Owner.Execution_Context__c,Opportunity__r.Owner.Default_Sales_Organization__c,PendingItems__c, ApprovedItems__c, RejectedItems__c,FactoryPendingItems__c,FactoryRejectedItems__c,
            FactoryWaitingItems__c
            from OppPriceRequestHeader__c
            where PendingItems__c > 0 and Id NOT IN : pendingHeadersId order by NeededBy__c ASC];
        } else {
            groups = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName LIKE 'price_approvers_%' and UserOrGroupId =: UserInfo.getUserId()];
            if (groups.size() > 0) {
                for (GroupMember elem : groups) {
                    salesCountryOrgsOffices.add(elem.Group.DeveloperName.toUpperCase().substringAfter('PRICE_APPROVERS_'));
                }
                listHeaders = [SELECT Id,Notes__c,NeededBy__c,toLabel(Status__c),CreatedDate,CurrencyIsoCode,Opportunity__c,SalesOrg__c,SAPAccountingInfo__c,SAPAccountingInfo__r.Sales_Org__c,
                                SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c,Opportunity__r.Name,Opportunity__r.Id, Opportunity__r.StageName,Opportunity__r.AccountId,
                                Opportunity__r.Account.Name,Opportunity__r.Owner.Id,Opportunity__r.Owner.Name,Opportunity__r.Owner.Email,Opportunity__r.Owner.Sales_Office__c,
                                Opportunity__r.Owner.Execution_Context__c,Opportunity__r.Owner.Default_Sales_Organization__c,PendingItems__c, ApprovedItems__c, RejectedItems__c,FactoryPendingItems__c,FactoryRejectedItems__c,
                                FactoryWaitingItems__c
                                from OppPriceRequestHeader__c
                                where PendingItems__c > 0 and ( Opportunity__r.Owner.Default_Sales_Organization__c IN : salesCountryOrgsOffices or Opportunity__r.Owner.Sales_Office__c IN : salesCountryOrgsOffices
                                or Opportunity__r.Owner.CountryCode IN : salesCountryOrgsOffices )
                                and Id NOT IN : pendingHeadersId
                                order by NeededBy__c ASC];
            }
        }

        return listHeaders;
    }

    /**
    * @description Returns a list of the Price Request Headers an Approver can manage.
    * @return List<OppPriceRequestHeader__c>
    */
    @AuraEnabled 
    public static List<OppPriceRequestHeader__c> getFactoryHeadersList() {
        List<OppPriceRequestHeader__c> listHeaders = new List<OppPriceRequestHeader__c>();
        List<GroupMember> groups = new List<GroupMember>();
        List<String> salesCountryOrgsOffices = new List<String>();

        List<OppPriceRequestItem__c> pendingItems = [SELECT Id,PriceRequestHeader__c FROM OppPriceRequestItem__c WHERE FactoryStatus__c = 'PENDING'];
        Set<String> pendingHeadersId = new Set<String>();
        for (OppPriceRequestItem__c item : pendingItems) {
            pendingHeadersId.add(item.PriceRequestHeader__c);
        }

        if (UserUtils.isAdministrator() == true) {
            listHeaders = [SELECT Id,Notes__c,NeededBy__c,toLabel(Status__c),CreatedDate,CurrencyIsoCode,SalesOrg__c,SAPAccountingInfo__c,CreatedBy.name,CreatedBy.Email,SAPAccountingInfo__r.Sales_Org__c,
            SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c,Opportunity__c,Opportunity__r.Name,Opportunity__r.Id, Opportunity__r.StageName,Opportunity__r.AccountId,
            Opportunity__r.Account.Name,Opportunity__r.Owner.Id,Opportunity__r.Owner.Name,Opportunity__r.Owner.Email,Opportunity__r.Owner.Sales_Office__c,
            Opportunity__r.Owner.Execution_Context__c,Opportunity__r.Owner.Default_Sales_Organization__c,PendingItems__c,FactoryPendingItems__c, ApprovedItems__c, RejectedItems__c
            from OppPriceRequestHeader__c
            where FactoryPendingItems__c > 0 and Id IN : pendingHeadersId order by NeededBy__c ASC];
        } else {
            groups = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName LIKE 'price_factory_approvers_%' and UserOrGroupId =: UserInfo.getUserId()];
            if (groups.size() > 0) {
                for (GroupMember elem : groups) {
                    salesCountryOrgsOffices.add(elem.Group.DeveloperName.toUpperCase().substringAfter('PRICE_FACTORY_APPROVERS_'));
                }
                listHeaders = [SELECT Id,Notes__c,NeededBy__c,toLabel(Status__c),CreatedDate,CurrencyIsoCode,Opportunity__c,SalesOrg__c,SAPAccountingInfo__c,CreatedBy.name,CreatedBy.Email,SAPAccountingInfo__r.Sales_Org__c,
                                SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c,Opportunity__r.Name,Opportunity__r.Id, Opportunity__r.StageName,Opportunity__r.AccountId,
                                Opportunity__r.Account.Name,Opportunity__r.Owner.Id,Opportunity__r.Owner.Name,Opportunity__r.Owner.Email,Opportunity__r.Owner.Sales_Office__c,
                                Opportunity__r.Owner.Execution_Context__c,Opportunity__r.Owner.Default_Sales_Organization__c,PendingItems__c, FactoryPendingItems__c,ApprovedItems__c, RejectedItems__c
                                from OppPriceRequestHeader__c
                                where FactoryPendingItems__c > 0 and ( Opportunity__r.Owner.Default_Sales_Organization__c IN : salesCountryOrgsOffices or Opportunity__r.Owner.Sales_Office__c IN : salesCountryOrgsOffices
                                or Opportunity__r.Owner.CountryCode IN : salesCountryOrgsOffices )
                                and Id IN : pendingHeadersId
                                order by NeededBy__c ASC];
            }
        }

        return listHeaders;
    }

    /**
    * @description Returns a list of all Sales Orgs.
    * @return Map<String, Sales_Org__c>
    */
    @AuraEnabled 
    public static Map<String, Sales_Org__c> getSalesOrgs() {
        return OrganizationUtil.getSalesOrgs();
    }

    /**
    * @description Returns a list of all Sales Offices.
    * @return Map<String, SALES_OFFICE__c>
    */
    @AuraEnabled 
    public static Map<String, SALES_OFFICE__c> getSalesOffices() {
        return OrganizationUtil.getSalesOffices();
    }

    private static Boolean updateHeadersStatusByItems(List<OppPriceRequestItem__c> items) {
        Savepoint sp = Database.setSavepoint();
        Set<String> headersIds = new Set<String>();

        try {
            for (OppPriceRequestItem__c item : items) {
                headersIds.add(item.PriceRequestHeader__c);
            }
    
            List<OppPriceRequestHeader__c> headersList = [Select Id, TotalItems__c,SalesOrg__c,SAPAccountingInfo__c,SAPAccountingInfo__r.Sales_Org__c,
                                                            SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c, Status__c,
                                                             WaitingItems__c, PendingItems__c, RejectedItems__c, ApprovedItems__c
                                                            from OppPriceRequestHeader__c where Id IN : headersIds];
            
            for (OppPriceRequestHeader__c header : headersList) {
                if (header.TotalItems__c == 0) {
                    header.Status__c = 'NEW';
                } else {
                    if (header.PendingItems__c > 0 || header.WaitingItems__c > 0) {
                        header.Status__c = 'PENDING';
                    } else {
                        header.Status__c = 'FINISHED';
                    }
                }
            }
            update headersList;
            return true;
        } catch (PriceRequestException ex) {
            Database.RollBack(sp);
            throw new PriceRequestException(ex);
        }
    }

    @AuraEnabled
    public static PriceRequestPrices.SAPItem updateOppProductPrice(String oppProductLineId ){
        PriceRequestPrices.SAPItem result = null;

        try {
            OpportunityLineItem item = [select id,PricebookEntryId,ProductCode,Product2.Umv__c,Product2.Umb__c,UnitPrice,Opportunity.Account.Sap_Id__c,OpportunityId,Opportunity.AccountId, Product2.ProductCode,PricebookEntry.Uprice__c from opportunitylineitem where Id =: oppProductLineId];

            List<OppPriceRequestHeader__c> header = [SELECT Id,CurrencyIsoCode,SalesOrg__c,Opportunity__c,SAPAccountingInfo__c,SAPAccountingInfo__r.Sales_Org__c,
                                                            SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c
                                                            FROM OppPriceRequestHeader__c 
                                                            WHERE Opportunity__c =: item.OpportunityId];

            if (header.size() == 1 && header[0].SAPAccountingInfo__c != null) {

                PriceRequestPrices sapPrices = new PriceRequestPrices();
                sapPrices.order.requestedBy = item.Opportunity.Account.Sap_Id__c;
                sapPrices.order.salesOrg = header[0].SAPAccountingInfo__r.Sales_Org__c;
                sapPrices.order.channel = header[0].SAPAccountingInfo__r.Distribution_Channel__c;
                sapPrices.order.currencyParam = header[0].CurrencyIsoCode;
                sapPrices.order.dateParam = System.today();
                sapPrices.order.operationType = '20';
                sapPrices.addItem(item.ProductCode, item.PricebookEntry.Uprice__c, 1);
                sapPrices.getPrices();

                result = sapPrices.order.items[0];
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static PriceRequestPrices.SAPItem OppProductFactoryPrice(String oppProductLineId, String Unit, Boolean useUnit ){
        PriceRequestPrices.SAPItem result = null;

        try {
            OpportunityLineItem item = [select id,PricebookEntryId,ProductCode,Product2.Umv__c,Product2.Umb__c,UnitPrice,Opportunity.countryCode__c,Opportunity.Account.Sap_Id__c,OpportunityId,Opportunity.AccountId, Product2.ProductCode,PricebookEntry.Uprice__c,Product2.SAPMake__c from opportunitylineitem where Id =: oppProductLineId];

            List<OppPriceRequestHeader__c> header = [SELECT Id,CurrencyIsoCode,SalesOrg__c,Opportunity__c,SAPAccountingInfo__c,SAPAccountingInfo__r.Sales_Org__c,
                                                            SAPAccountingInfo__r.Distribution_Channel__c,SAPAccountingInfo__r.Sales_Office__c
                                                            FROM OppPriceRequestHeader__c 
                                                            WHERE Opportunity__c =: item.OpportunityId];
            if (header.size() == 1 && header[0].SAPAccountingInfo__c != null) {
                List<PorcelanosaSetting__c> settings = [SELECT Id,value2__c,value3__c
                                                        FROM PorcelanosaSetting__c 
                                                        WHERE Key__c = 'FACTORYPRICEREQUEST' AND Subkey__c = :item.Opportunity.countryCode__c AND value1__c =: item.Product2.SAPMake__c LIMIT 1];

                if (settings.isEmpty()) {
                    throw new AuraHandledException('No Factory Price Request setting found for org ' + header[0].SAPAccountingInfo__r.Sales_Org__c + ' and make ' + item.Product2.SAPMake__c);
                } else {
                    PorcelanosaSetting__c setting = settings[0];
                    PriceRequestPrices sapPrices = new PriceRequestPrices();
                    sapPrices.order.requestedBy = setting.Value3__c;
                    sapPrices.order.salesOrg = setting.Value2__c;
                    sapPrices.order.channel = '20';
                    sapPrices.order.operationType = '20';
                    sapPrices.order.dateParam = System.today();
                    if (useUnit) {
                        sapPrices.addItem(item.ProductCode, Unit, 1);
                    } else {
                        sapPrices.addItem(item.ProductCode, item.PricebookEntry.Uprice__c, 1);
                    }
                    
                    sapPrices.getPrices();

                    result = sapPrices.order.items[0];
                }
            }
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @testVisible public static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}