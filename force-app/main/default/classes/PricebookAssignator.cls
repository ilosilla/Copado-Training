/**
 * @author       Ivan Losilla
 * @since        Marzo 2021
 * @group        Tools
 * @description  Returns the instance of IPricebookAssignator depending on the object and context set
 */
public class PricebookAssignator {

    public static AbstractPricebookAssignator getInstance(Id usrId) {
        User usr = new UsersSelector().selectById(usrId);
        System.debug(usr.Execution_Context__c);
        System.debug('****************************');
      return getInstance(usr.Execution_Context__c);
    }
  
    public static AbstractPricebookAssignator getInstance(String execContextLabel) {
        AbstractPricebookAssignator assignatorObject;
        
      if (execContextLabel == 'FR') {
        System.debug('A');
        System.debug('Assigned algorithm is SalesZone Assignator');
        assignatorObject = new SalesZoneTariffAssignator();
    } else {
          System.debug('B');
        System.debug('Assigned algorithm is Reference Tariff Assignator');
        assignatorObject = new ReferenceTariffAssignator();
      }
      return assignatorObject;
    }
  }