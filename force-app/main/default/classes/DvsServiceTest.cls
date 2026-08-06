@isTest public class DvsServiceTest {
 
    @isTest static void testLoremIpsum() {
        String lorem = DvsService.loremIpsum();
        Assert.isNotNull(lorem);
    }
       
    

}