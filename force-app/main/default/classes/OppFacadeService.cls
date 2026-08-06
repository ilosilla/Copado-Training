/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Opportunities
* @description 	Service class for OppFacade
*/
public class OppFacadeService {

    /**
     * Deletes a facade is no files have been attached
     */
    public static Boolean deleteFacade(Id id) {
        Boolean success = false;
        ContentVersion[] attachments = AttachmentUtils.getSObjectAttachments(id);        
        if (attachments.size() == 0) {
            OppFacade__c facade = [select Id, Opportunity__c from OppFacade__c where Id = :id limit 1];
            Opportunity opp = [select Id from Opportunity where Id = :facade.Opportunity__c limit 1];
            if (SystemSettings.CPNotificationsEnabled) {
                OppFacadeMailer mailer = new OppFacadeMailer(id);
                mailer.sendDeletedFacadeMail();
            }
            delete opp;   
            Logger.setScenario('OPP.FACADE');
            Logger.info('La fachada con id ' + id + ' ha sido borrada por no tener ficheros adjuntos');
            Logger.saveLog();
            success = true;
        } 
        return success;
    } // deleteFacade
} // class