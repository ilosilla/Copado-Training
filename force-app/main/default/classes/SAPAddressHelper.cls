/**
* @author 		Ramón Prades
* @date 		November 2021
* @group 		Utils
* @description 	Class to deal with SAP delivery addresses 
*/
global class SAPAddressHelper {

    global static final String SHIPPING_TYPE = 'Shipping';
    global static final String BILLING_TYPE = 'Billing';
    global static final String CUSTOMER_TYPE = 'Customer';    
    global static final String OTHERS_TYPE = 'Others';
    
    global static ContactPointAddress readInvoiceDeliveryAddress(string invoice) {
        ContactPointAddress addr;
        List<ContactPointAddress> addresses = SAPAddressHelper.readInvoiceAddresses(invoice);
        if (addresses.size() > 0) {
            for (ContactPointAddress a : addresses) {
                if (a.addressType == SHIPPING_TYPE) {
                    addr = a;
                }
            }
            if (addr == null) {
                addr = addresses[0];
            }
        } else {
            // NO addresses read
            throw new ObjectNotFoundException('Error reading invoice addresses!');
        }
        ContactPointAddress[] cpAddresses = new ContactPointAddressesSelector().selectBySAPId(new Set<String>{addr.SAPId__c});
        if (cpAddresses.size() > 0) {
            addr = cpAddresses[0];
        }
        return addr;
    } // readInvoiceDeliveryAddress

    global static List<ContactPointAddress> readInvoiceAddresses(string invoice) {
        return SAPAddressHelper.readInvoiceAddresses(invoice, false);
    } // readInvoiceAddresses

    global static List<ContactPointAddress> readInvoiceAddresses(string invoice, Boolean register) {
        List<AddressDTO> sapAddresses = new List<AddressDTO>();
        if (String.isBlank(invoice)) {
            throw new ValidationException('Invoice number is required');
        }
        String paramString = 'invoice=' + invoice;
        if (register) {
            paramString += '&register=true';
        }
        SAPWS_Utility.SapResponse response = SAPConnector.connect(
            '', 
            paramString,
            SAPConnector.ADDRESS_SERVICE, 
            'GET', 
            ''
        );  
        if (response.success) {
            sapAddresses = (List<AddressDTO>)JSON.deserialize(response.json, List<AddressDTO>.class); 
        } else {
            throw new HttpException(response.message + ' (error code ' + response.code + ')');
        }
        return SAPAddressHelper.SAPToSalesforce(sapAddresses);
    } // readInvoiceAddresses

    global static List<ContactPointAddress> readAccountAddresses(string sapId, Boolean register) {
        List<AddressDTO> sapAddresses = new List<AddressDTO>();
        if (String.IsNotBlank(sapId)) {
            String paramString = 'customer=' + sapId;
            if (register) {
                paramString += '&register=true';
            }
            SAPWS_Utility.SapResponse response = SAPConnector.connect(
                '', 
                paramString,
                SAPConnector.ADDRESS_SERVICE, 
                'GET', 
                ''
            );  
            if (response.success) {
                sapAddresses = (List<AddressDTO>)JSON.deserialize(response.json, List<AddressDTO>.class); 
            } else {
                throw new HttpException(response.message + ' (error code ' + response.code + ')');
            }
        }
        return SAPAddressHelper.SAPToSalesforce(sapAddresses);
    } // readAccountAddresses

    global static AddressDTO sendAddressToSAP(ContactPointAddress address) {
        AddressDTO result = new AddressDTO();            
        AddressDTO dto = SAPAddressHelper.SalesforceToSAP(address);            
        String xjson = JSON.serialize(dto);
        String method = 'PUT';
        String resource = dto.sapId;
        if (resource == null) {
            method = 'POST';
            resource = '';
        }
        SAPWS_Utility.SapResponse response = SAPConnector.connect(
            resource, 
            SAPConnector.ADDRESS_SERVICE, 
            method,
            xjson
        );
        if (response.success) {            
            result = (AddressDTO) JSON.deserialize(response.json, AddressDTO.class); 
        } else {
            throw new ValidationException('SAP ERROR: ' +  response.code + ' - ' + response.message);
        }
        return result;
    } // sendAddressToSAP

    global static ContactPointAddress[] SAPToSalesforce(AddressDTO[] dtos) {
        ContactPointAddress[] sfAddresses = new List<ContactPointAddress>();
        for (AddressDTO dto : dtos) {
            ContactPointAddress sfAddress = new ContactPointAddress();                 
            sfAddress.AddressType = convertAddressTypeFromSAP(dto.addressType);
            sfAddress.Name = dto.name;
            sfAddress.SAPId__c = dto.sapId;
            sfAddress.ParentId = dto.accountId;
            sfAddress.City = dto.city;
            sfAddress.CountryCode = dto.countryCode;
            sfAddress.PostalCode = dto.postalCode;
            sfAddress.StateCode = dto.stateCode;
            sfAddress.Street = dto.street;
            if (String.IsNotBlank(dto.street2)) {
                sfAddress.Street +=  '\n' + dto.street2;
            }
            if (String.IsNotBlank(dto.street3)) {
                sfAddress.Street +=  '\n' + dto.street3;
            }
            sfAddress.EMail__c = dto.email;
            sfAddress.Phone__c = dto.phone;
            sfAddress.Mobile__c = dto.mobile;
            sfAddresses.add(sfAddress);
        }
        return sfAddresses;
    } // SAPToSalesforce

    /*
    global static Address SAPToSalesforceAddress(AddressDTO dto) {
        Address addr = new Address();
        addr.City = dto.city;
        addr.CountryCode = dto.countryCode;
        addr.PostalCode = dto.postalCode;
        addr.StateCode = dto.stateCode;
        addr.Street = dto.street;
        if (String.IsNotBlank(dto.street2)) {
            addr.Street +=  '\n' + dto.street2;
        }
        if (String.IsNotBlank(dto.street3)) {
            addr.Street +=  '\n' + dto.street3;
        }
        return addr;
    } // SAPToSalesforce
    */
    
    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/    
    private static AddressDTO SalesforceToSAP(ContactPointAddress address) {
        AddressDTO dto = new AddressDTO();
        dto.origin = 'SFORCE';
        dto.addressType = 'D';
        if (address.AddressType.ToUpperCase() == 'BILLING') {
            dto.addressType = 'B';
        }
        dto.externalId = address.Id;
        dto.name = address.Name;
        dto.sapId = address.SAPId__c;
        dto.accountId= address.ParentId;
        dto.city = address.City;
        dto.countryCode = address.CountryCode;
        dto.postalCode = address.PostalCode;
        dto.state = address.state;
        dto.stateCode = address.stateCode;
        String[] addressLines = new List<String>();
        if (String.IsNotEmpty(address.Street)) {
            addressLines  = address.Street.split('\n');
        }
        if (addressLines.size() > 0) {
            dto.street = addressLines[0];
        }
        if (addressLines.size() > 1) {
            dto.street2 = addressLines[1]; 
        }
        if (addressLines.size() > 2) {
            dto.street3 = addressLines[2];
        }                    
        dto.language =  UserInfo.getLanguage();
        dto.email = address.EMail__c;
        dto.phone =  address.Phone__c;
        dto.mobile = address.Mobile__c;
        if (dto.accountId != null) {
            Account acc = [select Id, SAP_Id__c from Account where Id = :dto.accountId limit 1];
            dto.customer = acc.SAP_Id__c;
        }
        return dto;    
    } // SalesforceToSAP

    private static String convertAddressTypeFromSAP(String aType) {
        String result;
        switch on aType {
            when 'D' {
                result = SHIPPING_TYPE;
            }
            when 'B' {
                result = BILLING_TYPE;
            }
            when 'C' {
                result = CUSTOMER_TYPE;
            }
            when else {
                result = OTHERS_TYPE;
            }
        }
        return result;
    }


    /*********************************************************/
    /******************** INNER CLASSES  *********************/
    /*********************************************************/
    global class AddressDTO {
        @AuraEnabled global String addressType;         // D delivery, B billing, C Customer, O others
        @AuraEnabled global String sapId;
        @AuraEnabled global String customer;            // Parent customer (the address belong to this one)
        @AuraEnabled global String street;
        @AuraEnabled global String street2;
        @AuraEnabled global String street3;
        @AuraEnabled global String countryCode;
        @AuraEnabled global String city;
        @AuraEnabled global String postalCode;
        @AuraEnabled global String stateCode;
        @AuraEnabled global String state;
        @AuraEnabled global String name;
        @AuraEnabled global String email;
        @AuraEnabled global String phone;
        @AuraEnabled global String mobile;
        @AuraEnabled global String origin;
        @AuraEnabled global String externalId;          // Id18 de salesforce (o del sistema externo que sea)
        @AuraEnabled global String accountId;           // Id18 del acocunt al que pertenece la dirección
        @AuraEnabled global String language;
    } // inner class
    
} // class