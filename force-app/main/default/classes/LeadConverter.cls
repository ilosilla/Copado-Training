/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Leads
* @description 	Converts a lead into an account, contact and opportunity
*/
public class LeadConverter {    
    
    private Boolean createContactFlag = true;
    private Boolean createAccountFlag = true;
    private Boolean createOpportunityFlag = true;
    private Boolean createOpportunityFlagBackup;
    private Boolean convertProductsFlag = true;
    private Boolean convertAvailableProducts = false;
    private String opportunityName;
    private String accountId;
    private Lead lead;
    private Account account;
    private Contact contact;
    private Opportunity opportunity;
    private ProductListItem__c[] leadItems = new List<ProductListItem__c>();
    private ProductListItem__c[] notAvailableItems = new List<ProductListItem__c>();
    private Boolean usePersonAccount = false;
    
    private Boolean noOpportunity = true;

    public class ConverterException extends Exception {}

    /**
     * Constructor
     **/
    public LeadConverter(Id id) {
        this.lead = this.readLead(id);
        if (this.lead.IsConverted) {
            throw new ContextException('The lead has already been converted!');
        }
        this.createAccountFlag = true;  // Account is required (either new or an exisitng one passed in setAccountId)
        this.createContactFlag = true;  // A contact will be created
        this.createOpportunityFlag = false;
        this.createOpportunityFlagBackup = this.createOpportunityFlag;
        this.convertProductsFlag = false;
    }

    public void setNewContactFlag(Boolean flag) {
        this.createContactFlag = flag;
    }

    public void setNewOpportunityFlag(Boolean flag, String oppName) {
        this.createOpportunityFlag = flag;
        this.opportunityName  = oppName;
        this.createOpportunityFlagBackup = this.createOpportunityFlag;
    }

    public void setConvertProductsFlag(Boolean flag, Boolean flagAvailable) {
        this.convertProductsFlag = flag;
        this.convertAvailableProducts = flagAvailable;
    }

    /**
     * Object Ids
     **/

    public void setAccountId(Id accountId) {
        if (accountId != null) {
            this.accountId = accountId;
            this.createAccountFlag = false;
        }
    } // setAccountId

    public void setContactId(String contactId) {
        if (String.IsNotBlank(contactId)) {
            this.contact =  [select Id, Name, MailingCity, MailingCountry, MobilePhone from Contact where Id = :contactId ];
            this.createContactFlag = false;
        }
    } // setContactId

    public void setOpportunityId(Id opportunityId) {
        if (opportunityId != null) {
            this.opportunity = [select Id, Description, ContactId__c, Pricebook2Id from Opportunity where Id = :opportunityId limit 1];
            this.createOpportunityFlag = false;
        }
    }

    public Integer getProductsMissing() {
        return this.notAvailableItems.size();
    }

    /**
     * Convert the lead
     **/
    public Database.LeadConvertResult convert() {

        Savepoint sp = Database.setSavepoint();

        this.setLeadAccount();
        this.setLeadContact();
        this.setLeadOpportunity();
        update this.lead;

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];

