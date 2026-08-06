@IsTest
public class AddressStoreWRP_Test {

    @IsTest
    public static void test1(){
        AddressStoreWRP result;
        Test.startTest();
            result = new AddressStoreWRP();
            result.address = new PorcelanosaAddress__c();
            result.distance = 100;
            result.imageStore = 'imagen'; 
        Test.stopTest();
    }

    @IsTest
    public static void test2(){
        AddressStoreWRP result;
        Test.startTest();
            result = new AddressStoreWRP(new PorcelanosaAddress__c(),100,'imagen');
        Test.stopTest();
    }

}