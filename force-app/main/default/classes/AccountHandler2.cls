/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:           05-04-2019
Description:    Manejo de automatizaciones de SAP
Test Class:     AccountHandlerTest
History
<Date>            <Author>              <Change Description>
										No permite eliminar una cuenta que tenga un sap id asignado.
22-04-2019        Jose Fluxa            Se comenta la validación del campo VAT_Number_2__c 
                                        Ramón indica que finalmente sólo se quiere validar VAT_Number_1__c
24-04-2019        Jose Fluxa            No funciona la validación: a.RecordType.Name != 'Private Customer'
17-05-2019                              Para Record Types Private customer, Fabricator y Third party Retailer / Reseller o
                                        Account con ‘Account Classification’ == ‘National House Builder’
                                        Se genera automáticamente y se envía a SAP una Sales RelationShip (Send to SAP)
29/07/2019								Cuando la cuenta cambia de nombre se actualiza el FullName de las Sales Relationships asociadas.
30/11/2020          Ivan Losilla        No se usa esta clase para el Trigger. Se usa AccountTriggerHandler
-----------------------------------------------------------------------------------------*/
/**
* @author Ivan Losilla
* @date September 2021
* @group Triggers
* @deprecated  We don't use this one, instead we use AccountTriggerHandler
*/
public class AccountHandler2 {}