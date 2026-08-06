/**
 * @author         Ramón Prades
 * @date           August 2023
 * @group          Tests
 * @description    Test class
*/
@isTest public class DateTimeCommonsTest {

    @isTest private static void test001() {
        TimeZone tz = UserInfo.getTimeZone();

        Time t = Time.newInstance(9, 30, 0, 0);
        DateTime r1 = DateTimeCommons.buildDateTime(t, tz.getID());
        Assert.areEqual(Date.today(), r1.Date(), 'Dates do not match');

    } // test
    @isTest private static void test002() {
        TimeZone tz = UserInfo.getTimeZone();
        Time t = Time.newInstance(9, 30, 0, 0);
        Date d = Date.newInstance(2023, 12, 31);
        DateTime r1 = DateTimeCommons.buildDateTime(d, t, tz.getID());
        String s1 = DateTimeCommons.toJavascriptString(r1);
        String s2 = DateTimeCommons.toJavascriptString(r1, tz.getID());
        Assert.areEqual('2023-12-31 09:30:00', s1, 'Unexpected string ' + tz.getID());
        Assert.areEqual('2023-12-31 09:30:00', s2, 'Unexpected string ' + tz.getID());
    } // test

    @isTest private static void test003() {
        // Friday
        Datetime dt = Datetime.newInstance(2023, 8, 25, 10, 30, 0);
        Datetime r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt, r1, 'Dates should be equal');

        // Saturday
        dt = dt.addDays(1);
        r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt.addDays(2), r1, 'Dates should be equal');

        // Sunday
        dt = dt.addDays(1);
        r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt.addDays(1), r1, 'Dates should be equal');
        
        // Monday
        dt = dt.addDays(1);
        r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt, r1, 'Dates should be equal');        
    }

    @isTest private static void test004() {
        // Friday
        Date dt = Date.newInstance(2023, 8, 25);
        Date r1 = DateTimeCommons.advanceWeekend(dt);
        Assert.areEqual(dt, r1, 'Dates should be equal');

        // Saturday
        dt = dt.addDays(1);
        r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt.addDays(2), r1, 'Dates should be equal');

        // Sunday
        dt = dt.addDays(1);
        r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt.addDays(1), r1, 'Dates should be equal');
        
        // Monday
        dt = dt.addDays(1);
        r1 = DateTimeCOmmons.advanceWeekend(dt);
        Assert.areEqual(dt, r1, 'Dates should be equal');        
    }
}