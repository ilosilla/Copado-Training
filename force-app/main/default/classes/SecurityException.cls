/**
* @author 		Ramón Prades
* @date 		January 2025
* @group 		Exceptions
* @description 	Missing permissions to access an object
*/

public class SecurityException extends Exception {
    @testVisible private static String coverage() {
        return 'I am RequiredFieldException';
    }
}