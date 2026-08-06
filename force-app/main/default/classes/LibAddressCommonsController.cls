/**
* @author 		Ramón Prades
* @date 		AUgust 2023
* @group 		Commons
* @description 	Address COmmons
*/
public class LibAddressCommonsController {
    @AuraEnabled(cacheable=false)
    public static PorcelanosaAddress__c getPorcelanosaAddress(Id addressId) {
        PorcelanosaAddress__c address = (PorcelanosaAddress__c) new PorcelanosaAddressesSelector().selectSingle(addressId);
        return address;
    }
}