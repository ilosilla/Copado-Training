/**
* @author 		Ramón Prades
* @date 		May 2023
* @group 		Addresses
* @description 	Controller class for CPAddressForm lwc
*/
public class CPAddressFormController {
    /**
     * Reads data for the form
     * - AccountId - Id of an account 
     * Reads delivery addresses and pickup addresses (from the sales orgs of the customer)
     */
    @AuraEnabled public static DataDTO getFormData(String accountId) {
        DataDTO dto = new DataDTO();
        dto.countries = getCountriesPicklist();        
        dto.states = getStatesPicklist();
        dto.addressTypes = getAddressTypesPicklist();
        dto.addresses = readAddresses(accountId);        
        dto.addressesPicklist = getAddressesPicklist(accountId, dto.addresses);
        dto.pickupPoints = readSalesOrgAddresses(accountId);        
        dto.pickupPointsPicklist = getPickupPointsPicklist(dto.pickupPoints);        
        dto.showroomsPicklist = getShowroomsPicklist(dto.pickupPoints);
        return dto;
    }

    /**
     * Saves the address
     */
    @AuraEnabled public static SavedAddressDTO  saveContactPointAddress(ContactPointAddress inputAddress) {
        ContactPointAddress caddress = new ContactPointAddress();
        if (inputAddress.Id != null) {
            caddress = new ContactPointAddressesSelector().selectById(new Set<Id>{inputAddress.Id})[0];
        }
        caddress.ParentId = inputAddress.ParentId;
        caddress.Name = inputAddress.Name;
        caddress.CountryCode = inputAddress.CountryCode;
        caddress.StateCode = inputAddress.StateCode;
        caddress.Street = inputAddress.Street;
        caddress.City = inputAddress.City;
        caddress.PostalCode = inputAddress.PostalCode;
        caddress.Phone__c = inputAddress.Phone__c;
        caddress.EMail__c = inputAddress.EMail__c;
        caddress.addressType = inputAddress.AddressType;
        caddress.IsDefault = inputAddress.IsDefault;
        ContactPointAddressesService.save(caddress);

        SavedAddressDTO dto = new SavedAddressDTO();
        dto.address = caddress;
        dto.option = new PicklistOption();
        dto.option.value = caddress.Id;
        
        dto.option.label = AddressCommons.buildAddressLabel(caddress);

        return dto;
    }

    //////////////////////////////////////////////////////
    // PRIVATE METHODS
    //////////////////////////////////////////////////////

    private static List<PicklistOption> getAddressTypesPicklist() {
        List<PicklistOption> picklist = new List<PicklistOption>();
        Map<String, String> types = PicklistCommons.getValues(ContactPointAddress.AddressType);
        for (String type : types.keySet()) {
            PicklistOption opt  = new PicklistOption();
            opt.value = type;
            opt.label = types.get(type);
            picklist.add(opt);
        }
        return picklist;
    }

    private static List<PicklistOption> getCountriesPicklist() {
        List<PicklistOption> countries = new List<PicklistOption>();
        Map<String, Schema.PicklistEntry> countriesMap = AddressCommons.getCountries();
        for (Schema.PicklistEntry country : countriesMap.values()) {
            PicklistOption opt1 = new PicklistOption();
            opt1.value = country.getValue();
            opt1.label = country.getLabel();
            countries.add(opt1);
        }
        return countries;
    }

    private static Map<String, List<PicklistOption>> getStatesPicklist() {
        Map<String, List<PicklistOption>> states = new Map<String, List<PicklistOption>>();
        Map<String, List<Schema.PicklistEntry>> statesMap = AddressCommons.getStates();
        for (String country : statesMap.keySet()) {
            List<PicklistOption> options = new List<PicklistOption>();
            for (Schema.PicklistEntry state : statesMap.get(country)) {
                PicklistOption opt1 = new PicklistOption();
                opt1.value = state.getValue();
                opt1.label = state.getLabel();
                options.add(opt1);
            }
            states.put(country, options);
        }
        return states;
    }

