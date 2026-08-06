/**
    * Type: Apex  class
    * Name: NBK_RefreshIndex
    * @author: Adrián Petit
    * Company: Nubika S.L.
    * Date: 04/08/2023
    * @description Class with all the refresh index operations
    * @version 1.0
*/
public with sharing class NBK_RefreshIndex {
    
        /**
         * @description launch the refresh index search operation
         * @param storeId contains the store ID
         */ 
        public static void refreshIndex(String storeId){
            try {
                if (storeId!= null && storeId != '') {
                    ConnectApi.CommerceSearchSettings.createCommerceSearchIndex(storeId);
                }
            } catch (Exception e) {
                //Nbk_ErrorsManager.addError(e, NBK_CaseHandlerTrigger.class.getName(), Nbk_ErrorsManager.Causante.INTEGRACION, true);
                //Nbk_ErrorsManager.flush();
                System.debug('NBK_RefreshIndex Exception:' + e);
            }
        }
    }