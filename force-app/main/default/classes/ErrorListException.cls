/**
* @author Ramón Prades
* @date January 2022
*
* @group Exceptions
* @group-content ../../ApexDocContent/Exceptions.htm
*
* @description Exception to pass a lkist of errors to the upper layers 
*/
public class ErrorListException extends Exception {
    public ErrorListException(List<String> messages) {
        this.setMessage(JSON.serialize(messages));
    }
}