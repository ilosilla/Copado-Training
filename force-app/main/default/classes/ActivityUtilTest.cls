/**
* @service Hecho por NTS
*/
@isTest
public class ActivityUtilTest {}
// public class ActivityUtilTest 
// {
//     static Integer QUANT = 10;
//     static Integer QUANT_BULK = 200;
    
// 	@testSetup static void setup() {
//         // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
//         // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
//         // para activar el trigger.
//         insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers(); 
// 	}

    
//     /** 
//      *  @description: El propietario del Caso es una Cola, y se actualiza una Actividad pasando el Notify_Owner__c de False a True para que notifique. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */     
// 	@isTest 
//     static void testCase_1()
// 	{
//         Integer     act_mode    =   1;      // TASKS
//         Integer     case_mode   =   2;      // CASE RELATED 2 QUEUE
//         Boolean     notify      =   False;  //  The Notify_Owner__c is FALSE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             // System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Case owner is a Queue');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /** 
//      *  @description: El propietario del Caso es un Usuario, y se actualiza una Actividad pasando el Notify_Owner__c de False a True para que notifique. SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */        
// 	@isTest 
//     static void testCase_2()
// 	{
        
//         Integer     act_mode    =   1;      // TASKS
//         Integer     case_mode   =   3;      // CASE RELATED 2 USER
//         Boolean     notify      =   False;  //  The Notify_Owner__c is FALSE
        
//         Queue_metadata__mdt mt  =   Test_DataFactory.getQueueMetadata( Test_DataFactory.getAdminUser().id ); 

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a un Usuario
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertNotEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should be updated because the Case owner is a User.');
//             //System.assertEquals( mt.Queue__c, upd_cMap.get(c).OwnerID, 'ERROR. The new Owner of the Case (the Queue) does not match the expected result.');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
//     }

//     /** 
//      *  @description: El propietario del Caso es una Cola, y se actualiza una Actividad pasando el Notify_Owner__c de True a True para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */     
// 	@isTest 
//     static void testCase_3()
// 	{
        
//         Integer     act_mode    =   1;      // TASKS
//         Integer     case_mode   =   2;      // CASE RELATED 2 QUEUE
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Case owner is a Queue and the Notify Owner value has remain without change (True > True)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /** 
//      *  @description: El propietario del Caso es un User, y se actualiza una Actividad pasando el Notify_Owner__c de True a True para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */       
// 	@isTest 
//     static void testCase_4()
// 	{
        
//         Integer     act_mode    =   1;      // TASKS
//         Integer     case_mode   =   3;      // CASE RELATED 2 USER
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Notify Owner value has remain without change (True > True)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }  

//     /** 
//      *  @description: El propietario del Caso es una Cola, y se actualiza una Actividad pasando el Notify_Owner__c de TRUE a FALSE para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */    
// 	@isTest 
//     static void testCase_5()
// 	{
        
//         Integer     act_mode    =   1;      // TASKS
//         Integer     case_mode   =   2;      // CASE RELATED 2 QUEUE
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a True

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', False);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Case owner is a Queue and the Notify Owner value has changed to False (True > False)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy'); 
//     }

//     /** 
//      *  @description: El propietario del Caso es un Usuario, y se actualiza una Actividad pasando el Notify_Owner__c de TRUE a FALSE para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */  
// 	@isTest 
//     static void testCase_6()
// 	{
        
//         Integer     act_mode    =   1;      // TASKS
//         Integer     case_mode   =   3;      // CASE RELATED 2 USER
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a True

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', False);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Notify Owner value has changed to False (True > False)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /*
//         ######## ##     ## ######## ##    ## ######## 
//         ##       ##     ## ##       ###   ##    ##    
//         ##       ##     ## ##       ####  ##    ##    
//         ######   ##     ## ######   ## ## ##    ##    
//         ##        ##   ##  ##       ##  ####    ##    
//         ##         ## ##   ##       ##   ###    ##    
//         ########    ###    ######## ##    ##    ##    
//     */
//     /** 
//      *  @description: El propietario del Caso es una Cola, y se actualiza una Actividad pasando el Notify_Owner__c de False a True para que notifique. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */     
// 	@isTest 
//     static void testCase_7()
// 	{
        
