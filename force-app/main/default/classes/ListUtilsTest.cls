@isTest
public class ListUtilsTest {
    @isTest
    public static void anyOn() {
        List<String> listOne = new List<String>{'A','B','C'};
        List<String> listTwo = new List<String>{'B','O','J'};
        Boolean aux = ListUtils.anyOn(listOne, listTwo);
        System.assertEquals(true, aux, 'The method is not working');
    }
}