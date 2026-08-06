/**
* @author 		Ramón Prades
* @date 		April 2022
* @group 		REST
* @description 	Simple class to return the result of a REST call. Mimics the object returned by the standard API.
*/
global class RESTResult {
    global String id;
    global Boolean success;
    global List<RESTError> errors = new List<RESTError>();
}