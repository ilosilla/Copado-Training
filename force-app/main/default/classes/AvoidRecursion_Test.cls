@isTest
public class AvoidRecursion_Test {
	
    @isTest public static void test_AvoidRecursion(){
        //La primera vez tiene que dar true y las otras falso.
        System.assert(AvoidRecursion.isFirstRun());
        System.assert(!AvoidRecursion.isFirstRun());
        System.assert(!AvoidRecursion.isFirstRun());
        System.assert(!AvoidRecursion.isFirstRun());
    }
}