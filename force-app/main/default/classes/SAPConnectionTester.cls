/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Commons
* @description 	Simple class to test SAP is up and running
*/
public class SAPConnectionTester {
    public static void isAlive() {
        SAPWS_Utility.SapResponse response = SAPConnector.connect('', '', SAPConnector.HELLO_SERVICE, 'GET', '');  
        if (response.success) {
            String text = response.json; 
            System.debug('SAP response: ' + text);
        } else {
            throw new AuraHandledException(response.message + ' (error code ' + response.code + ')');
        }
    } // isAlive

} // class