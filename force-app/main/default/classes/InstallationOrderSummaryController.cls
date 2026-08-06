/**
* @author 			Ramón Prades
* @date 			July 2020
*
* @group 			Installation Order
* @group-content 	../../ApexDocContent/Opportunities.htm
*
* @description 		Apex controler for InstallationOrderSummary componenent
*/
public class InstallationOrderSummaryController {
    
	/**
     * @description Searches the installation order related to a request
 	 * @param 		The installation request id 
 	 * @return 		The installation orders found (the first one if there are several)
	*/        
    @AuraEnabled 
    public static InstallationOrder__c getOrderFromRequest(String requestId) {
        InstallationOrder__c order = null;
        String fields = 'Id, CreatedById, CustomerComments__c, EndDate__c,  Finished__c, Notes__c, Name, Installation_Request__c, InstallerAccount__c,' +           
						' LastModifiedById,OpportunityId__c, OwnerId, StartDate__c, State__c ';
        String sql = 'select ' + fields + ' from InstallationOrder__c where Installation_Request__c = :requestId';
        if (requestId <> null) {
            List<InstallationOrder__c> orders = Database.query(sql);
            if (orders.size() > 0) {
                order = orders[0];
            }
        }
        return order;
    } // getOrderFromRequest

}