@isTest
public class NB2B_CreateContactPointAddressTest {
    @isTest
    public static void testBatchProcess(){
        Map<String,Object> params = new Map<String,Object>();
        params.put('actionName','createAddress');
        params.put('fields', '{"PostalCode":"AB41 6BE","CountryCode":"GB","StateCode":"","City":"Ellon","Street":"The Gables\nMain Street\nNewburgh","IsDefault":false,"ParentId":"0011j00001L2OKLAA3","Name":"TEST NACHO 2"}');
		NB2B_CreateContactPointAddress controller = new NB2B_CreateContactPointAddress();
		
        NBK_ResponseWr response = controller.execute(params);
        //System.assert(!response.getSuccess());
    }
    @isTest
    public static void testBatchProcessOk(){
        Map<String,String> fields = new Map<String,String>();
        fields.put('PostalCode','AB41 6BE');
                fields.put('CountryCode','GB');
                fields.put('StateCode','');
                fields.put('City','Ellon');
                fields.put('Street','The Gables\nMain Street\nNewburgh');
                fields.put('IsDefault','false');
                fields.put('ParentId','0011j00001L2OKLAA3');
                fields.put('Name','TEST');
        Map<String,Object> params = new Map<String,Object>();
        params.put('actionName','createAddress');
        params.put('fields', fields);
		NB2B_CreateContactPointAddress controller = new NB2B_CreateContactPointAddress();
		
        NBK_ResponseWr response = controller.execute(params);
        //System.assert(response.getSuccess());
    }
}