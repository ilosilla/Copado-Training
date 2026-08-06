/**
* @author 		Ivan Losilla
* @date 		June 2023
* @group 		User
* @description  Gives, using REST, different methods to have access to user's data
*/
@RestResource(urlMapping='/UserCustom/*')
global class RESTUserCustom {
    public class applicationException extends Exception {}

    @HttpGet global static void methods () {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String functionParam = req.params.get('function');
        String username = req.params.get('email');

        res.statusCode = 500;
        res.responseBody = Blob.valueOf('{ "error" : "Something happened"}');

        if (String.isNotBlank(functionParam)) {
            switch on functionParam.toUpperCase() {
                when 'USEREXISTS' {
                    List<User> usr = [SELECT Id, Firstname, Lastname, Email, username FROM User WHERE username =: username LIMIT 1];
                    if (usr.size() > 0) {
                        res.statusCode = 200;
                        res.responseBody = Blob.valueOf('{ "id" : "' + usr[0].Id + '", "firstname" : "' + usr[0].Firstname + '", "lastname" : "' + usr[0].Lastname + '", "username" : "' + usr[0].username + '"}');
                    } else {
                        res.statusCode = 500;
                        res.responseBody = Blob.valueOf('{ "error" : "' + 'User doesn\'t exist' + '"}');
                    }
                }
                when 'PING' {
                    res.statusCode = 200;
                    res.responseBody = Blob.valueOf('{"hola":"mundo"}');
                }
            }
        }
    }
}