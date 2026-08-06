/** 
* Help method for CaseUtil 
* @author dguzman (nts) 
* @date 03/05/2018
* @service Hecho por NTS
*/
public class CaseUtil {}
// public class CaseUtil 
// {
// 	/** 
// 	* 	@author dguzman (nts) 
// 	* 	@date 03/05/2018
// 	* 	@description Method that updates the status of PARENTS to have the most advanced status value of childs
// 	*	@on BEFORE UPDATE
// 	*/
// 	public static void updateParentStatus(List<Case> newList, map<Id,Case> oldMap)
// 	{
// 		Map <Id, Case> updateParentCases	=	new Map <Id, Case>();
// 		Set <Id> parentIds					=	new Set <Id> ();

// 		for(Case c : newList)
// 		{
// 			if (oldMap.get(c.Id).ParentId != null)
// 			{
// 				parentIds.add(oldMap.get(c.Id).ParentId);
// 			}
// 			else if (c.parentId != null)			
// 			{
// 				parentIds.add(c.parentId);
// 			}
// 		}

// 		Map <Id, Case> parentCases	=	new Map <Id, Case> ([select id, Status from Case where Id IN: parentIds]);
// 		Map <Id, Case> childCases	=	new Map <Id, Case> ([select id, Status, ParentId from Case where ParentId IN : parentIds]);

// 		List<Case> 	cases2Update	=	new List<Case>();
// 		String 		minStatus;
		
// 		for(Case c : parentCases.values())
// 		{
// 			 minStatus = Constants.CASE_STATUS_CLOSED;

// 			for(Case cc : childCases.values())
// 			{
// 				if( cc.ParentId == c.Id && Integer.valueOf(minStatus) > Integer.valueof(cc.Status))
// 				{
// 					minStatus = cc.Status;
// 				}
// 			}

// 			if ( c.Status != minStatus )
// 			{
// 				c.Status = minStatus;
// 				cases2Update.add(c);
// 			}
// 		}

// 		update cases2Update;
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 09/05/2018
// 	*	@description When customer and technician service conclusion is OK, the CURRENT case status will change to Closed.
// 	*	@on BEFORE UPDATE
// 	*/
// 	public static void serviceAccomplishCloseCase(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		List<Case> scopeCases = new List<Case>();
// 		for(Case caso:newList)
// 		{
// 			//Fields technician service conclusion or customer service conclusion changes their value, and technician service conclusion = OK and customer service conclusion = OK
// 			if ( 
// 					caso.Technician_service_conclusion__c 	== 'OK' &&
// 					caso.Customer_service_conclusion__c 	== 'OK' &&
// 					( 	
// 						caso.Technician_service_conclusion__c 	!=	oldMap.get(caso.Id).Technician_service_conclusion__c || 
// 						caso.Customer_service_conclusion__c 	!=	oldMap.get(caso.Id).Customer_service_conclusion__c
// 					)
// 				)
// 			{
// 				scopeCases.add(caso);
// 			}
// 		}

// 		for(Case scopeCase:scopeCases)
// 		{
// 			scopeCase.Status = Constants.CASE_STATUS_CLOSED;
// 		}
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 09/05/2018
// 	*	@description Every time a subcase is deleted or the field Total price sent materials updated, the parent case field Total Price sent materials subcases must be updated with the summary of them
// 	*	@on BEFORE DELETE & AFTER INSERT & AFTER UPDATE
// 	*/
// 	public static void calculateTotalPriceSentMaterialsSubcases(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		Set<Id> caseIdsUpdateToTalPrice = new Set<Id>();

// 		//Si se trata de una actualización
// 		if	(newList != null)
// 		{
// 			for	(Case caso:	newList)
// 			{			
// 				if	(newList == null && caso.ParentId != null)
// 				{	//Si se trata de una eliminación --> Lo consideramos (CASOS MULTIPLES)
// 					caseIdsUpdateToTalPrice.add(caso.ParentId);				
// 				}
// 				else if	(oldMap != null && (caso.Total_price_sent_materials__c != oldMap.get(caso.Id).Total_price_sent_materials__c))
// 				{	//Si se trata de una modificación del campo Total_price_sent_materials__c

