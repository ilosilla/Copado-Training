/**
 * Created by Ivan Losilla
 * Date: 28-05-2020
 */
public class OpportunityUtil {

	public static final String QUALIFICATION_STAGE = 'Qualification';
	public static final String QUOTATION_STAGE = 'Cotización';
	public static final String SPECIFICATION_STAGE = 'Especificación';
	
	public static String getName(Id id) {
		List<Opportunity> ops = [select Id, Name from Opportunity where id = :id];
		if (ops.size() > 0) {
			return ops[0].Name;
		} else {
			return '';
		}
	}

}