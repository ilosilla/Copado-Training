/**
* Stores systems constants used by Apex Classes
** 
* @author dguzman
* @date: 03/05/2018
* @service Hecho por NTS
*
*/
public class Constants {}
// public without sharing class Constants {
	
// 	/*
// 	======================================================================================
// 	* -- CLASS: CaseUtils ----------------------------------------------------
// 	======================================================================================
// 	*/

// 	public static final String CASE_MANAGEMENT_ENTITLEMENT_PROCESS_NAME = 'Claim Management';

// 	public static final String CASE_STATUS_PENDING_TO_IDENTIFIED 			=	'1';
// 	public static final String CASE_STATUS_PENDING_TO_QUALIFICATION 		=	'2';
// 	public static final String CASE_STATUS_PENDING_TO_SKU_IDENTIFICATION 	=	'3';
// 	public static final String CASE_STATUS_PENDING_PROBLEM_IDENTIFICATION 	=	'4';
// 	public static final String CASE_STATUS_PENDING_CONSIDERATION 			=	'5';
// 	public static final String CASE_STATUS_PENDING_APPROVAL					=	'6';
// 	public static final String CASE_STATUS_PENDING_SOLUTION 				=	'7';
// 	public static final String CASE_STATUS_PENDING_DELIVERY_DATE 			=	'8';
// 	public static final String CASE_STATUS_PENDING_SERVICE_DATE 			=	'9';
// 	public static final String CASE_STATUS_PENDING_CUSTOMER_FEEDBACK 		=	'10';
// 	public static final String CASE_STATUS_PENDING_TECHNICIAN_FEEDBACK 		=	'11';
// 	public static final String CASE_STATUS_CLOSED 							=	'12';


// 	public static final String CASE_REASON_OTHER_QUALIFICATION 				=	'Other qualification';
// 	public static final String CASE_REASON_DUPLICATED 						=	'Duplicated';
// 	public static final String CASE_REASON_ERROR 							=	'Error';
// 	public static final String CASE_REASON_SUCCESSFULLY_ACCOMPLISHED 		=	'Successfully accomplished';


// 	public static final String PROFILE_USA_DIRECTOR_NAME 					=	'USA Director';

// 	public static final String CHARLES_NAME 								=	'Charles Driscoll';

// 	public static final String NO_OK_SERVICE_TECHNICIAN_RESCHEDULE 			=	'Reschedule';

// 	public static final String CASE_PENDING_CUSTOMER					=	'Customer';
// 	public static final String CASE_PENDING_PORCELANOSA						=	'Porcelanosa';

// 	/*
// 	======================================================================================
// 	* -- CLASS: CaseManagementWizardController -------------------------------------------
// 	======================================================================================
// 	*/

// 	public static final String OTHER_QUALIFICATION 							=	'Others';

// 	public static final String PRODUCT_CASE_TYPE_IDENT_SKU 					=	'Identified SKU';

// 	public static final String PRODUCT_CASE_TYPE_TO_SEND 					=	'Product to send';

// 	public static final Decimal PRODUCT_CASE_DISCOUNT_WITH_WARRANTY 		=	100; 

// 	public static final Decimal PRODUCT_CASE_DISCOUNT_WITHOUT_WARRANTY 		=	40; 

// 	public static final String NAME_APPROVAL_PROCESS_CASE 					=	'USA_Claim_approval_process_v3';



// 	public static String MINIMUM_TOTAL_PRICE_APPROVAL 						=	'';

// 	public static String FINAL_MILESTONE_NAME 								=	'Solve customer claim';

// 	//Tasks names
// 	public static String TASK_DELIVERY_DATE_NAME = '';
// 	public static String TASK_SERVICE_DATE_NAME = '';
// 	public static String TASK_CUSTOMER_FEEDBACK_DATE_NAME = '';
// 	public static String TASK_TECHNICIAN_FEEDBACK_DATE_NAME = '';

	
// 	//Emails
// 	public static final String ORGANIZATION_EMAIL_ADDRESS = 'porcelanosainbox@gmail.com';
// 	public static final String EMAIL_TEMPLATE_PRECLOSING = 'Case pre closing';
// 	public static final String EMAIL_TEMPLATE_CLOSED = 'Case closed';



// 	public static final String USA_CASE_RECORD_TYPE = 'USA';
// 	public static final String USA_CASE_CLAIM_RECORD_TYPE_NAME = 'USA Claim';
// 	public static final String USA_CASE_REQUEST_RECORD_TYPE_NAME = 'USA Request';


// 	/*
// 	======================================================================================
// 	* -- DATA INITIALIZATION  ------------------------------------------------------------
// 	======================================================================================
// 	*/
// 	static
// 	{
// 		List<System_Setup__mdt> systemSetups = 	[
// 													SELECT	Id, MasterLabel, DeveloperName, Value__c 
// 		 											FROM	System_Setup__mdt
// 												];

// 		Map <String, String> systemSetupValueOrderByDeveloperName = new Map <String, String>();

// 		for	(	System_Setup__mdt setup:	systemSetups )
// 		{
// 			if (	setup.DeveloperName != null )
// 			{
// 				systemSetupValueOrderByDeveloperName.put ( setup.DeveloperName, setup.Value__c );
// 			}
// 		}

// 		// All Clasess
// 		MINIMUM_TOTAL_PRICE_APPROVAL			=	systemSetupValueOrderByDeveloperName.get ( 'MINIMUM_TOTAL_PRICE_APPROVAL' );

// 		TASK_DELIVERY_DATE_NAME					=	systemSetupValueOrderByDeveloperName.get ( 'TASK_DELIVERY_DATE_NAME' );
// 		TASK_SERVICE_DATE_NAME					=	systemSetupValueOrderByDeveloperName.get ( 'TASK_SERVICE_DATE_NAME' );
// 		TASK_CUSTOMER_FEEDBACK_DATE_NAME		=	systemSetupValueOrderByDeveloperName.get ( 'TASK_CUSTOMER_FEEDBACK_DATE_NAME' );
// 		TASK_TECHNICIAN_FEEDBACK_DATE_NAME		=	systemSetupValueOrderByDeveloperName.get ( 'TASK_TECHNICIAN_FEEDBACK_DATE_NAME' );
// 	}
// }