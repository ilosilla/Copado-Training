/**
* @author 		Ramón Prades
* @date 		October 2022
* @group 		Tests
* @description 	Testing Copado Pipeline
*/
@isTest public class CopadoPipelineTest {
    @isTest public static void CopadoPipelineTest() {
        System.assertEquals('COPADO', CopadoPipeline.whoAreYou());
    }
}