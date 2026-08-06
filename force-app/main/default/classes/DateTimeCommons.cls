/**
 * @author         Ramón Prades
 * @date           August 2023
 * @group          Commons
 * @description    Date and time methods
*/
public class DateTimeCommons {

    /**
     * Returns a datetime with today and the passed time and timezone
     */
    public static DateTime buildDateTime(Time targetTime, String strTimeZone) {
        Date targetDate = DateTime.now().dateGMT();     // Today in GMT
        return buildDateTime(targetDate, targetTime, strTimeZone);
    } // buildDateTime

    /**
     * Returns a datetime with the passed date, time and timezone
     */
    public static DateTime buildDateTime(Date targetDate, Time targetTime, String strTimeZone) {
        TimeZone targetTimezone = TimeZone.getTimeZone(strTimeZone);
        Integer offsetSeconds = targetTimezone.getOffset(targetDate) / 1000;
        Datetime targetDatetime = Datetime.newInstanceGmt(targetDate, targetTime).addSeconds(-offsetSeconds);
        return targetDateTime;
    } // buildDateTime

    /**
     * Returns a Javascript string (form a specified Time Zone)
     */
    public static String toJavascriptString (DateTime dt, String timeZone) {
        return dt.format('yyyy-MM-dd HH:mm:ss', TimeZone);
    }

    /**
     * Returns a Javascript string
     */
    public static String toJavascriptString (DateTime dt) {
        return dt.format('yyyy-MM-dd HH:mm:ss');
    }

    /**
     * Advance weekend (move to monday if saturday or sunday)
     */
    public static Date advanceWeekend(Date d) {
        Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        return advanceWeekend(dt).date();
    }

    /**
     * Advance weekend (move to monday if saturday or sunday)
     */
    public static DateTime advanceWeekend(DateTime dt) {
        Integer additionalDays = 0;
        String day = dt.format('u');
        if (day == '6') {
            additionalDays = 2;
        } else if (day == '7') {
            additionalDays = 1;
        }
        return dt.addDays(additionalDays);
    }

} //class