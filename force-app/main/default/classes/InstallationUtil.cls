/**
* @author 	Ramón Prades
* @date 	July 2020
*
* @group 	Opportunities
* @group-content ../../ApexDocContent/Opportunities.htm
*
* @description Utility meethods for Installation Requests and Installation orders
*/
public class InstallationUtil {
    
    public static String newState = 'New Request';				// New state
    public static String acceptedState = 'Site Survey';			// Installer accepted the request
    public static String rejectedState = 'Rejected';			// Installer rejected the request
    public static List<String> closedStateRequest = new List<String>{'Closed Won', 'Closed Lost', 'Rejected'};
    public static List<String> closedStateOrder = new List<String>{'Customer Satisfied', 'Customer Unsatisfied'};

    /**
    * @description Searches installation orders related to an installation request
 	* @param Installation request id 
 	* @return The list of installation orders
 	*/    
    public static List<InstallationOrder__c> getInstallationOrders(String requestId) {
    	return [select Id from InstallationOrder__c where Installation_Request__c = :requestId ];
    } // getInstallationOrders
    
    public static Boolean hasInstallationRequest(String oppId) {
        List<InstallationRequest__c> results = [select Id from InstallationRequest__c where Opportunity__c = :oppId];
        return (results.size() > 0);
    } // hasInstallationRequest

    /**
     * @description	Checks if the installation is in Accepted state
     * @param 		The request
     * @return		true if in accepted state
     */
    public static Boolean isRequestAccepted(InstallationRequest__c request) {
       return (request.State__c == InstallationUtil.acceptedState);
    } // isRequestAccepted

    /**
     * @description	Checks if the installation is in New state
     * @param 		The request
     * @return		true if in new state
     */
    public static Boolean isRequestNew(InstallationRequest__c request) {
       return (request.State__c == InstallationUtil.newState || request.State__c == null);
    } // isRequestNew
    
    /**
     * @description	Checks if the installation is in Rejected state
     * @param 		The request
     * @return		true if in new state
     */
    public static Boolean isRequestRejected(InstallationRequest__c request) {
       return (request.State__c == InstallationUtil.rejectedState);
    } // isRequestNew

    /**
     * @description	Checks if the installation Request is closed
     * @param 		The request
     * @return		true if not closed
     */
    public static Boolean isRequestClosed(InstallationRequest__c request) {
        return InstallationUtil.closedStateRequest.contains(request.State__c);
     } // isRequestNew
 
     /**
      * @description	Checks if the installation Order is closed
      * @param 		The request
      * @return		true if not closed
      */
     public static Boolean isOrderClosed(InstallationOrder__c inso) {
        return InstallationUtil.closedStateOrder.contains(inso.State__c);
     } // isRequestNew
 
     public static String requestNextActionLabel(InstallationRequest__c request) {
         if (request.State__c == 'New Request') {
             return Label.insr_next_newrequest;
         }
         if (request.State__c == 'Site Survey') {
             return Label.insr_next_sitesurvey;
         }
         if (request.State__c == '3D Design') {
             return Label.insr_next_3ddesign;
         }
         if (request.State__c == 'Cost Estimation') {
             return Label.insr_next_costestimation;
         }
         if (request.State__c == 'Quote Preparation') {
             return Label.insr_next_quotepreparation;
         }
         if (request.State__c == 'Quote Sent') {
             return Label.insr_next_quotesent;
         }
         return '';        
     }
 
     public static String orderNextActionLabel(InstallationOrder__c inso) {
         if (inso.State__c == 'New Installation') {
             return Label.inso_next_newinstallation;
         }
         if (inso.State__c == 'Ongoing') {
             if (inso.EndDate__c == null) {
                 return Label.inso_next_ongoing;
             }
             return Label.inso_next_ongoing + ' ' + inso.EndDate__c;
         }
         if (inso.State__c == 'Scheduled') {
             if (inso.StartDate__c == null) {
                 return Label.inso_next_scheduled;
             }
             return Label.inso_next_scheduled + ' ' + inso.StartDate__c;
         }
         if (inso.State__c == 'Finished') {
             return Label.inso_next_finished;
         }
         return '';        
     }
    
	/**
	 * Returns the installer assigned to a post code
     *  Old version per Post Code
	 *
    public static List<Id> getInstallers(String country, String postCode) {
        PostCodeObjectFinder objFinder = new PostCodeObjectFinder('INSTALLER');        
        objFinder.countryCode = country;
        objFinder.postCode = postCode;
        return new List<String>(objFinder.find());
    } // getInstallers
    */
    public static List<Id> getInstallers(String salesOrgs) {
        List<Id> result = new List<Id>();
        List<String> orgs = salesOrgs.split(';');
        List<Installer__c> installers = [select SalesOrg__c, Account__c from Installer__c where SalesOrg__c in :orgs];
        for (Installer__c ins :installers) {
            if (!result.contains(ins.Account__c)) {
                result.add(ins.Account__c);
            }
        }
        return result;
    } // getInstallers

    
    /**
     * Returns the installer for an opportunity
     */
    public static List<Id> getOpportunityInstallers(Id idOpportunity) {
        // Opportunity opp = [select Id, countryCode__c, Postcode__c from Opportunity where id = :idOpportunity][0];
        // return InstallationUtil.getInstallers(opp.countryCode__c, opp.Postcode__c);
        Opportunity opp = [select Id, countryCode__c, Postcode__c, OwnerId, Owner.Sales_Org__c from Opportunity where id = :idOpportunity limit 1];
        List<Id> installers = new List<Id>();
        if (String.isNotBlank(opp.Owner.Sales_Org__c)) {
            installers =InstallationUtil.getInstallers(opp.Owner.Sales_Org__c);
        }
        return installers;
    } // getOpportunityInstaller
    
    /**
     * Checks if the current user has access to the installations
     */
    public static Boolean hasInstallations() {
        return (checkChannel() && checkSalesOrgs());
	} // hasInstallations
    
    private static Boolean checkChannel() {
    	String channels = [select Distribution_Channel__c from User where id = :UserInfo.getUserId() limit 1].Distribution_Channel__c;
        return (channels.contains('60'));
    } // checkChannel
    
    private static Boolean checkSalesOrgs() {
		List<String> salesOrgs = UserUtils.getSalesOrgs();
        for (String salesOrg :salesOrgs) {
            RegionalSettings settings = new RegionalSettings(salesOrg);
            if (settings.installationsEnabled) {
                return true;
            }
        }
        return false;
    } // checkSalesOrgs
    
} // class