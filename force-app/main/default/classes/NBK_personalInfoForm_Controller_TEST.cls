@isTest
public class NBK_personalInfoForm_Controller_TEST {

    @isTest
    public static void test1(){
        list<NBK_personalInfoForm_Controller.picklistWrapper> resultado = new list<NBK_personalInfoForm_Controller.picklistWrapper>();
        Test.startTest();
            resultado = NBK_personalInfoForm_Controller.getPicklistValues('customerProfile');
        	resultado = NBK_personalInfoForm_Controller.getPicklistValues('hearAbout');
        	resultado = NBK_personalInfoForm_Controller.getPicklistValues('country');
        	resultado = NBK_personalInfoForm_Controller.getPicklistValues('states');
        	resultado = NBK_personalInfoForm_Controller.getPicklistValues('appointmentType');
        Test.stopTest();

        Assert.areEqual(resultado != null, true);
    }
    
}