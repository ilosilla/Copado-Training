/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			21-03-2019
Description:    No permite crear una nueva Tarea si tienee puesta una Account en el campo WhatID 
				y ésta cuenta se encuentra con el flag bloqueada o borrada a True. 
Test Class:     TaskHandlerTest
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

trigger TaskTrigger on Task (before insert, before update, before delete, after insert, after update, after delete) {
	TriggerDispatcher.run(new TaskTriggerHandler());
}