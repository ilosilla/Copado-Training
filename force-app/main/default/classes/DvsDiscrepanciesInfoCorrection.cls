/**
 * Entry point for correcting the discrepencies of accounts
 */
public with sharing class DvsDiscrepanciesInfoCorrection {
    
    
    @InvocableMethod(label='Correct discrepancies' 
                    description='Correct discrepancies'
                    )
    public static void correctDvsDiscrepanciesInfo(List<List<Id>> selectedRecordIds) {

        System.debug('Number of selected records: ' + selectedRecordIds[0].size());
        DvsService.handleDiscrepancies(selectedRecordIds[0], DvsActions.CORRECT);
    }
}