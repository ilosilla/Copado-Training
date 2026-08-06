/****
* @author 			Ramón Prades
* @date 			October-2020
* @group 			Accounts
* @group-content 	../../ApexDocContent/Accounts.htm
* @description 	    Reads an address
*/
public without sharing class AddressDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String country;
    @AuraEnabled public String countryCode;
    @AuraEnabled public String street;
    @AuraEnabled public String city;
    @AuraEnabled public String postCode;
    @AuraEnabled public String state;
    @AuraEnabled public String stateCode;
    @AuraEnabled public String phone1;
    @AuraEnabled public String phone2;
    @AuraEnabled public String email;
    @AuraEnabled public String sapId;
    @AuraEnabled public String className;
    @AuraEnabled public String addressType;
    @AuraEnabled public String additionalInfo;
    @AuraEnabled public Boolean isDefault = false;
    @AuraEnabled public Datetime lastModifiedDate;

    /**
     * Reads the address from an account id (or person account id)
     */
    public static AddressDTO readFromAccount(Id accountId) {
        Account account = AddressDTO.readAccount(accountId);
        return AddressDTO.copyFromAccount(account);
    } // readFromAccount

    /**
     * Reads an address form a contact point address
     */
    public static AddressDTO readContactPointAddress(Id cpoint) {
        ContactPointAddress cpa = [select Id, Name, Address, Phone__c, Mobile__c, Email__c, SAPId__c, LastModifiedDate, IsDefault from ContactPointAddress where Id = :cpoint limit 1];
        return readContactPointAddress(cpa);
    }

    public static AddressDTO readContactPointAddress(ContactPointAddress cpa) {
        AddressDTO dto = new AddressDTO();
        dto.id = cpa.Id;
        dto.name = cpa.Name;
        dto.country = cpa.Address.getCountry();
        dto.countryCode = cpa.Address.getCountryCode();
        dto.postCode = cpa.Address.getPostalCode();
        dto.street = cpa.Address.getStreet();
        dto.city = cpa.Address.getCity();
        dto.state = cpa.Address.getState();
        dto.stateCode = cpa.Address.getStateCode();
        if (String.IsNotBlank(cpa.Mobile__c)) {
            dto.phone1 = cpa.Mobile__c;
            dto.phone2 = cpa.Phone__c;
        } else {
            dto.phone1 = cpa.Phone__c;
        }
        dto.email = cpa.Email__c;
        dto.sapId = cpa.SAPId__c;
        dto.lastModifiedDate = cpa.LastModifiedDate;
        dto.isDefault = cpa.IsDefault;
        dto.className = 'ContactPointAddress';
        return dto;
    }    

    public static AddressDTO readPorcelanosaAddress(Id porsaId) {
        PorcelanosaAddress__c por = [select Id, Name, NBK_Address__c, NBK_Phone__c, Email__c, NBK_SAPId__c from PorcelanosaAddress__c where Id = :porsaId limit 1];
        return readPorcelanosaAddress(por);
    }

    public static AddressDTO readPorcelanosaAddress(PorcelanosaAddress__c por) {
        AddressDTO dto = new AddressDTO();
        dto.id          = por.Id;
        dto.name        = por.Name;
        if (por.NBK_Address__c != null) {
            dto.country     = por.NBK_Address__c.getCountry();
            dto.countryCode = por.NBK_Address__c.getCountryCode();
            dto.postCode    = por.NBK_Address__c.getPostalCode();
            dto.street      = por.NBK_Address__c.getStreet();
            dto.city        = por.NBK_Address__c.getCity();
            dto.state       = por.NBK_Address__c.getState();
            dto.stateCode   = por.NBK_Address__c.getStateCode();
        }
        dto.phone1 = por.NBK_Phone__c;        
        dto.email = por.Email__c;
        dto.sapId = por.NBK_SAPId__c;
        dto.className = 'PorcelanosaAddress__c';
        return dto;
    }

    public static AddressDTO readFromOrderDeliveryGroup(Id orderId) {
        OrderDeliveryGroup odg = [
            select 
                Id, DeliverToName, DesiredDeliveryDate, DeliveryMethod__c, DeliverToStreet, DeliverToCity, DeliverToState, DeliverToStateCode,
                DeliverToPostalCode, DeliverToCountry, DeliverToCountryCode, 
                ContactPointAddress__c, PorcelanosaAddress__c, 
                PhoneNumber, EmailAddress, SAPId__c
            from OrderDeliveryGroup 
            where OrderId = :orderId limit 1
        ];
        return readFromOrderDeliveryGroup(odg);
    }
    
    public static AddressDTO readFromOrderDeliveryGroup(OrderDeliveryGroup odg) {        
        AddressDTO dto = new AddressDTO();
        dto.id = odg.Id;
        dto.name = odg.DeliverToName;
        dto.country = odg.DeliverToCountry;
        dto.countryCode = odg.DeliverToCountryCode;
        dto.street = odg.DeliverToStreet;
        dto.city = odg.DeliverToCity;   
        dto.state = odg.DeliverToState;
        dto.stateCode = odg.DeliverToStateCode;
        dto.postCode = odg.DeliverToPostalCode;
        dto.phone1 = odg.PhoneNumber;
        dto.email = odg.EmailAddress;
        dto.sapId = odg.SAPId__c;
        dto.className = 'CartDeliveryGroup';
        if (odg.ContactPointAddress__c != null) {
            dto.additionalInfo = 'ContactPointAddress';
        } else if (odg.PorcelanosaAddress__c != null) {
            dto.additionalInfo = 'CollectionPoint';
        }        
        return dto;
    }

     /**
     * Compare
     */
    public Boolean isTheSame(AddressDTO target) {        
        return (
            (this.city?.toUpperCase() == target.city?.toUpperCase()) &&
            (this.countryCode?.toUpperCase() == target.countryCode?.toUpperCase()) &&
            (this.postCode?.toUpperCase() == target.postCode?.toUpperCase()) &&
            (this.street?.toUpperCase() == target.street?.toUpperCase()) &&
            (this.stateCode?.toUpperCase() == target.stateCode?.toUpperCase()) 
        );

    }

    /**
     * Convert to address
     */
    public Schema.Address toAddress() {
        Schema.Address addr = new Schema.Address();
        addr.City = this.city;
        addr.StateCode = this.stateCode;
        addr.State = this.state;
        addr.Country = this.country;
        addr.CountryCode = this.countryCode;
        addr.PostalCode = this.postCode;
        addr.Street = this.street;

        return addr;
    }
    
    /************************************************************************/
    private static Account readAccount(Id accountId) {
        Account acc = [Select Id,
                            isPersonAccount,
                            PersonMailingCountry,
                            PersonMailingCountryCode,
                            PersonMailingStreet,
                            PersonMailingPostalCode,
                            PersonMailingCity,
                            PersonMailingState,
                            PersonMailingStateCode,
                            BillingCountry,
                            BillingCountryCode,
                            BillingStreet,
                            BillingPostalCode,
                            BillingCity,
                            BillingState,
                            BillingStateCode,
                            Phone,
                            PersonMobilePhone,
                            Name,
                            Business_Email__c,
                            PersonEmail,
                            SAP_Id__c,
                            LastModifiedDate
                        from Account where Id = :accountId ];        
        return acc;
    } // readAccount

    private static AddressDTO copyFromAccount(Account account) {
        if (account.IsPersonAccount) {
            return AddressDTO.copyFromPersonAccount(account);
        } else {
            AddressDTO dto = new AddressDTO();
            dto.id = account.Id;
            dto.name = account.Name;
            dto.country = account.BillingCountry;
            dto.countryCode = account.BillingCountryCode;
            dto.street = account.BillingStreet;
            dto.city = account.BillingCity;
            dto.postCode = account.BillingPostalCode;
            dto.state = account.BillingState; 
            dto.stateCode = account.BillingStateCode;
            dto.phone1 = account.Phone;
            dto.phone2 = account.PersonMobilePhone;
            dto.email = account.Business_Email__c;
            dto.sapId = account.SAP_Id__c;
            dto.lastModifiedDate = account.LastModifiedDate;
            dto.className = 'Account';
            return dto;
        }
    } // copyFromAccount

    private static AddressDTO copyFromPersonAccount(Account account) {
        AddressDTO dto = new AddressDTO();
        dto.id = account.Id;
        dto.name = account.Name;
        dto.country = account.PersonMailingCountry;
        dto.countryCode = account.PersonMailingCountryCode;
        dto.street = account.PersonMailingStreet;
        dto.city = account.PersonMailingCity;
        dto.postCode = account.PersonMailingState;
        dto.state = account.PersonMailingState; 
        dto.stateCode = account.PersonMailingStateCode;
        dto.email = account.PersonEmail;
        dto.phone1 = account.PersonMobilePhone;
        dto.className = 'PersonAccount';
        dto.sapId = account.SAP_Id__c;
        dto.lastModifiedDate = account.LastModifiedDate;    
        dto.className = 'Account';
        return dto;
    } // copyFromPersonAccount


}