// 					if(caso.ParentId != null) 
// 					{	//Si tiene padre --> Lo tenemos en cuenta para actualizar su campo de total price	
// 						caseIdsUpdateToTalPrice.add(caso.ParentId);
// 					}

// 					//Tanto si tiene como si no tiene padre, actualizamos el campo del propio caso con lo del campo rollup
// 					caseIdsUpdateToTalPrice.add(caso.Id);
// 				}
// 				else if (oldMap != null && ((caso.parentId != oldMap.get(caso.Id).parentId)))
// 				{//Si se trata de una separación de un hijo del padre, se debe recalcular el precio calculado de padre a partir de los hijos
// 					caseIdsUpdateToTalPrice.add(oldMap.get(caso.Id).parentId);					
// 				}
// 			}
// 		}
// 		else
// 		{	//Si se trata de una eliminación --> Actualizaremos el padre
// 			for(Case caso:oldMap.values())
// 			{
// 				caseIdsUpdateToTalPrice.add(caso.ParentId);
// 			}
// 		}

// 		List<Case> scopeCases = [	
// 									SELECT 	Id,Total_Price_sent_materials_subcases__c,Total_price_sent_materials__c,(SELECT Total_Price_sent_materials__c FROM Cases)
// 									FROM	Case	
// 									WHERE	Id IN:caseIdsUpdateToTalPrice
// 								];

// 		for(Case scopeCase:scopeCases)
// 		{
// 			if(scopeCase.Cases.isEmpty())
// 			{	//Actualizamos el mismo caso con el campo rollup
// 				scopeCase.Total_Price_sent_materials_subcases__c = scopeCase.Total_price_sent_materials__c;
// 			}
// 			else
// 			{	//Tiene hijos, rellenamos con el sumatorio del rollup
// 				Decimal sum = 0.0;
// 				for(Case childCase: scopeCase.Cases)
// 				{
// 					sum += childCase.Total_Price_sent_materials__c;
// 				}
// 				scopeCase.Total_Price_sent_materials_subcases__c = sum;
// 			}
// 		}
	
// 		update scopeCases;
// 	}


// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 14/05/2018
// 	*	@description Everytime a case is created, it is related to the account "Case Management" entitlement
// 	*	@on BEFORE INSERT & BEFORE UPDATE
// 	*/
// 	public static void relateToAccountContactCaseManagementEntitlement(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		List<Case> scopeCases	=	new List<Case>();
// 		Map<Id,Id> contactIds	=	new Map<Id,Id>();
				

// 		for(Case inputCase:newList)
// 		{
// 			//Si al crearse identifica al contacto o se updatea el contacto
// 			if(	inputCase.ContactId != null && 
// 				(oldMap == null || inputCase.ContactId != oldMap.get(inputCase.Id).ContactId)
// 			&&
// 				(
// 					(inputCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_CLAIM_RECORD_TYPE_NAME).getRecordTypeId() ||
// 													inputCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_REQUEST_RECORD_TYPE_NAME).getRecordTypeId()))	
// 				) 		

// 			{
// 				contactIds.put(inputCase.ContactId,null);
// 				scopeCases.add(inputCase);	
// 			}
			
// 		}

// 		for	( Contact contacto: [SELECT Id,AccountId from Contact where Id in:contactIds.keyset()])
// 		{
// 			contactIds.put(contacto.Id,contacto.AccountId);
// 		}

// 		//Tendré que completar que me pueden venir ids de cuentas personales por lo que habrá que hacer la siguiente query también para obtener la parte de sus cuentas
// 		//Select id,PersonContactId  from Account where personContactId = idsContactos que me vienen por email to case
// 		//Esos ids de cuentas que obtengo a partir de los ids de contacto del email to case los meto a accountIds y continua el proceso

