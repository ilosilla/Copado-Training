/**
 * @author Ramón Prades
 * @date August 2020
 *
 * @group Settings
 * @group-content ../../ApexDocContent/Settings.htm
 *
 * @description App configuration per region
 */

public class RegionalSettings {
    
    public String salesOrganization {
        get { return this.settings.SalesOrganization__c;} 
    }
    public Boolean installationsEnabled {
    	get { return this.settings.InstallationsEnabled__c;} 
    }
    
    private RegionalSettings__mdt settings;
            
    public RegionalSettings(String salesOrg) {    
        List<RegionalSettings__mdt> rlist = [Select SalesOrganization__c, Label, InstallationsEnabled__c From RegionalSettings__mdt Where SalesOrganization__c = :salesOrg];
        if (rlist.size() > 0) {
            this.settings = rlist[0];
        } else {
            this.settings = this.getDefaultValues(salesOrg);
        } 
    }

    /*
    public static ExecutionContext getUserExecutionContext() {
        String contextLabel = [Select Execution_Context__c From User Where  Id = :UserInfo.getUserId()].Execution_Context__c;
        if (ExecutionContext.context == null) {
            System.debug('Creating context');
            ExecutionContext.context =  new ExecutionContext( contextLabel );

        } else{
            System.debug('Context already loaded');
        }
        return ExecutionContext.context;
    }
	*/
    private RegionalSettings__mdt getDefaultValues(String salesOrg) {
        RegionalSettings__mdt lsettings = new  RegionalSettings__mdt();
        lsettings.SalesOrganization__c = salesOrg;
        lsettings.InstallationsEnabled__c = false;
        return settings;
    } // defaultValues
}