        Database.LeadConvert converter = new Database.LeadConvert();        
        converter.setLeadId(this.lead.Id);        
        converter.setConvertedStatus(convertStatus.MasterLabel);  
        converter.setDoNotCreateOpportunity(true);      
        converter.setAccountId(this.lead.AccountId__c);
        converter.setContactId(this.lead.ContactId__c);
        if (this.opportunity != null) {
            converter.setDoNotCreateOpportunity(false);      
            converter.setOpportunityId(this.opportunity.Id);
        }
        Database.LeadConvertResult result = Database.convertLead(converter);  
        if (result.success) {
            if (this.opportunity != null && this.convertProductsFlag) {
                this.convertProductList();
            }
        } else {
            Database.rollback(sp);
        }
        this.notifyConversion(result);
        return result;
    } // convert
    
    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private void setLeadAccount() {
        this.lead.accountId__c = null;
        if (this.createAccountFlag) {
            this.createNewAccount();
        } 
        this.lead.accountId__c = this.accountId;
        this.account = [select Id, IsPersonAccount, PersonContactId, Name from Account where Id = :this.accountId limit 1];
    } // setLeadAccount

    private void setLeadContact() {
        this.lead.ContactId__c = null;
        if (this.account.IsPersonAccount) {
            this.lead.ContactId__c = this.account.PersonContactId;
        } else {
            if (this.createContactFlag) {
                this.createNewContact();    
            }
            if (this.contact != null)  {
                this.lead.contactId__c = this.contact.Id;
            }
        }
    } // setLeadContact

    private void setLeadOpportunity() {
        if (this.createOpportunityFlag) {
            if (String.IsNotBlank( this.opportunityName)) {
                this.lead.Opportunity_Name__c = this.opportunityName;
            }
            this.opportunity = this.getNewOpportunity();
        } else if (this.opportunity != null) {
            this.opportunity.Description += this.leadToText();
        } 
        if (this.opportunity != null) {
            if (this.convertProductsFlag) {
                if (this.opportunity.Pricebook2Id == null) {
                    this.opportunity.Pricebook2Id = SystemSettings.materialBankPricebook;
                }    
            }

            upsert this.opportunity;
        }
    } // setLeadOpportunity

    
    private void createNewAccount() {
        Boolean usePersonAccount = LeadUtil.convertToPersonAccount(this.lead);            
        if (usePersonAccount) {                
            this.account = this.getNewPersonAccount();
        } else {
            this.account = this.getNewAccount();
        }
        insert this.account;
        this.accountId = this.account.Id;
    } // createNewAccount

    private void createNewContact() {
        this.contact = getNewContact();
        insert this.contact;
    } // setContact


    private void convertProductList() {
        Opportunity opp = [select Id, Pricebook2Id, CurrencyIsoCode from Opportunity where Id = :this.opportunity.Id limit 1];
        if (opp.Pricebook2Id == null) {
            opp.Pricebook2Id = SystemSettings.materialBankPricebook;
            update opp;
        }
        this.leadItems = [select Id, ProductCode__c, Name__c, IsSample__c, Product__c from ProductListItem__c where Lead__c = :this.lead.Id]; 
        this.fillProductsId(this.leadItems);  
        OpportunityLineItem[] oppItems = this.convertFromLeadItems(opp, this.leadItems, this.convertAvailableProducts); 
        insert oppItems;     
    } // convertProductList

    private void fillProductsId(ProductListItem__c[] leadItems) {
        Map<String, Product2> productsMap = this.getProduct2Map(leadItems);
        for (ProductListItem__c item : leadItems) {
            Product2 product = productsMap.get(item.ProductCode__c);
            if (product != null) {
                item.Product__c = product.Id;
            }
        }
    } // fillProductId

    private Map<String, Product2> getProduct2Map(ProductListItem__c[] leadItems) {
        String[] codes = new String[]{};
        for (ProductListItem__c item : leadItems) {
            codes.add(item.ProductCode__c);
        }
        Product2[] products = [select Id, ProductCode from Product2 where ProductCode in :codes];
        Map<String, Product2> result = new Map<String, Product2>();
        for (Product2 pr : products) {
            result.put(pr.ProductCode, pr);
        }
        return result;
    } // getProduct2Map

    private OpportunityLineItem[] convertFromLeadItems(Opportunity opp, ProductListItem__c[] leadItems, Boolean onlyAvailable) { 
        
        Map<Id, PricebookEntry> priceEntries = getPricebookEntries(leadItems, opp.Pricebook2Id, opp.CurrencyIsoCode);  
        OpportunityLineItem[] oppItems = new OpportunityLineItem[]{};

        for (ProductListItem__c leadItem : leadItems) {     
            OpportunityLineItem oppItem = new OpportunityLineItem();        
            oppItem.opportunityId = this.opportunity.Id;
            oppItem.Sample__c = leadItem.IsSample__c;
            oppItem.Quantity = 0.01; // No pasamos cantidad porque no podemos fijar la unidad (piezas si son muestras)            
            oppItem.TotalPrice = 0.01;
            oppItem.Product2Id = leadItem.Product__c;
            if (oppItem.Product2Id != null) {
                PricebookEntry entry = priceEntries.get(oppItem.Product2Id);
                if (entry != null) {
                    oppItem.PricebookEntryId = entry.Id;
                    oppItems.add(oppItem);
                }
            }

            if (oppItem.Product2Id == null || oppItem.PricebookEntryId == null) {
                this.notAvailableItems.add(leadItem);
            }
        }

        if (this.notAvailableItems.size() > 0 && onlyAvailable == false) {
            String errorText = getExceptionText(this.notAvailableItems);
            throw new ConverterException(errorText);
        }
        return oppItems;
    } // convertFromLeadItems

    /**
     * @description Checks if all lead Items exist on Salesforce. If not, throws an Exception with the
     *              text wich has to be shown
     */
    private String getExceptionText(ProductListItem__c[] errorItems) {
        Map<String, String> leadProducts = new Map<String, String>();

        for (ProductListItem__c leadItem : errorItems) {
            if (String.isNotBlank(leadItem.ProductCode__c)){
                leadProducts.put(leadItem.ProductCode__c, leadItem.Name__c);
            }
        }

        String textItems ='';
        for (String productCode : leadProducts.keySet()) {
            textItems += leadProducts.get(productCode) + ' (<i>' + productCode + '</i>), ';
        }
        if (textItems.length() > 0) {
            textItems.removeEnd(', ');
        }

        return Label.lead_noExistingProduct + '<p>' + textItems + '</p>';
    }

    private Map<Id, PricebookEntry> getPricebookEntries(ProductListItem__c[] items, Id pricebookId, String currencyCOde) {
        List<Id> products = new List<Id>();
        for (ProductListItem__c item : items) {
            if (item.Product__c != null ) 
                products.add(item.Product__c);
        }
        PricebookEntry[] entries = [select Id,ProductCode, Product2Id from PricebookEntry where pricebook2Id = :pricebookId 
                                        and currencyIsoCode = :currencyCode
                                        and Product2Id in :products
                                        and IsActive = true];

        Map<Id, PricebookEntry> result =  new Map<Id, PricebookEntry>();
        for (PricebookEntry entry :entries) {
            result.put(entry.Product2Id, entry);
        } 
        return result;
    } // getPricebookEntries

    private Id XXXgetProductId(ProductListItem__c leadItem) {
        Id id = leadItem.Product__c;
        if (id == null) {
            Product2 product = ProductUtils.getProduct(leadItem.ProductCode__c);
            id = product.Id;
        }
        return id;
    } // getProductId
    
    private Account getNewPersonAccount() {
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeLibrary.Account_PrivateCustomer;
        acc.Salutation = this.lead.Salutation;
        acc.LastName = this.lead.LastName;
        acc.FirstName = this.lead.FirstName;
        acc.PersonEmail = this.lead.Email;
        acc.PersonMailingCountryCode = this.lead.CountryCode__c;
        acc.PersonMailingStateCode = this.lead.State__c;        
        acc.PersonMailingCity = this.lead.City__c;
        acc.PersonMailingPostalCode = this.lead.Postcode__c;
        acc.PersonMailingStreet = this.lead.Address__c;
        acc.Phone = this.lead.MobilePhone;
        acc.ownerId = this.lead.OwnerId;
        return acc;
    } // createPersonAccount

    private Account getNewAccount() {
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeLibrary.Account_TradeCustomer;
        acc.Name = this.lead.Company;
        if (String.isBlank(acc.Name)) {
            acc.Name = this.lead.Name;
        }
        acc.Business_Email__c = this.lead.Email;
        acc.BillingCountryCode = this.lead.CountryCode__c;
        acc.BillingStateCode = this.lead.State__c;
        acc.BillingCity = this.lead.City__c;
        acc.BillingPostalCode = this.lead.Postcode__c;
        acc.BillingStreet = this.lead.Address__c;
        acc.Phone = this.lead.MobilePhone;
        acc.ownerId = this.lead.OwnerId;
        return acc;
    } // createAccount

    private Contact getNewContact() {
        Contact con = new Contact();
        con.FirstName = this.lead.FirstName;
        con.LastName = this.lead.LastName;
        if (this.lead.Title != null) {
            con.Title = this.lead.Title;
        } else {
            con.Title = this.lead.Profile__c;
        }
        con.Email = this.lead.Email;
        con.MailingCountryCode = this.lead.CountryCode__c;
        con.MailingCity = this.lead.City__c;
        con.MailingPostalCode = this.lead.Postcode__c;
        con.MailingStreet = this.lead.Address__c;
        con.MobilePhone = this.lead.MobilePhone;
        con.ownerId = this.lead.OwnerId;
        con.AccountId = this.lead.AccountId__c;        
        return con;
    } // createAccountAccount

    private Opportunity getNewOpportunity() {
        Opportunity opp = new Opportunity();
        opp.Name = this.lead.Opportunity_Name__c;
        if (this.account.IsPersonAccount) {
            opp.RecordTypeId = RecordTypeLibrary.Opportunity_Retail;
            opp.Opportunity_Classification__c = 'Residential (Retail)';
            this.lead.Product_Categories__c = '';
        } else {
            opp.RecordTypeId = RecordTypeLibrary.Opportunity_Trade;
        }        
        opp.Product_Categories__c = this.lead.Product_Categories__c; 
        opp.AccountId = this.lead.accountId__c;
        opp.ContactId__c = this.lead.contactId__c;        
        opp.CloseDate = this.lead.Close_Date__c;        
        opp.OwnerId = this.lead.OwnerId;
        opp.Description = this.lead.Description + this.leadToText();
        opp.Operation_Type__c = this.lead.Operation_Type__c;
        opp.Address__c = this.lead.Address__c;
        opp.City__c = this.lead.City__c;
        opp.Postcode__c = this.lead.Postcode__c;
        opp.countryCode__c = this.lead.CountryCode__c;
        opp.State__c = this.lead.State__c;
        opp.StageName = 'Qualification';
        opp.Currency__c = this.lead.CurrencyIsoCode;
        opp.CurrencyIsoCode = this.lead.CurrencyIsoCode;
        opp.roomTypeBathroom__c = this.lead.roomTypeBathroom__c;
        opp.roomTypeBedroom__c = this.lead.roomTypeBedroom__c;
        opp.roomTypeFireplace__c = this.lead.roomTypeFireplace__c;
        opp.roomTypeFoyer__c = this.lead.roomTypeFoyer__c;
        opp.roomTypeFullHouse__c = this.lead.roomTypeFullHouse__c;
        opp.roomTypeKitchen__c = this.lead.roomTypeKitchen__c;
        opp.roomTypeLaundryRoom__c = this.lead.roomTypeLaundryRoom__c;
        opp.roomTypeLivingRoom__c = this.lead.roomTypeLivingRoom__c;
        opp.roomTypeOther__c = this.lead.roomTypeOther__c;
        opp.roomTypeOutdoorPatio__c = this.lead.roomTypeOutdoorPatio__c;
        opp.roomTypeSwimmingPool__c = this.lead.roomTypeSwimmingPool__c;
        opp.Amount_custom__c = this.lead.Quantity_of_the_opportunity__c;
        opp.LeadId__c = this.lead.Id;
        return opp;
    } // getNewOpportunity

    private String leadToText() {
        Lead translatedLead = [select Id, toLabel(LeadSource), toLabel(LeadType__c), toLabel(Product_Categories__c) from Lead where Id = :this.lead.Id limit 1];
        String txt = '\n\n========================================================================\n';
        txt += Label.dict_lead + ': "' + this.lead.Opportunity_Name__c + '"\n';        
        txt += '========================================================================\n';
        txt += '- ' + Label.dict_created + ': ' + this.lead.CreatedDate + '\n';
        txt += '- ' + Label.lead_source + ': ' + translatedLead.LeadSource + '\n';
        txt += '- ' + Label.lead_type + ': ' + translatedLead.LeadType__c + '\n';
        txt += '- ' + Label.lead_subtype + ': ' + this.lead.LeadSubtype__c + '\n';
        txt += '- ' + Label.dict_email + ': ' + this.lead.EMail + '\n';
        if (String.IsNotBlank(translatedLead.Product_Categories__c)) {
            txt += '- ' + Label.dict_product_cats + ': ' + translatedLead.Product_Categories__c + '\n';
        }

        return txt;
    } // leadToText

    private Lead readLead(String leadId) {

    LeadsSelector selector = new LeadsSelector();
        return selector.selectById(new Set<Id>{leadId})[0];
    } // readLead

    private void notifyConversion(Database.LeadConvertResult result) {
        try {
            String message = 'LEAD ' + this.lead.Id + ' CONVERTED BY ' + UserInfo.getName().toUpperCase() + '\r\n';
            message += '- this.lead.name = ' + this.lead.Name + '\r';
            message += '- this.createOpportunityFlag = ' + this.createOpportunityFlagBackup + '\r';
            message += '- opportunity id = ' + result.getOpportunityId() + '\r';
            if (result.opportunityId != null && !this.createOpportunityFlagBackup) {
                WebhooksService.publish('LEADS_CHANNEL_TEAMS', 'Lead converted to opportunity!', message); // Por cobertura
            }
        } catch (Exception ex) {
            LoggerCommons.LogException('LEAD CONVERSION', this.lead.id, ex);
        }
    }
} // class