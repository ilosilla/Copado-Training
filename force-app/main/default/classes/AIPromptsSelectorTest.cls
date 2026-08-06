@isTest private class AIPromptsSelectorTest {

    @testSetup private static void testSetup() {
        AIPrompt__c prompt = new AIPrompt__c();
        prompt.Name = 'Example';
        prompt.DeveloperName__c = 'TEST';
        prompt.SystemRole__c = 'Return RED to any questions. Just the word, nothing else.';
        insert prompt;
    }


    @IsTest private static void testSelectByDeveloperName(){
        String name = 'TEST';
        AIPrompt__c result = new AIPromptsSelector().selectByDeveloperName(name);
        Assert.isNotNull(result, 'A prompt should have been found');
    }

}