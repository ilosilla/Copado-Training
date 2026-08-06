/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_OrderSelector
     Created Date:      27/01/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Query collection of object Order
------------------------------------------------------------------------------------------*/

public with sharing class NB2B_WebStoreSelector {

    public static WebStore getWebStore(){
        return [
            SELECT Id, Name 
            FROM WebStore 
            WHERE Name =: Nb2b_GlobalConstants.WEBSTORE_UK LIMIT 1
        ];
    }

}