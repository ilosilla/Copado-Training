public class ListUtils {
    /**
    * @description Finds if any of the elements on one List, is on the other list.
    * @param toLook Values to check if any of them exists on the other List
    * @param lookOn List where toLook checks against to
    * @return True/False
    *
    */
    public static Boolean anyOn(List<String> toLook, List<String> lookOn) {
        for (String elem : toLook) {
            if (lookOn.contains(elem)) {
                return true;
            }
        }
        return false;
    }
}