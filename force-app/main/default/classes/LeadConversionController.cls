/**
 * @author 		Ramón Prades
 * @date 		April 2021
 * @group 		Leads
 * @description 	Lead conversion component controller. Provides methos to prepare the conversion and for the conversion itself.
 */
public class LeadConversionController 
{

    private static Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Lead.fields.getMap();

    /**
     * Reads the lead passed and prepares data for the conversion of the web request lead form.
     */
    @AuraEnabled 
    public static ConversionDataDTO prepareConversion(String leadId) {
        Lead theLead = readLead(leadId);
        if (theLead == null) {
            throw new ObjectNotFoundException('Lead not found');
        }        
        ConversionDataDTO dto = new ConversionDataDTO();
        dto.lead = theLead;
        dto.errors = new List<String>();
        dto.warnings = new List<String>();
        dto.isConvertible = (theLead.Dealer__c == null);
        if (dto.isConvertible) {
            dto.isConverted = dto.lead.IsConverted;
            dto.variant = LeadUtil.getLeadVariant(dto.lead);
            dto.isPersonAccount = false;
            dto.usePersonAccount = String.isBlank(dto.lead.Company);
            dto.ready = false;
            dto.locked = false;
            if (dto.lead.AccountId__c != null) {
                dto.locked = true;
                // LeadHelper helper = new LeadHelper(dto.lead);
                // .0-helper.setAccountAndOwner();
                readAccountData(dto.lead.AccountId__c, dto);
            }
            dto.accountId = dto.lead.AccountId__c;
            dto.contactId = dto.lead.ContactId__c;
            List<ProductListItem__c> items = [select Id from ProductListitem__c where Lead__c = :leadId];
            dto.hasProductList = (items.size() > 0);
            validateLead(dto);                    
        }
        return dto;
    } // validateLead

    /**
     * Performs the conversion of the web request lead into a person account and a retail opportunity.
     */
    @AuraEnabled 
    public static ConversionResultDTO convertLead(String leadId, String accountId, String contactId, Boolean newContact, String opportunityId, 
            String opportunityName, Boolean noOpportunity, Boolean convertProducts, Boolean convertAvailableProducts) {
        ConversionResultDTO resultDTO;
        try {        
            LeadConverter converter = new LeadConverter(leadId);
            converter.setAccountId(accountId);
            converter.setContactId(contactId);
            if (!noOpportunity) {
                if (opportunityId == null || opportunityId == '') {
                    converter.setNewOpportunityFlag(true, opportunityName);
                } else {
                    converter.setOpportunityId(opportunityId);
                }
                converter.setConvertProductsFlag(convertProducts, convertAvailableProducts);
            } 
            Database.LeadConvertResult result = converter.convert();
            resultDTO = digestResult(result);
            resultDTO.productsNotAdded = converter.getProductsMissing();
        } catch (DMLException dex) {
            LoggerCommons.LogException('LEAD_CONVERSION_CONTROLLER', 'Lead ' + leadId, dex);
            LoggerCommons.createCase(dex);
            throw new AuraHandledException(dex.getMessage());
        } catch (Exception ex) {
            LoggerCommons.LogException('LEAD_CONVERSION_CONTROLLER', 'Lead ' + leadId, ex);
            LoggerCommons.createCase(ex);
            throw new AuraHandledException(ex.getMessage());
        } 
        return resultDTO;
    } // convertLead

    /**
     * reads the opportunites of an account
     */
    @AuraEnabled 
    public static ConversionDataDTO readAccountInfo(String accountId) {
        ConversionDataDTO dto = new ConversionDataDTO();
        dto.isPersonAccount = false;
        readAccountData(accountId, dto);
        return dto;
    } // readOportunities

    
    /**
     * ==================================================================================
     *                                  Private methods
     * ==================================================================================
     */

     private static void readAccountData(Id accountId, ConversionDataDTO dto) {
        dto.contacts = new List<Contact>();
        dto.opportunities = new List<Opportunity>();
        if (accountId != null) {
            dto.account = [select Id, Name, IsPersonAccount from Account where Id = :accountId][0];   
            dto.opportunities = readAccountOpportunities(accountId);
            if (!dto.account.IsPersonAccount) {
                dto.contacts = AccountUtil.getContacts(accountId);
            }
            dto.isPersonAccount = dto.account.IsPersonAccount;
            dto.accountId = accountId;    
        } 
     }

