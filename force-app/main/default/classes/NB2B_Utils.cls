public with sharing class NB2B_Utils {
	private static final Map<String,String> HEX_BIN_MAP = new Map<String,String>{
		'0'=>'0000',
		'1'=>'0001',
		'2'=>'0010',
		'3'=>'0011',
		'4'=>'0100',
		'5'=>'0101',
		'6'=>'0110',
		'7'=>'0111',
		'8'=>'1000',
		'9'=>'1001',
		'A'=>'1010',
		'B'=>'1011',
		'C'=>'1100',
		'D'=>'1101',
		'E'=>'1110',
		'F'=>'1111'
	};

	public static Map<String,List<Schema.PicklistEntry>> getDependentPicklistValues(String objName, String fieldName, Boolean valueAsKey){
		Map<String,List<Schema.PicklistEntry>> dependentPicklistValues = new Map<String,List<Schema.PicklistEntry>>();

		Schema.DescribeFieldResult depend = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe();
		if(depend.getType() == Schema.DisplayType.Picklist) {
			Schema.sObjectField controlToken = depend.getController();
			if (controlToken != null) {
				Schema.DescribeFieldResult control = controlToken.getDescribe();
				if(control.getType() == Schema.DisplayType.Picklist) {
					List<Schema.PicklistEntry> dependEntries = depend.getPicklistValues();
					List<Schema.PicklistEntry> controlEntries = control.getPicklistValues();
					for(Schema.PicklistEntry entry : dependEntries) {
						String validFor = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor'));
						if(entry.isActive() && String.isNotBlank(validFor)) {
							String hex = EncodingUtil.convertToHex(EncodingUtil.base64Decode(validFor)).toUpperCase();
							String bin = '';
							for(String h : hex.split('')){
								bin+=HEX_BIN_MAP.get(h);
							}
							List<String> binList = bin.split('');
							for(Integer i=0;i<binList.size();i++){
								if(binList.get(i)=='1'){
									String contKey = valueAsKey ? controlEntries.get(i).getValue() : controlEntries.get(i).getLabel();
									if(!dependentPicklistValues.containsKey(contKey)){
										dependentPicklistValues.put(contKey,new List<Schema.PicklistEntry>());
									}
									dependentPicklistValues.get(contKey).add(entry);
								}
							}
						}
					}
				}
			}
		}
		return dependentPicklistValues;
	}
}