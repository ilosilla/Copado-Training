/**
 * Author           Ramón prades
 * Description      User object utility methods 
 * Date             May 2020
 * History              
 */

public class UserUtils {

     
    public static String getUserIdFromEmail(String email) {
        Id userId = null;
        if (String.IsNotBlank(email)) {
            List<User> users = [select Id from User where email = :email and isActive = true];
            if (users.size() > 0) {
                return users[0].Id;
            }
        }
        throw new ObjectNotFoundException('User not found');
    } // sapId    

    public static List<User> getUsersFromEmails(String[] emails) {
        List<User> users = [select Id,email, FirstName, LastName from User where email in :emails and isActive = true];
        return users;
    } // sapId    


    public static Boolean isTester() {
        String testers = 'rprades;ivan.losilla;balma.sales;';
        Boolean result = false;
        String email = UserInfo.getUserEmail();
        List<String> names  = email.split('@');
        if (names.size() > 0) {
            String name = names[0] + ';';
            result = testers.contains(name);
        }
        return result;
    }

    public static Boolean isAdministrator( ) {
        return isAdminProfile(UserInfo.getProfileId());
    } // isAdministrator

    public static Boolean isAdministrator( User user ) {
        return isAdminProfile(user.ProfileId);
    } // isAdministrator
    
    public static List<String> getSalesOrgs() {
        return getSalesOrgs(UserInfo.getUserId());
    } // getSalesOrgs 

    public static Boolean isActive(Id userId) {
        User u = [select Id, IsActive from User where Id = :userId limit 1];
        if (u != null) {
            return u.IsActive;
        } else {
            return false;
        }
    } // isActive

    public static List<String> getSalesOrgs( Id userId ) {
        User usr = [SELECT Id, Sales_Org__c from User where Id =: userId];
        return getSalesOrgs(usr);
    } // getSalesOrgs

    public static List<String> getSalesOrgs( User user ) {
        List<String> userOrgs = new List<String>(); 
        if (user.Sales_Org__c.length() > 0) {       
            userOrgs = user.Sales_Org__c.split(';');
        }                                           
        return userOrgs;                            
    } // getSalesOrgs
                
	private static Boolean isAdminProfile(String profileId) {
		return SystemSettings.adminProfiles.contains(profileId);
    } // isAdminProfile   
    
    public static Boolean isGenericUser( User user ) {
        return isGenericUser(user.Id);
    } // isMagentoUser
    
	public static Boolean isGenericUser(String userId) {
		return SystemSettings.genericUsers == null ? false : SystemSettings.genericUsers.contains(userId);
    } // isMagentoUser

    /**
    * @description Creates a hierarchy with the key=> Manager, value => subordinates
    * @return Map with, foreach userId, the usersId of his or her subordinates.
    */
    public static Map<Id,Set<Id>> getHierarchyUsers() {
        Set<Id> subordinates = new Set<Id>();
        Map<Id,Set<Id>> hierarchy = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> userRole = new Map<Id,Set<Id>>();
        List<User> usrList = [select Id, UserRoleId, UserRole.ParentRoleId from User where isActive = true];
        for (User usr : usrList) {
            if (usr.UserRole.ParentRoleId != null) {
                if (userRole.containsKey(usr.UserRole.ParentRoleId) == false) {
                    userRole.put(usr.UserRole.ParentRoleId, new Set<Id>());
                }
                subordinates = userRole.get(usr.UserRole.ParentRoleId);
                subordinates.add(usr.Id);
                userRole.put(usr.UserRole.ParentRoleId, subordinates);
            }
        }

        for (User usr : usrList) {
            if (userRole.containsKey(usr.UserRoleId) == true) {
                hierarchy.put(usr.Id, userRole.get(usr.UserRoleId));
            }
        }
        return hierarchy;
    }

	public static User getData(Id userId) {
        List<User> usrList = getData(new Set<Id>{userId});
        
        if (usrList.size() > 0) {
            return usrList[0];
        }
        return null;
    }
    
    /**
    * @description Given a list of ids, returns all data of the users with those Ids
    * @param accIds Set of Ids 
    * @return 
    *
    * @example 
    */
	public static List<User> getData(Set<Id> userIds) {
        String objectName = 'User';
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet());
        String queryString  = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + ' WHERE Id IN :userIds';

