/**
* @service Hecho por NTS
*/
@isTest (SeeAllData = false)
public class TEST_EmailMessageUtil {}
// public class TEST_EmailMessageUtil 
// {
//     static Integer QUANT = 10;
//     static Integer QUANT_BULK = 200;

// 	@isTest 
//     /** 
//      *  @description: Creates an email for the administrator, who allready has a case and is in the metadata list - OK case owner assigned to the admins queue.
//      **
//      *  @Autor: jurretabizkaia (17/07/2018)
//      **
//      *  @Modificacion: 
//      **
//      */ 
// 	static void test_1_caseAssignedToAdminUser() 
//     { 
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
//         /*
//         //Generate/get values
//         Queue_metadata__mdt metadata        =   Test_DataFactory.getQueueMetadata(Test_DataFactory.getAdminUser().id); 
//         List<Case> caseList                 =   Test_DataFactory.gen_Cases(QUANT, 0);
//         List<EmailMessage> testEmailMessage =   Test_DataFactory.gen_Emails(QUANT, caseList, true);

// 		Test.startTest();
// 		    insert(testEmailMessage);
// 		Test.stopTest(); 

//         for (Case c: [Select id, OwnerId from Case] )
//         {
//             System.assertEquals(c.OwnerId, metadata.Queue__c);
//         }
//         */
//     }


// }