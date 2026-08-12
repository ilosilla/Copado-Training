@isTest
public class  AAAConflictTest {
    
    public static testmethod void testCountPlusOne(){
        
        Decimal input = 10;
        Test.startTest();
        decimal result =  AAAConflict.countPlusOne(input);
        Test.stopTest();
        System.assertEquals(11, result);
    }
    
}