        return Database.query(queryString);
    }
    
    public static Map<Id, User> getMapUserData(Set<Id> accIds) {
		return new Map<Id, User>(getData(accIds));
    }
    
  /**
     * @description Returns the current user's default sales organization
     */
    public static String  getDefaultSalesOrg() {
        String org = '';
        List<User> users = [select Default_Sales_Organization__c from User where Id = :UserInfo.getUserId()];
        if (users.size() > 0) {
            org = users[0].Default_Sales_Organization__c;                
        }
        return org;
    } // getSalesOrg    
 
    public static String getSAPUserId(String sapId) {
        String id18 = '';
        if (!String.isBlank(sapId)) {
            List<zsforce1Set__x> users = [select sfobj__c, sapky__c, id18__c from zsforce1Set__x where sfobj__c = 'R' and sapky__c = :sapId.leftPad(10, '0')];
            if (users.size() > 0) {
                id18 = users[0].Id18__c;
            }
        }
        return id18;
    } // sapId    
 

    public static String getUserName(String id) {
        String name = '';

        if (!String.isBlank(id)) {
            List<User> users = [select id, Name from User where id = :id];
            if (users.size() > 0) {
                name = users[0].Name;
            }
        }
        return name;
    }

    public static List<Id> getPublicGroupMembers(String groupName) {
        Id[] ids = new List<Id>();
        Group[] groups = [select Id, DeveloperName from Group where DeveloperName = :groupName];
        if (groups.size() > 0) {
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :groups[0].Id]) {
                ids.add(member.UserOrGroupId);
            }
        }
        return ids;
    }

    public static List<User> getSalesOfficeUsersWithAppointment(String salesOffice) {
        return [Select 
                    Id,Default_Sales_Organization__c,Distribution_channel_default__c,Email,Execution_Context__c,FirstName,IsActive,LastName,Sales_Office__c, Appointment__c
                    From User 
                    where IsActive = true and Sales_Office__c =: salesOffice and Appointment__c = true];
    }

    public static List<User> getSalesOfficeUsers(String salesOffice) {
        return [Select 
                    Id,Default_Sales_Organization__c,Distribution_channel_default__c,Email,Execution_Context__c,FirstName,IsActive,LastName,Sales_Office__c, Appointment__c
                    From User 
                    where IsActive = true and Sales_Office__c =: salesOffice];
    }

    public static User getSalesOfficeRandomUser(String salesOffice) {
        User user = null;
        if (String.IsNotBlank(salesOffice )) {
            List<User> users = userUtils.getSalesOfficeUsersWithAppointment(salesOffice);
            if (users.size() > 0) {
                Integer index = Integer.valueOf(Math.random() * (users.size() - 1));
                user = users[index];
            }
        }
        return user;
    }

    public static List<User> getFacadeManagers(String context) {
        List<User> users = new List<User>();
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'USFacadeManagers' limit 1];
        if (gr != null) { 
            Id[] ids = new List<Id>();
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :gr.Id]) {
                ids.add(member.UserOrGroupId);
            }
            for (User usr : [select Id, Name, Execution_Context__c, IsActive, EMail from User where id in :ids]) {                
                if (usr.IsActive && usr.Execution_Context__c == context) {
                    users.add(usr);
                }
            }
        }
        return users;
    } // getFacadeManagers

    public static List<User> getProductManagers(String context) {
        List<User> users = new List<User>();
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'ProductManagers' limit 1];
        if (gr != null) { 
            Id[] ids = new List<Id>();
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :gr.Id]) {
                ids.add(member.UserOrGroupId);
            }
            for (User usr : [select Id, Name, Execution_Context__c, IsActive, EMail from User where id in :ids]) {                
                if (usr.IsActive && usr.Execution_Context__c == context) {
                    users.add(usr);
                }
            }
        }
        return users;
    } // getProductManagers

    public static List<User> getProjectsStaff(String context) {
        List<User> users = new List<User>();
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'ProjectsStaff' limit 1];
        if (gr != null) { 
            Id[] ids = new List<Id>();
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :gr.Id]) {
                ids.add(member.UserOrGroupId);
            }
            for (User usr : [select Id, Name, EMail, Execution_Context__c, IsActive from User where id in :ids]) {                
                if (usr.IsActive && usr.Execution_Context__c == context) {
                    users.add(usr);
                }
            }
        }
        return users;
    } // getProjectsStaff

    public static List<User> getKitchenManagers(String context) {
        List<User> users = new List<User>();
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'USKitchenManagers' limit 1];
        if (gr != null) { 
            Id[] ids = new List<Id>();
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :gr.Id]) {
                ids.add(member.UserOrGroupId);
            }
            for (User usr : [select Id, Name, Execution_Context__c, IsActive, EMail from User where id in :ids]) {                
                if (usr.IsActive && usr.Execution_Context__c == context) {
                    users.add(usr);
                }
            }
        }
        return users;
    } // getProductManagers


    public static List<KitchenTeam__c> getKitchenDesigners(String context) {
        List<KitchenTeam__c> designers = [select 
                Manager__c, Manager__r.Name, Manager__r.Execution_Context__c, 
                Designer__c, Designer__r.Name, Designer__r.Execution_Context__c, Designer__r.IsActive
            from KitchenTeam__c where Manager__r.Execution_Context__c = :context and Designer__r.IsActive = true];
        return designers;
    } // getProductManagers


    /*
    public static Boolean isPriceApprover(Id userId) {
        if (UserUtils.isAdministrator() == true) {
            return true;
        }
        
        List<GroupMember> groupMember = new List<GroupMember>();
        groupMember = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName LIKE 'price_approvers_%' and UserOrGroupId =: userId LIMIT 1];
        if (groupMember.size() > 0) {
            return true;
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
            groupMember = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember 
                            where Group.DeveloperName IN : managerGroups and UserOrGroupId =: userId LIMIT 1];
            if (groupMember.size() > 0) {
                return true;
            }
        }
        return false;
    }
    */

    public static Boolean hasWritePermission(Id userId, Id recordId) {
        List<UserRecordAccess>  auxAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userId AND RecordId =: recordId];
        if (auxAccess.size() > 0 && auxAccess[0].HasEditAccess == true) {
            return true;
        }
        return false;
    }

    public static Boolean checkPermissionSet(String permissionSetName) {
        return checkPermissionSet(UserInfo.getUserId(), permissionSetName);
    }

    public static Boolean checkPermissionSet(Id userId, String permissionSetName) {        
        List<PermissionSetAssignment> psas = [ select Id from PermissionSetAssignment where PermissionSetId IN 
            ( select Id from PermissionSet where Name = :permissionSetName) and AssigneeId = :userId ];
        return psas.size() > 0;
    }
    
} // class UserUtils