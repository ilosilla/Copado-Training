/**
* @description Given a user and an Account, returns the Pricebook should be used. The implementation works like this:
*
*                               The User Has Pricebooks, besides of the Standard?
*                                                           |
*                                       ------------------------------------------------------------------
*                                        |                                                                |
*                                       YES                                                               NO                     
*                                        |                                                                |                         
*                           User Has a Reference Pricebook?                                 Returns the Standard Pricebook  
*                                        |                     
*                                        |                      
*                               -------------------                
*                               |                 |          
*                              YES                NO          
*                               |                 |           
*                       return Reference    return Standard 
*                           Pricebook           Pricebook   
*                                                                                                                                              
*/
    public class ReferenceTariffAssignator extends AbstractPricebookAssignator
    {
        protected User user;
    
        public override void setUser(Id usrId) {
          this.user = new UsersSelector().selectById(usrId);
        }
        
        public override void setAccount(Id accId) {
        }
    
        public override Pricebook2 getPricebook() {
    
            Map<Id, Pricebook2> mapUserPricebooks = new Map<Id, Pricebook2>();
    
            if (this.user != null) {
                List<Pricebook2> listuserPricebooks = getUserPricebooksWithTariff();

                for (Pricebook2 pb : listuserPricebooks) {
                    if (pb.IsRetailReferencePricebook__c == true) {
                        return pb;
                    }
                }
            }
    
            List<Pricebook2> standardPricebook = new PricebooksSelector().selectStandardPricebook();
            if (standardPricebook.size() == 1) {
                return standardPricebook[0];
            }
    
            return null;
    
        } // getOwner
    
        /*************************************************/
        /************* PRIVATE METHODS *******************/
        /*************************************************/
        
        /**
        * @description Gets the Pricebooks an User can work with. These are related through the Execution Context
        * @param userId
        * @return List of Pricebooks
        */
        private List<Pricebook2> getUserPricebooks() {
            List<Pricebook2> result = new List<Pricebook2>();
            if (this.user != null) {
                result = new PricebooksSelector().selectByExecutionContext(this.user.Execution_Context__c);
            }
            
            return result;
        }
        
        /**
        * @description Gets the Pricebooks an User can work with, but filtered by the ones related to a tariff. 
        * These are related through the Execution Context and the field Bzirk__c is not empty
        * @param userId
        * @return List of Pricebooks
        */
        private List<Pricebook2> getUserPricebooksWithTariff() {
            List<Pricebook2> result = new List<Pricebook2>();
            List<Pricebook2> pbooks = getUserPricebooks();
            if (pbooks.size() > 0) {
                for (Pricebook2 obj : pbooks) {
                    if (obj.isActive == true && String.isBlank(obj.Bzirk__c) == false) {
                        result.add(obj);
                    }
                }
            }
            
            return result;
        }
    } // class