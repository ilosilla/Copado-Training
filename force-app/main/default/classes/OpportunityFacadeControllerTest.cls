@isTest public class OpportunityFacadeControllerTest {

    @isTest private static void testReadFacadeData() {
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(1, 2);
        OpportunityFacadeController.DataDTO dto = OpportunityFacadeController.readFacadeData(opps[0].Id, null);
        System.assertEquals(true, dto.isNew, 'isNew should be true');
    }
}