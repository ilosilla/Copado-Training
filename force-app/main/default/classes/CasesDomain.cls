/**
* @author 		Ramón Prades
* @date 		April 2023
* @group 		Cases
* @description 	Cases domain layer class
*/ 
public class CasesDomain extends zflib_TriggerDomainClass {  

    public static final String MULTI_PLANT_SALES_ORGS = '615'; 

    // Common status
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_REJECTED = 'Rejected';

    // Collection Status
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_READY = 'Ready';
    public static final String STATUS_COLLECTED = 'Collected';
    public static final String STATUS_INVOICED = 'Invoiced';

    // Claim Status
    public static final String CLAIM_STATUS_CONSIDERATION = 'Consideration';
    public static final String CLAIM_STATUS_PROPOSAL = 'Proposal';
    public static final String CLAIM_STATUS_AGREEMENT = 'Agreement';
    public static final String CLAIM_STATUS_EXECUTION = 'Execution';
    public static final String CLAIM_STATUS_CLOSED = 'Closed';

    public static final String PSET_COLLECTIONS_MANAGER = 'CASE_COLLECTIONS_MANAGER';
    public static final String CLAIM_EDITOR_PERMISSION = 'CASE_CLAIMS_EDITOR';
    public static final String CLAIM_APPROVER_CUSTOM_PERMISSION = 'CASEApproveClaims';
    public static final String COL_APPROVER_CUSTOM_PERMISSION = 'CASEApproveCollections';    

    private static Map<String, SAPCasesSettings__c> settingsMap = new Map<String, SAPCasesSettings__c>();

    public static SAPCasesSettings__c getSAPSettings(String salesOrg) {
        //Uses the sales org redirection if any (i.e. 517 instead of 507)
        String currentSalesOrg = BusinessStructureCommons.getRedirectedSalesOrg(salesOrg);
        if (settingsMap.containsKey(currentSalesOrg)) {
            return settingsMap.get(currentSalesOrg);
        } else {
            SAPCasesSettings__c settings = SAPCasesSettings__c.getValues(currentSalesOrg);
            settingsMap.put(currentSalesOrg, settings);
            return settings;
        }
   }

   /**
    * Returns the settings for the sales organization associated with the invoice plant. 
    * If no matching organization is found, returns the input organization.
    */    
   public static SAPCasesSettings__c getSAPSettings(String salesOrg, String sapInvoice) {
        String defaultSalesOrg = BusinessStructureCommons.getRedirectedSalesOrg(salesOrg) ?? '';
        String selectedSalesOrg = defaultSalesOrg;
        if (MULTI_PLANT_SALES_ORGS.contains(defaultSalesOrg) && String.isNotBlank(sapInvoice)) {
            Facturas_posicionesSet__x[] records = [select Werks__c from Facturas_posicionesSet__x where Ordernum__c = :sapInvoice];
            if (records.size() > 0) {
                selectedSalesOrg = BusinessStructureCommons.getSalesOrgByPlant(records[0].Werks__c) ?? defaultSalesOrg;
            }
        }
        return getSAPSettings(selectedSalesOrg);
   }

   /**
    * Returns the settings for the sales organization associated with the invoice plant. 
    * If no matching organization is found, returns the input organization.
    */    
   public static SAPCasesSettings__c getSAPSettings(String salesOrg, String sapInvoice, String Plant) {
        String defaultSalesOrg = BusinessStructureCommons.getRedirectedSalesOrg(salesOrg) ?? '';
        String selectedSalesOrg = defaultSalesOrg;
        if (MULTI_PLANT_SALES_ORGS.contains(defaultSalesOrg) && String.isNotBlank(sapInvoice)) {
            if (String.isNotBlank(Plant)) {
                selectedSalesOrg = BusinessStructureCommons.getSalesOrgByPlant(Plant) ?? defaultSalesOrg;
            }
        }
        return getSAPSettings(selectedSalesOrg);
   }


    public CasesDomain() {
        super();
        this.setAssignDefaultsOnUpdate(true);
    }

    public CasesDomain(List<Case> cases) {
        super(cases);
        this.setAssignDefaultsOnUpdate(true);
    }

    public override zflib_TriggerDomainClass cast() {
        return (CasesDomain) this;
    } 

    public override Type getSObjectType() {
        return CasesDomain.class;
    }

    /*********************************************************/
    /**************** BUSINESS LOGIC METHODS *****************/
    /*********************************************************/

    /*
     * After Insert
     */
    public override void onAfterInsert() { 
        this.sendCustomerReceipts();
        //this.sendClaimsToFactory();
    }