// 		Map<Id,Account> accounts = new Map<Id,Account>(
// 			[
// 				SELECT	Id,(SELECT Id FROM Entitlements) 
// 				FROM	Account
// 				WHERE	Id IN 
// 						(
// 							SELECT	AccountId 
// 							FROM	Entitlement
// 							WHERE	SlaProcess.Name	=	:Constants.CASE_MANAGEMENT_ENTITLEMENT_PROCESS_NAME 
// 									AND 
// 									accountId 		IN	:contactIds.values()
// 						)
// 			]
// 		);

// 		for(Case scopeCase:scopeCases)
// 		{
// 			if	(scopeCase.ContactId != null)
// 			{
// 				if	(contactIds.containsKey(scopeCase.ContactId))
// 				{
// 					if	(accounts.containsKey(contactIds.get(scopeCase.ContactId)))
// 					{
// 						scopeCase.EntitlementId = accounts.get(contactIds.get(scopeCase.ContactId)).Entitlements[0].Id;
// 					}
// 				}	
// 			}						
// 		}
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 21/05/2018
// 	*	@description Everytime the status changes, the status change date is stored
// 	*	@on BEFORE UPDATE
// 	*/
// 	public static void registerLastStatusChange(list<Case> newList, map<Id,Case> oldMap)
// 	{		
// 		for(Case scopeCase:newList)
// 		{
// 			if	(scopeCase.Status != oldMap.get(scopeCase.Id).Status)
// 			{
// 				scopeCase.Date_last_status_change__c	=	System.now();
// 				scopeCase.Case_Stopped__c 				=	false;
// 				//scopeCase.PreClosing__c					=	false;
// 			}
// 		}
// 	}

// 	/** 
// 	* 	@author gmiranda (nts) 
// 	* 	@date 21/05/2018
// 	* 	@description Everytime the check reopened is marked, the case will return to status "Pending Problem identification"
// 	*	@on BEFORE UPDATE
// 	*/
// 	public static void reopenReturnToProblemIdentification(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		for(Case scopeCase:newList)
// 		{
// 			if	(scopeCase.Reopened__c != oldMap.get(scopeCase.Id).Reopened__c && scopeCase.Reopened__c)
// 			{
// 				scopeCase.Status = Constants.CASE_STATUS_PENDING_PROBLEM_IDENTIFICATION;
// 			}
// 		}
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 21/05/2018
// 	*	@description Everytime a parent case is reopen, child cases should be reopened too
// 	*	@on AFTER UPDATE
// 	*/
// 	public static void reopenChildCases(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		Map<Id,Case> scopeParentCases	=	new Map<Id,Case>();

// 		for(Case triggerCase:newList)
// 		{
// 			if	(	triggerCase.Status	==	Constants.CASE_STATUS_PENDING_PROBLEM_IDENTIFICATION 	&& 
// 					triggerCase.Status	!=	oldMap.get(triggerCase.Id).Status 						&&
// 					oldMap.get(triggerCase.Id).Status == Constants.CASE_STATUS_CLOSED
// 				)
// 			{
// 				scopeParentCases.put(triggerCase.Id,triggerCase);
// 			}
// 		}

// 		List<Case> childCases = 
// 			[
// 				SELECT	Id,Status,Reason,ParentId
// 				FROM	Case	
// 				WHERE	ParentId in	:scopeParentCases.keyset()
// 			];

// 		for(Case childCase:childCases)
// 		{
// 			if(scopeParentCases.containsKey(childCase.ParentId))
// 			{	//Los hijos los reabrimos al estado de problem identification			
// 				childCase.Status = Constants.CASE_STATUS_PENDING_PROBLEM_IDENTIFICATION;
// 			}
// 		}

