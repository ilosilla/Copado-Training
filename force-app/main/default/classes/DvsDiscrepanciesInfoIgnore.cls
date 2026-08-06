public with sharing class DvsDiscrepanciesInfoIgnore {
    
    @InvocableMethod(label='Ignore discrepancies' 
                    description='Ignore discrepancies'
                    )
    public static void ignoreDvsDiscrepanciesInfo(List<List<Id>> selectedRecordIds) {

        System.debug('Number of selected records: ' + selectedRecordIds[0].size());
        DvsService.handleDiscrepancies(selectedRecordIds[0], DvsActions.IGNORE);

    }
}