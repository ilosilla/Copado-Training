@isTest public class AIServiceTest {
    @testSetup public static void testSetup() {
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    @isTest private static void testAIService() {
        Test.setMock(HttpCalloutMock.class, new AIServiceTest.Mocker());
        AIService aiService = new AIService();
        aiService.setTemperature(0.1);
        aiService.setSystemRole('You are a geo service that answers geo questions in a brief and unabiguous manner. Just give the answer, no superflouos texts');
        aiService.setUserRole('What is the capital of the state of California');
        Test.startTest();
        String response = aiService.getResponse();
        Test.stopTest();
        Assert.areEqual(response, response);        
    }

    @isTest private static void testStaticResponse() {
        Test.setMock(HttpCalloutMock.class, new AIServiceTest.Mocker());
        Test.startTest();
        String response = AIService.getResponse('What is the capital of the state of California');
        Test.stopTest();
        Assert.areEqual(response, response);        
    }


    public class Mocker implements HttpCalloutMock {
        
        public Boolean testError = false;

        String jsonResponse = '{' +
            '"id": "chatcmpl-B5DYfKo4G8Xvww1ppOk5RUf3bOxLA",' +
            '"object": "chat.completion",' +
            '"created": 1740583457,' +
            '"model": "gpt-4o-mini-2024-07-18",' +
            '"choices": [' +
                '{' +
                    '"index": 0,' +
                    '"message": {' +
                        '"role": "assistant",' +
                        '"content": "Sacramento.",' +
                        '"refusal": null' +
                    '},' +
                    '"logprobs": null,' +
                    '"finish_reason": "stop"' +
                '}' +
            '],' +
            '"usage": {' +
                '"prompt_tokens": 48,' +
                '"completion_tokens": 4,' +
                '"total_tokens": 52,' +
                '"prompt_tokens_details": {' +
                    '"cached_tokens": 0,' +
                    '"audio_tokens": 0' +
                '},' +
                '"completion_tokens_details": {' +
                    '"reasoning_tokens": 0,' +
                    '"audio_tokens": 0,' +
                    '"accepted_prediction_tokens": 0,' +
                    '"rejected_prediction_tokens": 0' +
                '}' +
            '},' +
            '"service_tier": "default",' +
            '"system_fingerprint": "fp_06737a9306"' +
        '}';

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response            
            request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            if (this.testError) {
                mockResponse.setStatusCode(400);
                mockResponse.setBody('Generic Error');
            } else {
                mockResponse.setStatusCode(200);
                mockResponse.setBody(jsonResponse);
            }
            return mockResponse;
        }
    }

}