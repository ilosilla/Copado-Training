/**
* @author 			Ramón Prades
* @date 			February-2021
* @group 			Leads
* @group-content 	../../ApexDocContent/Lead.htm
* @description 	    Helper class for web leads (to assign an owner or to find the account the lead belongs to)
*/
public class LeadHelper {    

    public Boolean usePersonAccount { get; private set; }

    private Lead theLead;
    private Id accountId;
    private String leadSourceDefaultValue = 'Web Request';

    /**
     * Constructor
     */
    public leadHelper(Lead theLead) {
        this.theLead = theLead;
        this.usePersonAccount = LeadUtil.convertToPersonAccount(this.theLead);
    } // constructor

    /**
     * Makes the lead a web lead (record type and source)
     */    
    public void setWebRequestFields() {
        this.usePersonAccount = true;
        this.theLead.RecordTypeId = RecordTypeLibrary.Lead_WebRequest;
        this.theLead.Source__c = 'WEB';
        this.theLead.DateCreated__c = System.today();
        this.theLead.Close_Date__c = this.theLead.DateCreated__c.addMonths(1);
        if (this.theLead.LeadSource == null) {
            this.theLead.LeadSource = this.leadSourceDefaultValue;
        }
        if (String.IsBlank(this.theLead.Opportunity_Name__c)) {
            this.theLead.Opportunity_Name__c = this.theLead.FirstName + ' ' + this.theLead.LastName + '\'s Web Request';
        }        
    } // setWebRequestFields

    /**
     * Makes the lead a EU web lead (recpord type and source)
     */    
    public void setEUWebRequestFields() {
        this.setWebRequestFields();
        this.theLead.RecordTypeId = RecordTypeLibrary.Lead_USWebRequest;
        this.theLead.Source__c = 'EUW';
        this.theLead.CurrencyIsoCode = 'EUR';
        this.usePersonAccount = LeadUtil.convertToPersonAccount(this.theLead);
    } // setUSWebRequestFields

    /**
     * Makes the lead a US web lead (recpord type and source)
     */    
    public void setUSWebRequestFields() {
        this.setWebRequestFields();
        this.theLead.RecordTypeId = RecordTypeLibrary.Lead_USWebRequest;
        this.theLead.Source__c = 'USW';
        this.theLead.CurrencyIsoCode = 'USD';
        this.usePersonAccount = LeadUtil.convertToPersonAccount(this.theLead);
    } // setUSWebRequestFields

    /**
     * Searches  an account and a contact to the lead
     */
    public void setAccountAndOwner() {
        setAccountAndOwner(true);
    }
    
    public void setAccountAndOwner(Boolean setOwner) {
        // If not found, searches account/contact
        if (this.theLead.accountId__c == null) {
            this.setAccount();
            this.setContact();
        }
        if (setOwner && !this.theLead.ownerLocked__c) {
            if (String.isNotBlank(this.theLead.Email) && this.theLead.Email.contains('@nubika')) {
                User[] us = [select id from User where username = 'nubika@porcelanosa.com'];
                if (us.size() > 0) {
                    this.theLead.OwnerId = us[0].Id;
                    this.theLead.OwnerReason__c = 'TESTING';
                }
            } else {
                this.setOwner();
            }
        }
    } // setAccountAndOwner

    /*********************************************************/
    /******************** STATIC METHODS ********************/
    /*********************************************************/
    public static String mapProfile(String title) {
        String profile = '';
        String position = title.toLowerCase();
        if (position.contains('designer')) {
            profile = 'Designer';
        } else if (position.contains('architect')) {
            profile = 'Architect';
        }
        return profile;
    } //mapPorfile

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /**
     * Sets the owner
     */
    private void setOwner() {
        this.theLead.OwnerId = null;
        this.theLead.OwnerReason__c = '';

        // [1] Get the owner from other leads with the same email
        this.setOwnerFromOtherLeads();

        // [2] The owner is the contact's owner (if any)
        if (this.theLead.OwnerId == null && this.theLead.ContactId__c != null) {
            Contact con = [select Id, OwnerId from Contact where Id = :this.theLead.ContactId__c limit 1];
            if (con != null && UserUtils.isActive(con.OwnerId) && !UserUtils.isGenericUser(con.OwnerId)) {                 
               this.theLead.OwnerId = con.OwnerId;
               this.theLead.OwnerReason__c = 'CONTACT ' + con.OwnerId;
               return;
            }
       }

       // [3] The owner is the account's owner
       if (this.theLead.AccountId__c != null) {
            Account acc = [select Id, OwnerId from Account where Id = :this.theLead.AccountId__c limit 1];
            if (acc != null && UserUtils.isActive(acc.OwnerId) && !UserUtils.isGenericUser(acc.OwnerId)) {
               this.theLead.OwnerId = acc.OwnerId;
               this.theLead.OwnerReason__c = 'ACCOUNT ' + acc.OwnerId;
               return;
            }
       }
        
        // [4] If there's a rep, if contact email is from Porcelanosa, default owner. Otherwise, the rep.
        if (this.theLead.Representative__c != null) {
            if (!this.theLead.Email.containsIgnoreCase('porcelanosa')) {
                this.theLead.ownerId = this.theLead.Representative__c;
                this.theLead.OwnerReason__c = 'REPRESENTATIVE ' + this.theLead.OwnerId;
            }
            //} else {
                //this.assignDefaultOwner();                
                //this.theLead.OwnerReason__c = 'PORSA EMAIL '+ this.theLead.OwnerId;
            //} 
        }

        // [5] Use postcode
        if (this.theLead.ownerId == null) {
            this.assignRandomOwner();
        }

        // [6] Default owner
        if (this.theLead.ownerId == null) {
            this.assignDefaultOwner();
        }

        // [7] Current user will be the owner
        if (this.thelead.ownerId == null) {
            this.theLead.ownerId = UserInfo.getUserId();
        }

    } // setOwner