    /*
     * After update
     */
    public override void onAfterUpdate(Map<Id,SObject> existing) { 
        this.ExistingRecords = existing;
        List<Case> claims = new List<Case>();
        Set<Id> factoryClaims = new Set<Id>();
        for (Case c : (List<Case>) this.Records) {
            if (c.IsClaim__c) {
                Case beforeCase = (Case) this.ExistingRecords.get(c.Id);
                if (c.Status == CLAIM_STATUS_PROPOSAL) {
                    if (beforeCase.Status == CLAIM_STATUS_CONSIDERATION ) {
                        claims.add(c);
                    }
                } 
                if (c.Status == CLAIM_STATUS_CLOSED && beforeCase.Status != CLAIM_STATUS_CLOSED) {
                    // Only Factory Liability sent to the factory system API
                    if (c.Liability__c == 'G1') {
                        factoryClaims.add(c.Id);
                    }
                } else if (c.FactoryInquiryDate__c != null && beforeCase.FactoryInquiryDate__c == null) {
                    factoryClaims.add(c.Id);
                }
            } 
        }
        if (claims.size() > 0) {
            ObjectAuditTrailsService.logClaimSolutionChanged(claims);
        }
        if (factoryClaims.size() > 0) {
            FactoryQualityEndpoint endpoint = new FactoryQualityEndpoint(factoryClaims);
            endpoint.doRequests();
        }
        this.notifyNewClaims();
    }

    /*     
     * Sets the flags that define the case type
     */
    public override void onApplyDefaults() {          
        for (Case c : (List<Case>) this.Records) {
            c.isCollection__c = (c.RecordTypeId == RecordTypeLibrary.Case_SAPInvoice);
            c.isClaim__c = (c.RecordTypeId == RecordTypeLibrary.Case_SAPClaim);
            if (c.IsCollection__c) {
                if (this.isInsert) {
                     SAPCasesSettings__c settings = getSAPSettings(c.SalesOrg__c, c.SAPInvoice__c, c.Plant__c); 
                     c.RestockFee__c = settings?.COL_RestockingCharges__c ?? false;
                }
                if (c.Status == STATUS_APPROVED && !c.Approved__c) {
                    c.Approved__c = true;
                    c.ApprovedBy__c = UserInfo.getUserId();
                    c.ApprovalDate__c = System.today();        
                }
                this.setCollectionStatus(c);
            } else if (c.IsClaim__c) {
                this.setClaimDefaults(c);
            } 
            // Status timestamp
            if (this.isInsert || c.Status != ((Case) this.ExistingRecords.get(c.Id)).Status) {
                c.StatusTimestamp__c = Datetime.now();
            }
            // Claim status change rule
        }
    } // onApplyDefaults

    /*
     * Validations
     */
    public override void onValidate() {  
        for (Case c : (List<Case>) this.Records) {
            if (c.isCollection__c || c.isClaim__c) {
                this.validateSAPCase(c);
            }
        }
    } // onValidate

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /************** *******************************************/

    /*
     * Sets the value of the pseudo-formula fields.
     * Pseudo-formulas are fields that should be a formula but that we decide to use the trigger to set the values.
     */
    private void setPseudoFormulas(Case c, Case before) {
        Boolean isNew = (c.Id == null);
        if (c.isClaim__c && (isNew || c.Product != before?.Product || c.Problem__c != before?.Problem__c || c.ProductType__c != before?.ProductType__c)) {
            String makeProblem = c.SAPMake__c + '-' + c.Problem__c;
            if (makeProblem != c.ReportedMakeProblem__c) {
                c.ReportedMakeProblem__c = makeProblem;                
            }
            String typeProblem =  c.SAPMake__c + '-' + c.ProductType__c + '-' + c.Problem__c;
            if (String.IsBlank(c.ProductType__c)) {
                typeProblem = null;
            }
            if (typeProblem != c.ReportedTypeProblem__c) {
                c.ReportedTypeProblem__c = typeProblem;                
            }
        }
    }

    /*
     * Sends an email to the customer when the claim is created
     */
    private void sendCustomerReceipts() {
        for (Case c : (List<Case>) this.Records) {
            if (c.IsClaim__c) {
                SAPCasesSettings__c settings = getSAPSettings(c.SalesOrg__c, c.SAPInvoice__c, c.Plant__c);            
                if ((settings?.CLAIM_SendCustomerReceipt__c) ?? false) {
                    if (this.isInsert) { 
                        SAPCasesMailerService.AsyncSendClaimReceipt(c.Id);
                    }
                }
            }
        }
    }

