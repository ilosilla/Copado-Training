public class ContactsUtil {
    
    /**
     * Obtiene el objeto cuenta de un person account por el identificador de la cuenta
     * 
     * @author mario.navarro@seidor.com
     * @date fecha 18/12/2023
     * @param accountId identificador de la cuenta del que obtener el contacto
     * @return el contacto encontrado (o un contacto vacio si no se ha encontrado)
     */
    @AuraEnabled(cacheable=true)
    public static Contact selectPersonAccountContactByAccountId(Id accountId){
        Contact cnt;
        List<Contact> foundContacts = new ContactsSelector().selectByAccountId(new Set<Id>{accountId});
        if (!foundContacts.isEmpty()) {
            cnt = foundContacts.get(0);
        }
        return cnt;
    }

}