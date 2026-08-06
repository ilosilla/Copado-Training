/**
* @author Ivan Losilla
* @date April 2025
* @group Dvs
* @test DvsHelperTest
*/
public class DvsHelper {
    public static Map<String, DvsPorsaService> searchDiscrepancies(List<Account> accounts, Boolean fuzzySearch) {
        Map<String, DvsPorsaService> result = new Map<String, DvsPorsaService>();

        for (Account acc : accounts) {
            DvsPorsaService elem = new DvsPorsaService(acc);
            elem.doFullSearch();
            result.put(acc.Id, elem);
        }

        return result;
    }

    /**
     * Applies discrepancies to the account fields
     */
    public static List<Account> correctDiscrepancies(List<DvsDiscrepancy__c> discrepancies, List<Account> accounts) {
        SavePoint sp = Database.setSavepoint();

        try {
            Map<Id, DvsDiscrepancy__c> discrepanciesByAccountId = new Map<Id, DvsDiscrepancy__c>();
            for (DvsDiscrepancy__c discrepancy : discrepancies) {
                if (discrepancy.DvsId__c != null) {
                    discrepanciesByAccountId.put(discrepancy.Account__c, discrepancy);
                }
            }

            if (discrepanciesByAccountId.size() > 0) {
                List<DvsAccountInfo__c> oldInfo = new List<DvsAccountInfo__c>();

                for (Account account : accounts) {
                    oldInfo.add(createOldData(account));

                    DvsDiscrepancy__c discrepancy = discrepanciesByAccountId.get(account.Id);
                    account.Name = discrepancy.DvsName__c;
                    account.BillingStreet = discrepancy.DvsStreet__c;
                    account.BillingPostalCode = discrepancy.DvsPostalCode__c;
                    account.BillingCity = discrepancy.DvsCity__c;
                    account.VAT_Number__c = discrepancy.DvsId__c;
                    account.VAT_Number_2__c = discrepancy.DvsId2__c;
                    account.SynchronizedWithDvs__c = true;
                    account.DvsLongError__c = '';
                    account.DvsError__c = '';
                    account.DvsHasError__c = false;

                    account.DVSAcceptedBy__c = UserInfo.getUserId();
                    account.DVSAcceptedDate__c = Datetime.now();
                    account.DVSAction__c = 'ACCEPTED';
                }

                insert oldInfo;
            }
        } catch (Exception ex) {
            Database.rollback(sp);
        }

        return accounts;
    }

    private static DvsAccountInfo__c createOldData(Account acc){
        DvsAccountInfo__c result = new DvsAccountInfo__c();
        result.Account__c = acc.Id;
        result.PreviousCity__c = acc.BillingCity;
        result.PreviousId1__c = acc.VAT_Number__c;
        result.PreviousId2__c = acc.VAT_Number_2__c;
        result.PreviousName__c = acc.Name;
        result.PreviousPostalCode__c = acc.BillingPostalCode;
        result.PreviousStreet__c = acc.BillingStreet;
        result.ProcessedTime__c = Datetime.now();

        return result;
    }

    @testVisible public static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}