    /**
     * Notify the claim to the new owner
     */
    private void notifyNewClaims() {
        for (Case c : (List<Case>) this.Records) {
            if (!c.IsClaim__c) {
                continue;
            }  
            if (c.OwnerId != UserInfo.getUserId()) {
                SAPCasesSettings__c settings = getSAPSettings(c.SalesOrg__c, c.SAPInvoice__c, c.Plant__c);     
                Boolean notify =  (settings?.CLAIM_NotifyNewToOwner__c || String.isNotBlank(settings?.CLAIM_NotifyNewTo__c)) ?? false;     
                if (notify) {
                    if (this.isInsert) {
                        SAPCasesMailerService.AsyncNotifyNewClaim(c.Id);
                    } else if (this.isUpdate) {
                        Case beforeCase = (Case) this.ExistingRecords.get(c.Id);
                        if (c.OwnerId != beforeCase.OwnerId) {
                            SAPCasesMailerService.AsyncNotifyNewClaim(c.Id);
                        }
                    }                    
                }
            }
        }
    }
     
    private void setClaimDefaults(Case c) {
        Case beforeCase = (Case) this.ExistingRecords?.get(c.Id);
        if (this.isInsert || beforeCase.Status != c.Status) {
            if (c.Status == CLAIM_STATUS_CONSIDERATION) {
                this.setClaimConsiderationDefaults(c);
            } else if (c.Status == CLAIM_STATUS_PROPOSAL) {
                this.setClaimProposalDefaults(c);
            } else if (c.Status == CLAIM_STATUS_AGREEMENT) {
                this.setClaimAgreementDefaults(c);
            }
        } // if isInsert
        if (this.isInsert) {
            this.setPseudoFormulas(c, null);
            this.setNewClaimOwner(c); 
        } else if (this.isUpdate) {
            if (c.Compensation__c == 0 || c.Compensation__c == null) {
                c.ApprovalRequested__c = null;
            }
            this.setPseudoFormulas(c, beforeCase);
            this.reassignClaimOwner(c);
        } 
    }

    private void reassignClaimOwner(Case c) {
        // If the case owner is a queue and an editor saves it, assign it to the editor
        Schema.SObjectType sObjectType = c.ownerId.getSObjectType();
        String sObjectName = sObjectType.getDescribe().getName();
        if (sObjectName?.toLowerCase() == 'group' ) {
            if (UserCommons.hasPermissionSet(UserInfo.getUserId(), CLAIM_EDITOR_PERMISSION) || FeatureManagement.checkPermission('CASE_CLAIMS_EDITOR')) {
                c.ownerId = UserInfo.getUserId();
            } 

        }
    }

    private void setNewClaimOwner(Case c) {
        SAPCasesSettings__c settings = CasesDomain.getSAPSettings(c.SalesOrg__c, c.SAPInvoice__c, c.Plant__c);
        Id ownerId = null;

        // If the user is an editor, he's the owner
        if (UserCommons.hasPermissionSet(UserInfo.getUserId(), CLAIM_EDITOR_PERMISSION) || FeatureManagement.checkPermission('CASE_CLAIMS_EDITOR')) {
            ownerId = UserInfo.getUserId();
        } else if (settings != null) {
            // If all claims go to a user in settings, assign it
            if (ownerId == null && String.IsNotBlank(settings.CLAIM_AssignTo__c)) {
                try {
                    ownerId = UserUtils.getUserIdFromEmail(settings.CLAIM_AssignTo__c);
                } catch(Exception ex) {
                    ownerId = null;
                }
            }  
            // If user is not editor and no default owner in settings, use the queue
            if (ownerId == null && String.IsNotBlank(settings.CLAIM_QueueDevName__c)) {
                QueueSobject[] queues =  [SELECT Id, Queue.Name, Queue.Id, Queue.DeveloperName from QueueSobject 
                                    where Queue.DeveloperName = :settings.CLAIM_QueueDevName__c];
                if (queues.size() > 0) {
                    ownerId = queues[0].Queue.Id;
                }
            }
        }
        // If there's no owner, use the current user
        if (ownerId == null) {
            ownerId = UserInfo.getUserId(); // Default if everything else has failed
        }
        c.OwnerId = ownerId;
    }

    private void setClaimConsiderationDefaults(Case c) {
        c.ProposalDate__c = null;
        c.CustomerAgreed__c = null;
        c.RejectionReason__c = '';
    }

    private void setClaimProposalDefaults(Case c) {
        if (c.ProposalDate__c == null) {
            c.ProposalDate__c = Date.today();
        }
        c.CustomerAgreed__c = null;
        c.RejectionReason__c = '';
    }

    private void setClaimAgreementDefaults(Case c) {
        if (c.ProposalDate__c == null) {
            c.ProposalDate__c = Date.today();
        }
        c.customerAgreed__c = Date.today();
        c.RejectionReason__c = '';
    }

