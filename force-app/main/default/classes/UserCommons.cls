public class UserCommons {

    public static Boolean hasAccessToSalesOrg(Id userId, String salesOrg) {
        User usr = [SELECT Id, Sales_Org__c from User where Id =: userId];
        usr.Sales_Org__c += ';';
        salesOrg += ';';
        return (usr.Sales_Org__c.contains(salesOrg));
    }
       
    public static Pricebook2 getStandardUserPricebook(Id userId) {
        List<User> usr = new UsersSelector().selectById(new Set<Id>{UserInfo.getUserId()});
        List<Pricebook2> userPricebook = new PricebooksSelector().selectByExecutionContext(usr[0].Execution_Context__c);

        if (userPricebook.size() > 0) {
            return userPricebook[0];
        }
        return null;

    }

    public static Boolean isStandardAccounts(Id userId) {
        Boolean result = false;
        List<User> user = [SELECT Id FROM USER WHERE id =: userId AND Profile.Name = 'Standard Accounts'];

        if (user.size() > 0) {
            result = true;
        }
        return result;
    }

    public static Boolean isPriceApprover(Id userId, Id opportunityId) {
        if (UserUtils.isAdministrator() == true) {
            return true;
        }

        List<GroupMember> groupMember = new List<GroupMember>();
        if (opportunityId == null) {
            groupMember = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember 
            where Group.DeveloperName like 'price_approvers_%' and UserOrGroupId =: userId LIMIT 1];
            if (groupMember.size() > 0) {
                return true;
            }
        } else {
            List<Opportunity> opp = [SELECT Id, OwnerId, Owner.Default_Sales_Organization__c, numberOfProducts__c, Owner.Sales_office__c, Owner.CountryCode from Opportunity where Id =: opportunityId LIMIT 1];
            if (opp.size() > 0) {
                List<String> managerGroups = new List<String>();
                managerGroups.add('price_approvers_' + opp[0].Owner.Sales_office__c);
                managerGroups.add('price_approvers_' + opp[0].Owner.Default_Sales_Organization__c);
                managerGroups.add('price_approvers_' + opp[0].Owner.CountryCode);
                groupMember = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember 
                                where Group.DeveloperName IN : managerGroups and UserOrGroupId =: userId LIMIT 1];
                if (groupMember.size() > 0) {
                    return true;
                }
            }
        }

        return false;
    }

    public static Boolean isPriceManager(Id userId, Id opportunityId) {
        if (UserUtils.isAdministrator() == true) {
            return true;
        }

        List<GroupMember> groupMember = new List<GroupMember>();
        List<Opportunity> opp = [SELECT Id, OwnerId, Owner.Default_Sales_Organization__c, numberOfProducts__c, Owner.Sales_office__c, Owner.CountryCode from Opportunity where Id =: opportunityId LIMIT 1];
        if (opp.size() > 0) {
            List<String> managerGroups = new List<String>();
            managerGroups.add('price_managers_' + opp[0].Owner.Sales_office__c);
            managerGroups.add('price_managers_' + opp[0].Owner.Default_Sales_Organization__c);
            managerGroups.add('price_managers_' + opp[0].Owner.CountryCode);
            groupMember = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName IN : managerGroups and UserOrGroupId =: userId LIMIT 1];
            if (groupMember.size() > 0) {
                return true;
            }
        }
        return false;
    }

    public static Boolean hasSAPConnection() {
        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        Boolean result = false;

        if (context.useSAP && ( SystemSettings.sapConnectionDown == false || UserUtils.isTester())) {
            result = true;
        }

        return result;
    }

    /**
     * Checks if current user has a custom permission
     */
    public static Boolean hasCustomPermission(String customPermissionName) {
        return FeatureManagement.checkPermission(customPermissionName);
    }

    /**
     * Checks if given user has a custom permission
     */
    public static Boolean hasCustomPermission(String userId, String customPermissionName) {
        Boolean hasPermission = false;
        CustomPermission[] perms = [SELECT Id FROM CustomPermission WHERE DeveloperName = :customPermissionName];
        if (!perms.isEmpty()) {
            Set<Id> permissionSets = new Set<Id>();
            for (SetupEntityAccess access : [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId = :perms[0].Id]) {
                permissionSets.add(access.ParentId);
            }
            if (!permissionSets.isEmpty()) {
                PermissionSetAssignment[] users = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId IN :permissionSets ];
                hasPermission = (users.size() > 0);
            }
        }
        return hasPermission;
    }

    /**
     * Checks if a user has a permission set
     */
    public static Boolean hasPermissionSet(String userId, String permissionSetName) {
        List<PermissionSetAssignment> psaList = [SELECT Id FROM PermissionSetAssignment 
                                                    WHERE AssigneeId = :userId 
                                                    AND PermissionSet.Name = :permissionSetName];
        return (psaList.size() > 0);
    }

    /**
     * Checks the key Accounts (Silvestre) from a user
     */
    @AuraEnabled(cacheable=true)
    public static List<Follow__c> getKeyAccounts(String userId) {
        List<Follow__c> keyAccounts = [select id, Account__r.ownerId, Account__r.name, Owner.Alias from Follow__c where RecordType.name = 'Account' and Owner.Alias IN ('ssega','MPrio', 'JB', 'PSimar') and Account__r.ownerId =: userId];
        return keyAccounts;
    }

    /**
     * Checks the key Opportunities created/updated through Porsamarket, from a user
     */
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getKeyOpportunities(String userId) {
        List<Opportunity> keyOpps = [select id, name from Opportunity where LeadSource = 'Porsamarket' and ownerId =: userId and StageName <> 'Closed Won' and StageName <> 'Lost' and StageName <> 'Closed Lost'];
        return keyOpps;
    }
}