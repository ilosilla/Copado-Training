/**
* @author 		Ramón Prades
* @date 		January 2025
* @group 		Exceptions
* @description 	Thrown when a required field is missing or left empty. Indicates that all necessary input values were not provided.
*/
public class RequiredFieldException extends Exception {
    @testVisible private static String coverage() {
        return 'I am RequiredFieldException';
    }
}