    private void setCollectionStatus(Case sapCase) {
        if (sapCase.Status == CasesDomain.STATUS_NEW && sapcase.Approved__c) {
            sapCase.Status = CasesDomain.STATUS_APPROVED;
        }
        Boolean statusOK = (sapCase.Status == CasesDomain.STATUS_APPROVED || sapCase.Status == CasesDomain.STATUS_READY || sapCase.Status == CasesDomain.STATUS_COLLECTED || sapCase.Status == CasesDomain.STATUS_INVOICED);        
        if (statusOK) {    
            if (sapCase.SAPCreditNote__c != null) {
                sapCase.Status = CasesDomain.STATUS_INVOICED;
            }  else if (sapCase.SAPGoodsPosted__c) {
                sapCase.Status = CasesDomain.STATUS_COLLECTED;
            } else if (sapCase.SAPOrderNumber__c != null) {                
                sapCase.Status = CasesDomain.STATUS_READY;
            }
        }
    }

    private void validateSAPCase(Case sapCase) {
        // All SAP Cases must have a SAP invoice
        if (String.IsBlank(sapCase.SAPInvoice__c)) {
            this.addRecordError(sapCase, System.label.error_invoice_required, 'SAPInvoice__c'); // The invoice number ius required
        }

        // ANd the invoice can't be changed
        if (this.isUpdate) {
            Case beforeCase = (Case) this.ExistingRecords.get(sapCase.Id);
            if (beforeCase.SAPInvoice__c != null && beforeCase.SAPInvoice__c != sapCase.SAPInvoice__c) {
                this.addRecordError(sapCase, System.label.error_invoice_fixed); // 'SAP Invoice cannot be changed'
            }
            if (beforeCase.AccountId !=null && beforeCase.AccountId != sapCase.AccountId) {
                this.addRecordError(sapCase, System.label.error_account_fixed); // 'The account cannot be changed'
            }    
        }

        // Validate collection instructions
        if (sapCase.isCollection__c) {            
            this.validateCollection(sapCase);
        } else if (sapCase.IsClaim__c) {
            this.validateClaim(sapCase);
        }
    } // validateSAPCase

    /**
     * Validates collection instructions for collections in READY status (and superior)
     * 
     * No SOQL sentences here!
     */
    private void validateCollection(Case sapCase) {

        // No validation required if NEW or REJECTED
        if (sapCase.Status == CasesDomain.STATUS_NEW || sapCase.Status == CasesDomain.STATUS_REJECTED) {
            return;
        }

        // Credit Order required fopr ready and later
        if (sapCase.Status == CasesDomain.STATUS_READY && sapCase.SAPOrderNumber__c == null) {
            this.addRecordError(sapCase, System.label.case_error_sap_returns_required, 'SAPOrderNumber__c');   // SAP Returns Order number required'
        }
        
        if (sapCase.Status == STATUS_COLLECTED) {
            if (sapCase.SAPDeliveryNumber__c == null) {
                String txt = System.label.case_error_status_no_delivery.replace('{0}', sapCase.Status); // 'Status XXX not allowed unless there is a delivery note in SAP'
                this.addRecordError(sapCase, txt , 'SAPGoodsPosted__c');
            }
            if (!sapCase.SAPGoodsPosted__c) {
                String txt = System.label.case_error_status_no_goods.replace('{0}', sapCase.Status); // 'Status XXX not allowed until goods have been received                 
                this.addRecordError(sapCase, txt, 'SAPGoodsPosted__c');
            }
        }
        
        if (sapCase.Status == CasesDomain.STATUS_CLOSED && sapCase.CreditRequired__c && sapCase.SAPCreditNote__c == null) {
            this.addRecordError(sapCase, System.label.case_error_sap_credit_required, 'SAPCreditNote__c'); // 'SAP Credit Note number required to close this collection'
        }

        // if (sapCase.Status == STATUS_CLOSED) return;
    } // validateCollectionInstructions

    /**
     * Validates claims
     * 
     * Avoid SOQL sentences here
     */
    private void validateClaim(Case sapCase) {

        if (sapCase.Status == CasesDomain.STATUS_REJECTED && String.IsBlank(sapCase.RejectionReason__c)) {
            this.addRecordError(sapCase, System.label.case_error_rejection_required); // 'A rejection reason is required'
        }

        // No validation required if CONSIDERATION or REJECTED
        if (sapCase.Status == CasesDomain.CLAIM_STATUS_CONSIDERATION || sapCase.Status == CasesDomain.STATUS_REJECTED) {
            return;
        }

        // A solution is required if the status isn't CONSIDERATION or REJECTED.
        Boolean solutionRequired = true;

        if (solutionRequired) {
            if (!sapCase.SupplyReplacement__c && !sapCase.SupplyInstallation__c && !(sapCase.Compensation__c > 0)) {
                this.addRecordError(sapCase, System.label.case_error_proposal_required); // 'A solution proposal is required');
            }
        }
                        
    } // validateClaim
}