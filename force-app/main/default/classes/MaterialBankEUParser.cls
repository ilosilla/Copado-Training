/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Leads
* @description 	Class to parse the XML received from Material Bank EU and to launch the lead creation process.
*               It implmenetes AbstractStreamParser because it can be called from RESTStreamService.
*/
public class MaterialBankEUParser extends MaterialBankParser {

    public override void setEurope() {
        this.isEurope = true;
    }

} // MaterialBankEUParser