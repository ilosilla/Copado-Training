/**
	* Type: Apex Class
	* Name: NB2B_DeliveryDateSelector_Controller
	* @author dev@nubika.com
	* Company: Nubika S.L.
	* Date: 26/04/2022
	* Description: Apex controller for nb2bDeliveryDateSelector lwc
	* @version 1.0
*/
public without sharing class NB2B_DeliveryDateSelector_Controller extends NBK_DynamicController  {
	public override NBK_ResponseWr execute(Map<String,Object> params){
		try{
			String actionName = String.valueOf(params.get(NBK_ControllerExecuterConstants.PARAM_ACTION));
			switch on actionName{
				when 'getDeliveryDates' {return getDeliveryDates(String.valueOf(params.get('postalCode')));}
				when 'getUserData' {return getUserData();}
				when else {
					throw new NB2B_DeliveryDateSelector_ControllerException('Invalid Action');
				}
			}
		}catch(Exception e){
			Logger.error(e.getMessage());
			return new NBK_ResponseWr(false,e,null);
		} finally {
			Logger.saveLog();
		}
	}

	/*-----------------------------------------------------------------------------------------
	Apex Method Name: 	getDeliveryDates
	Version: 1.0
	Created Date: 		26/04/2022
	Function: 			get a list of delivery dates configuration
	param: 				the postal code
	return: 			An instance of NBK_ResponseWr class that contains the list of delivery dates
	------------------------------------------------------------------------------------------*/
	private NBK_ResponseWr getDeliveryDates(String postalCode){
		NBK_ResponseWr res;
		try {
			if(String.isNotBlank(postalCode)){
				Set<String> deliveryDays = new Set<String>();
                Decimal delayDays;
				Boolean defaultAdd = false;
				for(Delivery_Days_Configuration__c ddc : NB2B_AddressSelector.getDeliveryDaysConfigFromPostalCode(postalCode)){
                    if(ddc.Default_code__c){
                        delayDays = ddc.DaysToDelay__c;
                        defaultAdd = ddc.Default_code__c;
                    }
					deliveryDays.addAll(ddc.Delivery_Days__c.split(';'));
				}
				res = new NBK_ResponseWr(true,null,JSON.serialize(deliveryDays), defaultAdd, delayDays );
                System.debug('res : ' + JSON.serialize(res));
			}else{
				//TODO: a label
				throw new NB2B_DeliveryDateSelector_ControllerException('There is an empty parameter.');
			}
		}catch(Exception e){
			throw new NB2B_DeliveryDateSelector_ControllerException(e.getMessage());
		}
		return res;
	}

	private static NBK_ResponseWr getUserData(){
		NBK_ResponseWr res;

		try {
			String userInfo = Userinfo.getLocale();

			Map<String, String> mapLocaleDateFormat = localeDateFormat();
			String dateFormat = mapLocaleDateFormat.get(userInfo);

			res = new NBK_ResponseWr(true,null,JSON.serialize(dateFormat));
			
		}catch (Exception e) {
			System.debug('NB2B_DeliveryDateSelector_Controller.getUserData: ' + e.getMessage() + ', in line: ' + e.getLineNumber());
			res = new NBK_ResponseWr(false,null,null);
		}
		return res;
	}

	public static Map<String, String> localeDateFormat() {
		Map<String, String> locale_map = new Map<String, String>(); //holds the locale to timedate formats

		locale_map.put('af_ZA', 'yyyy-MM-dd');
		locale_map.put('ar_AE', 'd/M/yyyy');
		locale_map.put('ar_BH', 'd/M/yyyy');
		locale_map.put('ar_DZ', 'd/M/yyyy');
		locale_map.put('ar_EG', 'd/M/yyyy');
		locale_map.put('ar_IQ', 'd/M/yyyy');
		locale_map.put('ar_JO', 'dd/MM/yyyy');
		locale_map.put('ar_KW', 'd/M/yyyy');
		locale_map.put('ar_LB', 'dd/MM/yyyy');
		locale_map.put('ar_LY', 'd/M/yyyy');
		locale_map.put('ar_MA', 'd/M/yyyy');
		locale_map.put('ar_OM', 'd/M/yyyy');
		locale_map.put('ar_QA', 'd/M/yyyy');
		locale_map.put('ar_SA', 'dd/MM/yyyy');
		locale_map.put('ar_SD', 'd/M/yyyy');
		locale_map.put('ar_SY', 'dd/MM/yyyy');
		locale_map.put('ar_TN', 'd/M/yyyy');
		locale_map.put('ar_YE', 'd/M/yyyy');
		locale_map.put('az_AZ', 'dd.MM.yyyy');
		locale_map.put('be_BY', 'd.M.yyyy');
		locale_map.put('bg_BG', 'dd.MM.yyyy');
		locale_map.put('bn_BD', 'd/M/yyyy');
		locale_map.put('bn_IN', 'd/M/yyyy');
		locale_map.put('bs_BA', 'd.M.yyyy');
		locale_map.put('ca_ES', 'dd/MM/yyyy');
		locale_map.put('ca_ES_EURO', 'dd/MM/yyyy');
		locale_map.put('cs_CZ', 'd.M.yyyy');
		locale_map.put('cy_GB', 'dd/MM/yyyy');
		locale_map.put('da_DK', 'dd-MM-yyyy');
		locale_map.put('de_AT', 'dd.MM.yyyy');
		locale_map.put('de_AT_EURO', 'dd.MM.yyyy');
		locale_map.put('de_BE', 'dd.MM.yyyy');
		locale_map.put('de_DE', 'dd.MM.yyyy');
		locale_map.put('de_DE_EURO', 'dd.MM.yyyy');
		locale_map.put('de_LU', 'dd.MM.yyyy');
		locale_map.put('de_LU_EURO', 'dd.MM.yyyy');
		locale_map.put('de_CH', 'dd.MM.yyyy');
		locale_map.put('dz_BT', 'yyyy-MM-dd');
		locale_map.put('el_GR', 'd/M/yyyy');
		locale_map.put('en_AG', 'dd/MM/yyyy');
		locale_map.put('en_AU', 'd/MM/yyyy');
		locale_map.put('en_BB', 'dd/MM/yyyy');
		locale_map.put('en_BS', 'dd/MM/yyyy');
		locale_map.put('en_BZ', 'dd/MM/yyyy');
		locale_map.put('en_BM', 'dd/MM/yyyy');
		locale_map.put('en_BW', 'dd/MM/yyyy');
		locale_map.put('en_CA', 'dd/MM/yyyy');
		locale_map.put('en_CM', 'dd/MM/yyyy');
		locale_map.put('en_KY', 'dd/MM/yyyy');
		locale_map.put('en_ER', 'dd/MM/yyyy');
		locale_map.put('en_FK', 'dd/MM/yyyy');
		locale_map.put('en_FJ', 'dd/MM/yyyy');
		locale_map.put('en_GM', 'dd/MM/yyyy');
		locale_map.put('en_GH', 'dd/MM/yyyy');
		locale_map.put('en_GI', 'dd/MM/yyyy');
		locale_map.put('en_GY', 'dd/MM/yyyy');
		locale_map.put('en_HK', 'd/M/yyyy,');
		locale_map.put('en_IN', 'd/M/yyyy');
		locale_map.put('en_ID', 'dd/MM/yyyy');
		locale_map.put('en_IE', 'dd/MM/yyyy');
		locale_map.put('en_IE_EURO', 'dd/MM/yyyy');
		locale_map.put('en_JM', 'dd/MM/yyyy');
		locale_map.put('en_KE', 'dd/MM/yyyy');
		locale_map.put('en_LR', 'dd/MM/yyyy');
		locale_map.put('en_MG', 'dd/MM/yyyy');
		locale_map.put('en_MW', 'dd/MM/yyyy');
		locale_map.put('en_MY', 'dd/MM/yyyy');
		locale_map.put('en_MU', 'dd/MM/yyyy');
		locale_map.put('en_NA', 'dd/MM/yyyy');
		locale_map.put('en_NZ', 'd/MM/yyyy');
		locale_map.put('en_NG', 'dd/MM/yyyy');
		locale_map.put('en_PK', 'dd/MM/yyyy');
		locale_map.put('en_PG', 'dd/MM/yyyy');
		locale_map.put('en_PH', 'M/d/yyyy');
		locale_map.put('en_RW', 'dd/MM/yyyy');
		locale_map.put('en_SH', 'dd/MM/yyyy');
		locale_map.put('en_WS', 'dd/MM/yyyy');
		locale_map.put('en_SC', 'dd/MM/yyyy');
		locale_map.put('en_SL', 'dd/MM/yyyy');
		locale_map.put('en_SG', 'dd/MM/yyyy');
		locale_map.put('en_SX', 'dd/MM/yyyy');
		locale_map.put('en_SB', 'dd/MM/yyyy');
		locale_map.put('en_ZA', 'yyyy/MM/dd');
		locale_map.put('en_SZ', 'dd/MM/yyyy');
		locale_map.put('en_TZ', 'dd/MM/yyyy');
		locale_map.put('en_TO', 'dd/MM/yyyy');
		locale_map.put('en_TT', 'dd/MM/yyyy');
		locale_map.put('en_UG', 'dd/MM/yyyy');
		locale_map.put('en_GB', 'dd/MM/yyyy');
		locale_map.put('en_US', 'M/d/yyyy');
		locale_map.put('en_VU', 'dd/MM/yyyy');
		locale_map.put('es_AR', 'dd/MM/yyyy');
		locale_map.put('es_BO', 'dd-MM-yyyy');
		locale_map.put('es_CL', 'dd-MM-yyyy');
		locale_map.put('es_CO', 'd/MM/yyyy');
		locale_map.put('es_CR', 'dd/MM/yyyy');
		locale_map.put('es_CU', 'd/M/yyyy');
		locale_map.put('es_DO', 'dd/MM/yyyy');
		locale_map.put('es_EC', 'dd/MM/yyyy');
		locale_map.put('es_ES', 'd/MM/yyyy');
		locale_map.put('es_ES_EURO', 'd/MM/yyyy');
		locale_map.put('es_GT', 'd/MM/yyyy');
		locale_map.put('es_HN', 'MM-dd-yyyy');
		locale_map.put('es_MX', 'd/MM/yyyy');
		locale_map.put('es_NI', 'MM-dd-yyyy');
		locale_map.put('es_PA', 'MM/dd/yyyy');
		locale_map.put('es_PE', 'dd/MM/yyyy');
		locale_map.put('es_PR', 'MM-dd-yyyy');
		locale_map.put('es_PY', 'dd/MM/yyyy');
		locale_map.put('es_SV', 'MM-dd-yyyy');
		locale_map.put('es_US', 'M/d/yyyy');
		locale_map.put('es_UY', 'dd/MM/yyyy');
		locale_map.put('es_VE', 'dd/MM/yyyy');
		locale_map.put('et_EE', 'd.MM.yyyy');
		locale_map.put('eu_ES', 'yyyy/M/d');
		locale_map.put('fa_IR', 'yyyy/M/d،\u200f');
		locale_map.put('fi_FI', 'd.M.yyyy');
		locale_map.put('fi_FI_EURO', 'd.M.yyyy');
		locale_map.put('fr_BE', 'd/MM/yyyy');
		locale_map.put('fr_CA', 'yyyy-MM-dd');
		locale_map.put('fr_KM', 'dd/MM/yyyy');
		locale_map.put('fr_FR', 'dd/MM/yyyy');
		locale_map.put('fr_FR_EURO', 'dd/MM/yyyy');
		locale_map.put('fr_GN', 'dd/MM/yyyy');
		locale_map.put('fr_HT', 'dd/MM/yyyy');
		locale_map.put('fr_LU', 'dd/MM/yyyy');
		locale_map.put('fr_MR', 'dd/MM/yyyy');
		locale_map.put('fr_MC', 'dd/MM/yyyy');
		locale_map.put('fr_CH', 'dd.MM.yyyy');
		locale_map.put('fr_WF', 'dd/MM/yyyy');
		locale_map.put('ga_IE', 'dd/MM/yyyy');
		locale_map.put('gu_IN', 'd/M/yyyy');
		locale_map.put('hi_IN', 'd/M/yyyy');
		locale_map.put('hr_HR', 'dd.MM.yyyy');
		locale_map.put('hu_HU', 'yyyy.MM.dd');
		locale_map.put('hy_AM', 'dd.MM.yyyy');
		locale_map.put('in_ID', 'dd/MM/yyyy');
		locale_map.put('is_IS', 'd.M.yyyy');
		locale_map.put('it_CH', 'dd.MM.yyyy');
		locale_map.put('it_IT', 'dd/MM/yyyy');
		locale_map.put('iw_IL', 'dd/MM/yyyy');
		locale_map.put('ja_JP', 'yyyy/MM/dd');
		locale_map.put('ka_GE', 'dd.MM.yyyy');
		locale_map.put('kk_KZ', 'dd.MM.yyyy');
		locale_map.put('km_KH', 'd/M/yyyy');
		locale_map.put('kn_IN', 'd/M/yyyy');
		locale_map.put('ko_KP', 'yyyy. M. d.');
		locale_map.put('ko_KR', 'yyyy. M. d');
		locale_map.put('ky_KG', 'd/M/yyyy');
		locale_map.put('lb_LU', 'dd.MM.yyyy');
		locale_map.put('lo_LA', 'd/M/yyyy');
		locale_map.put('lt_LT', 'yyyy.M.d');
		locale_map.put('lu_CD', 'd/M/yyyy');
		locale_map.put('lv_LV', 'dd.MM.yyyy');
		locale_map.put('mk_MK', 'd.M.yyyy');
		locale_map.put('ml_IN', 'd/M/yyyy');
		locale_map.put('mr_IN', 'd/M/yyyy');
		locale_map.put('ms_BN', 'd/MM/yyyy');
		locale_map.put('ms_MY', 'dd/MM/yyyy');
		locale_map.put('mt_MT', 'dd/MM/yyyy');
		locale_map.put('my_MM', 'dd-MM-yyyy B');
		locale_map.put('ne_NP', 'yyyy/M/d');
		locale_map.put('nl_AW', 'dd-MM-yyyy');
		locale_map.put('nl_BE', 'd/MM/yyyy');
		locale_map.put('nl_NL', 'd-M-yyyy');
		locale_map.put('nl_SR', 'dd-MM-yyyy');
		locale_map.put('no_NO', 'dd.MM.yyyy');
		locale_map.put('pl_PL', 'dd.MM.yyyy');
		locale_map.put('ps_AF', 'yyyy/M/d');
		locale_map.put('pt_AO', 'dd/MM/yyyy');
		locale_map.put('pt_BR', 'dd/MM/yyyy');
		locale_map.put('pt_CV', 'dd/MM/yyyy');
		locale_map.put('pt_MZ', 'dd/MM/yyyy');
		locale_map.put('pt_PT', 'dd-MM-yyyy');
		locale_map.put('pt_ST', 'dd/MM/yyyy');
		locale_map.put('rm_CH', 'dd-MM-yyyy');
		locale_map.put('rn_BI', 'd/M/yyyy');
		locale_map.put('ro_MD', 'dd.MM.yyyy');
		locale_map.put('ro_RO', 'dd.MM.yyyy');
		locale_map.put('ru_KZ', 'dd.MM.yyyy');
		locale_map.put('ru_RU', 'dd.MM.yyyy');
		locale_map.put('sh_BA', 'dd.MM.yyyy');
		locale_map.put('sh_CS', 'dd.MM.yyyy');
		locale_map.put('sh_ME', 'dd.MM.yyyy');
		locale_map.put('sk_SK', 'd.M.yyyy');
		locale_map.put('sl_SI', 'd.M.yyyy');
		locale_map.put('so_DJ', 'dd/MM/yyyy');
		locale_map.put('so_SO', 'dd/MM/yyyy');
		locale_map.put('sr_BA', 'yyyy-MM-dd');
		locale_map.put('sr_CS', 'd.M.yyyy');
		locale_map.put('sr_RS', 'd.M.yyyy');
		locale_map.put('sq_AL', 'yyyy-MM-dd');
		locale_map.put('sv_SE', 'yyyy-MM-dd');
		locale_map.put('sw_KE', 'dd/MM/yyyy');
		locale_map.put('ta_IN', 'd/M/yyyy');
		locale_map.put('ta_LK', 'd/M/yyyy');
		locale_map.put('te_IN', 'dd-MM-yyyy');
		locale_map.put('tg_TJ', 'dd/MM/yyyy');
		locale_map.put('th_TH', 'd/M/yyyy, น.');
		locale_map.put('ti_ET', 'dd/MM/yyyy');
		locale_map.put('tl_PH', 'M/d/yyyy');
		locale_map.put('tr_TR', 'dd.MM.yyyy');
		locale_map.put('uk_UA', 'dd.MM.yyyy');
		locale_map.put('ur_PK', 'd/M/yyyy');
		locale_map.put('uz_LATN_UZ', 'dd/MM/yyyy');
		locale_map.put('vi_VN', 'dd/MM/yyyy');
		locale_map.put('yo_BJ', 'dd/MM/yyyy');
		locale_map.put('xh_ZA', 'M/d/yyyy');
		locale_map.put('zh_CN', 'yyyy-M-d');
		locale_map.put('zh_CN_PINYIN', 'yyyy/M/d');
		locale_map.put('zh_CN_STROKE', 'yyyy/M/d');
		locale_map.put('zh_HK', 'yyyy年M月d日');
		locale_map.put('zh_HK_STROKE', 'd/M/yyyy');
		locale_map.put('zh_MO', 'd/M/yyyy');
		locale_map.put('zh_SG', 'dd/MM/yyyy');
		locale_map.put('zh_TW', 'yyyy/M/d');
		locale_map.put('zh_TW_STROKE', 'yyyy/M/d');
		locale_map.put('zu_ZA', 'M/d/yyyy');

		return locale_map; //return the map
	}

	private class NB2B_DeliveryDateSelector_ControllerException extends Exception {}
}