    private static List<ContactPointAddress> readAddresses(String accountId) {
        return ContactPointAddressesService.getAccountAddresses(accountId);
    }

    private static List<PicklistOption> getAddressesPicklist(String accountId, List<ContactPointAddress> l) {
        List<PicklistOption> picklist = new List<PicklistOption>();

        // Add the account address to the list        
        if (accountId != null) {
            PicklistOption accountOption = getAccountAddress(accountId);
            picklist.add(accountOption);
        }

        // Add teh account address
        for (ContactPointAddress cpa : l) {
            PicklistOption opt = new PicklistOption();
            opt.value = cpa.Id;
            if (cpa.address != null) {
                opt.label = AddressCommons.buildAddressLabel(cpa.Name, cpa.address);
                picklist.add(opt);
            }
        }
        return picklist;
    }

    private static PicklistOption getAccountAddress(String acccountId) {
        Account acc = [select Id, Name, IsPersonAccount, BillingAddress, PersonMailingAddress from Account where Id = :acccountId limit 1];
        Address addr = acc.BillingAddress;
        if (acc.IsPersonAccount) {
            addr = acc.PersonMailingAddress;
        }
        PicklistOption opt = new PicklistOption();
        opt.label = AddressCommons.buildAddressLabel(acc.Name, addr);
        opt.value = acc.Id;
        return opt;
    }

    private static List<PorcelanosaAddress__c> readSalesOrgAddresses(String accountId) {
        Set<String> salesOrgs = new Set<String>();
        List<Sales_Relationship__c> relations = [select Sales_Org__c from Sales_Relationship__c where Account_Org__c = :accountId];
        for (Sales_Relationship__c rel : relations) {
            if (!salesOrgs.contains(rel.Sales_Org__c)) {
                salesOrgs.add(rel.Sales_Org__c);
            }
        }
        return new PorcelanosaAddressesSelector().selectBySalesOrg(salesOrgs);
    }

    @testVisible private static List<PicklistOption> getPickupPointsPicklist(List<PorcelanosaAddress__c> l) {
        List<PicklistOption> picklist = new List<PicklistOption>();
        for (PorcelanosaAddress__c pa : l) {
            if (pa.NBK_Address_Type__c.containsIgnoreCase('Collection Point')) {
                PicklistOption opt = new PicklistOption();
                opt.value = pa.Id;
                if (pa.NBK_Address__c != null) {
                    opt.label = AddressCommons.buildAddressLabel(pa.Name, pa.NBK_Address__c);
                    picklist.add(opt);
                }
            }
        }
        return picklist;
    }

    @testVisible private static List<PicklistOption> getShowroomsPicklist(List<PorcelanosaAddress__c> l) {
        List<PicklistOption> picklist = new List<PicklistOption>();
        for (PorcelanosaAddress__c pa : l) {
            if (pa.NBK_Address_Type__c.containsIgnoreCase('Showroom')) {
                PicklistOption opt = new PicklistOption();
                opt.value = pa.Id;
                if (pa.NBK_Address__c != null) {
                    opt.label = AddressCommons.buildAddressLabel(pa.Name, pa.NBK_Address__c);
                    picklist.add(opt);
                }
            }
        }
        return picklist;
    }


    //////////////////////////////////////////////////////
    // INNER CLASSES
    //////////////////////////////////////////////////////

    public class DataDTO {
        @AuraEnabled public List<PicklistOption> countries;
        @AuraEnabled public Map<String, List<PicklistOption>> states;
        @AuraEnabled public List<PicklistOption> addressesPicklist;
        @AuraEnabled public List<PicklistOption> addressTypes;
        @AuraEnabled public List<ContactPointAddress> addresses;
        @AuraEnabled public List<PorcelanosaAddress__c> pickupPoints;
        @AuraEnabled public List<PicklistOption> pickupPointsPicklist;
        @AuraEnabled public List<PicklistOption> showroomsPicklist;
    }

    public class PicklistOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
    }

    public class SavedAddressDTO {
        @AuraEnabled public ContactPointAddress address;
        @AuraEnabled public PicklistOption option;
    }
}