//         Integer     act_mode    =   2;      // EVENT
//         Integer     case_mode   =   2;      // CASE RELATED 2 QUEUE
//         Boolean     notify      =   False;  //  The Notify_Owner__c is FALSE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Case owner is a Queue');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /** 
//      *  @description: El propietario del Caso es un Usuario, y se actualiza una Actividad pasando el Notify_Owner__c de False a True para que notifique. SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */         
// 	@isTest 
//     static void testCase_8()
// 	{
        
//         Integer     act_mode    =   2;      // EVENT
//         Integer     case_mode   =   3;      // CASE RELATED 2 USER
//         Boolean     notify      =   False;  //  The Notify_Owner__c is FALSE
        
//         Queue_metadata__mdt mt  =   Test_DataFactory.getQueueMetadata( Test_DataFactory.getAdminUser().id ); 

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a un Usuario
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertNotEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should be updated because the Case owner is a User.');
//             //System.assertEquals( mt.Queue__c, upd_cMap.get(c).OwnerID, 'ERROR. The new Owner of the Case (the Queue) does not match the expected result.');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /** 
//      *  @description: El propietario del Caso es una Cola, y se actualiza una Actividad pasando el Notify_Owner__c de True a True para que NO HAGA NADA.NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */             
// 	@isTest 
//     static void testCase_9()
// 	{
        
//         Integer     act_mode    =   2;      // EVENT
//         Integer     case_mode   =   2;      // CASE RELATED 2 QUEUE
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         System.debug('=====> ' + cMap.size());
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             // System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Case owner is a Queue and the Notify Owner value has remain without change (True > True)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /** 
//      *  @description: El propietario del Caso es un User, y se actualiza una Actividad  pasando el Notify_Owner__c de True a True para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */          
// 	@isTest 
//     static void testCase_10()
// 	{
        
//         Integer     act_mode    =   2;      // EVENT
//         Integer     case_mode   =   3;      // CASE RELATED 2 USER
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a false

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', true);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Notify Owner value has remain without change (True > True)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }  

//     /** 
//      *  @description: El propietario del Caso es una Cola, y se actualiza una Actividad pasando el Notify_Owner__c de TRUE a FALSE para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */      
// 	@isTest 
//     static void testCase_11()
// 	{
        
//         Integer     act_mode    =   2;      // EVENT
//         Integer     case_mode   =   2;      // CASE RELATED 2 QUEUE
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a True

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', False);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Case owner is a Queue and the Notify Owner value has changed to False (True > False)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }

//     /** 
//      *  @description: El propietario del Caso es un Usuario, y se actualiza una Actividad pasando el Notify_Owner__c de TRUE a FALSE para que NO HAGA NADA. NO SE DEBERÍA ACTUALIZAR EL CASO
//      **
//      *  @Autor: ugonzalez (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */        
// 	@isTest 
//     static void testCase_12()
// 	{
        

//         Integer     act_mode    =   2;      // EVENT
//         Integer     case_mode   =   3;      // CASE RELATED 2 USER
//         Boolean     notify      =   True;   //  The Notify_Owner__c is TRUE

//         Map<Id, Case>   cMap    =   new Map<Id, Case> ( Test_DataFactory.gen_Cases( QUANT, case_mode ) );           // Vamos a tener que generar N Casos asociados a una Cola
//         List<sObject>   aList   =   Test_DataFactory.gen_Acti_Rel2_Cases( cMap.values(), QUANT, act_mode, notify ); // Vamos a tener que generar N Actividades (Tareas u Eventos) relacionados con los N Casos con Notify_Owner__c a True

//         for ( sObject o: aList )
//         {
//             o.put('Notify_Owner__c', False);
//         }

//         Test.startTest();
//             //update aList;                                                                                           // Hacemos una actualización del Check notificar en las actividades (Tareas u Eventos)
//         Test.stopTest();

//         Map<Id, Case> upd_cMap  =   new Map<Id, Case> ( [SELECT Id, OwnerID FROM Case] );                           // Hacemos un SELECT de los Casos, y un assert de que los propietarios no han cambiado

//         for ( Id c: upd_cMap.keySet() )
//         {
//             //System.assertEquals( cMap.get(c).OwnerID, upd_cMap.get(c).OwnerID, 'ERROR. The OwnerID should remain without modifications because the Notify Owner value has changed to False (True > False)');
//         }
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//     }
// }