    private static ConversionResultDTO digestResult(Database.LeadConvertResult result) {
        ConversionResultDTO dto = new ConversionResultDTO();
        dto.success = result.isSuccess();
        if (!dto.success) {
            for (Database.Error error :result.getErrors()) {
                dto.errors.add(error.getMessage());
            }
        } else {
            dto.account =  new AccountProxy(result.getAccountId());
            dto.info = 'Sacamos el id ' + result.getAccountId() + ' y el nombre es ' + dto.account.name ;
            dto.contact =  [select Id, Name, MailingCity, MailingCountry, MobilePhone from Contact where Id = :result.getContactId() limit 1 ];
            dto.noOpportunity = true;
            if (result.getOpportunityId() != null) {
                dto.opportunity = [select Id, Name, stageName, OwnerId, Company__c, (SELECT Id FROM opportunityLineItems)  from Opportunity where Id = :result.getOpportunityId() limit 1];
                if (dto.opportunity != null) {
                    dto.owner = [select Id, Name, Sales_Office_Text__c, SalesOrg_Text__c  from user where Id = : dto.opportunity.ownerId limit 1] ;
                    dto.noOpportunity = false;
                } 
            }
        }
        return dto;
    } // digestResult

    private static void validateLead(ConversionDataDTO dto) {
        if (dto.lead.IsConverted) {
            dto.errors.add(Label.Lead_converted);
        } else {
            validateRequired('Opportunity_Name__c', dto, false);
            validateRequired('Salutation', dto, false);
            validateRequired('FirstName', dto, false);
            validateRequired('LastName', dto, false); 
            validateRequired('MobilePhone', dto, false);
            validateRequired('Email', dto, false);
            validateRequired('Operation_Type__c', dto, true);
            validateRequired('CountryCode__c', dto, false);
            validateRequired('Address__c', dto, false);
            validateRequired('Postcode__c', dto, false);
            validateRequired('City__c', dto, false);
            validateRequired('Close_Date__c', dto, true);
                
            /*
            if (dto.account != null) {
                if (dto.usePersonAccount && !dto.account.IsPersonAccount) {
                    dto.errors.add(Label.lead_not_person_account);
                } 
                if (!dto.usePersonAccount && dto.account.IsPersonAccount) {
                    dto.errors.add(Label.lead_not_biz_account);
                }
            } 
            */           
        }        
    } // validateLead

    private static void validateRequired(String fieldName, ConversionDataDTO dto, Boolean isWarning) {
        String value = String.valueOf(dto.lead.get(fieldName));
        if (String.isBlank(value)) {
            String msg = Label.dict_required;
            String lbl = fieldsMap.get(fieldName).getDescribe().getLabel();
            if (isWarning) {
                dto.warnings.add(msg.replace('&1', lbl));
            } else {
                dto.errors.add(msg.replace('&1', lbl));
            }
        }
    } // validateRequired

    private static Opportunity[] readAccountOpportunities(Id accountId) {
        return [select Id, Name, IsClosed, AccountId from opportunity where AccountId = :accountId and (IsClosed = false OR (LastStageChangeDate = LAST_N_DAYS:180 AND StageName = 'Closed Won')) ]; // and recordTypeId = :RecordTypeLibrary.Opportunity_Retail ];
    } // readOpportunities

    private static lead readLead(String leadId) {
        Lead l = null;
        LeadsSelector selector = new LeadsSelector();
        Lead[] leads = selector.selectById(new Set<Id>{leadId});
        if (leads.size() > 0) {
            l = leads[0];
        }
        return l;
    } // readLead

    /**************************************************************************
     * INNER CLASSES
     **************************************************************************/

    public class ConversionDataDTO {
        @AuraEnabled public Boolean ready = false;          
        @AuraEnabled public Boolean isConverted = false;
        @AuraEnabled public Boolean isPersonAccount = false;
        @AuraEnabled public Boolean usePersonAccount = false;
        @AuraEnabled public String variant;
        @AuraEnabled public Lead lead;
        @AuraEnabled public Account account;
        @AuraEnabled public String accountId;
        @AuraEnabled public String contactId;
        @AuraEnabled public Opportunity[] opportunities = new List<Opportunity>();        
        @AuraEnabled public Contact[] contacts = new List<Contact>();        
        @AuraEnabled public String[] errors;
        @AuraEnabled public String[] warnings;
        @AuraEnabled public Boolean locked;
        @AuraEnabled public Boolean hasProductList = false;
        @AuraEnabled public Boolean isConvertible = true;
    }

    public class ConversionResultDTO {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String[] errors;
        @AuraEnabled public AccountProxy account;
        @AuraEnabled public Contact contact;
        @AuraEnabled public Opportunity opportunity;
        @AuraEnabled public Boolean noOpportunity;
        @AuraEnabled public user owner;
        @AuraEnabled public String info;
        @AuraEnabled public Integer productsNotAdded;
    }
}