/**
* @author 	Ramón Prades
* @date 	July 2020
*
* @group 	Opportunities
* @group-content ../../ApexDocContent/Opportunities.htm
*
* @description Helper methods for the NEW INSTALLATION ORDER flow
*/
public class NewInstallationOrderFlowHelper {
    
    @InvocableMethod(label='Get Installation Orders' description='Returns the list of installation orders related to a installation request' category='InstallationRequest__c')  	
 
   /***********************************************************
    * @description Searches installation orders related to an installation request
 	* @param Installation request id (as a list)
 	* @return The list of installation orders
 	*/    
	 public static List<InstallationOrder__c> getInstallationOrders(List<String> requests) {
    	List<InstallationOrder__c> orders = new List<InstallationOrder__c>();
        if ( requests.size() > 0 ) {
            orders = InstallationUtil.getInstallationOrders(requests[0]);
        }
         if (orders.size() == 0) {
             orders = null;
         }
        return orders;
    } // getInstallationOrders

} // class