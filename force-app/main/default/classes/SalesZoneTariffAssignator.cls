/**
    * @description Given a user and an Account, returns the Pricebook should be used. The implementation works like this:
    *
    *                               The User Has Pricebooks, besides of the Standard?
    *                                                           |
    *                                       ------------------------------------------------------------------
    *                                        |                                                                |
    *                                       YES                                                               NO
    *                                        |                                                                |
    *                                        |                                                                |
    *                ------------------ Account has Pricebooks ----------                     Returns the Standard Pricebook
    *                |                                                  |
    *                NO                                                YES
    *                |                                                  |
    *   User Has a Reference Pricebook? <-----|           Account has a Pricebook on the User
    *                |                       ||                  default Sales Org and can
    *                |                       ||                     the user use it?
    *         ------------------             ||                         |
    *         |                 |            ||             -----------------------------
    *        YES                NO           ||             |                           |
    *         |                 |            ||            YES                          NO
    *   return Reference    return Standard  ||             |                           |
    *       Pricebook           Pricebook    ||     return Sales Relation   ------ Account has more Sales Rel ------
    *                                        ||          Pricebook          |      with Pricebook apart  of the    |
    *                                        ||                             NO          Users default?             |
    *                                        | -----------------------------|                                      |
    *                                        |                                                                    YES
    *                                        |                                                                     |
    *                                        |                                                       --- Can the user use any of them? ---
    *                                        |                                                       |                                   |
    *                                        |                                                      YES                                  NO
    *                                        |                                                       |                                   |
    *                                        |                                                  Returns the first one                    |
    *                                        |                                                  of the other Sales Rel                   |
    *                                        |                                                                                           |
    *                                        --------------------------------------------------------------------------------------------|
    *                                                                                          
    *                                                                                          
    * @param User Id
    * @param Account Id
    * @return Pricebook to assign, or null 
    */
    public class SalesZoneTariffAssignator extends AbstractPricebookAssignator
    {
        protected List<Sales_Relationship__c> accountSalesRel;
        protected User user;
    
        public override void setAccount(Id accId) {
          this.accountSalesRel = new SalesRelationshipsSelector().selectByAccountId(new Set<Id>{accId});
        }
      
        public override void setUser(Id usrId) {
          this.user = new UsersSelector().selectById(usrId);
        }
    
        public override Pricebook2 getPricebook() {
    
            Map<Id, Pricebook2> mapUserPricebooks = new Map<Id, Pricebook2>();
            Map<Id, Pricebook2> mapAccountPricebooks = new Map<Id, Pricebook2>();
    
            if (this.user != null) {
                List<Pricebook2> listuserPricebooks = getUserPricebooks();
                Map<String, Pricebook2> mapAccountPricebooksSalesOrg = getAccountPricebooksMap();
    
                for (Pricebook2 pb : listUserPricebooks) {
                    mapUserPricebooks.put(pb.Id, pb);
                }
                
                for (Pricebook2 pb : mapAccountPricebooksSalesOrg.values()) {
                    mapAccountPricebooks.put(pb.Id, pb);
                }
                
                // El Account no tiene Pricebooks por Sales Relationships.
                if (mapAccountPricebooksSalesOrg.size() == 0) {
                    for (Pricebook2 pb : listuserPricebooks) {
                        
                        // De los que el User puede acceder, cogemos el que sea Retail Standard
                        if (pb.IsRetailReferencePricebook__c == true) {
                            return pb;
                        }
                    }
                } else {
                    // Se mira si el Account tiene Pricebook configurado en la Sales Rel que el usuario tiene seteado como default. Si lo tiene y
                    // el usuario tiene acceso, cogemos el pricebook
                    if (mapAccountPricebooksSalesOrg.containsKey(this.user.Default_Sales_Organization__c) == true) {
                        if (mapUserPricebooks.containsKey(mapAccountPricebooksSalesOrg.get(this.user.Default_Sales_Organization__c).Id) == true) {
                            return mapAccountPricebooksSalesOrg.get(this.user.Default_Sales_Organization__c);
                        }
                    } else {
                        // No hay Pricebook en la Sales rel del Account, que es la misma que la del user, pero hay mas Pricebooks por Sales relationship
                        for (String salesOrg : mapAccountPricebooksSalesOrg.keySet()){
                            // Cogemos el primer Pricebook de Sales Relationship que el usuario tenga acceso
                            if (mapUserPricebooks.containsKey(mapAccountPricebooksSalesOrg.get(salesOrg).Id) == true) {
                                return mapAccountPricebooksSalesOrg.get(salesOrg);
                            }
                        }

                    }
                    
                    for (Pricebook2 pb : listuserPricebooks) {
                        // De los que el User puede acceder, cogemos el que sea Retail Standard
                        if (pb.IsRetailReferencePricebook__c == true) {
                            return pb;
                        }
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
        * @description Gets the Pricebooks an Account works with, defined by the field Bzirk__c field on the
        * different Sales Relations of the Account, wich contains the tariff code.
        * @param accountId
        * @return Map of Pricebooks with the format SalesOrg => Pricebook
        */
        private Map<String, Pricebook2> getAccountPricebooksMap() {
            Map<String, Pricebook2> result = new Map<String, Pricebook2>();
            Set<String> listTariffs = new Set<String>();
            Map<String, Pricebook2> tariffPricebookMap = new Map<String, Pricebook2>();
            Map<String, String> tariffSalesRelMap = new Map<String, String>();
            
            if (this.accountSalesRel.size() > 0) {
                for (Sales_Relationship__c obj :this.accountSalesRel) {
                    if (String.isEmpty(obj.Bzirk__c) == false) {
                        tariffSalesRelMap.put(obj.Sales_org__c, obj.Bzirk__c);
                        listTariffs.add(obj.Bzirk__c);
                    }
                }
                
                for (Pricebook2 obj : new PricebooksSelector().selectByTariffs(listTariffs)) {
                    tariffPricebookMap.put(obj.Bzirk__c, obj);
                }
                
                for (String salesOrg : tariffSalesRelMap.keySet()) {
                    if (tariffPricebookMap.containsKey(tariffSalesRelMap.get(salesOrg))) {
                        result.put(salesOrg, tariffPricebookMap.get(tariffSalesRelMap.get(salesOrg)));
                    }
                }
            }
    
            return result;
        }
        
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
        private List<Pricebook2> getUserPricebooksWithTariff(Id userId) {
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