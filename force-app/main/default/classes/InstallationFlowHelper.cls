/**
* @author Ramón Prades
* @date June 2020
*
* @group Opportunities
* @group-content ../../ApexDocContent/Opportunities.htm
*
* @description Helper methods for the REQUEST INSTALLATION flows
*/
public class InstallationFlowHelper {
  
	@InvocableMethod(label='Get Installers' description='Returns the list of installers corresponding to the specified country and postcode.' category='Opportunity')  	
    
    /****************************************************************************
     * @description Returns the list of installers assigned to the opportunity (by country and postcode)
     * @param 		idsOpportunities List of opportunity ids (just uses the first one)
     * @return 		Allocated installer (as a list of accounts)
     */    
    public static List<FlowListType> getInstallers(List<String> idsOpportunities) {
        if (!InstallationUtil.hasInstallations()) {
            throw new NotEnabledException('Installations not enabled');
        }
        List<Account> installers = new List<Account>();
        if (idsOpportunities.size()>0) {            
            if (InstallationUtil.hasInstallationRequest(idsOpportunities[0])) {
                throw new ContextException('The opportunity has already an installation');
            }            
            List<id> ids = InstallationUtil.getOpportunityInstallers(idsOpportunities[0]);            
            installers = readInstallers(ids);              
        }
        
        FlowListType result = new FlowListType();
        result.size = installers.size();
        result.theJSON = JSON.serialize(installers);
        List<FlowListType> results = new List<FlowListType>();
        results.add(result);  
        return results;
  	} // getInstallers
    
    private static List<Account> readInstallers(List<id> ids) {
        return [select Id, Name from Account where id in :ids];
    }
    
} // InstallationFlowHelper