/*
 * Author : Ivan Losilla
 * Description : Tets Class for AddressUtil
 * Date : 2020-06-23
 * History
 */
@isTest
public class AddressUtilTest {
    
	@testSetup static void setup() {
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
    
    @isTest
    public static void wellFormed() {
        Map<String, String> aux = new AddressUtil().splitPostCode('GB','LA22 9NZ'); 
        System.assert(aux.containsKey('Global'));
        System.assert(aux.containsKey('Specific'));
        System.assert(aux.containsKey('Medium'));
        System.assert(aux.containsKey('Valid'));
    }

    @isTest
    public static void validGBPostCode() {
        Map<String, String> aux = new AddressUtil().splitPostCode('GB','LA22 9NZ');
        System.assert(aux.get('Global') == 'LA');
        System.assert(aux.get('Medium') == 'LA22');
        System.assert(aux.get('Specific') == 'LA22 9NZ');
        System.assert(aux.get('Valid') == 'true');
    }

    @isTest
    public static void validESPostCode() {
        Map<String, String> aux = new AddressUtil().splitPostCode('ES','12003');
        System.assert(aux.get('Global') == '12');
        System.assert(aux.get('Medium') == null);
        System.assert(aux.get('Specific') == '12003');
        System.assert(aux.get('Valid') == 'true');
    }

    @isTest
    public static void validFRPostCode() {
        Map<String, String> aux = new AddressUtil().splitPostCode('FR','75003');
        System.assert(aux.get('Global') == '75');
        System.assert(aux.get('Medium') == null);
        System.assert(aux.get('Specific') == '75003');
        System.assert(aux.get('Valid') == 'true');
    }

    @isTest
    public static void noValidPostCode() {
        Map<String, String> aux = new AddressUtil().splitPostCode('ES','23423242');
        System.assert(aux.get('Global') == null);
        System.assert(aux.get('Medium') == null);
        System.assert(aux.get('Specific') == '23423242');
        System.assert(aux.get('Valid') == 'false');
    }

    @isTest
    public static void salesOrgPostCode() {
        AccountSettings__c newAccSetting = new AccountSettings__c(Name = 'UK', Country__c = 'GB', novalidcreation_mailto__c = 'ivan.losilla@porcelanosagrupo.com');
        PostCodeObjects__c aux = new PostCodeObjects__c(postCode__c = 'BB', objectId__c = '500', objectType__c = 'SALES_ORG', country__c = 'GB');
        insert aux;
        insert newAccSetting;

        List<String> auxList = AddressUtil.salesOrgPostCode('GB','BB4 7YH');
        System.assertEquals(1, auxList.size(), 'Sales Org not found');
    }

    @isTest private static void normalizeUSCodeTest() {
        String pcode = '1';
        System.assertEquals('00001', AddressUtil.normalizeUSCode(pcode));
        pcode = '111111';
        System.assertEquals('111111', AddressUtil.normalizeUSCode(pcode));
        pcode = null;
        System.assertEquals('00000', AddressUtil.normalizeUSCode(pcode));
    }
    @isTest private static void testUSCode() {
        String pcode = '77493-1122';
        AddressUtil au = new AddressUtil();
        Map<String,String> result = au.splitPostCode('US', pcode);
        System.assertEquals(true, Boolean.valueOf(result.get('Valid')));        
        System.assertEquals('77493', result.get('Global'));          

        pcode = '07493';
        result = au.splitPostCode('US', pcode);
        System.assertEquals(true, Boolean.valueOf(result.get('Valid')));        
        System.assertEquals('07493', result.get('Global'));          

        pcode = '7493';
        result = au.splitPostCode('US', pcode);
        System.assertEquals(false, Boolean.valueOf(result.get('Valid')));        
    }

    @isTest private static void testCACode() {
        String pcode = 'A1A 2B2';
        AddressUtil au = new AddressUtil();
        Map<String,String> result = au.splitPostCode('CA', pcode);
        System.assertEquals(true, Boolean.valueOf(result.get('Valid')));        
        System.assertEquals('A1A', result.get('Global'));          

        pcode = 'ABA 3233';
        result = au.splitPostCode('CA', pcode);
        System.assertEquals(false, Boolean.valueOf(result.get('Valid')));        
    }

}