/**
* @author 		Ramón Prades
* @date 		July 2022
* @group 		Commons
* @description 	Common opportunity stuff
*/
public without sharing class OpportunityCommons {

    /**
     * Returns the list of closed won stages
     */
    public static List<String> getClosedWonStages() {
        List<String> result = new List<String>();
        List<OpportunityStage> stages = [select apiName from OpportunityStage where isActive = true and isClosed = true and isWon = true];
        for (OpportunityStage stage :stages) {
            result.add(stage.ApiName);
        }
        return result;
    }

    /**
     * Returns the list of closed lost stages
     */
    public static List<String> getClosedLostStages() {
        List<String> result = new List<String>();
        List<OpportunityStage> stages = [select apiName from OpportunityStage where isActive = true and isClosed = true and isWon = false];
        for (OpportunityStage stage :stages) {
            result.add(stage.ApiName);
        }
        return result;
    }

}