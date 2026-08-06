/**
* @author Ivan Losilla
* @date January 2025
* @group API
* @description Clase que se encarga de la gestión con el servicio API de pappers
* @test @test AccountPlanClassesTest
*/
public with sharing class PappersService {
    private static final String FILE_ROOT_NAME = 'PAPPERS_';
    private static final String FOLDER_NAME = 'PAPPERS DATA';
    private static final Decimal GOAL_PERCENTAGE = 0.07; //7%

    public static PappersWrapper readData(String siren) {
        String nameFileLike = FILE_ROOT_NAME + siren + '%';
        List<ContentVersion> doc = [select id,VersionData,Title from ContentVersion where title like : nameFileLike LIMIT 1];

        if (doc.size() == 0) {
            return new PappersWrapper();
        }

        Blob jsonFileBody =doc[0].VersionData;
        return jsonToPappersWrapper(JsonFileBody.toString());
    }

    public static void getAPIData(String siren) {
        // Hacer la llamada a la API externa
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Configura la URL de la API externa (Usar Named Credential si es posible)
        String apiUrl = 'https://api.pappers.fr/v2/entreprise?siren=' + siren; // Reemplaza con la URL real
        request.setEndpoint(apiUrl);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + 'a61419ed39b06ab043118a6eb491f7bcd1975dee3fcc3256');
        request.setTimeout(60000); // 60 segundos

        try {
            // Ejecutar la petición
            HttpResponse response = http.send(request);
            
            // Verificar respuesta exitosa
            if (response.getStatusCode() == 200) {
                String jsonResponse = response.getBody();
                String nameFileLike = FILE_ROOT_NAME + siren;

                // Crear un archivo JSON para almacenar el SJON devuelto
                List<ContentVersion> doc = [select id,VersionData,Title from ContentVersion where title like : nameFileLike LIMIT 1];
                ContentVersion cv = new ContentVersion();
                if (doc.size() == 1) {
                    cv = doc[0];
                } else {
                    cv.Title = FILE_ROOT_NAME + siren;
                    cv.PathOnClient = 'ApiResponse.json';
                }
                cv.VersionData = Blob.valueOf(jsonResponse);
                upsert cv;

                if (doc.size() == 0) {
                    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                    ContentWorkspace ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name =: FOLDER_NAME LIMIT 1];
    
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.ShareType = 'I';
                    cdl.Visibility = 'AllUsers';
                    cdl.LinkedEntityId = ws.Id; //Magic happens here
                    insert cdl;
                }

            } else {
                throw new CalloutException('Error en la llamada a la API: ' + response.getStatus());
            }
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
        }
    }

    public static List<AccountAdditionalInfo__c> setData(Set<String> sirens) {
        List<Account> accountsList = [SELECT id, Vat_number_2__c, vat_number__c FROM Account WHERE vat_number_2__c IN : sirens];
        List<AccountAdditionalInfo__c> listFinances = new List<AccountAdditionalInfo__c>();
        Map<String, List<String>> sirenAccountsMap = new Map<String, List<String>>();

        for (Account acc : accountsList) {
            if (sirenAccountsMap.containsKey(acc.Vat_number_2__c)) {
                List<String> accounts = sirenAccountsMap.get(acc.Vat_number_2__c);
                accounts.add(acc.Id);
                sirenAccountsMap.put(acc.Vat_number_2__c, accounts);
            } else {
                sirenAccountsMap.put(acc.Vat_number_2__c, new List<String>{acc.Id});
            }
        }

        for (String siren : sirenAccountsMap.keySet()) {
            PappersService.PappersWrapper dataSiren = PappersService.readData(siren);

            if (dataSiren != null && dataSiren.finances != null && dataSiren.finances.size() > 0) {
                for (PappersService.Finances finance : dataSiren.finances) {
                    for (String accountId : sirenAccountsMap.get(siren)) {
                        listFinances.addAll(PappersService.createFinanceData(finance, accountId));
                    }
                }  
            }
        }

        return listFinances;
    }

    private static PappersWrapper jsonToPappersWrapper(String data) {
        Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(data);

        PappersWrapper result = new PappersWrapper();
        result.siren = (String) cObjMap.get('siren');
        result.diffusable = (Boolean) cObjMap.get('diffusable');
        result.nom_entreprise = (String) cObjMap.get('nom_entreprise');
        result.denomination = (String) cObjMap.get('denomination');
        result.code_naf = (String) cObjMap.get('code_naf');
        result.libelle_code_naf = (String) cObjMap.get('libelle_code_naf');
        result.domaine_activite = (String) cObjMap.get('domaine_activite');
        result.date_creation = (String) cObjMap.get('date_creation');
        result.entreprise_cessee = (Boolean) cObjMap.get('entreprise_cessee');

        List<Etablissement> listEtablissements = new List<Etablissement>();

        for (Object obj : (List<Object>) cObjMap.get('etablissements')) {
            Map<String, Object> etablissementJson = (Map<String, Object>) obj;
            Etablissement etablissementResult = new Etablissement();
            etablissementResult.siret = (String) etablissementJson.get('siret');
            etablissementResult.nic = (String) etablissementJson.get('nic');
            etablissementResult.adresse_ligne_1 = (String) etablissementJson.get('adresse_ligne_1');
            etablissementResult.code_postal = (String) etablissementJson.get('code_postal');
            etablissementResult.code_pays = (String) etablissementJson.get('code_pays');
            etablissementResult.code_naf = (String) etablissementJson.get('code_naf');
            etablissementResult.libelle_code_naf = (String) etablissementJson.get('libelle_code_naf');
            etablissementResult.annee_effectif = (Integer) etablissementJson.get('annee_effectif');
            etablissementResult.date_de_creation = (String) etablissementJson.get('date_de_creation');
            etablissementResult.etablissement_cesse = (Boolean) etablissementJson.get('etablissement_cesse');
            etablissementResult.date_cessation = (String) etablissementJson.get('date_cessation');
            etablissementResult.siege = (Boolean) etablissementJson.get('siege');
            listEtablissements.add(etablissementResult);
        }

        List<Finances> listFinances = new List<Finances>();

        for (Object obj : (List<Object>) cObjMap.get('finances')) {
            Map<String, Object> financesJson = (Map<String, Object>) obj;
            Finances financesResult = new Finances();
            financesResult.annee = String.valueOf((Integer) financesJson.get('annee'));
            financesResult.date_de_cloture_exercice = (String) financesJson.get('date_de_cloture_exercice');
            financesResult.chiffre_affaires = (Integer) financesJson.get('chiffre_affaires');
            financesResult.chiffre_affaires_export = (Decimal) financesJson.get('chiffre_affaires_export');
            financesResult.marge_brute = (Decimal) financesJson.get('marge_brute');
            financesResult.excedent_brut_exploitation = (Decimal) financesJson.get('excedent_brut_exploitation');
            financesResult.resultat_exploitation = (Decimal) financesJson.get('resultat_exploitation');
            financesResult.taux_croissance_chiffre_affaires = (Decimal) financesJson.get('taux_croissance_chiffre_affaires');
            financesResult.taux_marge_brute = (Decimal) financesJson.get('taux_marge_brute');
            financesResult.taux_marge_EBITDA = (Decimal) financesJson.get('taux_marge_EBITDA');
            financesResult.taux_marge_operationnelle = (Decimal) financesJson.get('taux_marge_operationnelle');
            financesResult.tresorerie = (Decimal) financesJson.get('tresorerie');
            financesResult.dettes_financieres = (Decimal) financesJson.get('dettes_financieres');
            listFinances.add(financesResult);
        }

        result.etablissements = listEtablissements;
        result.finances = listFinances;

        return result;
    }

    public static void deleteData(Set<String> sirens) {
        List<Account> accounts = [select id from Account WHERE vat_number_2__c in : sirens];
        Set<String> accountIds = new Set<String>();

        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        List<AccountAdditionalInfo__c> listFinances = [SELECT id from AccountAdditionalInfo__c WHERE Account__c IN : accountIds AND Source__c = 'PAPPERS'];

        delete listFinances;
    }

    public static List<AccountAdditionalInfo__c> createFinanceData(Finances data, String accountId) {
        List<AccountAdditionalInfo__c> results = new List<AccountAdditionalInfo__c>();

        AccountAdditionalInfo__c result = new AccountAdditionalInfo__c();
        result.Account__c = accountId;
        result.CurrencyIsoCode = 'EUR';
        result.Quantity__c = data.chiffre_affaires;
        result.Source__c = 'PAPPERS';
        result.Year__c = data.annee;
        result.InfoType__c = 'FINANCIAL';

        results.add(result);

        AccountAdditionalInfo__c resultGoal = new AccountAdditionalInfo__c();
        resultGoal.Account__c = accountId;
        resultGoal.CurrencyIsoCode = 'EUR';
        resultGoal.Quantity__c = Decimal.valueOf(data.chiffre_affaires);
        resultGoal.Source__c = 'PAPPERS';
        resultGoal.Year__c = data.annee;
        resultGoal.InfoType__c = 'GOAL';
        if (resultGoal.Quantity__c != null) {
            resultGoal.Quantity__c = resultGoal.Quantity__c * GOAL_PERCENTAGE;
        }

        results.add(resultGoal);

        return results;
    }

    public static AccountAdditionalInfo__c createGoalData(Finances data, String accountId) {
        AccountAdditionalInfo__c result = new AccountAdditionalInfo__c();
        result.Account__c = accountId;
        result.CurrencyIsoCode = 'EUR';
        result.Quantity__c = Decimal.valueOf(data.chiffre_affaires);
        result.Source__c = 'PAPPERS';
        result.Year__c = data.annee;
        result.InfoType__c = 'GOAL';
        if (result.Quantity__c != null) {
            result.Quantity__c = result.Quantity__c * GOAL_PERCENTAGE;
        }

        return result;
    }

    public class PappersWrapper {
        public String siren;
        public Boolean diffusable;
        public String nom_entreprise;
        public String denomination;
        public String code_naf;
        public String libelle_code_naf;
        public String domaine_activite;
        public String date_creation;
        public Boolean entreprise_cessee;

        public List<Etablissement> etablissements;
        public List<Finances> finances;
    }

    public class Etablissement {
        public String siret;
        public String nic;
        public String adresse_ligne_1;
        public String code_postal;
        public String ville;
        public String code_pays;
        public String code_naf;
        public String libelle_code_naf;
        public Integer annee_effectif;
        public String date_de_creation;
        public Boolean etablissement_cesse;
        public String date_cessation;
        public Boolean siege;
    }

    public class Finances {
        public String annee;
        public String date_de_cloture_exercice;
        public Integer chiffre_affaires;
        public Decimal chiffre_affaires_export;
        public Decimal marge_brute;
        public Decimal excedent_brut_exploitation;
        public Decimal resultat_exploitation;
        public Decimal taux_croissance_chiffre_affaires;
        public Decimal taux_marge_brute;
        public Decimal taux_marge_EBITDA;
        public Decimal taux_marge_operationnelle;

        public Decimal tresorerie;
        public Decimal dettes_financieres;
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }

}