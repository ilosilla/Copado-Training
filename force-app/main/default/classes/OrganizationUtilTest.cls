/**
* @author 			Ramón Prades
* @date 			October-2020
* @group 			Util
* @group-content 	../../ApexDocContent/Util.htm
* @description 	    Test 
*/
@isTest private class OrganizationUtilTest {

    @TestSetup
    static void makeData(){
        TestUtils.enableTriggers();
        DataFactoryOrganization.createData();
    }

    @isTest static void testCutoffTime() {        
        Integer theHour = 9;
        Integer theMinute = 30;
        Sales_Org__c so = [select Name, SamplesCutoff__c, SamplesMinDays__c, SamplesWeekendDays__c, TimeZone__c 
                            from Sales_Org__c 
                            where SalesOrg__c = :OrganizationCommons.ORG_SOUTH_EAST limit 1];
        so.SamplesCutOff__c = Time.newInstance(theHour, theMinute, 0, 0);
        so.SamplesMinDays__c = 1;
        so.SamplesWeekendDays__c = '';
        so.Timezone__c = 'Europe/London';
        DateTime cutoffTime = OrganizationUtil.getSamplesCutoff(so);

        TimeZone targetTimezone = TimeZone.getTimeZone(so.Timezone__c);
        Integer offset1 = targetTimezone.getOffset(cutoffTime) / 1000;
        Integer offset2 = TimeZone.getTimeZone('Europe/Madrid').getOffset(cutoffTime) / 1000;
        Integer offset = offset2 - offset1;
        Assert.areEqual(offset, 3600 * (cutoffTime.hour() - theHour), 'Time should be the same');

        //Assert.areEqual(so.SamplesCutoff__c, cutoffTime.time(), 'Time should be the same');        
    }

    @isTest static void isFrench() {  
        System.assertEquals(true, OrganizationUtil.isFrench('200'));
        System.assertEquals(false, OrganizationUtil.isFrench('500'));
    } // isFrench

    @isTest static void getSalesOrgCompanY() {
        System.assertEquals('207', OrganizationUtil.getSalesOrgCompany(OrganizationCommons.ORG_LORCERAM), 'Wrong Company');
    }

    @isTest static void getSalesOrgName() {
        System.assertNotEquals('', OrganizationUtil.getSalesOrgName(OrganizationCommons.ORG_SOUTH_EAST), 'Sales org name not retrieved');
    }

    @isTest static void getSalesOrgs() {
        System.assert(OrganizationUtil.getSalesOrgs().size() > 0, 'Map of Sales Orgs empty');
    }
    
    @isTest static void getSalesOfficeName() {
        System.assertNotEquals('', OrganizationUtil.getSalesOfficeName('3035'), 'Sales office name not retrieved');
    }
    @isTest static void getSalesOffices() {
        System.assert(OrganizationUtil.getSalesOffices().size() > 0, 'Map of Sales Offices empty');
    }

    @isTest static void getChannelOrgName() {
        System.assertNotEquals('', OrganizationUtil.getChannelName('60'), 'Channel name not retrieved');
    }
}