// 		update childCases;
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 21/05/2018
// 	*	@description Everytime a parent case is closed, child cases should be closed too
// 	*	@on AFTER UPDATE
// 	*/
// 	public static void closeChildCases(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		Map<Id,Case> scopeParentCases	=	new Map<Id,Case>();
		
// 		for	(Case triggerCase:newList)
// 		{
// 			if	(triggerCase.status == Constants.CASE_STATUS_CLOSED && triggerCase.Status != oldMap.get(triggerCase.Id).Status)
// 			{
// 				scopeParentCases.put(triggerCase.Id,triggerCase);
// 			}
// 		}

// 		List<Case> childCases = 
// 			[
// 				SELECT	Id,Status,Reason,ParentId
// 				FROM	Case
// 				WHERE	ParentId in:scopeParentCases.keyset()
// 			];
		
// 		List<Case> cases2Update	=	new List<Case>();

// 		for(Case childCase:childCases)
// 		{
// 			if(scopeParentCases.containsKey(childCase.ParentId))
// 			{	
// 				if ( childCase.Status != (scopeParentCases.get(childCase.ParentId)).Status || childCase.Reason != (scopeParentCases.get(childCase.ParentId)).Reason)
// 				{
// 					childCase.Status = (scopeParentCases.get(childCase.ParentId)).Status;	
// 					childCase.Reason = (scopeParentCases.get(childCase.ParentId)).Reason;
// 					cases2Update.add(childCase);
// 				}
// 			}
// 		}

// 		update cases2Update;
// 	}

// 	/** 
// 	* 	@author gmiranda (nts) 
// 	*	@date 21/05/2018
// 	*	@description Everytime a case is created with a customer, the customer state is copied to the case
// 	* 	Every time the case customer changes, the state is copied to the case
// 	*	@on BEFORE INSERT & BEFORE UPDATE
// 	*/
// 	public static void getCustomerState(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		List<Case>scopeCases	=	new List<Case>();
// 		Set<Id> customerIds		=	new Set<Id>();

// 		for	(Case triggerCase:newList)
// 		{
// 			if	(	triggerCase.Customer__c != null &&
// 					(	oldMap == null	||	triggerCase.Customer__c != oldMap.get(triggerCase.Id).Customer__c)
// 				)
// 			{
// 				scopeCases.add(triggerCase);
// 				customerIds.add(triggerCase.Customer__c);
// 			}
// 		}

// 		Map<Id,Contact> customers = new Map<Id,Contact>(
// 			[	
// 				SELECT	Id,MailingState 
// 				FROM	Contact	
// 				WHERE	Id IN: customerIds 
// 						AND
// 						MailingState != null
// 			]
// 		);

// 		for(Case scopeCase:scopeCases)
// 		{
// 			if(customers.containsKey(scopeCase.Customer__c))
// 			{
// 				scopeCase.State__c = customers.get(scopeCase.Customer__c).MailingState;
// 			}
// 		}
// 	}

// 	/** 
// 	*	@author dguzman (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Cada vez que el servicio del caso para a ser reprogramado, pasa la resolucion a no terminada
// 	*	@on BEFORE UPDATE
// 	*/
// 	public static void updateServiceDoneReschedulable(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		for	(Case c : newList)
// 		{
// 			if	( 	
// 					c.Technician_service_conclusion__c	==	Constants.NO_OK_SERVICE_TECHNICIAN_RESCHEDULE && 
// 					c.Technician_service_conclusion__c	!=	oldMap.get(c.Id).Technician_service_conclusion__c
// 				)
// 			{
// 				c.Service_done__c = false;
// 			}
// 		}
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Cuando se separa un caso hijo de padre, los product cases también deben borrar el lookup que tenían al padre.
// 	*	@on AFTER UPDATE
// 	*/	
// 	public static void splitProductCasesFromParent(list<Case> newList, map<Id,Case> oldMap)
// 	{		
// 		Map<Id,Case> scopeCases	=	new Map<Id,Case>();
		
