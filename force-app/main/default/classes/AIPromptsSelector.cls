/**
 * @author         Ramón Prades
 * @date           March 2025
 * @layer          Selector
 * @description    Reads AI Prompts
*/
public class AIPromptsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'AIPrompt__c';
    }

    public List<AIPrompt__c> selectByDeveloperName(Set<String> names){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('DeveloperName__c IN :names');
        return (List<AIPrompt__c>) Database.query(query.toSOQL());
    }
    public AIPrompt__c selectByDeveloperName(String name){        
        List<AIPrompt__c> prompts = this.selectByDeveloperName(new Set<String>{name});
        if(prompts.size() > 0){ 
            return prompts[0];
         } else { 
            return null;
         } 
    }
}