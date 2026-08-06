/**
* @author 		Ramón Prades
* @date 		April 2023
* @group 		Cases
* @description 	Case selector class
*/
public class CasesSelector extends zflib_SObjectSelector {

    public Schema.SObjectType getSObjectType() {
        return Case.sObjectType;
    }

    public List<Case> selectById(Set<Id> recordIds) {
       return (List<Case>) selectSObjectsById(recordIds);
    }

    public List<Case> selectByCaseNumbers(Set<String> caseNumbers) {
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('CaseNumber IN :caseNumbers');
        return (List<Case>) Database.query(query.toSOQL());
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
       SObjectType caseType = Schema.getGlobalDescribe().get('Case');
       Map<String,Schema.SObjectField> mfields = caseType.getDescribe().fields.getMap();
       List<Schema.SObjectField> fields = mfields.values();
       return fields;
    }

} // class