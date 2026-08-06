/**
 * Author: Ivan Losilla Perez
 * July 2020
 */
@isTest
public class OwnerAssignatorTest {
    @isTest
    static void getInstance() {      
      AbstractOwnerAssignator aux = OwnerAssignator.getInstance('ACCOUNT');
      System.assert(aux != null, 'Todo bien');
      ExecutionContext contxt= new ExecutionContext('DEFAULT');
      aux = OwnerAssignator.getInstance('ACCOUNT', contxt);
      System.assert(aux != null, 'Todo bien');      
    }
} //class