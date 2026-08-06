/**
 * @author: Ramópn Prades
 * @date: April 2023
 */
trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete) {
	zflib_TriggerDomainClass.triggerHandler(CasesDomain.class);
}