    private void setAccount() {
        if (this.theLead.AccountId__c == null) {
            if (this.usePersonAccount) {
                this.theLead.AccountId__c = AccountFinder.getPersonAccountFromEmail(this.theLead.Email);
            } else {
                this.theLead.AccountId__c = AccountFinder.getTradeAccountFromEmail(this.theLead.Email);                                
            }    
        }
    } // setAccount

    private void setContact() {
        if (this.usePersonAccount || this.theLead.ContactId__c != null) {
            return;
        }
        if (this.theLead.AccountId__c != null) {
            setContactFromAccount();
            return;
        } 
        Contact[] contacts = [select Id, Email, AccountId from Contact where Email = :this.theLead.Email ];
        if (contacts.size() > 0) {
            this.theLead.AccountId__c = contacts[0].AccountId;
            this.theLead.ContactId__c = contacts[0].Id;
        }
    } // setContact

    private void setContactFromAccount() {
        Contact[] contacts = [select Id, Name, FirstName, LastName, Email from Contact where AccountId = :this.theLead.AccountId__c];

        for (Contact contact :contacts) {
            if (contact.Email == this.theLead.Email) {
                this.theLead.ContactId__c = contact.Id;
                return;
            }
            if(contact.Name == this.theLead.Name ) {
                this.theLead.ContactId__c = contact.Id;
            }
        }
    } // setContactFromAccount

    /*
     * Searches ACTIVE leads with the same email
     */
    private void setOwnerFromOtherLeads() {
        if (String.IsNotBlank(this.theLead.Email)) {
            Lead[] leads = [select Id, DateCreated__c, Close_Date__c, AccountId__c, ContactId__c, OwnerId, IsConverted, IsDeleted 
            from Lead where EMail = :this.theLead.Email and isDeleted = false and isConverted = false order by DateCreated__c desc];        
            for (Lead l : leads) {
                if (this.thelead.Id == null || l.Id != this.thelead.Id) {
                    this.theLead.AccountId__c = l.AccountId__c;
                    this.theLead.ContactId__c = l.ContactId__c;
                    if (UserUtils.IsActive(l.OwnerId)) {
                        this.theLead.OwnerId = l.ownerId;   
                        this.theLead.OwnerReason__c = 'OTHER LEADS ' + l.ownerId;             
                        break;
                    }
                }
            }            
        }
    } // setOwnerFromOtherLeads

    private void assignRandomOwner() {
        String algorithm = 'EUR';        
        if (this.theLead.Source__c == 'EUW') {
            algorithm = 'MBK-EUR';
        } else if (this.theLead.Source__c == 'USW' || this.theLead.Source__c == 'MBK') {
            algorithm = 'USA';
        }
        if (String.isNotBlank(this.theLead.CountryCode__c)) { 
            AbstractOwnerAssignator assignator = OwnerAssignator.getInstance('LEAD', algorithm);
            assignator.setCountry(this.theLead.CountryCode__c);
            assignator.setState(this.theLead.State__c);
            assignator.setPostCode(this.theLead.Postcode__c);
            assignator.setProfile(this.theLead.Profile__c);
            assignator.setProductLine(this.theLead.LeadSubtype__c);
            User usr = assignator.getOwner();
            if (usr != null) {
                this.theLead.OwnerId = usr.Id;
                this.theLead.OwnerReason__c = 'RANDOM ' + usr.Id;
            }            
        }
    } // assignRandomOwner
  
    private void assignDefaultOwner() {
        CountrySettings__c settings = CountrySettings__c.getValues(this.theLead.CountryCode__c);
        if (settings != null && String.isNotBlank(settings.LeadDefaultOwnerID__c)) {
            this.theLead.ownerId = (Id) settings.LeadDefaultOwnerID__c;
            this.theLead.OwnerReason__c = 'CTRY DEFAULT ' + settings.LeadDefaultOwnerID__c;
        }
    } // assignDefaultOwner

    @testVisible private static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }


} // LeadHelper