@isTest public class CasesSelectorTest {

    @testSetup private static void testSetup() {
        DataFactoryCase.createCollections(10);
    }

    @isTest private static void testSelectById() {
        Case c = [select Id from Case limit 1];
        CasesSelector selector = new CasesSelector();
        Case c2 = selector.selectById(new Set<Id>{c.Id})[0];
        Assert.areEqual(c.Id, c2.Id, 'Case not found');
    }

    @isTest private static void testSelectByCaseNumber() {
        Case c = [select Id, CaseNumber from Case limit 1];
        CasesSelector selector = new CasesSelector();
        List<Case> cases = selector.selectByCaseNumbers(new Set<String>{c.CaseNumber});
        Assert.areEqual(1, cases.size(), 'Wrong number of cases');
    }

}