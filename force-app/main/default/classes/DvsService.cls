// To test:
// TestInseeDvsService
// TestDiscrepanciesHandling

public with sharing class DvsService {

    // Factory used to get the right DVS service implementation
    private static DvsFactory dvsFactory = new DvsFactory();

    // Update the list of discrepencies for the given accounts.
    // This function:
    // - gets the DVS implemention for the righ country
    // - retrieves the official informations for the given accounts
    // - treats the results in function of the presence of errors and/or discrepencies
    public static void updateDiscrepancies(List<Account> accounts, DvsSetting__mdt dvsSettings, Boolean fuzzySearch) {

        // Get the DVS service implemenation
        DiscrepancyService discrepancyService = dvsFactory.getDvsService(dvsSettings.CountryCode__c); 

        // Retrieve the official information for the given accounts
        DvsResponseDto responseDto = discrepancyService.getOfficialInformation(accounts, dvsSettings, fuzzySearch);

        List<DvsDiscrepancy__c> discrepanciesToUpsert = new List<DvsDiscrepancy__c>();
        List<Account> accountsToUpdate = new List<Account>();
        Integer perfectMatch = 0;
        Integer discrepanciesWithMatch = 0;
        Integer discrepanciesWithoutMatch = 0;

        // Loop through accounts to treat discrepencies
        for (Account account : accounts) {
            if (responseDto.message == null) {
                DvsResponseDto.Company company = responseDto.companiesMap.get(account.Id);
                if (company != null) {
                    // Create the discrependy records if there is a difference between account fields and official informations
                    if (discrepancyService.isInformationDifferent(account, company)) {
                        DvsDiscrepancy__c newDiscrepancy = discrepancyService.createDiscrepancy(account, company);
                        discrepanciesToUpsert.add(newDiscrepancy);
                        // In case of error, fill the account dedicated field
                        if (company.message != null) {
                            String errorMsg = '[' + Datetime.now() + ']' + company.message;
                            account.DvsLongError__c = errorMsg;
                            account.DvsError__c = errorMsg.left(254);
                            account.DvsHasError__c = true;
                            discrepanciesWithoutMatch++;
                        }
                        else {
                            account.DvsLongError__c = '';
                            account.DvsError__c = '';
                            account.DvsHasError__c = false;
                            discrepanciesWithMatch++;
                        }
                    } 
                    // Otherwise, just mark it as 'synchronized'
                    else {
                        account.SynchronizedWithDvs__c = true;
                        account.DvsLongError__c = '';
                        account.DvsError__c = '';
                        account.DvsHasError__c = false;
                        perfectMatch++;
                    }
                    accountsToUpdate.add(account);

                }
            }
            // In case of error, fill the account dedicated field
            else {
                String errorMsg = '[' + Datetime.now() + ']' + responseDto.message;
                account.DvsLongError__c = errorMsg;
                account.DvsError__c = errorMsg.left(254);
                account.DvsHasError__c = true;
                accountsToUpdate.add(account);
            }
        }

        System.debug('Number of perfect matches found: ' + perfectMatch);
        System.debug('Number of discrepancies created with a match: ' + discrepanciesWithMatch);
        System.debug('Number of discrepancies created without a match: ' + discrepanciesWithoutMatch);

        System.debug('number of discrepancies: ' + discrepanciesToUpsert.size());
        Database.UpsertResult[] urList = Database.upsert(discrepanciesToUpsert, false);
        for (Database.UpsertResult ur: urList) {
            if (!ur.isSuccess()) {
                System.debug('An error has occured: ' + ur.getErrors());
            }
        }

        System.debug('number of accounts to update: ' + accountsToUpdate.size());
        Database.SaveResult[] upList = Database.update(accountsToUpdate, false);
        for (Database.SaveResult up: upList) {
            if (!up.isSuccess()) {
                System.debug(up.getId());
                System.debug('An error has occured: ' + up.getErrors());
            }
        }
    }

    /**
     * Performs an action on a list of discrepencies
     * List of actions allowed: CORRECT and IGNORE
     */
    public static void handleDiscrepancies(List<Id> discrependyIds, DvsActions dvsAction) {

        List<DvsDiscrepancy__c> selectedDiscrepancies = getSelectedDiscrepancies(discrependyIds);
        System.debug('Number of discrepancies: ' + selectedDiscrepancies.size());

        List<Id> accountIds = new List<Id>();
        for (DvsDiscrepancy__c selectedDiscrepancy : selectedDiscrepancies) {
            accountIds.add(selectedDiscrepancy.Account__c);
        }
        List<Account> accounts = getAccounts(accountIds);

        // Get discrepancies by corresponding country code
        Map<String, List<DvsDiscrepancy__c>> discrepanciesByCountryCodeMap = getDiscrepanciesByCountryCode(selectedDiscrepancies);
        Set<String> keySet = discrepanciesByCountryCodeMap.keySet();

        List<Account> accountsToUpdate = new List<Account>();

        // Loop through the different countries to perform actions independently
        for (String key : keySet) {

            List<Account> handledAccounts = new List<Account>();
            List<DvsDiscrepancy__c> discrepancies = discrepanciesByCountryCodeMap.get(key);

            DiscrepancyService discrepancyService = dvsFactory.getDvsService(key);

            // Redirect to the right action treatment
            switch on dvsAction {
                when CORRECT {
                    handledAccounts = discrepancyService.correctDiscrepancies(discrepancies, accounts);
                }
                when IGNORE {
                    handledAccounts = discrepancyService.ignoreDiscrepancies(accounts);
                }
                when else {
                    // Action not implemented
                    // Nothing to do
                }
            }
            System.debug(handledAccounts[0]);

            accountsToUpdate.addAll(handledAccounts);
            system.debug(accountsToUpdate.size());
        }
    

        Database.SaveResult[] srList = Database.update(accountsToUpdate, false);
        for (Database.SaveResult sr: srList) {
            if (!sr.isSuccess()) {
                System.debug('An error has occured: ' + sr.getErrors());
            }
        }

        Database.DeleteResult[] dlList = Database.delete(selectedDiscrepancies, false);
        for (Database.DeleteResult dl: dlList) {
            if (!dl.isSuccess()) {
                System.debug('An error has occured: ' + dl.getErrors());
            }
        }
    }

    /**
     * Retrieves the discrepancies from their id.
     */
    private static List<DvsDiscrepancy__c> getSelectedDiscrepancies(List<Id> recordsIds) {
        return [SELECT Id, 
                    DvsName__c,
                    DvsStreet__c,
                    DvsPostalCode__c,
                    DvsCity__c,
                    DvsId__c,
                    DvsId2__c,
                    SalesforceName__c,
                    SalesforceStreet__c,
                    SalesforcePostalCode__c,
                    SalesforceCity__c,
                    SalesforceId__c,
                    SalesforceId2__c,
                    Account__c,
                    SalesforceCountryCode__c
            FROM DvsDiscrepancy__c
            WHERE Id IN :recordsIds
        ];
    }

    /**
     * Retrieves the accounts from their id.
     */
    public static List<Account> getAccounts(List<Id> accountIds) {
        
        return [SELECT Id, 
                    Name, 
                    BillingStreet, 
                    BillingPostalCode, 
                    BillingCity, 
                    VAT_Number__c, 
                    VAT_Number_2__c, 
                    SynchronizedWithDvs__c,
                    DvsAction__c,
                    DvsAcceptedBy__c,
                    DvsAcceptedDate__c,
                    Sap_Id__c
                FROM Account
                WHERE Id IN :accountIds
            ];
    }

    private static DvsSetting__mdt getDVSSettings(String countryCode) {
        return [SELECT Id, 
                        DvsId__c, 
                        DvsSecret__c, 
                        DvsURL__c, 
                        DvsTokenUrl__c,
                        BatchSize__c, 
                        DvsWaitingTime__c,
                        IsActif__c,
                        CountryCode__c
                FROM DvsSetting__mdt
                WHERE IsActif__c = true
                AND CountryCode__c = :countryCode
                LIMIT 1
        ];
    }

    /**
     * For a given country code, returns all the discrepencies for this country
     */
    public static Map<String, List<DvsDiscrepancy__c>> getDiscrepanciesByCountryCode(List<DvsDiscrepancy__c> selectedDiscrepancies) {
        
        Map<String, List<DvsDiscrepancy__c>> discrepanciesByCountryCodeMap = new Map<String, List<DvsDiscrepancy__c>>();
        
        for (DvsDiscrepancy__c discrepancy : selectedDiscrepancies) {
            System.debug('discrepancy CountryCode: ' + discrepancy.SalesforceCountryCode__c);
            List<DvsDiscrepancy__c> discrepancies = discrepanciesByCountryCodeMap.get(discrepancy.SalesforceCountryCode__c);
            if(discrepancies == null) {
                discrepancies = new List<DvsDiscrepancy__c>();
                discrepanciesByCountryCodeMap.put(discrepancy.SalesforceCountryCode__c, discrepancies);
            }
            discrepancies.add(discrepancy);
        }

        return discrepanciesByCountryCodeMap;
    }

    @AuraEnabled (cacheable=true)
    public static CompanyInfosResult getCompanies(CompanyInfosInput input, Boolean fuzzySearch) {
        
        try {

            Account account = getAccount(input.id);
            DvsFactory factory = new DvsFactory();
            DiscrepancyService service = factory.getDvsService(account.BillingCountryCode);
            DvsSetting__mdt settings = getDVSSettings(account.BillingCountryCode);
            
            return service.getCompanies(input, account, settings, fuzzySearch);
        } catch (Exception e) {
            String msg = 'An exception has been raised: ' + e.getMessage();
        } 
        return null;
    }

    @AuraEnabled
    public static UpdateCompanyResult confirmNoResults(Id accountId) {
        Account account = getAccount(accountId);
        DvsFactory factory = new DvsFactory();
        DiscrepancyService service = factory.getDvsService(account.BillingCountryCode);
        UpdateCompanyResult result = service.applyNoResults(account);
        if (result.success) {
            UserAdditionalInfo.setDvsAccountsManaged(UserInfo.getUserId(), accountId);
            if (!isAccounting()) {
                DvsEmails.sendDvsConfirmationRequest(null, account.Id, 'UNKNOWN');
            }
        }
        
        return result;
    }

    @AuraEnabled (cacheable=true)
    public static Account accountDvsData(Id recordId) {
        return getAccount(recordId);
    }

    @AuraEnabled (cacheable=true)
    public static Boolean isAccounting() {
        return (UserCommons.isStandardAccounts(Userinfo.getUserId()) || UserCommons.hasPermissionSet(UserInfo.getUserId(), 'is_accounting'));
    }

    @AuraEnabled (cacheable=true)
    public static Boolean isDvsEnabled(Id recordId) {
        Account acc = new AccountsSelector().selectById(recordId);
        Boolean result = false;

        if (acc.BillingCountryCode != null && acc.BillingCountryCode != '') {
            CountrySettings__c settings = CountrySettings__c.getValues(acc.BillingCountryCode);
            if (settings != null) {
                result =  settings.dataValidation__c;
                // Descomentar al pasar unos dias 27-11-2024
                /*if (isAccounting()) {
                    result =  settings.dataValidation__c;
                } else if (acc.Sap_Id__c == null){
                    result =  settings.dataValidation__c;
                }*/
            }
        }
        return result;
    }

    @AuraEnabled
    public static CompanyInfosResult confirmData(Id accountId) {
        Boolean informUser = false;
        String userToInform = null;
        Boolean sendEmail = false;
        Account account = getAccount(accountId);

        if (account.DvsAction__c == 'DISCARDED' || account.DvsAction__c == 'UNKNOWN') {
            userToInform = account.DvsAcceptedBy__c;
            sendEmail = true;
        }
        account.DvsAction__c = 'CONFIRMED';
        account.DvsAcceptedBy__c = UserInfo.getUserId();
        account.DvsAcceptedDate__c = Datetime.now();
        account.SynchronizedWithDvs__c = true;
        
        //Update sin tener en cuenta duplicados
        update account;

        UserAdditionalInfo.setDvsAccountsManaged(UserInfo.getUserId(), account.Id);

        if (userToInform != UserInfo.getUserId() && sendEmail) {
            DvsEmails.sendDvsConfirmation(accountId, userToInform);
        }

        return new CompanyInfosResult(true, '');
    }

    @AuraEnabled
    public static UpdateCompanyResult applyChanges(Map<String, String> company, Id accountId, Boolean discardChanges) {
        
        Account account = getAccount(accountId);
        DvsFactory factory = new DvsFactory();
        DiscrepancyService service = factory.getDvsService(account.BillingCountryCode);
        UpdateCompanyResult result = service.applyChanges(company, account, discardChanges);
        UserAdditionalInfo.setDvsAccountsManaged(UserInfo.getUserId(), accountId);
        
        if (result.success && discardChanges == true && !Usercommons.isStandardAccounts(UserInfo.getUserId())) {
            DvsEmails.sendDvsConfirmationRequest(company, account.Id, 'DISCARDED');
        }
            
        return result;
    }

    private static Account getAccount(Id accountId) {
        return  [SELECT Id, 
                        Name, 
                        VAT_Number__c, 
                        VAT_Number_2__c, 
                        BillingStreet, 
                        BillingPostalCode, 
                        BillingCity, 
                        BillingCountry,
                        BillingCountryCode,
                        DvsAction__c,
                        DvsAcceptedBy__c,
                        DvsAcceptedDate__c,
                        SynchronizedWithDvs__c,
                        DvsAcceptedBy__r.Name,
                        Sap_Id__c
                FROM Account
                WHERE Id = :accountId];
    }

    @AuraEnabled
    public static CompanyInfosResult getDiscrepancy(Id id, String objectName) {

        Id accountId;
        String countryCode;

        if (objectName == 'Account') {
            Account account = getAccount(id);
            accountId = account.Id;
            countryCode = account.BillingCountryCode;
        }
        else {
            DvsDiscrepancy__c discrepancy = [SELECT Account__c, Account__r.BillingCountryCode FROM DvsDiscrepancy__c WHERE Id = :id];
            accountId = discrepancy.Account__c;
            countryCode = discrepancy.Account__r.BillingCountryCode;
        }
        DvsFactory factory = new DvsFactory();
        DiscrepancyService service = factory.getDvsService(countryCode);
        
        return service.getDiscrepancy(accountId);
    }

    @AuraEnabled(cacheable=true)
    public static String getObjectApiName(Id recordId) {

        System.debug('object name: ' + recordId.getSobjectType());
        return String.valueof(recordId.getSobjectType());
    
    }

    @TestVisible private static String loremIpsum() {
        String s = 'Lorem Ipsum';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        s+= 'Lorem';
        return s;
    }
}