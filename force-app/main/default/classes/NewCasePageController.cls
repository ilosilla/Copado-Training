/**
* @author 		Ramón Prades
* @date 		December 2021
* @group 		Cases
* @description 	New Case Page
*/
public class NewCasePageController {
    @AuraEnabled 
    public static resultDTO getCaseRecordTypes() {  
        Schema.DescribeSObjectResult R = case.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        ResultDTO result = new ResultDTO();
        result.sapInvoiceRecordTypeId = RecordTypeLibrary.Case_SAPInvoice; 
        result.recordTypes = new List<RecordTypeDTO>();
        /*
        for(Schema.RecordTypeInfo info : RT) {
            if (info.isActive() && info.isAvailable() && !info.isMaster()) {
                RecordTypeDTO dto = new RecordTypeDTO();
                dto.isDefault = info.isDefaultRecordTypeMapping();
                dto.id = info.getRecordTypeId();
                dto.name = info.getName();
                RecordType rec = [SELECT Description FROM RecordType WHERE Id = :dto.id limit 1];
                dto.description = rec.Description; 
                result.recordTypes.add(dto);
            }
        }
        */
        RecordTypeDTO dto = new RecordTypeDTO();
        dto.id = result.sapInvoiceRecordTypeId;
        dto.name = 'Customer Returns (Collection)';
        dto.isDefault = true;
        //RecordType rec = [SELECT Description FROM RecordType WHERE Id = :dto.id limit 1];        
        result.recordTypes.add(dto);
        return result;
    } // getCaseRecordTypes

    public class resultDTO {
        @AuraEnabled public String sapInvoiceRecordTypeId;
        @AuraEnabled public RecordTypeDTO[] recordTypes;
    } // resultDTO

    public class RecordTypeDTO {
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
    }

} // class