// 		for	(Case triggerCase:newList)
// 		{
// 			if	( triggerCase.ParentId != oldMap.get(triggerCase.Id).ParentId )
// 			{
// 				scopeCases.put(triggerCase.Id,triggerCase);
// 			}
// 		}

// 		Map<Id,Product_Case__c> productCasesUpdate	=	new Map<Id,Product_Case__c>(
// 			[
// 				SELECT 	Id, Case__c, Parent_Case__c
// 				FROM	Product_Case__c
// 				WHERE	Case__c IN:scopeCases.keyset()
// 			]
// 		);

// 		for	(Product_Case__c pc:productCasesUpdate.values())
// 		{
// 				pc.Parent_Case__c = scopeCases.get(pc.Case__c).ParentId;
// 		}

// 		if (!productCasesUpdate.isEmpty()) update productCasesUpdate.values();
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Cuando se llega a un estado final, marcar el milestone como finalizado.
// 	*	@on BEFORE UPDATE
// 	*/
// 	public static void completeFinalMilestone(list<Case> newList, map<Id,Case> oldMap)
// 	{
// 		List<Id> scopeCases	=	new List<Id>();
// 		for	(Case scopeCase: newList)
// 		{
// 			if	( 	
// 					scopeCase.Status == Constants.CASE_STATUS_CLOSED 	&& 
// 					scopeCase.Status != oldMap.get(scopeCase.Id).Status
// 				)
// 			{
// 				scopeCases.add(scopeCase.Id);
// 			}
// 		}

// 		completeMilestone(scopeCases, Constants.FINAL_MILESTONE_NAME, System.now());
// 	}

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Se obtienen los milestones, y se actualizan aquellos que no se encuentren completado.
// 	*/
//     private static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) 
// 	{  
//     	List<CaseMilestone> cmsToUpdate = 
// 		[
// 			SELECT	Id, completionDate
//             FROM	CaseMilestone cm
//             WHERE	caseId in :caseIds 
// 					AND cm.MilestoneType.Name=:milestoneName 
//             		AND completionDate = null 
// 			LIMIT 1
// 		];

//     	if (cmsToUpdate.isEmpty() == false)
//     	{
//         	for (CaseMilestone cm : cmsToUpdate)
// 			{
// 	            cm.completionDate = complDate;
//             }

//         	update cmsToUpdate;
//         }
//     }

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Método para actualizar las tareas asociadas al Caso cuando se ha introducido una fecha de envío
// 	*	@on AFTER UPDATE
// 	*/
//     public static void completeDeliveryDate(List<Case>newList,Map<Id,Case>oldMap)
//     {
//     	Set<Id> scopeCases	=	new Set<Id>();
//     	for	(Case triggerCase:newList)
//     	{
//     		if 	( 	triggerCase.Estimated_Delivery_Date__c != null && 
// 					triggerCase.Estimated_Delivery_Date__c != oldMap.get(triggerCase.Id).Estimated_Delivery_Date__c
// 				)
//     		{
//     			scopeCases.add(triggerCase.Id);
//     		}
//     	}

//     	List<Task> tasksToUpdate = new List<Task>();
//     	for(Task t :  [select Id,WhatId,Status from Task where WhatId IN: scopeCases and Subject =: Constants.TASK_DELIVERY_DATE_NAME and Status != 'Completed'])
//         {
//         	t.Status='Completed';
//             tasksToUpdate.add(t);
//         } 
//         update tasksToUpdate;   
//     }

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Método para actualizar las tareas asociadas al Caso cuando se ha introducido una fecha de envío
// 	*	@on AFTER UPDATE
// 	*/
//     public static void completeServiceDate(List<Case>newList,Map<Id,Case>oldMap)
//     {
//     	Set<Id> scopeCases = new Set<Id>();
//     	for(Case triggerCase:newList)
//     	{
//     		if(triggerCase.Service_date__c != null && triggerCase.Service_date__c != oldMap.get(triggerCase.Id).Service_date__c)
//     		{
//     			scopeCases.add(triggerCase.Id);
//     		}
//     	}

