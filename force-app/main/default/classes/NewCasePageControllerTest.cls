@isTest public class NewCasePageControllerTest {

    @isTest static void test001() {
        NewCasePageController.resultDTO dto = NewCasePageController.getCaseRecordTypes();
        Assert.isNotNull(dto);
    }
}