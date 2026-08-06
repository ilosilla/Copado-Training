/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Utils
* @description 	Utility methods to schedule apex tasks
*/
public class ScheduleUtils {
    /**
     * Retunrs the string to schedule a job after hours:minutes today
     */
    public static String runTodayAfter(Integer hours, Integer minutes) {        
        Datetime dt = datetime.now().addHours(hours);
        dt = dt.addMinutes(minutes); 
        String sch = '00 &2 &3 &4 &5 ? &7';
        sch = sch.replace('&2', String.valueOf(dt.minute()));
        sch = sch.replace('&3', String.valueOf(dt.hour()));
        sch = sch.replace('&4', String.valueOf(dt.day()));
        sch = sch.replace('&5', String.valueOf(dt.month()));
        sch = sch.replace('&7', String.valueOf(dt.year()));
        return sch;
    } // runTodayAfter

}