//     	List<Task> tasksToUpdate = new List<Task>();
//     	for(Task t :  [select Id,WhatId,Status from Task where WhatId IN: scopeCases and Subject =: Constants.TASK_SERVICE_DATE_NAME and Status != 'Completed'])
//         {
//         	t.Status='Completed';
//             tasksToUpdate.add(t);
//         } 
//         update tasksToUpdate;
//     }

// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Método para actualizar las tareas asociadas al Caso cuando se ha introducido una conclusión de atención al cliente
// 	*	@on AFTER UPDATE
// 	*/
//     public static void completeCustomerFeedBack(List<Case>newList,Map<Id,Case>oldMap)
//     {
//     	Set<Id> scopeCases = new Set<Id>();
//     	for(Case triggerCase:newList)
//     	{
//     		if(triggerCase.Customer_service_conclusion__c != null && triggerCase.Customer_service_conclusion__c != oldMap.get(triggerCase.Id).Customer_service_conclusion__c)
//     		{
//     			scopeCases.add(triggerCase.Id);
//     		}
//     	}

//     	List<Task> tasksToUpdate = new List<Task>();
//     	for(Task t :  [select Id,WhatId,Status from Task where WhatId IN: scopeCases and Subject =: Constants.TASK_CUSTOMER_FEEDBACK_DATE_NAME and Status != 'Completed'])
//         {
//         	t.Status='Completed';
//             tasksToUpdate.add(t);
//         } 
//         update tasksToUpdate;
//     }


// 	/** 
// 	*	@author gmiranda (nts) 
// 	*	@date 29/05/2018
// 	*	@description: Método para actualizar las tareas asociadas al Caso cuando se ha introducido una conclusión del técnico
// 	*	@on AFTER UPDATE
// 	*/
//     public static void completeTechnicianFeedback(List<Case>newList,Map<Id,Case>oldMap)
//     {
//     	Set<Id> scopeCases	=	new Set<Id>();
//     	for(Case triggerCase:newList)
//     	{
//     		if(triggerCase.Technician_service_conclusion__c != null && triggerCase.Technician_service_conclusion__c != oldMap.get(triggerCase.Id).Technician_service_conclusion__c)
//     		{
//     			scopeCases.add(triggerCase.Id);
//     		}
//     	}

//     	List<Task> tasksToUpdate	=	new List<Task>();
//     	for(Task t :  [select Id,WhatId,Status from Task where WhatId IN: scopeCases and Subject =: Constants.TASK_TECHNICIAN_FEEDBACK_DATE_NAME and Status != 'Completed'])
//         {
//         	t.Status='Completed';
//             tasksToUpdate.add(t);
//         } 

//         update tasksToUpdate;
//     }

//     	/** 
// 	* @author gmiranda (nts) 
// 	* @date 14/05/2018
// 	* @description Cuando se crea el primer caso para un cliente --> Se crea automaticamente un entitlement asociado al cliente y al nuevo caso que se crea
// 	*/
// 	public static void createAccountCaseManagementEntitlement(list<Case> newList)
// 	{

// 		/*System.debug('*init createAccountCaseManagementEntitlement caso '+newList[0].AccountId+' - '+newList[0].RecordTypeId);				
// 		System.debug('*init createAccountCaseManagementEntitlement caso '+newList[1].AccountId+' - '+newList[1].RecordTypeId);
// 		System.debug('*init createAccountCaseManagementEntitlement caso '+Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_CLAIM_RECORD_TYPE_NAME).getRecordTypeId());
// 		System.debug('*init createAccountCaseManagementEntitlement caso '+Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_REQUEST_RECORD_TYPE_NAME).getRecordTypeId());
// 		*/

		


