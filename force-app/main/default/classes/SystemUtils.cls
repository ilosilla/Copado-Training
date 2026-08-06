/**
 * @author Ivan Losilla
 * @date September 2020
 *
 * @group Utils
 * @group-content ../../ApexDocContent/SystemUtils.htm
 *
 * @description Class to create methods about System info
 */
public class SystemUtils {
    /**
   	 * @description 	It returns if we are on a Sandbox or not
   	 * @return			Are we on a Sandbox?
     */    
    public static boolean getOnSandbox(){
        boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        return runningInASandbox;
    }

    public static Long getdiffDays(datetime beginDate, datetime endDate) {
        if (beginDate == null || endDate == null) {
            return null;
        }
        
        Long dt1Long = beginDate.getTime();
        Long dt2Long = endDate.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Long hours = minutes / 60;
        Long days = hours / 24;

        return days;
    }

    /**
    * @description Registers a Debug Error on Salesforce
    * @param category category of the error
    * @param personalMessage Any message to add more info
    * @param e Exception
    *
    * @example 
    * try {
    *   throw new Exception;
    * } catch (Exception e) {
    *   SystemUtils.debugError('CITAENTIENDA', 'Error al crear una oprotunidad', e);
    * }
    */
    public static void debugError(String category, String personalMessage, Exception e) {
        try {
            Devlog__c newDevlog = new Devlog__c();
            Mail errorMail = new Mail();

            newDevlog.type__c = 'ERROR';
            newDevlog.Category__c = category;
            newDevlog.Messagepersonal__c = personalMessage;
            if (e != null) {
                newDevlog.Messageexception__c = e.getMessage();
                newDevlog.Where__c = e.getStackTraceString();
            }
            
            insert newDevlog;
            
            errorMail.sendDevelopers(
                'DevLog ERROR: [' + category + '] ' + personalMessage,
                'Hay un nuevo debug de error: ' + '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + newDevlog.Id + '"> - Click para ir al debug - </a>');
        } catch (Exception exc) {
        }
    }

    /**
    * @description Registers a Debug Warning on Salesforce
    * @param category category of the error
    * @param personalMessage Any message to add more info
    * @param e Exception
    */
    public static void debugWarning(String category, String personalMessage,  Exception e) {
        try {
            Devlog__c newDevlog = new Devlog__c();

            newDevlog.type__c = 'WARNING';
            newDevlog.Category__c = category;
            newDevlog.Messagepersonal__c = personalMessage;
            if (e != null) {
                newDevlog.Messageexception__c = e.getMessage();
                newDevlog.Where__c = e.getStackTraceString();
            }

            insert newDevlog;
        } catch (Exception exc) {
        }
    }

    /**
    * @description Registers a Debug Info on Salesforce
    * @param category category of the error
    * @param personalMessage Any message to add more info
    */
    public static void debugInfo(String category,String personalMessage) {
        try {
            Devlog__c newDevlog = new Devlog__c();

            newDevlog.type__c = 'INFO';
            newDevlog.Category__c = category;
            newDevlog.Messagepersonal__c = personalMessage;
    
            insert newDevlog;
        } catch (Exception exc) {
        }
    }

    private static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
        Set<ID> currentRoleIds = new Set<ID>();
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id from UserRole where ParentRoleId
          IN :roleIds AND ParentRoleID != null])
        currentRoleIds.add(userRole.Id);
    
        // go fetch some more rolls!
        if(currentRoleIds.size() > 0)
          currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
    
        return currentRoleIds;
      }

      public static Set<ID> getRoleSubordinateUsers(Id roleId) {
        // get all of the roles underneath the user
        Set<Id> allSubRoleIds = getAllSubRoleIds(new Set<ID>{roleId});
        
        // get all of the ids for the users in those roles
        Map<Id,User> users = new Map<Id, User>([Select Id, Name From User where
          UserRoleId IN :allSubRoleIds and isActive = true]);
          
        // return the ids as a set so you can do what you want with them
        return users.keySet();
      }

      /**
      * @description Transforms a DateTime to a User timezone value
      * @param dateTimeValue The orifinal Date Time
      */
      public static DateTime toUserTimezone(DateTime dateTimeValue) {
            TimeZone tz = UserInfo.getTimeZone();
            DateTime timeTransformed = dateTimeValue.addSeconds((tz.getOffset(dateTimeValue)/1000));

            return timeTransformed;
      }
}