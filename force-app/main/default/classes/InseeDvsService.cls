/**
 * Implementation of DVS service for FRANCE
 * Class in charge of communicating with the Siren API
 */
public with sharing class InseeDvsService extends DiscrepancyService {

    /** HTTP request timeout */
    private static final Integer REQUEST_TIMEOUT = 60000;

    /** Relative URLs */
    public static final String SIRET_RELATIVE_URL = '/siret'; 

    /** Attribute names for search by request */
    public static final String NAME_PARAM = 'raisonSociale';
    public static final String LASTNAME_PARAM = 'nomUniteLegale';
    public static final String USUALLASTNAME_PARAM = 'nomUsageUniteLegale';
    public static final String FIRSTNAME_PARAM = 'prenom1UniteLegale';
    public static final String SIREN_PARAM = 'siren';
    public static final String POSTAL_CODE_PARAM = 'codePostalEtablissement';
    public static final String CITY_PARAM = 'libelleCommuneEtablissement';
    public static final String QUERY_PARAM = 'q';
    public static final String NOMBRE_PARAM = 'nombre';
    public static final String DEBUT_PARAM = 'debut';

    public static final String DEFAULT_ERROR_MSG = Label.dvs_no_company_found;

    @testVisible
    private static Integer pageSize = 1000;


    /**
     * Special character treatments
     */
    private static Map<String, String> accentsReplacementMap = new Map<String, String> {
        'É' => 'E',
        'È' => 'E',
        'Ê' => 'E',
        'Ë' => 'E',
        'À' => 'A',
        'Â' => 'A',
        'Ä' => 'A',
        'Ô' => 'O',
        'Ö' => 'O',
        'Û' => 'U',
        'Ù' => 'U',
        'Ï' => 'I',
        'Î' => 'I',
        'Ç' => 'C'
    };

    private Pattern accentsPattern = Pattern.compile('[' + String.join(accentsReplacementMap.keySet(), '') + ']');

    /**
     * List of possible French legal statuses
     */
    private static List<String> legalStatuses = new List<String>{'SARL', 'EURL', 'SAS', 'SASU', 'SCI', 'SCM', 'SOCIETE', 'ENTREPRISE', 'AGENCE'};

    /**
     * New request squeleton
     */
    private static HttpRequest newRequest(String method) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json' );
        request.setTimeout(REQUEST_TIMEOUT);
        request.setMethod(method);

        return request;
    }

    /**
     * Get token for client id and secret
     */
    /*private static String getToken(DvsSetting__mdt dvsSettings) {

        String clientId = dvsSettings.DvsId__c;
        String clientSecret = dvsSettings.DvsSecret__c;
        
        Http http = new Http();
        HttpRequest request = newRequest('POST');

        Blob authBlob = Blob.valueOf(clientId + ':' + clientSecret);
        String auth = EncodingUtil.base64Encode(authBlob);
        request.setHeader('Authorization', 'Basic ' + auth); //used to provide credentials that authenticate a user agent with a server

        request.setEndpoint(dvsSettings.DvsTokenUrl__c);

        HttpResponse res = http.send(request);

        System.debug('Login status code: ' + res.getStatusCode());
        Integer status = res.getStatusCode();
        String msg = '';
        if (status == 200) {
            
            // In case of success then return the object id
            SireneTokenResult sireneToken = (SireneTokenResult) JSON.deserialize(res.getBody(), SireneTokenResult.class);
            
            // Return the deserialize object
            return sireneToken.access_token;
        } else if (status == 401) {
            msg = 'Authentication to INSEE\'s Sirene api failed. Please check your credentials';
        } else if (status == 403) {
            msg = 'You\'re not authorized to access the INSEE\'s Sirene API.';
        } else {
            msg = 'Authentication to INSEE\'s Sirene api failed: [' + status + '] ' + res.getBody();
        }

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(new List<String>{'salesforce@porcelanosagrupo.com'});
        m.setSubject('DVS API ERROR');
        m.setHtml(Label.error_dvs_message + msg);
        m.send();

        throw new DvsException(msg);
    }*/

    /**
     * From a list of accounts and a DVS configuration, retrieves the company official information call the API
     */
    public override DvsResponseDto getOfficialInformation(List<Account> accounts, DvsSetting__mdt dvsSettings, Boolean fuzzySearch) {
        Map<Id, DvsResponseDto.Company> responseDtoMap = new Map<Id, DvsResponseDto.Company>();
        DvsResponseDto responseDto = new DvsResponseDto();
           
        try {
            // Retrieve a valid token
            /*String token = getToken(dvsSettings);

            Http http = new Http();
            HttpRequest request = newRequest('POST');
            request.setHeader('Authorization', 'Bearer ' + token);*/

            //String token = getToken(settings);
            String token = dvsSettings.DvsId__c;

            Http http = new Http();
            HttpRequest request = newRequest('POST');
            request.setHeader('X-INSEE-Api-Key-Integration', token);

            String baseUrl = dvsSettings.DvsUrl__c;
            String url = baseUrl + SIRET_RELATIVE_URL;
            request.setEndpoint(url);

            // We want to devide the accounts in 2 groups:
            // - The first group is for the company lookup by siret
            // - The second group is for the company name lookup
            //
            // The reason is that siret lookup is more accurate than name lookup.

            List<Account> searchBySiretAccounts = new List<Account>();
            List<Account> searchBySirenAccounts = new List<Account>();
            List<Account> searchByNameAccounts = new List<Account>();

            // Building the query
            String query = '';
            for (Account account: accounts) {
                if (account.VAT_Number__c != null) {
                    // Remove white spaces from the siret number because Siren api doesn't handle it and the request will fail.
                    String siretNumber = formatExternalId(account.VAT_Number__c);
                    query += 'siret:' + siretNumber + ' OR ';
                    searchBySiretAccounts.add(account);
                }
                else if (account.VAT_Number_2__c != null) {
                    // Remove white spaces from the siren number because Siren api doesn't handle it and the request will fail.
                    String sirenNumber = formatExternalId(account.VAT_Number_2__c);
                    query += 'siren:' + sirenNumber + ' OR ';
                    searchBySirenAccounts.add(account);
                }
                else {
                    // Remove '"' because this character is not handled by Siren api and the request will fail. 
                    // Also remove '.' from words like 'S.A.R.L' or 'S.C.I'.
                    if (account.BillingPostalCode != null) {
                        String accountName = removeCharacterFromAccountName(account.Name);
                        if (fuzzySearch) {
                            accountName = removeCityName(accountName, account.BillingCity);
                        } 
                        LevenshteinParameters ld = defineLevenshteinParameters(accountName);
                        String lastName1;
                        String lastName2;
                        String firstName1;
                        String firstName2;
                        if (ld.nameWordsNumber == 2) {
                            lastName1 = removeCharacterFromAccountName(ld.nameWords[0]);
                            firstName1 = removeCharacterFromAccountName(ld.nameWords[1]);
                            lastName2 = firstName1;
                            firstName2 = lastName1;
                        }
                        else if (ld.nameWordsNumber == 3) {
                            String str1 = removeCharacterFromAccountName(ld.nameWords[1]);
                            firstName1 = removeCharacterFromAccountName(ld.nameWords[2]);
                            firstName2 = removeCharacterFromAccountName(ld.nameWords[0]);
                            lastName1 = firstName2 + ' ' + str1;
                            lastName2 = str1 + ' ' + firstName1;
                        }
                        if (fuzzySearch) {
                            // Split the account name in words to define the Levenshtein distance to apply
                            // 1 word : levenshtein distance = 2. Ex: 'FNAC' can return 'TRAC', 'FLAT', 'UNIC'...
                            // 2 or more : levenshtein distance = number of words. Ex : 'House of Dragons' can return 'Dragons of the house', 'of Dragons house'...
                            if (ld.nameWordsNumber == 1) { 
                                query += '(' + NAME_PARAM + ':*' + accountName + '*~' + ld.levenshteinDistance + ' AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity +'")) OR '; 
                            }
                            // else if (ld.nameWordsNumber == 2 || ld.nameWordsNumber == 3) {
                            //     query += '((' + NAME_PARAM + ':*' + accountName + ' OR ' + '(' + LASTNAME_PARAM + ':"' + lastName1 + '"~2 AND ' + FIRSTNAME_PARAM + ':"' + firstName1 + '"~2) OR ' + '(' + LASTNAME_PARAM + ':"' + lastName2 + '"~2 AND ' + FIRSTNAME_PARAM + ':"' + firstName2 + '"~2)) AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':' + account.BillingCity +')) OR ';
                            // }
                            else if (ld.nameWordsNumber == 2 || ld.nameWordsNumber == 3) {
                                query += '((' + NAME_PARAM + ':"' + accountName + '"~' + ld.levenshteinDistance + ' OR ' + '(' + LASTNAME_PARAM + ':"' + lastName1 + '" AND ' + FIRSTNAME_PARAM + ':"' + firstName1 + '") OR ' + '(' + LASTNAME_PARAM + ':"' + lastName2 + '" AND ' + FIRSTNAME_PARAM + ':"' + firstName2 + '")) AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity +'")) OR '; 
                            }
                            else {
                                query += '(' + NAME_PARAM + ':"' + accountName + '"~' + ld.levenshteinDistance + ' AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity + '")) OR '; 
                            }
                            
                        }
                        else {
                            if (ld.nameWordsNumber == 2 || ld.nameWordsNumber == 3) {
                                query += '((' + NAME_PARAM + ':"*' + accountName + '*" OR ' + '(' + LASTNAME_PARAM + ':"' + lastName1 + '" AND ' + FIRSTNAME_PARAM + ':"' + firstName1 + '") OR ' + '(' + LASTNAME_PARAM + ':"' + lastName2 + '" AND ' + FIRSTNAME_PARAM + ':"' + firstName2 + '")) AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity +'")) OR ';
                            }
                            else {
                                query += '(' + NAME_PARAM + ':"*' + accountName + '*" AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity +'")) OR '; 
                            }
                        }
                        // If the account name contains the following substrings, it can prevent the Siren api from finding a match, 
                        // so we remove them, this way the request might be more accurate.
                        String cleanedName = cleanAccountName(accountName);
                        if(cleanedName != accountName) {
                            ld = defineLevenshteinParameters(cleanedName);
                            if (ld.nameWordsNumber == 2) {
                                lastName1 = removeCharacterFromAccountName(ld.nameWords[0]);
                                firstName1 = removeCharacterFromAccountName(ld.nameWords[1]);
                                lastName2 = firstName1;
                                firstName2 = lastName2;
                            }
                            else if (ld.nameWordsNumber == 3) {
                                String str1 = removeCharacterFromAccountName(ld.nameWords[1]);
                                firstName1 = removeCharacterFromAccountName(ld.nameWords[2]);
                                firstName2 = removeCharacterFromAccountName(ld.nameWords[0]);
                                lastName1 = firstName2 + ' ' + str1;
                                lastName2 = str1 + ' ' + firstName1;
                            }
                            if (fuzzySearch) {

                                if (ld.nameWordsNumber == 1) {
                                    query += '(' + NAME_PARAM + ':*' + cleanedName + '*~' + ld.levenshteinDistance + ' AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity +'")) OR '; 
                                }
                                // else if (ld.nameWordsNumber == 2 || ld.nameWordsNumber == 3) {
                                //     query += '((' + NAME_PARAM + ':*' + cleanedName + ' OR ' + '(' + LASTNAME_PARAM + ':"' + lastName1 + '"~2 AND ' + FIRSTNAME_PARAM + ':"' + firstName1 + '"~2) OR ' + '(' + LASTNAME_PARAM + ':"' + lastName2 + '"~2 AND ' + FIRSTNAME_PARAM + ':"' + firstName2 + '"~2)) AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':' + account.BillingCity +')) OR ';
                                // }
                                else if (ld.nameWordsNumber == 2 || ld.nameWordsNumber == 3) {
                                    query += '((' + NAME_PARAM + ':"' + cleanedName + '"~' + ld.levenshteinDistance + ' OR ' + '(' + LASTNAME_PARAM + ':"' + lastName1 + '"~2 AND ' + FIRSTNAME_PARAM + ':"' + firstName1 + '"~2) OR ' + '(' + LASTNAME_PARAM + ':"' + lastName2 + '"~2 AND ' + FIRSTNAME_PARAM + ':"' + firstName2 + '"~2)) AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity +'")) OR '; 
                                }
                                else {
                                    query += '(' + NAME_PARAM + ':"' + cleanedName + '"~' + ld.levenshteinDistance + ' AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity + '")) OR '; 

                                }

                            }
                            else {
                                if (ld.nameWordsNumber == 2 || ld.nameWordsNumber == 3) {
                                    query += '((' + NAME_PARAM + ':"*' + cleanedName + '*" OR (' + LASTNAME_PARAM + ':"' + lastName1 + '" AND ' + FIRSTNAME_PARAM + ':"' + firstName1 + '") OR (' + LASTNAME_PARAM + ':"' + lastName2 + '" AND ' + FIRSTNAME_PARAM + ':"' + firstName2 + '")) AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity + '")) OR ';
                                }
                                else {
                                    query += '(' + NAME_PARAM + ':"*' + cleanedName + '*" AND (' + POSTAL_CODE_PARAM + ':' + account.BillingPostalCode + ' OR ' + CITY_PARAM + ':"' + account.BillingCity + '")) OR '; 
                                }
                            }
                        }
                        searchByNameAccounts.add(account);
                    }
                }
            }
            query = query.removeEnd(' OR ');

            Map<String, Etablissement> companiesBySiretMap = new Map<String, Etablissement>();
            Map<String, List<Etablissement>> companiesBySirenMap = new Map<String, List<Etablissement>>();
            Map<String, List<Etablissement>> companiesByPostalCodeMap = new Map<String, List<Etablissement>>();
            Map<String, List<Etablissement>> companiesByCityMap = new Map<String, List<Etablissement>>();

            Integer total = null;
            Integer debut = 0;
            Integer page = 1;
            while ((total == null || debut < total) && responseDto.message == null) {
                Map<String, String> requestBodyMap = new Map<String, String>();
                
                requestBodyMap.put(QUERY_PARAM, query);
                requestBodyMap.put(NOMBRE_PARAM, String.valueOf(pageSize));
                requestBodyMap.put(DEBUT_PARAM, String.valueOf(debut));
                
                String requestBodyEncoded = encodeRequestBody(requestBodyMap);
                
                request.setBody(requestBodyEncoded);
                HttpResponse res = http.send(request);

                Integer status = res.getStatusCode();
                System.debug(LoggingLevel.INFO, 'INSEE API returned status code: ' + status);

                if (status == 200) {
                    System.debug('res body = ' + res.getBody());
                    SiretInfos siretInfos = (SiretInfos) JSON.deserialize(res.getBody(), SiretInfos.class);
                    
                    /* Fill in 5 maps with the info retrieved from INSEE
                    ** 1 with all companies sorted by siret
                    ** 1 with all campanies sorted by siren
                    ** 1 with all companies sorted by postalCode
                    ** 1 with all companies sorted by city
                    */
                    for (Etablissement company : siretInfos.etablissements) {
                        Etablissement comp = companiesBySiretMap.get(company.siret);
                        if (comp == null) {
                            companiesBySiretMap.put(company.siret, company);
                        }
                        else {
                            System.debug('At least two companies with the siret number ' + company.siret + ' have been found.');
                        }

                        List<Etablissement> sirenCompList = companiesBySirenMap.get(company.siren);
                        if (sirenCompList == null) {
                            sirenCompList = new List<Etablissement>();
                            companiesBySirenMap.put(company.siren, sirenCompList);
                        }
                        sirenCompList.add(company);

                        List<Etablissement> compList = companiesByPostalCodeMap.get(company.adresseEtablissement.codePostalEtablissement);
                        if (compList == null) {
                            compList = new List<Etablissement>();
                            companiesByPostalCodeMap.put(company.adresseEtablissement.codePostalEtablissement, compList);
                        }
                        compList.add(company);

                        List<Etablissement> cityCompList = companiesByCityMap.get(company.adresseEtablissement.libelleCommuneEtablissement);
                        if (cityCompList == null) {
                            cityCompList = new List<Etablissement>();
                            companiesByCityMap.put(company.adresseEtablissement.libelleCommuneEtablissement.toUpperCase(), cityCompList);
                        }
                        cityCompList.add(company);
                    }
                    total = SiretInfos.Header.total;
                    debut += SiretInfos.Header.nombre;
                    System.debug('total results: ' + total);
                    System.debug('page ' + page + '/' + total/pageSize);
                    page++;
                }
                else if (status == 400) {
                    try {
                        SiretInfos siretInfos = (SiretInfos) JSON.deserialize(res.getBody(), SiretInfos.class);
                        String msg = siretInfos.header.message;
                        responseDto.message = 'Bad request: ' + msg;
                    }
                    catch (Exception e) {
                        responseDto.message = 'Bad request: ' + res.getBody();
                    }
                } 
                else if (status == 401) {
                    String msg = 'Invalid Credentials. Make sure you have given the correct access token.';
                    responseDto.message = msg;
                } 
                else if (status == 404) {   
                    String msg = 'No company was found with the criteria you specified.';
                    responseDto.message = msg;
                } 
                else if (status == 500) {   
                    String msg = 'Error with the service. Contact an admin.';
                    responseDto.message = msg;
                } 
                else {
                    String msg = 'Search for companies matching the search criteria has failed: [' + status + '].';
                    responseDto.message = msg;
                }
                System.debug('responseDTO.message: ' + responseDto.message);
            }

            // Check if there is a match with the account's siret number
            if (responseDto.message == null) {
                for (Account account : searchBySiretAccounts) {
                    System.debug(account.Id);
                    String siretNumber = formatExternalId(account.VAT_Number__c);
                    DvsResponseDto.Company companyResponseDto = new DvsResponseDto.Company();
                    Etablissement company = companiesBySiretMap.get(siretNumber);
                    if (company != null) {
                        String companyName = getCompanyName(company);
                        companyResponseDto = createResponseDto(company, companyName);
                    }
                    else {
                        String notFoundMsg = 'No company with the siret ' + siretNumber + ' has been found.';
                        System.debug(notFoundMsg);
                        companyResponseDto.message = notFoundMsg;
                    }
                    responseDtoMap.put(account.Id, companyResponseDto);

                }

                // Check if there is a match with the account's siren number
                for (Account account : searchBySirenAccounts) {
                    System.debug(account.Id);
                    String sirenNumber = formatExternalId(account.VAT_Number_2__c);
                    DvsResponseDto.Company companyResponseDto = new DvsResponseDto.Company();
                    List<Etablissement> companies = companiesBySirenMap.get(sirenNumber);
                    Etablissement company;
                    String companyName;
                    if (companies != null && companies.size() == 1) {
                        company = companies[0];
                        companyName = getCompanyName(company);
                        companyResponseDto = createResponseDto(company, companyName);
                    }
                    else if (companies != null && companies.size() > 1) {
                        for (Etablissement comp : companies) {
                            if (comp.adresseEtablissement.codePostalEtablissement == account.BillingPostalCode && comp.uniteLegale.etatAdministratifUniteLegale == 'A') {
                                company = comp;
                                companyName = getCompanyName(company);
                                companyResponseDto = createResponseDto(company, companyName);
                                System.debug(companyResponseDto);
                                break;
                            }
                        }

                        for (Etablissement comp : companies) {
                            String cleanedStreetSF = removeAccents(account.BillingStreet.toUpperCase());
                            cleanedStreetSF = cleanAccountName(cleanedStreetSF);
                            cleanedStreetSF = removeCharacterFromAccountName(cleanedStreetSF);
                            System.debug('STEET DVS');
                            System.debug(comp.adresseEtablissement);
                            String cleanedStreetDVS = comp.adresseEtablissement.libelleVoieEtablissement;
                            List<String> streetParts = cleanedStreetSF.split(' ');
                            Boolean streetPartEquals = false;

                            for (String part: streetParts) {
                                if (part.length() > 3 && cleanedStreetDVS.contains(part)) {
                                    streetPartEquals = true;
                                }
                            }

                            if (comp.adresseEtablissement.codePostalEtablissement == account.BillingPostalCode && streetPartEquals == true) {
                                company = comp;
                                companyName = getCompanyName(company);
                                companyResponseDto = createResponseDto(company, companyName);
                                System.debug(companyResponseDto);
                                break;
                            }

                            if (comp.adresseEtablissement.codePostalEtablissement.substring(0,2) == account.BillingPostalCode.substring(0,2) && streetPartEquals == true) {
                                company = comp;
                                companyName = getCompanyName(company);
                                companyResponseDto = createResponseDto(company, companyName);
                                System.debug(companyResponseDto);
                                break;
                            }
                        }

                        if (!companyResponseDto.success) {
                            String notFoundMsg = 'No company with the siren ' + sirenNumber + ' has been selected from multiple options.';
                            System.debug(notFoundMsg);
                            companyResponseDto.message = notFoundMsg; 
                        }
                    }
                    else {
                        String notFoundMsg = 'No company with the siren ' + sirenNumber + ' has been found.';
                        System.debug(notFoundMsg);
                        companyResponseDto.message = notFoundMsg; 
                    }
                    responseDtoMap.put(account.Id, companyResponseDto);
                    if (!Test.isRunningTest()) {
                    	responseDto.companiesMap = responseDtoMap;
                    	return responseDto;
                    }
                }
                
                // Check if there is a match with the account's name and postalCode
                for (Account account : searchByNameAccounts) {
                    DvsResponseDto.Company companyResponseDto = new DvsResponseDto.Company();
                    
                    String accountName = removeCharacterFromAccountName(account.Name).toUpperCase();
                    
                    if (fuzzySearch) {
                        accountName = removeCityName(accountName, account.BillingCity);
                    }
                    // Replace all accents with their corresponding characters because Siren api return the company's name without accent
                    Matcher matcher = accentsPattern.matcher(accountName);
                    if (matcher.find()) {
                        accountName = removeAccents(accountName);
                    }

                    System.debug('accountName: ' + accountName + '/' + 'account Postal code: ' + account.BillingPostalCode);
                    
                    List<Etablissement> companies = companiesByPostalCodeMap.get(account.BillingPostalCode);
                    if (companies != null) {
                        companyResponseDto = containsCompany(accountName, companies, false);
                        if (fuzzySearch && !companyResponseDto.success) {
                            companyResponseDto = containsCompany(accountName, companies, true);
                        }
                    }
                    if (!companyResponseDto.success) {
                        List<Etablissement> companiesByCity = companiesByCityMap.get(account.Billingcity.toUpperCase());
                        if (companiesByCity != null) {
                            companyResponseDto = containsCompany(accountName, companiesByCity, false);
                            if (fuzzySearch && !companyResponseDto.success) {
                                companyResponseDto = containsCompany(accountName, companiesByCity, true);
                            }
                        }
                    }
                    if (!companyResponseDto.success) {
                        String notFoundMsg = 'No company with the name ' + account.Name + ' and postal code ' + account.BillingPostalCode + ' has been found.';
                        System.debug(notFoundMsg);
                        companyResponseDto.message = notFoundMsg;
                    }
                    responseDtoMap.put(account.Id, companyResponseDto);
                }
                responseDto.companiesMap = responseDtoMap;
            }
        } catch (Exception e) {
            String msg = e.getMessage();
            responseDto.message = 'EXCEPTION: ' + msg;
            return responseDto;
        }

        return responseDto;
    }

    private DvsResponseDto.Company containsCompany(String accountName, List<Etablissement> companies, Boolean fuzzy) {
        Integer companiesSize = companies.size();

        // First matching company, active or inactive.
        // This variable is used to store the first found inactive company waiting to see if there is an active company found later.
        // If a inactive company is found but no active company is found later, the first inactive company is returned
        DvsResponseDto.Company firstMatchingCompany = null;
        for (Etablissement company : companies) {
            /** 
             * Look at the company only if no matching company has already been found or if the company is active
             */
            if (firstMatchingCompany == null || !firstMatchingCompany.active) {
                // First, check if there is a matching result with the original account Name
                // Then, check again after having removed substrings like SARL,SAS,SCI or characters like '-' from the account name.
                DvsResponseDto.Company companyResponseDto = getMatchingCompany(company, accountName, fuzzy);
                if (!companyResponseDto.success) {
                    String modifiedAccountName = cleanAccountName(accountName);
                    if (modifiedAccountName != accountName) {
                        companyResponseDto = getMatchingCompany(company, modifiedAccountName, fuzzy);
                    }
                }
                
                // If there is a active match, then return it
                if (companyResponseDto.success && companyResponseDto.active) {
                    return companyResponseDto;
                }

                // Store the first found company.
                // At this step, the first found company is inactive for sure
                if (companyResponseDto.success && firstMatchingCompany == null) {
                    firstMatchingCompany = companyResponseDto;
                }
            }
        }

        // If no company has been found at all (active or inactive), then return a non null result
        if (firstMatchingCompany == null) {
            firstMatchingCompany = new DvsResponseDto.Company();
        }
 
        return firstMatchingCompany;
    }

    /**
     * Checks whether there is a difference between Account fields and returned company information
     */
    public override Boolean isInformationDifferent(Account account, DvsResponseDto.Company company) {

        return company.name != account.Name ||
            company.postalCode != account.BillingPostalCode ||
            company.city != account.BillingCity ||
            company.street != account.BillingStreet ||
            company.siret != account.VAT_Number__c ||
            company.siren != account.VAT_Number_2__c;
    }

    /**
     * Creates and fill discrepancy custom object information.
     * If a discrepancy already exists for the given account, then it updates it.
     */
    public override DvsDiscrepancy__c createDiscrepancy(Account account, DvsResponseDto.Company company) {

        DvsDiscrepancy__c discrepancy;

        if (account.Dvs_Discrepancies__r.size() > 0) {
            discrepancy = account.Dvs_Discrepancies__r[0];
        }
        else {
            discrepancy = new DvsDiscrepancy__c();
        }

        discrepancy.DvsName__c = company.name;
        discrepancy.DvsLastName__c = company.lastName;
        discrepancy.DvsFirstName__c = company.firstName;
        discrepancy.DvsStreet__c = company.street;
        discrepancy.DvsPostalCode__c = company.postalCode;
        discrepancy.DvsCity__c = company.city;
        discrepancy.DvsId__c = company.siret;
        discrepancy.DvsId2__c = company.siren;
        discrepancy.SalesforceName__c = account.Name;
        discrepancy.SalesforceStreet__c = account.BillingStreet;
        discrepancy.SalesforcePostalCode__c = account.BillingPostalCode;
        discrepancy.SalesforceCity__c = account.BillingCity;
        discrepancy.SalesforceId__c = account.VAT_Number__c;
        discrepancy.SalesforceId2__c = account.VAT_Number_2__c;
        discrepancy.SalesforceCountryCode__c = account.BillingCountryCode;
        discrepancy.Account__c = account.Id;

        return discrepancy;
    }

    /**
     * Applies discrepancies to the account fields
     */
    public override List<Account> correctDiscrepancies(List<DvsDiscrepancy__c> discrepancies, List<Account> accounts) {

        Map<Id, DvsDiscrepancy__c> discrepanciesByAccountId = new Map<Id, DvsDiscrepancy__c>();
        for (DvsDiscrepancy__c discrepancy : discrepancies) {
            if (discrepancy.DvsId__c != null) {
                discrepanciesByAccountId.put(discrepancy.Account__c, discrepancy);
            }
        }

        if (discrepanciesByAccountId.size() > 0) {
            Set<Id> accountIds = discrepanciesByAccountId.keySet();

            for (Account account : accounts) {
                DvsDiscrepancy__c discrepancy = discrepanciesByAccountId.get(account.Id);
                account.Name = discrepancy.DvsName__c;
                account.BillingStreet = discrepancy.DvsStreet__c;
                account.BillingPostalCode = discrepancy.DvsPostalCode__c;
                account.BillingCity = discrepancy.DvsCity__c;
                account.VAT_Number__c = discrepancy.DvsId__c;
                account.VAT_Number_2__c = discrepancy.DvsId2__c;
                account.SynchronizedWithDvs__c = true;
                account.DvsLongError__c = '';
                account.DvsError__c = '';
                account.DvsHasError__c = false;
            }
        }

        return accounts;

    }

    /**
     * Checks whether at least one account field relative to discrepancy verification has been modified
     */
    public override Boolean hasDiscrepancyChanged(Account newAccount, Account oldAccount) {

        return newAccount.Name != oldAccount.Name ||
            newAccount.BillingStreet != oldAccount.BillingStreet ||
            newAccount.BillingPostalCode != oldAccount.BillingPostalCode ||
            newAccount.BillingCity != oldAccount.BillingCity ||
            newAccount.VAT_Number__c != oldAccount.VAT_Number__c ||
            newAccount.VAT_Number_2__c != oldAccount.VAT_Number_2__c;
    }

    private static DvsResponseDto.Company getMatchingCompany(Etablissement company, String accountName, Boolean fuzzy) {
       return (fuzzy) ? getMatchingFuzzyCompany(company, accountName) : getMatchingCompany(company, accountName);
    }

    /**
     * From a company returned by the INSEE API, check whether this company match with the given account name
     * and if so, returns the corresponding common company DTO.
     */
    public static DvsResponseDto.Company getMatchingCompany(Etablissement company, String accountName) {
        String companyName;
        

        if (company.uniteLegale.denominationUniteLegale != null && company.uniteLegale.denominationUniteLegale.contains(accountName)) {
            companyName = company.uniteLegale.denominationUniteLegale;
        }
        else if (company.periodesEtablissement[0].denominationUsuelleEtablissement != null && company.periodesEtablissement[0].denominationUsuelleEtablissement.contains(accountName)) {
            companyName = company.periodesEtablissement[0].denominationUsuelleEtablissement;
        }
        else if (company.uniteLegale.denominationUsuelle1UniteLegale != null && company.uniteLegale.denominationUsuelle1UniteLegale.contains(accountName)) {
            companyName = company.uniteLegale.denominationUsuelle1UniteLegale;
        }
        else if (company.uniteLegale.sigleUniteLegale != null && company.uniteLegale.sigleUniteLegale == (accountName)) {
            companyName = company.uniteLegale.sigleUniteLegale;
        }
        else if ((company.uniteLegale.nomUniteLegale != null && company.uniteLegale.prenom1UniteLegale != null) && (company.uniteLegale.nomUniteLegale + ' ' + company.uniteLegale.prenom1UniteLegale == accountName || company.uniteLegale.prenom1UniteLegale + ' ' + company.uniteLegale.nomUniteLegale == accountName)) {
            companyName = company.uniteLegale.nomUniteLegale + ' ' + company.uniteLegale.prenom1UniteLegale;
        }


        if (companyName == null) {
            DvsResponseDto.Company comp = new DvsResponseDto.Company();
            comp.success = false;
            return comp;
        }
        return createResponseDto(company, companyName);
    }

    /**
     * From a company returned by the INSEE API (fuzzy mode), check whether this company match with the given account name 
     * and if so, returns the corresponding common company DTO.
     */
    public static DvsResponseDto.Company getMatchingFuzzyCompany(Etablissement company, String accountName) {

        String companyName = getCompanyName(company);

        if (companyName != null) {
            
            List<String> accountNameWords = accountName.split(' ');

            /** If the account name is a 1 word name, check the Levenshtein distance between the account name and
             * the name returned by INSEE API.
             * If -1 is returned, a distance superior than 2 is found, meaning that the company is not a match.
             */
            if (accountNameWords.size() == 1) {
                Integer levenshteinDistance = accountName.getLevenshteinDistance(companyName, 2);
                if (levenshteinDistance == -1) {
                    DvsResponseDto.Company comp = new DvsResponseDto.Company();
                    comp.success = false;
                    return comp;
                }
            /** If the account name is a multi-words name, check whether all the account name words are contained in the name returned by the INSEE API.
             *  If not, the company is not a match.
             * 
             */
            } else {
                Boolean isInBothNameList = false;
                List<String> companyNameWords = companyName.split(' ');
                for (String accountNameWord : accountNameWords) {
                    if (isInBothNameList == false) {
                        isInBothNameList = companyNameWords.contains(accountNameWord);
                    }
                }
                if (isInBothNameList == false) {
                    DvsResponseDto.Company comp = new DvsResponseDto.Company();
                    comp.success = false;
                    return comp;
                }
            }
        } else {
            DvsResponseDto.Company comp = new DvsResponseDto.Company();
            comp.success = false;
            return comp;
        }
        return createResponseDto(company, companyName);
    }

    /**
     * Converts INSEE result to common company dto (inpendent of company country).
     */
    public static DvsResponseDto.Company createResponseDto(Etablissement company, String companyName) {

        DvsResponseDto.Company dto = new DvsResponseDto.Company();
        dto.name = companyName;
        dto.lastName = company.uniteLegale.nomUniteLegale;
        dto.firstName = company.uniteLegale.prenom1UniteLegale;
        dto.siret = company.siret;
        dto.siren = company.siren;
        dto.street = '';
        if (company.adresseEtablissement.numeroVoieEtablissement != null) {
            dto.street += company.adresseEtablissement.numeroVoieEtablissement + ' ';
        } 
        if (company.adresseEtablissement.typeVoieEtablissement != null) {
            dto.street += company.adresseEtablissement.typeVoieEtablissement + ' ';
        }
        if (company.adresseEtablissement.libelleVoieEtablissement != null) {
            dto.street += company.adresseEtablissement.libelleVoieEtablissement;
        } 
        dto.postalCode = company.adresseEtablissement.codePostalEtablissement;
        dto.city = company.adresseEtablissement.libelleCommuneEtablissement;
        dto.active = (company.uniteLegale.etatAdministratifUniteLegale == 'A');
        dto.success = true;
        return dto;
    }

    /**
     * Clean account name by removing city name
     */
    private static String removeCityName(String accountName, String cityName) {
        String accountNameWithoutCityName = accountName;

        if (accountName.contains(cityName.toUpperCase())) {
            accountNameWithoutCityName = accountName.remove(cityName.toUpperCase());
        }

        return accountNameWithoutCityName.trim();
    }

    /**
     * Clean account name by removing legal status and dashes
     */
    private static String cleanAccountName(String accountName) {
        String result = accountName;
        for (String legalStatus: legalStatuses) {
            result = result.remove(legalStatus);
        }

        return result.replace('-', ' ').replace('\'', ' ').replace('&',' ').replace('#', ' ').replace('%', ' ').replace('/', ' ').replace('.', ' ').replaceAll('\\s{2,}', ' ').trim();
    }

    /**
     * Replace legal statuses by the corresponding legal statuses but without dot characters
     */
    private static String replaceLegalStatus(String accountName) {
        String result = accountName;
        for (Integer i = 0; i < legalStatuses.size(); i++) {
            String legalStatus = legalStatuses[i];
            String patternStr = String.join(legalStatus.getChars(), '\\.+') + '\\.+';
            Pattern pattern = Pattern.compile(patternStr);
            Matcher matcher = pattern.matcher(accountName);
            if (matcher.matches()) {
                result = matcher.replaceAll(legalStatus);
            }
        }
        return result;
    }

    private static String removeCharacterFromAccountName(String accountName) {
        String result = accountName;
        result = result.remove('"').remove('(').remove(')').remove('*');
        result = replaceLegalStatus(result);

        return result.replaceAll('\\s{2,}', ' ').trim();
    }

    /**
     * Encodes the request body containing the query conditions and the number of required results
     */
    public static String encodeRequestBody(Map<String, String> bodyMap) {

        String encodedBody = '';
        for (String key : bodyMap.keySet()) {
            encodedBody += EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(bodyMap.get(key), 'UTF-8');
            encodedBody += '&';
        }
        logDebug(encodedBody, 300);
        return encodedBody.removeEnd('&');
    
    }

    /**
     * Removes accents from the accountName
     */
    private static String removeAccents(String accountName) {

        for (String accent : accentsReplacementMap.keySet()) {
            accountName = accountName.replace(accent, accentsReplacementMap.get(accent));
        }

        return accountName;
    }

    public static void logDebug(String message, Integer maxLogSize) {
        for (Integer i = 0; i < message.length(); i = i + maxLogSize) {
            Integer iEffectiveEnd = (i + maxLogSize > (message.length()) ? message.length() : i + maxLogSize);
            System.debug(message.substring(i,iEffectiveEnd));
        }
    }

    private static String formatExternalId(String externalId) {

        return externalId.trim().remove('-').remove(' ').remove('.');
    }

    private static String getCompanyName(Etablissement company) {

        String companyName ;

        if (company.uniteLegale.denominationUniteLegale != null) {
            companyName = company.uniteLegale.denominationUniteLegale;
        } else if (company.periodesEtablissement[0].denominationUsuelleEtablissement != null) {
            companyName = company.periodesEtablissement[0].denominationUsuelleEtablissement;
        } else if (company.uniteLegale.denominationUsuelle1UniteLegale != null) {
            companyName = company.uniteLegale.denominationUsuelle1UniteLegale;
        } else if (company.periodesEtablissement[0].enseigne1Etablissement != null) {
            companyName = company.periodesEtablissement[0].enseigne1Etablissement;
        } else if (company.uniteLegale.nomUniteLegale != null) {
            companyName = company.uniteLegale.nomUniteLegale;
            if (company.uniteLegale.prenom1UniteLegale != null) {
                companyName += ' ' + company.uniteLegale.prenom1UniteLegale;
            }
        }

        return companyName;
    }

    private static LevenshteinParameters defineLevenshteinParameters(String name) {
        
        LevenshteinParameters ld = new LevenshteinParameters();

        List<String> nameWords = name.split(' ');
        
        Integer levenshteinDistance;
        if (nameWords.size() == 1) {
            levenshteinDistance = 2;
        } 
        else {
            levenshteinDistance = nameWords.size();
        }

        ld.levenshteinDistance = levenshteinDistance;
        ld.nameWordsNumber = nameWords.size();
        ld.nameWords = nameWords;

        return ld;
    }

    public override CompanyInfosResult getCompanies(CompanyInfosInput input, Account account, DvsSetting__mdt settings, Boolean fuzzySearch) {
        try {
            // Retrieve a valid token
            //String token = getToken(settings);
            String token = settings.DvsId__c;

            Http http = new Http();
            HttpRequest request = newRequest('GET');
            request.setHeader('X-INSEE-Api-Key-Integration', token);

            String baseUrl = settings.DvsUrl__c;
            String url = baseUrl + SIRET_RELATIVE_URL;
            String name = '';

            if (input.idNumber != null) {
                String encodedSiret = EncodingUtil.urlEncode(input.idNumber, 'UTF-8').replaceAll('[\\s-\\._]', '');
                if (input.idNumber.length() == 14) {
                    url += '/' + encodedSiret;
                } else if (input.idNumber.length() == 9) {
                    url += '?q=' + SIREN_PARAM + ':' + encodedSiret;
                    url += '&' + NOMBRE_PARAM + '=' + String.valueOf(pageSize);
                } else {
                    String msg = Label.dvs_bad_siret;
                    return new CompanyInfosResult(false, msg);
                }
            } else {
                name = input.name.trim();
                String lastName1;
                String lastName1Bis;
                String firstName1;
                String lastName2;
                String lastName2Bis;
                String firstName2;
                List<String> wordsName = name.split(' ');
                String searchByName = '';
                if (wordsName.size() > 1) {
                    if (wordsName.size() == 2) {
                        lastName1 = '"' + wordsName[0] + '"';
                        firstName1 = '"' + wordsName[1] + '"';
                        lastName2 = firstName1;
                        firstName2 = lastName1;
                    }
                    else if (wordsName.size() == 3) {
                        String str1 = wordsName[1];
                        firstName1 = '"' + wordsName[2] + '"';
                        firstName2 = '"' + wordsName[0] + '"';
                        lastName1 = '"' + wordsName[0] + ' ' + str1 + '"';
                        lastName2 = '"' + str1 + ' ' + wordsName[2] + '"';
                    }
                    name = '"' + name + '"';
                    if (fuzzySearch) {
                        String levenshteinDistance = String.valueOf(wordsName.size());
                        name = name + '~' + levenshteinDistance;
                        if (wordsName.size() == 2) {
                            lastName1 = '"' + wordsName[0] + '"~2';
                            firstName1 = '"' + wordsName[1] + '"~2';
                            lastName2 = firstName1;
                            firstName2 = lastName1;
                        }
                        else if (wordsName.size() == 3) {
                            firstName1 = '"' + wordsName[2] + '"~2';
                            lastName1 = '"' + wordsName[0] + '"~2';
                            lastName1Bis = '"' + wordsName[1] + '"~2';
                            firstName2 = '"' + wordsName[0] + '"~2';
                            lastName2 = '"' + wordsName[1] + '"~2';
                            lastName2Bis = '"' + wordsName[2] + '"~2';
                        }
                    } 
                    if (wordsName.size() == 2) {
                        searchByName += EncodingUtil.urlEncode(' OR (', 'UTF-8');
                        searchByName += LASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName1 + ' AND ', 'UTF-8');
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName1 + ') OR (', 'UTF-8');
                        searchByName += LASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName2 + ' AND ','UTF-8');
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName2 + ')', 'UTF-8');
                        searchByName += EncodingUtil.urlEncode(' OR (', 'UTF-8');
                        searchByName += USUALLASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName1 + ' AND ', 'UTF-8');
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName1 + ') OR (', 'UTF-8');
                        searchByName += USUALLASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName2 + ' AND ','UTF-8');
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName2 + ')', 'UTF-8');
                    }
                    else if (wordsName.size() == 3) {
                        searchByName += EncodingUtil.urlEncode(' OR (', 'UTF-8');
                        searchByName += LASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName1 + ' AND ', 'UTF-8');
                        if (lastName1Bis != null) {
                            searchByName += LASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName1Bis + ' AND ', 'UTF-8'); 
                        }
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName1 + ') OR (', 'UTF-8');
                        searchByName += LASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName2 + ' AND ','UTF-8');
                        if (lastName2Bis != null) {
                            searchByName += LASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName2Bis + ' AND ','UTF-8');
                        }
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName2 + ')', 'UTF-8');
                        searchByName += EncodingUtil.urlEncode(' OR (', 'UTF-8');
                        searchByName += USUALLASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName1 + ' AND ', 'UTF-8');
                        if (lastName1Bis != null) {
                            searchByName += USUALLASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName1Bis + ' AND ', 'UTF-8'); 
                        }
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName1 + ') OR (', 'UTF-8');
                        searchByName += USUALLASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName2 + ' AND ','UTF-8');
                        if (lastName2Bis != null) {
                            searchByName += USUALLASTNAME_PARAM + ':' + EncodingUtil.urlEncode(lastName2Bis + ' AND ','UTF-8');
                        }
                        searchByName += FIRSTNAME_PARAM + ':' + EncodingUtil.urlEncode(firstName2 + ')', 'UTF-8');
                    }
                } else {
                    name = '*' + name + '*';
                    if (fuzzySearch) {
                        name = name + '~2';
                    }
                }
                String encodedName = EncodingUtil.urlEncode(name, 'UTF-8');

                url += '?q=(' + NAME_PARAM + ':' + encodedName;
                if (searchByName != '') {
                    url += searchByName;
                }
                url += ')';

                if ((input.city != null && input.city != '') || (input.postalCode != null && input.postalCode != '')) {
                    url += EncodingUtil.urlEncode(' AND (', 'UTF-8');


                    Boolean hasCity = false;
                    if (input.city != null && input.city != '') {
                        String city = input.city.trim();
                        String encodedCity = EncodingUtil.urlEncode('"' + city + '"', 'UTF-8');

                        url += CITY_PARAM + ':' + encodedCity;
                        hasCity = true;
                    }
                    if (input.postalCode != null && input.postalCode != '') {
                        String postalCode = input.postalCode.trim().remove(' ');
                        String encodedPostalCode = EncodingUtil.urlEncode('"' + postalCode + '"', 'UTF-8');
                        if (hasCity) {
                            url += EncodingUtil.urlEncode(' OR ', 'UTF-8');

                        }
                        url += POSTAL_CODE_PARAM + ':' + encodedPostalCode;
                    }
                    url += EncodingUtil.urlEncode(')', 'UTF-8');
                }

                url += '&' + NOMBRE_PARAM + '=' + String.valueOf(pageSize);
                System.debug(url);
            }

            request.setEndpoint(url);
            HttpResponse res = http.send(request);


            System.debug(LoggingLevel.INFO, 'INSEE API returned status code: ' + res.getStatusCode());
            Integer status = res.getStatusCode();
            if (status == 200) {
                
                // Return the deserialize object
                CompanyInfosResult result = new CompanyInfosResult(true, '');
                
                Map<String, String> currentAccountInfo = new Map<String, String>();
                currentAccountInfo.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, account.Name);
                currentAccountInfo.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, account.VAT_Number__c);
                currentAccountInfo.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, account.VAT_Number_2__c);
                currentAccountInfo.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, account.BillingStreet);
                currentAccountInfo.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, account.BillingPostalCode);
                currentAccountInfo.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, account.BillingCity);

                result.currentAccount = currentAccountInfo;

                if (input.idNumber != null && input.idNumber.length() == 14) {
                    SiretInfo siretInfo = (SiretInfo) JSON.deserialize(res.getBody(), SiretInfo.class);

                    result.singleSearchSocieties = new List<Map<String, String>>();
                    if (siretInfo.etablissement != null) {
                        result.singleSearchSocieties.add(buildResult(siretInfo.etablissement, name));
                    }
                } else {
                    SiretInfos siretInfosList = (SiretInfos) JSON.deserialize(res.getBody(), SiretInfos.class);
                    
                    result.singleSearchSocieties = new List<Map<String, String>>();
                    if (siretInfosList.etablissements != null) {
                        for (Etablissement etablissement: siretInfosList.etablissements) {
                            result.singleSearchSocieties.add(buildResult(etablissement, name));
                        }
                    }
                }

                return result;

            } else if (status == 400) {
                System.debug('Unable to find companies matching search criteria: ' + res.getBody());
                return new CompanyInfosResult(false, DEFAULT_ERROR_MSG);
            } else if (status == 404) {
                return new CompanyInfosResult(false, DEFAULT_ERROR_MSG);
            } else {
                System.debug('Unable to find companies matching search criteria: [' + status + '] ' + res.getBody());
                return new CompanyInfosResult(false, DEFAULT_ERROR_MSG);
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            return new CompanyInfosResult(false, DEFAULT_ERROR_MSG);
        }
    }

    private static Map<String, String> buildResult(Etablissement etablissement, String name){
        Map<String, String> company = new Map<String, String>();
        company.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, etablissement.siret);
        company.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, etablissement.siren);

        // TODO: Check with Porcelanosa which name should be considered
        String companyName = getCompanyName(etablissement);
        // if (companyName == null) {
        //     String lastName = etablissement.uniteLegale.nomUniteLegale;
        //     if (name != null && name.contains(etablissement.uniteLegale.nomUsageUniteLegale)) {
        //         lastName = etablissement.uniteLegale.nomUsageUniteLegale;
        //     }
        //     companyName = lastName + ' ' + etablissement.uniteLegale.prenom1UniteLegale ;
        // }
        company.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, companyName);
        String street = etablissement.adresseEtablissement.numeroVoieEtablissement +
            ' ' + etablissement.adresseEtablissement.typeVoieEtablissement + ' ' +
            etablissement.adresseEtablissement.libelleVoieEtablissement;
        street = street.remove('null ');
        company.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, street);
        company.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, etablissement.adresseEtablissement.codePostalEtablissement);
        company.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, etablissement.adresseEtablissement.libelleCommuneEtablissement);
        company.put(ModalResultFieldLabels.GLOBAL_COUNTRY_FIELD_LABEL, 'France');

        System.debug('company: ' + company);
        return company;
    }

    public override UpdateCompanyResult applyNoResults(Account account) {
        String errorMessage = '';
        Boolean updateSucceeded = true;
        try {
            account.SynchronizedWithDvs__c = false;
            account.DVSAcceptedBy__c = UserInfo.getUserId();
            account.DVSAcceptedDate__c = Datetime.now();
            account.DVSAction__c = 'UNKNOWN';
            List<Account> accList = new List<Account>{account};

            Database.SaveResult[] srList = Database.update(accList);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    // errorMessage = sr.getErrors()[0];
                    errorMessage = String.valueof(sr.getErrors()[0]);
                    updateSucceeded = false;
                }
            }
        } catch (DmlException e) {
            errorMessage = e.getMessage();
            updateSucceeded = false;
        }

        UpdateCompanyResult result = new UpdateCompanyResult();
        result.success = updateSucceeded;
        result.message = errorMessage;

        return result;
    }

    public override UpdateCompanyResult applyChanges(Map<String, String> company, Account account, Boolean discardChanges) {

        System.debug(company);
        String errorMessage = '';
        Boolean updateSucceeded = true;
        DvsAccountInfo__c dvsAccountInfo = new DvsAccountInfo__c();

        try {
            if (!discardChanges) {
                dvsAccountInfo.Account__c = account.Id;
                dvsAccountInfo.PreviousName__c = account.Name;
                dvsAccountInfo.PreviousStreet__c = account.BillingStreet;
                dvsAccountInfo.PreviousPostalCode__c = account.BillingPostalCode;
                dvsAccountInfo.PreviousCity__c = account.BillingCity;
                dvsAccountInfo.PreviousId1__c = account.VAT_Number__c;
                dvsAccountInfo.PreviousId2__c = account.VAT_Number_2__c;
                dvsAccountInfo.ProcessedTime__c = Datetime.now();

                account.Name = company.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL);
                account.BillingStreet = company.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL);
                account.BillingPostalCode = company.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL);
                account.BillingCity = company.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL);
                account.BillingCountry = company.get(ModalResultFieldLabels.GLOBAL_COUNTRY_FIELD_LABEL);
                if (account.BillingCountry == null) {
                    account.BillingCountry = 'France';
                }
                account.VAT_Number__c = company.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL);
                account.VAT_Number_2__c = company.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL);
            }
            account.SynchronizedWithDvs__c = true;
            account.DVSAcceptedBy__c = UserInfo.getUserId();
            account.DVSAcceptedDate__c = Datetime.now();
            account.DVSAction__c = (discardChanges == true ? 'DISCARDED' : 'ACCEPTED');

            List<Account> accList = new List<Account>{account};
            
            Database.SaveResult[] srList = Database.update(accList);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    // errorMessage = sr.getErrors()[0];
                    errorMessage = String.valueof(sr.getErrors()[0]);
                    updateSucceeded = false;
                } else {
                    List<DvsAccountInfo__c> oldDataList = new List<DvsAccountInfo__c>{dvsAccountInfo};
                    srList = Database.insert(oldDataList);
                }
            }

            DvsDiscrepancy__c discrepancy = retrieveDiscrepancy(account.Id);
            if (discrepancy != null) {
                delete discrepancy;
            }
        } 
        catch (DmlException e) {
            errorMessage = e.getMessage();
            updateSucceeded = false;
        }

        UpdateCompanyResult result = new UpdateCompanyResult();
        result.success = updateSucceeded;
        result.message = errorMessage;
        result.company = company;

        return result;
    }

    public override CompanyInfosResult getDiscrepancy(Id accountId) {

        CompanyInfosResult cir = new CompanyInfosResult();
        cir.accountId = accountId;
        cir.fieldLabels = new Map<String, String>();
        cir.fieldLabels.put('Name', ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL);
        cir.fieldLabels.put('Id1', ModalResultFieldLabels.FR_SIRET_FIELD_LABEL);
        cir.fieldLabels.put('Id2', ModalResultFieldLabels.FR_SIREN_FIELD_LABEL);
        cir.fieldLabels.put('Address', ModalResultFieldLabels.GLOBAL_ADDRESS_FIELD_LABEL);
        cir.fieldLabels.put('Street', ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL);
        cir.fieldLabels.put('PostalCode', ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL);
        cir.fieldLabels.put('City', ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL);
        cir.fieldLabels.put('SearchById', ModalResultFieldLabels.FR_SEARCH_BY_ID_LABEL);

        Map<String, String> currentAccount = new Map<String, String>();
        Map<String, String> singleSearchSociety = new Map<String, String>();

        DvsDiscrepancy__c discrepancy = retrieveDiscrepancy(accountId);
        String searchStatus;

        if (discrepancy != null && discrepancy.DvsName__c != null) {

            singleSearchSociety.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, discrepancy.DvsName__c);
            singleSearchSociety.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, discrepancy.DvsStreet__c);
            singleSearchSociety.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, discrepancy.DvsPostalCode__c);
            singleSearchSociety.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, discrepancy.DvsCity__c);
            singleSearchSociety.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, discrepancy.DvsId__c);
            singleSearchSociety.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, discrepancy.DvsId2__c);
            
            cir.singleSearchSociety = singleSearchSociety;

            searchStatus = Label.dvs_discrepancy_found;
        }
        System.debug(cir.singleSearchSociety);

        Account acc = getAccount(accountId);
        if (searchStatus == null) {
            if (acc.SynchronizedWithDvs__c) {
                searchStatus = Label.dvs_discrepancy_treated;
            }
            else {
                searchStatus = Label.dvs_iscrepancy_not_performed;
            }
        }

        cir.searchStatus = searchStatus;

        currentAccount.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, acc.Name);
        currentAccount.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, acc.BillingStreet);
        currentAccount.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, acc.BillingPostalCode);
        currentAccount.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, acc.BillingCity);
        currentAccount.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, acc.VAT_Number__c);
        currentAccount.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, acc.VAT_Number_2__c);

        cir.currentAccount = currentAccount;

        return cir;
    }

    private static Account getAccount(Id accountId) {

        return [SELECT Id,
                        Name,
                        BillingStreet,
                        BillingPostalCode,
                        BillingCity,
                        VAT_Number__c,
                        VAT_Number_2__c,
                        SynchronizedWithDvs__c
                FROM Account
                WHERE Id = :accountId];
    }

    private static DvsDiscrepancy__c retrieveDiscrepancy(Id accountId) {

        List<DvsDiscrepancy__c> discrepancyList = [SELECT Id, 
                                                        Account__c,
                                                        DvsCity__c,
                                                        DvsId__c,
                                                        DvsId2__c,
                                                        DvsName__c,
                                                        DvsPostalCode__c,
                                                        DvsStreet__c,
                                                        SalesforceCity__c,
                                                        SalesforceCountryCode__c,
                                                        SalesforceId__c,
                                                        SalesforceId2__c,
                                                        SalesforceName__c,
                                                        SalesforcePostalCode__c,
                                                        SalesforceStreet__c
                                                FROM DvsDiscrepancy__c
                                                WHERE Account__c = :accountId
                                                LIMIT 1];
        if (discrepancyList != null && discrepancyList.size() > 0) {
            return discrepancyList[0];
        }
        else {
            return null;
        }
    }
}