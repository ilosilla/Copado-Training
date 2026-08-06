/**
* @author 		Ramón Prades
* @date 		May 2022
* @group 		ContactPointAddresses
* @description 	Data factory
*/
public class DataFactoryContactPointAddresses {
    public static Boolean autoInsert = true;

    public static List<ContactPointAddress> createRecords(Integer numAccounts, Integer numAddresses) {
        Account[] accounts = DataFactoryAccount.createAccounts(numAccounts);        
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        for (Account acc : accounts) {
            for (Integer i = 0; i< numAddresses; i++) {
                addresses.add(createAddress(acc.Id, i));
            }
        }
        if (autoInsert && Test.isRunningTest()) {
            insert addresses;
        }
        return addresses;
    }

    public static List<ContactPointAddress> createUSRecords(Integer numAddresses) {
        Account[] accounts = DataFactoryAccount.createAccounts(1);        
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        for (Account acc : accounts) {
            for (Integer i = 0; i< numAddresses; i++) {
                addresses.add(createUSAddress(acc.Id, i));
            }
        }
        if (autoInsert && Test.isRunningTest()) {
            insert addresses;
        }
        return addresses;
    }


    public static List<ContactPointAddress> createAccountAddresses(String accountId, Integer numAddresses) {
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        for (Integer i = 0; i< numAddresses; i++) {
            addresses.add(createAddress(accountId, i));
        }
        if (autoInsert && Test.isRunningTest()) {
            insert addresses;
        }
        return addresses;
    }
 
    private static ContactPointAddress createAddress(String accountId, Integer index) {
        ContactPointAddress address = new ContactPointAddress();
        address.addressType = 'Shipping';
        address.Name = 'Test adddress #' + index;
        address.SAPId__c = '0001' + String.valueOf(index).leftPad(6, '0');
        address.ParentId = accountId;
        address.City = 'Ilkley';
        address.CountryCode = 'GB';
        address.PostalCode = 'LS9 9EE';
        address.stateCode = 'SE';
        address.Street = index + ' The Grove';
        //address.EMail__c = 'aaa@ccc.cxm';
        //address.Phone__c = '111 222 333';  
        //address.Mobile__c = '666 777 888';
        return address;
    }

    private static ContactPointAddress createUSAddress(String accountId, Integer index) {
        ContactPointAddress address = new ContactPointAddress();
        address.addressType = 'Shipping';
        address.Name = 'Test adddress #' + index;
        address.SAPId__c = '0001' + String.valueOf(index).leftPad(6, '0');
        address.ParentId = accountId;
        address.City = 'Miami';
        address.CountryCode = 'US';
        address.PostalCode = '3705';
        address.stateCode = 'FL';
        address.Street = index + ' Biscayne Blvd';
        return address;
    }
}