// 		Set<Id> accountIds	=	new Set<Id>();
// 		Set<Id> caseIds	=	new Set<Id>();
		
// 		for(Case scopeCase:newList)
// 		{
// 			system.debug('Condicion '+scopeCase.AccountId != null && 

// 				(
// 					(scopeCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_CLAIM_RECORD_TYPE_NAME).getRecordTypeId() ||
// 													scopeCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_REQUEST_RECORD_TYPE_NAME).getRecordTypeId()
// 					)
// 				)
			


// 				);


// 			//Para todos aquellos caso que traen un cliente relacionado y son casos de usa
// 			if(scopeCase.AccountId != null && 

// 				(
// 					(scopeCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_CLAIM_RECORD_TYPE_NAME).getRecordTypeId() ||
// 													scopeCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_REQUEST_RECORD_TYPE_NAME).getRecordTypeId()
// 					)
// 				)
// 			)
// 			{
// 				system.debug('Rellenando con '+scopeCase.AccountId +' y '+scopeCase.Id);
// 				accountIds.add(scopeCase.AccountId);
// 				caseIds.add(scopeCase.Id);	
// 			}
			

// 		}

// 		system.debug('*accountIds '+accountIds);
// 		system.debug('*caseIds '+caseIds);

// 		//De esos ids de cuentas solo entrarán dentro del scope aquellas que todavía no tenian ningún caso asociado
// 		Map<Id,Account> scopeAccounts = new Map<Id,Account>([Select Id,(SELECT Id FROM Entitlements) FROM Account where Id IN: accountIds]);

// 		for(Account scopeAccount:scopeAccounts.values())
// 		{
// 			if(!scopeAccount.Entitlements.isempty())
// 			{
// 				accountIds.remove(scopeAccount.Id);
// 			}
// 		}

// 		//En este punto tenemos todas las cuentas para las que hay que crear entitlement



// 		//Obtenemos el entitlement process de gestión de casos
// 		List<SlaProcess> process =  [
// 										SELECT	Id 
// 										FROM	SlaProcess
// 										WHERE	Name=: Constants.CASE_MANAGEMENT_ENTITLEMENT_PROCESS_NAME
// 									];


// 		system.debug('*process '+process);



// 		if(!process.isEmpty())
// 		{
// 			List<Entitlement> entitlements = new List<Entitlement>();
			
// 			for(Id accountId: accountIds)
// 			{
// 				entitlements.add
// 				(
// 					new Entitlement
// 					(
// 						Name 			=	Constants.CASE_MANAGEMENT_ENTITLEMENT_PROCESS_NAME,
// 						AccountId 		=	accountId,
// 						StartDate 		=	System.today(),
// 						SlaProcessId 	=	process[0].Id
// 					)
// 				);
// 			}

// 			if (!entitlements.isEmpty())
// 			{
// 				insert entitlements;


// 				//Después de crear el entitlement, este se debe asociar al caso correspondiente
// 				List<Case> casesToUpdate = new List<Case>([SELECT Id,AccountId,EntitlementId FROM Case Where AccountId IN: accountIds and Id IN: caseIds]);

// 				for(Entitlement createdEntitlement: entitlements)
// 				{
// 					Id auxAccountId = createdEntitlement.AccountId;
// 					for(Case caseToUpdate: casesToUpdate)
// 					{
// 						if(caseToUpdate.AccountId == auxAccountId)
// 						{
// 							caseToUpdate.EntitlementId = createdEntitlement.Id;
// 						}
// 					}
// 				}

// 				update casesToUpdate;
// 			}
						

// 		}
// 		else 
// 		{
// 			for(Case c:newList)
// 			{
// 				c.addError('No SLA Process found for this Account so no Entitlement can be assigned. Notify about this error to the administrator of the system.');
// 			}
// 		}
// 	}

// }