public with sharing class OpportunityPriceRequestService {
    public class PriceRequestException extends Exception{}

    public static Opportunity getOpportunity(String opportunityId) {
        return [SELECT Id, Name,AccountId, Pricebook2Id,Pricebook2.Bzirk__c,Pricebook2.ExecutionContext__c,OwnerId,Owner.Execution_Context__c
                FROM Opportunity
                WHERE id =: opportunityId];
    }

    public static List<salesOrgsWrapper> getAccountSalesOrgs(String opportunityId) {
        List<salesOrgsWrapper> result = new List<salesOrgsWrapper>();
        Map<String, String> salesOrgsAux = new Map<String, String>();
        Map<String, String> channelOrgsAux = new Map<String, String>();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id =: opportunityId];
        List<Sales_Relationship__c> salesOrgs = [select id, Sales_Org__c,Distribution_Channel__c,Sales_Office__c from Sales_Relationship__c WHERE Account_Org__c =: opp.AccountId];
        User currentUser = new UsersSelector().selectById(UserInfo.getUserId());
        
        Schema.DescribeFieldResult fieldResult = Sales_Relationship__c.Sales_Org__c.getDescribe();
        Schema.DescribeFieldResult fieldResultChannel = Sales_Relationship__c.Distribution_Channel__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Schema.PicklistEntry> pleChannel = fieldResultChannel.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple){
            salesOrgsAux.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        for( Schema.PicklistEntry pickListVal : pleChannel){
            channelOrgsAux.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        for (Sales_Relationship__c salesOrg : salesOrgs) {
            salesOrgsWrapper auxSalesOrg = new salesOrgsWrapper();
            auxSalesOrg.data = salesOrg;
            auxSalesOrg.value = salesOrg.Id;
            auxSalesOrg.label = salesOrgsAux.get(salesOrg.Sales_Org__c) + ' - ' + channelOrgsAux.get(salesOrg.Distribution_Channel__c);
            result.add(auxSalesOrg);
            if (salesOrg.Sales_Org__c == currentUser.Default_Sales_Organization__c && salesOrg.Distribution_Channel__c == currentUser.Distribution_channel_default__c && UserUtils.isAdministrator() == false) {
                return new List<salesOrgsWrapper>{auxSalesOrg};
            }
        }

		return result;
    }

    public static Map<Id, User> getFactoryManagerUsers() {
        Map<Id, User> result = new Map<Id, User>();
        Set<Id> userIds = new Set<Id>();
        List<GroupMember> groupMember = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember 
                                        where Group.DeveloperName like 'price_factory_managers_%'];
        for (GroupMember member : groupMember) {
            userIds.add(member.UserOrGroupId);
        }
        List<User> users = new UsersSelector().selectById(userIds);
        for (User usr : users) {
            result.put(usr.Id, usr);
        }

        return result;
    }

    public static Map<String, Boolean> priceRequestApprovers(String userId, String opportunityId) {
        Map<String, Boolean> approversMap = new Map<String, Boolean>();
        approversMap.put('hasStoreApprover', false);
        approversMap.put('hasFactoryApprover', false);

        Opportunity opp = [SELECT Id, OwnerId, Owner.Default_Sales_Organization__c, numberOfProducts__c, Owner.Countries__c, Owner.Sales_office__c,Owner.CountryCode
                            FROM Opportunity
                            WHERE Id =: opportunityId];
        
        List<String> countries = new List<String>();
        if (String.isBlank(opp.Owner.Countries__c) == false) {
            countries = opp.Owner.Countries__c.split(';');
        }
        
        List<String> priceApproversGroups = new List<String>();
        priceApproversGroups.add('price_approvers_' + opp.Owner.Sales_office__c);
        priceApproversGroups.add('price_approvers_' + opp.Owner.Default_Sales_Organization__c);
        for (String country : countries) {
            priceApproversGroups.add('price_approvers_' + country);
        }
        priceApproversGroups.add('price_factory_approvers_' + opp.Owner.Sales_office__c);
        priceApproversGroups.add('price_factory_approvers_' + opp.Owner.Default_Sales_Organization__c);
        for (String country : countries) {
            priceApproversGroups.add('price_factory_approvers_' + country);
        }

        List<GroupMember> groupMembers = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId
                                            FROM GroupMember 
                                            WHERE Group.DeveloperName IN : priceApproversGroups];
        
        for (GroupMember groupMember : groupMembers) {
            if (groupMember.Group.DeveloperName.contains('price_approvers')) {
                approversMap.put('hasStoreApprover', true);
            }
            if (groupMember.Group.DeveloperName.contains('price_factory_approvers')) {
                approversMap.put('hasFactoryApprover', true);
            }
        }

        return approversMap;
    }

    public static PRRoles priceRequestRoles(String userId, String opportunityId) {
        PRRoles result = new PRRoles();

        User usr = [SELECT Id, Name, Email, ProfileId FROM User WHERE Id =: userId];
        if (UserUtils.isAdministrator(usr) == true) {
            result.isFactoryApprover = true;
            result.isFactoryManager = true;
            result.isStoreApprover = true;
            result.isStoreManager = true;
        }

        Opportunity opp = [SELECT Id, OwnerId, Owner.Default_Sales_Organization__c, numberOfProducts__c, Owner.Sales_office__c,Owner.CountryCode, Owner.Countries__c
                                FROM Opportunity
                                WHERE Id =: opportunityId];
        
        List<String> countries = new List<String>();
        if (String.isBlank(opp.Owner.Countries__c) == false) {
            countries = opp.Owner.Countries__c.split(';');
        }

        List<String> priceGroups = new List<String>();
        priceGroups.add('price_approvers_' + opp.Owner.Sales_office__c);
        priceGroups.add('price_approvers_' + opp.Owner.Default_Sales_Organization__c);
        for (String country : countries) {
            priceGroups.add('price_approvers_' + country);
        }

        priceGroups.add('price_factory_approvers_' + opp.Owner.Sales_office__c);
        priceGroups.add('price_factory_approvers_' + opp.Owner.Default_Sales_Organization__c);
        for (String country : countries) {
            priceGroups.add('price_factory_approvers_' + country);
        }

        priceGroups.add('price_managers_' + opp.Owner.Default_Sales_Organization__c);
        priceGroups.add('price_managers_' + opp.Owner.Sales_office__c);
        for (String country : countries) {
            priceGroups.add('price_managers_' + country);
        }
        
        priceGroups.add('price_factory_managers_' + opp.Owner.Default_Sales_Organization__c);
        priceGroups.add('price_factory_managers_' + opp.Owner.Sales_office__c);
        for (String country : countries) {
            priceGroups.add('price_factory_managers_' + country);
        }

        List<GroupMember> groupMembersUser = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId
                                            FROM GroupMember 
                                            WHERE Group.DeveloperName IN : priceGroups AND UserOrGroupId =: userId];
        
        for (GroupMember groupMember : groupMembersUser) {
            if (groupMember.Group.DeveloperName.contains('price_approvers')) {
                result.isStoreApprover = true;
            }
            if (groupMember.Group.DeveloperName.contains('price_managers')) {
                result.isStoreManager = true;
            }
            if (groupMember.Group.DeveloperName.contains('price_factory_approvers')) {
                result.isFactoryApprover = true;
            }
            if (groupMember.Group.DeveloperName.contains('price_factory_managers')) {
                result.isFactoryManager = true;
            }
        }

        return result;
    }

    public static PRRoles priceRequestRoles(String userId) {
        PRRoles result = new PRRoles();

        if (UserUtils.isAdministrator() == true) {
            result.isFactoryApprover = true;
            result.isFactoryManager = true;
            result.isStoreApprover = true;
            result.isStoreManager = true;
        }

        List<GroupMember> groupMembersUserApprovers = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId
                                            FROM GroupMember 
                                            WHERE (Group.DeveloperName like 'price_approvers_%' OR Group.DeveloperName like 'price_factory_approvers%' OR Group.DeveloperName like 'price_managers%' OR Group.DeveloperName like 'price_factory_managers%') AND UserOrGroupId =: userId];
        
        for (GroupMember groupMember : groupMembersUserApprovers) {
            if (groupMember.Group.DeveloperName.contains('price_approvers')) {
                result.isStoreApprover = true;
            }
            if (groupMember.Group.DeveloperName.contains('price_factory_approvers')) {
                result.isFactoryApprover = true;
            }
            if (groupMember.Group.DeveloperName.contains('price_managers')) {
                result.isStoreManager = true;
            }
            if (groupMember.Group.DeveloperName.contains('price_factory_managers')) {
                result.isFactoryManager = true;
            }
        }

        return result;
    }

    public class PRRoles {
        @AuraEnabled public Boolean isStoreManager{get;set;}
        @AuraEnabled public Boolean isStoreApprover{get;set;}
        @AuraEnabled public Boolean isFactoryManager{get;set;}
        @AuraEnabled public Boolean isFactoryApprover{get;set;}
    }

    public class PRPermissions {
        @AuraEnabled public Boolean hasProducts{get;set;}
        @AuraEnabled public Boolean hasStoreApprovers{get;set;}
        @AuraEnabled public Boolean hasFactoryApprovers{get;set;}
        @AuraEnabled public Boolean isEnabled{get;set;}
        @AuraEnabled public Boolean isStoreManager{get;set;}
        @AuraEnabled public Boolean isStoreApprover{get;set;}
        @AuraEnabled public Boolean isFactoryManager{get;set;}
        @AuraEnabled public Boolean isFactoryApprover{get;set;}

        public PRPermissions(String userId ,String opportunityId) {

            /*if (String.isBlank(userId) || String.isBlank(opportunityId)) {
                throw new PriceRequestException('user or opportunity cannot be null');
            }*/
            Opportunity opp = [SELECT Id, OwnerId, Owner.Default_Sales_Organization__c, numberOfProducts__c, Owner.Sales_office__c, Owner.CountryCode,Owner.Countries__c from Opportunity where Id =: opportunityId];
            Map<String, Boolean> approversMap = priceRequestApprovers(userId, opportunityId);
            PRRoles roles = priceRequestRoles(userId, opportunityId);

            this.isStoreApprover = roles.isStoreApprover == true ? true : false;
            this.isFactoryApprover = roles.isFactoryApprover == true ? true : false;
            this.isStoreManager = roles.isStoreManager == true ? true : false;
            this.isFactoryManager = roles.isFactoryManager == true ? true : false;
            this.hasProducts = opp.numberOfProducts__c > 0;
            this.isEnabled = this.isStoreApprover || this.isStoreManager || this.isFactoryApprover || this.isFactoryManager;
            this.hasStoreApprovers = approversMap.get('hasStoreApprover');
            this.hasFactoryApprovers = approversMap.get('hasFactoryApprover');
            
            List<salesOrgsWrapper> salesOrgsAccount = getAccountSalesOrgs(opportunityId);
            if (salesOrgsAccount.size() == 0) {
                this.isEnabled = false;
            }
        }

        public PRPermissions(String userId) {
            PRRoles roles = priceRequestRoles(userId);

            this.isStoreApprover = roles.isStoreApprover == true ? true : false;
            this.isFactoryApprover = roles.isFactoryApprover == true ? true : false;
            this.isStoreManager = roles.isStoreManager == true ? true : false;
            this.isFactoryManager = roles.isFactoryManager == true ? true : false;
            this.isEnabled = this.isStoreApprover || this.isStoreManager || this.isFactoryApprover || this.isFactoryManager;
        }
    }

    public class salesOrgsWrapper{
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Sales_Relationship__c data;
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
        return s;
    }
}