/**
* @author 			Ramón Prades
* @date 			February-2021
* @group 			Accounts
* @group-content 	../../ApexDocContent/Accounts.htm
* @description 	    Methods to find an account
*/
public with sharing class AccountFinder {

    public static Id getPersonAccountFromEmail(String email) {
        Id accountId = null;
        if (String.isNotBlank(email)) {
            Account[] accounts = [select id from Account where PersonEmail = :email];
            if (accounts.size() > 0) {
                accountId = accounts[0].Id;
            } 
        } 
        return accountId;
    } // getPersonAccountFromEmail

    public static Id getTradeAccountFromEmail(String email) {
        Id accountId = null;
        if (String.isNotBlank(email)) {
            Account[] accounts = [select id from Account where Business_Email__c = :email];
            if (accounts.size() > 0) {
                accountId = accounts[0].Id;
            } 
        } 
        return accountId;
    } // getTradeAccountFromEmail

} // class AccountFinder