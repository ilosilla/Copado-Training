@isTest
public with sharing class TestInseeDvsService {

    @TestSetup
    static void makeData(){
        CountrySettings__c newCountrySetting = new CountrySettings__c(Name = 'France', Country__c = 'FR', enableREVIEWSMS__c = true, dataValidation__c = true);
        insert newCountrySetting;
        
        RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'Trade and Specificators' LIMIT 1];
        List<Account> accountList = new List<Account>();

        Account acc1 = new Account(
            Name = 'Company 1',
            RecordTypeId = rt.Id,
            BillingStreet = '1 rue de la paix',
            BillingPostalCode = '33000',
            BillingCity = 'Bordeaux',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0711223344',
            Business_Email__c = 'company1@test.com',
            Account_Classification__c = 'Construction Company',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc1);

        Account acc2 = new Account(
            Name = 'Company 2',
            RecordTypeId = rt.Id,
            BillingStreet = '2 avenue de la libération',
            BillingPostalCode = '72100',
            BillingCity = 'Le Mans',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0799887766',
            Business_Email__c = 'company2@test.com',
            Account_Classification__c = 'Real State Agency',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc2);

        Account acc3 = new Account(
            Name = 'Company 3',
            RecordTypeId = rt.Id,
            BillingStreet = '3 place de la République',
            BillingPostalCode = '75001',
            BillingCity = 'Paris',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0712345678',
            Business_Email__c = 'company3@test.com',
            Account_Classification__c = 'Kitchen Instalation Company',
            CurrencyIsoCode = 'EUR',
            VAT_Number__c = '94844632300016',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc3);

        Account acc4 = new Account(
            Name = 'Company 4',
            RecordTypeId = rt.Id,
            BillingStreet = '4 avenue Jean Jaurès',
            BillingPostalCode = '31160',
            BillingCity = 'Aspet',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0648264936',
            Business_Email__c = 'company4@test.com',
            Account_Classification__c = 'Real State Agency',
            CurrencyIsoCode = 'EUR',
            VAT_Number__c = '94514697500078',
            Vat_Number_2__c = '945146975',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc4);

        Account acc5 = new Account(
            Name = 'SARL Company 5',
            RecordTypeId = rt.Id,
            BillingStreet = '5 rue Émile Zola',
            BillingPostalCode = '94700',
            BillingCity = 'Maisons-Alfort',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0789652354',
            Business_Email__c = 'company5@test.com',
            Account_Classification__c = 'Construction Company',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc5);

        Account acc6 = new Account(
            Name = 'Cômpàny 6',
            RecordTypeId = rt.Id,
            BillingStreet = '6 place du 24 août', 
            BillingPostalCode = '06130',
            BillingCity = 'Grasse',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0715463879',
            Business_Email__c = 'company6@test.com',
            Account_Classification__c = 'Construction Company',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc6);

        Account acc7 = new Account(
            Name = 'Company "7"',
            RecordTypeId = rt.Id,
            BillingStreet = '7 Traverse du Pont', 
            BillingPostalCode = '69000',
            BillingCity = 'Lyon',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0797416358',
            Business_Email__c = 'company7@test.com',
            Account_Classification__c = 'Construction Company',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false
        );
        accountList.add(acc7);

        Account acc8 = new Account(
            Name = 'Company 8',
            RecordTypeId = rt.Id,
            BillingStreet = '45 avenue de la Grande Porte', 
            BillingPostalCode = '84000',
            BillingCity = 'Avignon',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0742657159',
            Business_Email__c = 'company8@test.com',
            Account_Classification__c = 'Real State Agency',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false,
            VAT_Number_2__c = '377853536'
        );
        accountList.add(acc8);

        insert accountList;

    }

    @isTest static void testLorem() {
        String l = DvsService.loremIpsum();
        Assert.isNotNull(l);
    }

    @isTest
    public static void discrepancyCreation() {

        //Test that both calls are successfull and 4 discrepancies are created

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "94844632300016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 3",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "3",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "PLACE",'
        + '"libelleVoieEtablissement": "DE LA REPUBLIQUE",'
        + '"codePostalEtablissement": "75001",'
        + '"libelleCommuneEtablissement": "PARIS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "75001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 3",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 3",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1463871357",'
        + '"nic": "00028",'
        + '"siret": "146387135700028",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 2",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "2",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DES BUCHETTES",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "10442",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1463871357",'
        + '"nic": "00071",'
        + '"siret": "146387135700071",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "THE BEST COMPANY 2",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "14",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DES LILAS",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "35064",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1463840248",'
        + '"nic": "00097",'
        + '"siret": "146384024800097",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "FIRST COMPANY 1",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "1",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE LA PAIX",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "33045",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1204751357",'
        + '"nic": "00012",'
        + '"siret": "120475135700012",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "SECOND COMPANY 1",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "26",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DES ROSIERS",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "24442",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00056",'
        + '"siret": "37785353600056",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2002-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2002-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "56",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA GRANDE PORTE",'
        + '"codePostalEtablissement": "84000",'
        + '"libelleCommuneEtablissement": "AVIGNON",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "84002",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2002-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.areEqual('FIRST COMPANY 1', discrepancyListAfter[1].DvsName__c);
        Assert.areEqual('1 RUE DE LA PAIX', discrepancyListAfter[1].DvsStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].DvsPostalCode__c);
        Assert.areEqual('BORDEAUX', discrepancyListAfter[1].DvsCity__c);
        Assert.areEqual('146384024800097', discrepancyListAfter[1].DvsId__c);
        Assert.areEqual('1463840248', discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[2].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].DvsName__c);
        Assert.areEqual('2 AVENUE DES BUCHETTES', discrepancyListAfter[2].DvsStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].DvsPostalCode__c);
        Assert.areEqual('LE MANS', discrepancyListAfter[2].DvsCity__c);
        Assert.areEqual('146387135700028', discrepancyListAfter[2].DvsId__c);
        Assert.areEqual('1463871357', discrepancyListAfter[2].DvsId2__c);

        Assert.areEqual('COMPANY 3', discrepancyListAfter[3].SalesforceName__c);
        Assert.areEqual('3 place de la République', discrepancyListAfter[3].SalesforceStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[3].SalesforcePostalCode__c);
        Assert.areEqual('Paris', discrepancyListAfter[3].SalesforceCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[3].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[3].SalesforceId2__c);
        Assert.areEqual('COMPANY 3', discrepancyListAfter[3].DvsName__c);
        Assert.areEqual('3 PLACE DE LA REPUBLIQUE', discrepancyListAfter[3].DvsStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[3].DvsPostalCode__c);
        Assert.areEqual('PARIS', discrepancyListAfter[3].DvsCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[3].DvsId__c);
        Assert.areEqual('845021578', discrepancyListAfter[3].DvsId2__c);

        Assert.areEqual('COMPANY 8', discrepancyListAfter[6].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[6].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[6].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[6].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[6].SalesforceId2__c);
        Assert.areEqual('COMPANY 8', discrepancyListAfter[6].DvsName__c);
        Assert.areEqual('56 AVENUE DE LA GRANDE PORTE', discrepancyListAfter[6].DvsStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[6].DvsPostalCode__c);
        Assert.areEqual('AVIGNON', discrepancyListAfter[6].DvsCity__c);
        Assert.areEqual('37785353600056', discrepancyListAfter[6].DvsId__c);
        Assert.areEqual('377853536', discrepancyListAfter[6].DvsId2__c);
    }

    @isTest
    public static void discrepancyCreationFuzzySearch() {

        //Test that both calls are successfull and 8 discrepancies are created (1 match found)

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "84502157800016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "2 FUZZY COMPANY",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "2",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA LIBERATION",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setFuzzySearch(true);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[1].DvsName__c);
        Assert.isNull(discrepancyListAfter[1].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[1].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[1].DvsCity__c);
        Assert.isNull(discrepancyListAfter[1].DvsId__c);
        Assert.isNull(discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[2].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.areEqual('2 FUZZY COMPANY',discrepancyListAfter[2].DvsName__c);
        Assert.areEqual('2 AVENUE DE LA LIBERATION', discrepancyListAfter[2].DvsStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].DvsPostalCode__c);
        Assert.areEqual('LE MANS', discrepancyListAfter[2].DvsCity__c);
        Assert.areEqual('84502157800016', discrepancyListAfter[2].DvsId__c);
        Assert.areEqual('845021578', discrepancyListAfter[2].DvsId2__c);

        Assert.areEqual('COMPANY 3', discrepancyListAfter[3].SalesforceName__c);
        Assert.areEqual('3 place de la République', discrepancyListAfter[3].SalesforceStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[3].SalesforcePostalCode__c);
        Assert.areEqual('Paris', discrepancyListAfter[3].SalesforceCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[3].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[3].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[3].DvsName__c);
        Assert.isNull(discrepancyListAfter[3].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[3].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[3].DvsCity__c);
        Assert.isNull(discrepancyListAfter[3].DvsId__c);
        Assert.isNull(discrepancyListAfter[3].DvsId2__c);

        Assert.areEqual('COMPANY 8', discrepancyListAfter[6].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[6].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[6].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[6].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[6].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[6].DvsName__c);
        Assert.isNull(discrepancyListAfter[6].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[6].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[6].DvsCity__c);
        Assert.isNull(discrepancyListAfter[6].DvsId__c);
        Assert.isNull(discrepancyListAfter[6].DvsId2__c);
    }

    @isTest
    public static void discrepancyCreationFuzzySearchOneWordAccountName() {

        // Test that both calls are successfull and 8 discrepancies are created (1 match found)
        // Here, the account name is a one word name, FNAC. The INSEE API returns a result for a company named TRAC. 
        // Since there is no other fitting result, this one will be taken into account because the Levenshtein distance
        // between those two names is 2.

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());

        Account acc = getAccount('Company 2');
        acc.Name = 'FNAC';
        update acc;
        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "84502157800016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "TRAC",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "25",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE CARNAC",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setFuzzySearch(true);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[1].DvsName__c);
        Assert.isNull(discrepancyListAfter[1].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[1].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[1].DvsCity__c);
        Assert.isNull(discrepancyListAfter[1].DvsId__c);
        Assert.isNull(discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 3', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('3 place de la République', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Paris', discrepancyListAfter[2].SalesforceCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[2].DvsName__c);
        Assert.isNull(discrepancyListAfter[2].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[2].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[2].DvsCity__c);
        Assert.isNull(discrepancyListAfter[2].DvsId__c);
        Assert.isNull(discrepancyListAfter[2].DvsId2__c);

        Assert.areEqual('COMPANY 8', discrepancyListAfter[5].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[5].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[5].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[5].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[5].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[5].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[5].DvsName__c);
        Assert.isNull(discrepancyListAfter[5].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[5].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[5].DvsCity__c);
        Assert.isNull(discrepancyListAfter[5].DvsId__c);
        Assert.isNull(discrepancyListAfter[5].DvsId2__c);

        Assert.areEqual('FNAC', discrepancyListAfter[6].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[6].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[6].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[6].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId2__c);
        Assert.areEqual('TRAC',discrepancyListAfter[6].DvsName__c);
        Assert.areEqual('25 RUE DE CARNAC', discrepancyListAfter[6].DvsStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[6].DvsPostalCode__c);
        Assert.areEqual('LE MANS', discrepancyListAfter[6].DvsCity__c);
        Assert.areEqual('84502157800016', discrepancyListAfter[6].DvsId__c);
        Assert.areEqual('845021578', discrepancyListAfter[6].DvsId2__c);
    }

    @isTest
    public static void discrepancyCreationFuzzySearchOneWordAccountNameNoMatch() {

        // Test that both calls are successfull and 8 discrepancies are created (no match found)
        // Here, the account name is a one word name, FNAC. The INSEE API returns a result for a company named VICTORIA. 
        // Since there is no other fitting result, this one will not be taken into account because the Levenshtein distance
        // between those two names is superior than 2.

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());

        Account acc = getAccount('Company 2');
        acc.Name = 'FNAC';
        update acc;
        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "84502157800016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "VICTORIA",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "25",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE CARNAC",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setFuzzySearch(true);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[1].DvsName__c);
        Assert.isNull(discrepancyListAfter[1].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[1].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[1].DvsCity__c);
        Assert.isNull(discrepancyListAfter[1].DvsId__c);
        Assert.isNull(discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 3', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('3 place de la République', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Paris', discrepancyListAfter[2].SalesforceCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[2].DvsName__c);
        Assert.isNull(discrepancyListAfter[2].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[2].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[2].DvsCity__c);
        Assert.isNull(discrepancyListAfter[2].DvsId__c);
        Assert.isNull(discrepancyListAfter[2].DvsId2__c);

        Assert.areEqual('COMPANY 8', discrepancyListAfter[5].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[5].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[5].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[5].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[5].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[5].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[5].DvsName__c);
        Assert.isNull(discrepancyListAfter[5].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[5].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[5].DvsCity__c);
        Assert.isNull(discrepancyListAfter[5].DvsId__c);
        Assert.isNull(discrepancyListAfter[5].DvsId2__c);

        Assert.areEqual('FNAC', discrepancyListAfter[6].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[6].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[6].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[6].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[6].DvsName__c);
        Assert.isNull(discrepancyListAfter[6].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[6].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[6].DvsCity__c);
        Assert.isNull(discrepancyListAfter[6].DvsId__c);
        Assert.isNull(discrepancyListAfter[6].DvsId2__c);
    }


    @isTest
    public static void discrepancyCreationFuzzySearch2() {

        //Test that both calls are successfull and 8 discrepancies are created (1 match found)
        //In this test, the fuzzy result in not chosen since there is fitter result

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "84502157800016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "2 FUZZY COMPANY",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "2",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA LIBERATION",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "84502157800016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "THE COMPANY 2",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "25",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA LIBERATION",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';
        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setFuzzySearch(true);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[1].DvsName__c);
        Assert.isNull(discrepancyListAfter[1].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[1].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[1].DvsCity__c);
        Assert.isNull(discrepancyListAfter[1].DvsId__c);
        Assert.isNull(discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[2].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.areEqual('THE COMPANY 2',discrepancyListAfter[2].DvsName__c);
        Assert.areEqual('25 AVENUE DE LA LIBERATION', discrepancyListAfter[2].DvsStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].DvsPostalCode__c);
        Assert.areEqual('LE MANS', discrepancyListAfter[2].DvsCity__c);
        Assert.areEqual('84502157800016', discrepancyListAfter[2].DvsId__c);
        Assert.areEqual('845021578', discrepancyListAfter[2].DvsId2__c);

        Assert.areEqual('COMPANY 3', discrepancyListAfter[3].SalesforceName__c);
        Assert.areEqual('3 place de la République', discrepancyListAfter[3].SalesforceStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[3].SalesforcePostalCode__c);
        Assert.areEqual('Paris', discrepancyListAfter[3].SalesforceCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[3].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[3].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[3].DvsName__c);
        Assert.isNull(discrepancyListAfter[3].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[3].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[3].DvsCity__c);
        Assert.isNull(discrepancyListAfter[3].DvsId__c);
        Assert.isNull(discrepancyListAfter[3].DvsId2__c);

        Assert.areEqual('COMPANY 8', discrepancyListAfter[6].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[6].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[6].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[6].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[6].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[6].DvsName__c);
        Assert.isNull(discrepancyListAfter[6].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[6].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[6].DvsCity__c);
        Assert.isNull(discrepancyListAfter[6].DvsId__c);
        Assert.isNull(discrepancyListAfter[6].DvsId2__c);
    }

    @isTest
    public static void discrepancyCreationDateParameters() {

        // Since it's not possible to define the last activity date on the account, all of the accounts are selected
        // 1 account is created in this test, after defining the dates, this one should not be taken into account
        // thus, we should have 9 accounts but 8 discrepancies and only one with a match

        Datetime startDate = Datetime.now().addMonths(-1).addDays(-15);
        Datetime endDate = Datetime.now(); 

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "1463871357",'
        + '"nic": "00028",'
        + '"siret": "146387135700028",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 2",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "2",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DES BUCHETTES",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "10442",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        RecordType rt = [SELECT Id FROM RecordType WHERE Name = 'Trade and Specificators' LIMIT 1];

        Datetime now = Datetime.now();
        Datetime in1sec = Datetime.now().addSeconds(1);
        while (now < in1sec) {
            now = Datetime.now();
        }
        Account acc9 = new Account(
            Name = 'Company 9',
            RecordTypeId = rt.Id,
            BillingStreet = '93 rue Jean Jaurès', 
            BillingPostalCode = '94700',
            BillingCity = 'Maisons-Alfort',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0698264315',
            Business_Email__c = 'company9@test.com',
            Account_Classification__c = 'Real State Agency',
            CurrencyIsoCode = 'EUR',
            SynchronizedWithDvs__c = false
        );
        insert acc9;

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setPeriod(startDate, endDate);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.isNull(discrepancyListAfter[1].DvsName__c);
        Assert.isNull(discrepancyListAfter[1].DvsStreet__c);
        Assert.isNull(discrepancyListAfter[1].DvsPostalCode__c);
        Assert.isNull(discrepancyListAfter[1].DvsCity__c);
        Assert.isNull(discrepancyListAfter[1].DvsId__c);
        Assert.isNull(discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[2].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].DvsName__c);
        Assert.areEqual('2 AVENUE DES BUCHETTES', discrepancyListAfter[2].DvsStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].DvsPostalCode__c);
        Assert.areEqual('LE MANS', discrepancyListAfter[2].DvsCity__c);
        Assert.areEqual('146387135700028', discrepancyListAfter[2].DvsId__c);
        Assert.areEqual('1463871357', discrepancyListAfter[2].DvsId2__c);
    }

    @isTest
    public static void discrepancyCreationSeveralResultPages() {

        //Test that both calls are successfull and 4 discrepancies are created

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String resultsPerPage = '3';
        InseeDvsService.pageSize = Integer.valueOf(resultsPerPage);

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponsePage1 = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 6,'
        + '"debut": 0,'
        + '"nombre": ' + resultsPerPage
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "94844632300016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 3",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "3",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "PLACE",'
        + '"libelleVoieEtablissement": "DE LA REPUBLIQUE",'
        + '"codePostalEtablissement": "75001",'
        + '"libelleCommuneEtablissement": "PARIS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "75001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 3",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 3",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1463871357",'
        + '"nic": "00028",'
        + '"siret": "146387135700028",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 2",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "2",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DES BUCHETTES",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "10442",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1463871357",'
        + '"nic": "00071",'
        + '"siret": "146387135700071",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "THE BEST COMPANY 2",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "14",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DES LILAS",'
        + '"codePostalEtablissement": "72100",'
        + '"libelleCommuneEtablissement": "LE MANS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "35064",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        String requestResponsePage2 = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 6,'
        + '"debut": ' + resultsPerPage + ','
        + '"nombre": ' + resultsPerPage
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "1463840248",'
        + '"nic": "00097",'
        + '"siret": "146384024800097",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "FIRST COMPANY 1",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "1",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE LA PAIX",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "33045",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1204751357",'
        + '"nic": "00012",'
        + '"siret": "120475135700012",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "SECOND COMPANY 1",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "26",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DES ROSIERS",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "24442",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00056",'
        + '"siret": "37785353600056",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2002-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2002-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "56",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA GRANDE PORTE",'
        + '"codePostalEtablissement": "84000",'
        + '"libelleCommuneEtablissement": "AVIGNON",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "84002",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2002-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, 0), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponsePage1));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, 1), TestMockFactory.getHttpResponse(200, 'SUCCESS', requestResponsePage2));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[1].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[1].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[1].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[1].SalesforceId2__c);
        Assert.areEqual('FIRST COMPANY 1', discrepancyListAfter[1].DvsName__c);
        Assert.areEqual('1 RUE DE LA PAIX', discrepancyListAfter[1].DvsStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[1].DvsPostalCode__c);
        Assert.areEqual('BORDEAUX', discrepancyListAfter[1].DvsCity__c);
        Assert.areEqual('146384024800097', discrepancyListAfter[1].DvsId__c);
        Assert.areEqual('1463840248', discrepancyListAfter[1].DvsId2__c);

        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].SalesforceName__c);
        Assert.areEqual('2 avenue de la libération', discrepancyListAfter[2].SalesforceStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].SalesforcePostalCode__c);
        Assert.areEqual('Le Mans', discrepancyListAfter[2].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[2].SalesforceId2__c);
        Assert.areEqual('COMPANY 2', discrepancyListAfter[2].DvsName__c);
        Assert.areEqual('2 AVENUE DES BUCHETTES', discrepancyListAfter[2].DvsStreet__c);
        Assert.areEqual('72100', discrepancyListAfter[2].DvsPostalCode__c);
        Assert.areEqual('LE MANS', discrepancyListAfter[2].DvsCity__c);
        Assert.areEqual('146387135700028', discrepancyListAfter[2].DvsId__c);
        Assert.areEqual('1463871357', discrepancyListAfter[2].DvsId2__c);

        Assert.areEqual('COMPANY 3', discrepancyListAfter[3].SalesforceName__c);
        Assert.areEqual('3 place de la République', discrepancyListAfter[3].SalesforceStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[3].SalesforcePostalCode__c);
        Assert.areEqual('Paris', discrepancyListAfter[3].SalesforceCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[3].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[3].SalesforceId2__c);
        Assert.areEqual('COMPANY 3', discrepancyListAfter[3].DvsName__c);
        Assert.areEqual('3 PLACE DE LA REPUBLIQUE', discrepancyListAfter[3].DvsStreet__c);
        Assert.areEqual('75001', discrepancyListAfter[3].DvsPostalCode__c);
        Assert.areEqual('PARIS', discrepancyListAfter[3].DvsCity__c);
        Assert.areEqual('94844632300016', discrepancyListAfter[3].DvsId__c);
        Assert.areEqual('845021578', discrepancyListAfter[3].DvsId2__c);

        Assert.areEqual('COMPANY 8', discrepancyListAfter[6].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[6].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[6].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[6].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[6].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[6].SalesforceId2__c);
        Assert.areEqual('COMPANY 8', discrepancyListAfter[6].DvsName__c);
        Assert.areEqual('56 AVENUE DE LA GRANDE PORTE', discrepancyListAfter[6].DvsStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[6].DvsPostalCode__c);
        Assert.areEqual('AVIGNON', discrepancyListAfter[6].DvsCity__c);
        Assert.areEqual('37785353600056', discrepancyListAfter[6].DvsId__c);
        Assert.areEqual('377853536', discrepancyListAfter[6].DvsId2__c);
    }

    @isTest
    public static void discrepencyCreationWithSirenNumberOneResultResult() {

        //Test that both calls are successfull and 1 discrepancies are created but only one with siren

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00056",'
        + '"siret": "37785353600056",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2002-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2002-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "56",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA GRANDE PORTE",'
        + '"codePostalEtablissement": "84000",'
        + '"libelleCommuneEtablissement": "AVIGNON",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "84002",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2002-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setParameters('Company 8', '84000');
        batch.setLimit(1);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(1, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 8', discrepancyListAfter[0].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[0].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[0].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[0].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[0].SalesforceId2__c);
        Assert.areEqual('COMPANY 8', discrepancyListAfter[0].DvsName__c);
        Assert.areEqual('56 AVENUE DE LA GRANDE PORTE', discrepancyListAfter[0].DvsStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[0].DvsPostalCode__c);
        Assert.areEqual('AVIGNON', discrepancyListAfter[0].DvsCity__c);
        Assert.areEqual('37785353600056', discrepancyListAfter[0].DvsId__c);
        Assert.areEqual('377853536', discrepancyListAfter[0].DvsId2__c);
    }

    @isTest
    public static void discrepencyCreationWithSirenNumberSeveralResults() {

        //Test that both calls are successfull and 1 discrepancies are created but only one with siren

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00097",'
        + '"siret": "37785353600097",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "1999-01-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "1999-01-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "1",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE LA PAIX",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "33045",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00012",'
        + '"siret": "37785353600012",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2001-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2001-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "26",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DES ROSIERS",'
        + '"codePostalEtablissement": "72190",'
        + '"libelleCommuneEtablissement": "COULAINES",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72191",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2001-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00056",'
        + '"siret": "37785353600056",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2002-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2002-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "56",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA GRANDE PORTE",'
        + '"codePostalEtablissement": "84000",'
        + '"libelleCommuneEtablissement": "AVIGNON",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "84002",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2002-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setParameters('Company 8', '84000');
        batch.setLimit(1);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(1, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 8', discrepancyListAfter[0].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[0].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[0].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[0].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[0].SalesforceId2__c);
        Assert.areEqual('COMPANY 8', discrepancyListAfter[0].DvsName__c);
        Assert.areEqual('56 AVENUE DE LA GRANDE PORTE', discrepancyListAfter[0].DvsStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[0].DvsPostalCode__c);
        Assert.areEqual('AVIGNON', discrepancyListAfter[0].DvsCity__c);
        Assert.areEqual('37785353600056', discrepancyListAfter[0].DvsId__c);
        Assert.areEqual('377853536', discrepancyListAfter[0].DvsId2__c);
    }

    @isTest
    public static void discrepencyCreationWithSirenNumberSeveralResultsNoPostalCodeMatch() {

        //Test that both calls are successfull and 1 discrepancies are created but only one with siren

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00097",'
        + '"siret": "37785353600097",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "1999-01-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "1999-01-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "1",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE LA PAIX",'
        + '"codePostalEtablissement": "84000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "33045",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00012",'
        + '"siret": "37785353600012",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2001-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2001-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "26",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DES ROSIERS",'
        + '"codePostalEtablissement": "72190",'
        + '"libelleCommuneEtablissement": "COULAINES",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "72191",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2001-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "377853536",'
        + '"nic": "00056",'
        + '"siret": "37785353600056",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2002-07-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2002-07-01",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "COMPANY 8",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "56",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "DE LA GRANDE PORTE",'
        + '"codePostalEtablissement": "81000",'
        + '"libelleCommuneEtablissement": "ALBI",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "81007",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2002-07-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setParameters('Company 8', '84000');
        batch.setLimit(1);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(1, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 8', discrepancyListAfter[0].SalesforceName__c);
        Assert.areEqual('45 avenue de la Grande Porte', discrepancyListAfter[0].SalesforceStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[0].SalesforcePostalCode__c);
        Assert.areEqual('Avignon', discrepancyListAfter[0].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId__c);
        Assert.areEqual('377853536', discrepancyListAfter[0].SalesforceId2__c);
        Assert.areEqual('COMPANY 8', discrepancyListAfter[0].DvsName__c);
        Assert.areEqual('1 RUE DE LA PAIX', discrepancyListAfter[0].DvsStreet__c);
        Assert.areEqual('84000', discrepancyListAfter[0].DvsPostalCode__c);
        Assert.areEqual('BORDEAUX', discrepancyListAfter[0].DvsCity__c);
        Assert.areEqual('37785353600097', discrepancyListAfter[0].DvsId__c);
        Assert.areEqual('377853536', discrepancyListAfter[0].DvsId2__c);
    }

    @isTest
    public static void batchWithParameters() {

        //Test that both calls are successfull and 1 discrepancy is created

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "1463840248",'
        + '"nic": "00097",'
        + '"siret": "146384024800097",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "FIRST COMPANY 1",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "1",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DE LA PAIX",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "33045",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "1204751357",'
        + '"nic": "00012",'
        + '"siret": "120475135700012",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2023-01-26",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T14:47:06.010",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2023-01-26",'
        + '"categorieJuridiqueUniteLegale": "6540",'
        + '"denominationUniteLegale": "SECOND COMPANY 1",'
        + '"sigleUniteLegale": null,'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "68.20B",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00016",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": null,'
        + '"anneeCategorieEntreprise": null'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "26",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "DES ROSIERS",'
        + '"codePostalEtablissement": "33000",'
        + '"libelleCommuneEtablissement": "BORDEAUX",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "24442",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "104420001_B",'
        + '"coordonneeLambertAbscisseEtablissement": "783231.480248526",'
        + '"coordonneeLambertOrdonneeEtablissement": "6818272.50531205"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2023-01-26",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "68.20B",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        batch.setParameters('Company 1', '33000');
        batch.setLimit(1);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(1, discrepancyListAfter.size());

        Assert.areEqual('COMPANY 1', discrepancyListAfter[0].SalesforceName__c);
        Assert.areEqual('1 rue de la paix', discrepancyListAfter[0].SalesforceStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[0].SalesforcePostalCode__c);
        Assert.areEqual('Bordeaux', discrepancyListAfter[0].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId2__c);
        Assert.areEqual('FIRST COMPANY 1', discrepancyListAfter[0].DvsName__c);
        Assert.areEqual('1 RUE DE LA PAIX', discrepancyListAfter[0].DvsStreet__c);
        Assert.areEqual('33000', discrepancyListAfter[0].DvsPostalCode__c);
        Assert.areEqual('BORDEAUX', discrepancyListAfter[0].DvsCity__c);
        Assert.areEqual('146384024800097', discrepancyListAfter[0].DvsId__c);
        Assert.areEqual('1463840248', discrepancyListAfter[0].DvsId2__c);
    }

    @isTest
    public static void discrepancyNoCreation() {

        //Test that no discrepancy is created when info from account and dvs service are equal

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "945146975",'
        + '"nic": "00078",'
        + '"siret": "94514697500078",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2021-01-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2021-01-01",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 4",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "4",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "JEAN JAURÈS",'
        + '"codePostalEtablissement": "31160",'
        + '"libelleCommuneEtablissement": "ASPET",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "31100",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2021-01-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 4",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(7, discrepancyListAfter.size());

        Account account = getAccount('COMPANY 4');
        Assert.isTrue(account.SynchronizedWithDvs__c);
        Assert.isTrue(String.isBlank(account.DvsLongError__c));
    }

    @isTest
    public static void discrepancyCreationSpecialCase() {

        //Test that 1 discrepancy is created despite the fact that the account's name contains 'SARL' and the DVS account doesn't 

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "942368741",'
        + '"nic": "00045",'
        + '"siret": "94236874100045",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2017-04-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2017-04-01",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 5",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2017"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "5",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "EMILE ZOLA",'
        + '"codePostalEtablissement": "94700",'
        + '"libelleCommuneEtablissement": "MAISONS-ALFORT",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "94710",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2017-04-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 5",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('SARL COMPANY 5', discrepancyListAfter[7].SalesforceName__c);
        Assert.areEqual('5 rue Émile Zola', discrepancyListAfter[7].SalesforceStreet__c);
        Assert.areEqual('94700', discrepancyListAfter[7].SalesforcePostalCode__c);
        Assert.areEqual('Maisons-Alfort', discrepancyListAfter[7].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[7].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[7].SalesforceId2__c);
        Assert.areEqual('COMPANY 5', discrepancyListAfter[7].DvsName__c);
        Assert.areEqual('5 RUE EMILE ZOLA', discrepancyListAfter[7].DvsStreet__c);
        Assert.areEqual('94700', discrepancyListAfter[7].DvsPostalCode__c);
        Assert.areEqual('MAISONS-ALFORT', discrepancyListAfter[7].DvsCity__c);
        Assert.areEqual('94236874100045', discrepancyListAfter[7].DvsId__c);
        Assert.areEqual('942368741', discrepancyListAfter[7].DvsId2__c);

        Account account = getAccount('SARL COMPANY 5');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(String.isBlank(account.DvsLongError__c));
    }

    @isTest
    public static void discrepancyCreationAccents() {

        //Test that 1 discrepancy is created despite the fact that the account's name contains an accent and the DVS account doesn't 

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "94751238",'
        + '"nic": "00013",'
        + '"siret": "9475123800013",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2010-02-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2010-02-01",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": null,'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": "COMPANY 6",'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2010"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "6",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "PLACE",'
        + '"libelleVoieEtablissement": "DU 24 AOUT",'
        + '"codePostalEtablissement": "06130",'
        + '"libelleCommuneEtablissement": "GRASSE",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "06130",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2010-02-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('CÔMPÀNY 6', discrepancyListAfter[5].SalesforceName__c);
        Assert.areEqual('6 place du 24 août', discrepancyListAfter[5].SalesforceStreet__c);
        Assert.areEqual('06130', discrepancyListAfter[5].SalesforcePostalCode__c);
        Assert.areEqual('Grasse', discrepancyListAfter[5].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[5].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[5].SalesforceId2__c);
        Assert.areEqual('COMPANY 6', discrepancyListAfter[5].DvsName__c);
        Assert.areEqual('6 PLACE DU 24 AOUT', discrepancyListAfter[5].DvsStreet__c);
        Assert.areEqual('06130', discrepancyListAfter[5].DvsPostalCode__c);
        Assert.areEqual('GRASSE', discrepancyListAfter[5].DvsCity__c);
        Assert.areEqual('9475123800013', discrepancyListAfter[5].DvsId__c);
        Assert.areEqual('94751238', discrepancyListAfter[5].DvsId2__c);

        Account account = getAccount('CÔMPÀNY 6');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(String.isBlank(account.DvsLongError__c));
    }

    @isTest
    public static void discrepancyCreationSpecialCharacter() {

        //Test that 1 discrepancy is created despite the fact that the account's name contains '"' and the DVS account doesn't 
        // 6 discrepancies without DVS info should be created

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "94254724",'
        + '"nic": "00053",'
        + '"siret": "9425472400053",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2015-06-30",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2015-06-30",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": null,'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2015"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "7",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "TRAVERSE",'
        + '"libelleVoieEtablissement": "DU PONT",'
        + '"codePostalEtablissement": "69000",'
        + '"libelleCommuneEtablissement": "LYON",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "69100",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2015-06-30",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 7",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(8, discrepancyListAfter.size());

        Assert.areEqual('COMPANY "7"', discrepancyListAfter[0].SalesforceName__c);
        Assert.areEqual('7 Traverse du Pont', discrepancyListAfter[0].SalesforceStreet__c);
        Assert.areEqual('69000', discrepancyListAfter[0].SalesforcePostalCode__c);
        Assert.areEqual('Lyon', discrepancyListAfter[0].SalesforceCity__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId__c);
        Assert.isNull(discrepancyListAfter[0].SalesforceId2__c);
        Assert.areEqual('COMPANY 7', discrepancyListAfter[0].DvsName__c);
        Assert.areEqual('7 TRAVERSE DU PONT', discrepancyListAfter[0].DvsStreet__c);
        Assert.areEqual('69000', discrepancyListAfter[0].DvsPostalCode__c);
        Assert.areEqual('LYON', discrepancyListAfter[0].DvsCity__c);
        Assert.areEqual('9425472400053', discrepancyListAfter[0].DvsId__c);
        Assert.areEqual('94254724', discrepancyListAfter[0].DvsId2__c);

        Account account = getAccount('COMPANY "7"');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(String.isBlank(account.DvsLongError__c));
    }

    @isTest
    public static void error404() {

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '   "header": {'
        + '        "statut": 404,'
        + '       "message": "Aucun élément trouvé pour q=(raisonSociale:"*COMPANY 1*" AND codePostalEtablissement:33000)"'
        + '    }'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(404, 'FAIL', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Account account = getAccount('COMPANY 1');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(account.DvsLongError__c.contains('No company was found with the criteria you specified.'));
    }

    @isTest
    public static void error400() {

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '   "header": {'
        + '        "statut": 404,'
        + '       "message": "Aucun élément trouvé pour q=(raisonSociale:"*COMPANY 1*" AND codePostalEtablissement:33000)"'
        + '    }'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(400, 'FAIL', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Account account = getAccount('COMPANY 1');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(account.DvsLongError__c.contains('Aucun élément trouvé pour q=(raisonSociale:"*COMPANY 1*" AND codePostalEtablissement:33000)'));
    }

    @isTest
    public static void error401() {

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '    "fault": {'
        + '        "code": 900901,'
        + '        "message": "Invalid Credentials",'
        + '        "description": "Access failure for API: /entreprises/sirene/V3.11, version: V3.11 status: (900901) - Invalid Credentials. Make sure you have given the correct access token"'
        + '    }'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(401, 'FAIL', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Account account = getAccount('COMPANY 1');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(account.DvsLongError__c.contains('Invalid Credentials. Make sure you have given the correct access token.'));
    }

    @isTest
    public static void error403() {

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '   "header": {'
        + '        "statut": 403,'
        + '       "message": "Accès interdit."'
        + '    }'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(403, 'FAIL', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Account account = getAccount('COMPANY 1');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(account.DvsLongError__c.contains('Search for companies matching the search criteria has failed: [403].'));
    }

    @isTest
    public static void errorException() {

        List<DvsDiscrepancy__c> discrepancyList = getDiscrepancies();
        Assert.isTrue(discrepancyList.isEmpty());


        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + 'header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 4,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "845021578",'
        + '"nic": "00016",'
        + '"siret": "94844632300016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 3",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        List<DvsSetting__mdt> settings = getDVSSettings('FR');
        Assert.areEqual(1, settings.size());

        Test.startTest();
        DvsBatchController batch = new DvsBatchController(settings[0]);
        Database.executeBatch(batch, (Integer) settings[0].BatchSize__c);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Account account = getAccount('COMPANY 1');
        Assert.isFalse(account.SynchronizedWithDvs__c);
        Assert.isTrue(account.DvsLongError__c.contains('EXCEPTION: '));
    }

    @isTest
    public static void testBatchScheduler() {

        Test.startTest();
        Datetime scheduledDate = Datetime.now().addDays(1);
        String CRON_EXP = scheduledDate.second() + ' ' + scheduledDate.minute() + ' ' + scheduledDate.hour() + ' ' + scheduledDate.day() + ' ' + scheduledDate.month() + ' ' + ' ? ' + scheduledDate.year();
        DvsScheduler schedulable = new DvsScheduler();
        String jobId = System.schedule('ScheduledTask', CRON_EXP, schedulable);

        Test.stopTest();

        CronTrigger ct = [SELECT Id, 
                                CronExpression, 
                                TimesTriggered, 
                                NextFireTime
                            FROM CronTrigger 
                            WHERE id = :jobId
                            ];

        Assert.areEqual(0, ct.TimesTriggered);
        Assert.areEqual(CRON_EXP, ct.CronExpression);
    }

    @isTest
    public static void testGetCompaniesBySIRET() {

        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret/94844632300016';

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1'
        + '},'
        + '"etablissement": {'
        + '"siren": "948446323",'
        + '"nic": "00016",'
        + '"siret": "94844632300016",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2019-01-02",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 2,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2019-01-02",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 3",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "3",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "PLACE",'
        + '"libelleVoieEtablissement": "DE LA REPUBLIQUE",'
        + '"codePostalEtablissement": "75001",'
        + '"libelleCommuneEtablissement": "PARIS",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "75001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": null,'
        + '"dateDebut": "2022-09-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 3",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "O",'
        + '"changementCaractereEmployeurEtablissement": true'
        + '},'
        + '{'
        + '"dateFin": "2022-08-31",'
        + '"dateDebut": "2019-01-02",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 3",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + '}';



        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        Account account = getAccount('Company 3');
        CompanyInfosInput input = new CompanyInfosInput();
        input.idNumber = account.VAT_Number__c;
        input.id = account.Id;
        Boolean fuzzySearch = false;

        Test.startTest();
        CompanyInfosResult result = DvsService.getCompanies(input, fuzzySearch);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Assert.areEqual(1, result.singleSearchSocieties.size());
        Assert.areEqual('94844632300016', result.singleSearchSocieties[0].get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('948446323', result.singleSearchSocieties[0].get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('COMPANY 3', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('3 PLACE DE LA REPUBLIQUE', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('75001', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('PARIS', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));

        Assert.areEqual('COMPANY 3', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('94844632300016', result.currentAccount.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.isNull(result.currentAccount.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('3 place de la République', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('75001', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Paris', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));

        Assert.areEqual('', result.message);
        Assert.isTrue(result.success);
    }

    @isTest
    public static void testGetCompaniesBySIREN() {

        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret?q=' + InseeDvsService.SIREN_PARAM + ':' + '945146975' + '&' + InseeDvsService.NOMBRE_PARAM + '=' + String.valueOf(InseeDvsService.pageSize);

        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 1,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "945146975",'
        + '"nic": "00078",'
        + '"siret": "94514697500078",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2021-01-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2021-01-01",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 4",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "4",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "JEAN JAURÈS",'
        + '"codePostalEtablissement": "31160",'
        + '"libelleCommuneEtablissement": "ASPET",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "31100",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2021-01-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 4",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);

        Test.setMock(HttpCalloutMock.class, mock);

        Account account = getAccount('Company 4');
        CompanyInfosInput input = new CompanyInfosInput();
        input.idNumber = account.VAT_Number_2__c;
        input.id = account.Id;
        Boolean fuzzySearch = false;

        Test.startTest();
        CompanyInfosResult result = DvsService.getCompanies(input, fuzzySearch);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Assert.areEqual(1, result.singleSearchSocieties.size());
        Assert.areEqual('94514697500078', result.singleSearchSocieties[0].get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.singleSearchSocieties[0].get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('COMPANY 4', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('4 AVENUE JEAN JAURÈS', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('ASPET', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));

        Assert.areEqual('COMPANY 4', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('94514697500078', result.currentAccount.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.AREeQUAL('945146975', result.currentAccount.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('4 avenue Jean Jaurès', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Aspet', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));

        Assert.areEqual('',result.message);
        Assert.isTrue(result.success);
    }

    @isTest
    public static void testGetCompaniesByName() {

        String tokenEndpoint = 'https://api.insee.fr/api-sirene/3.11/token?grant_type=client_credentials';
        String name = EncodingUtil.urlEncode('"SARL Company 5"~3', 'UTF-8');
        String postalCode = EncodingUtil.urlEncode('"94700"', 'UTF-8');
        String openParenthesis = EncodingUtil.urlEncode(' AND (', 'UTF-8');
        String closeParenthesis = EncodingUtil.urlEncode(')', 'UTF-8');

        String requestEndpoint = 'https://api.insee.fr/api-sirene/3.11/siret?q=' + InseeDvsService.NAME_PARAM + ':' + name + openParenthesis + InseeDvsService.POSTAL_CODE_PARAM + ':' + postalCode + closeParenthesis + '&' + InseeDvsService.NOMBRE_PARAM + '=' + String.valueOf(InseeDvsService.pageSize);
        System.debug(requestEndpoint);
        String tokenResponse = '{'
        + '"access_token": "0cg9f2zh-1574-5q14-bskh-5b84543v8a15",'
        + '"scope": "am_application_scope default",'
        + '"token_type": "Bearer",'
        + '"expires_in": 604800'
        + '}';
        String requestResponse = '{'
        + '"header": {'
        + '"statut": 200,'
        + '"message": "OK",'
        + '"total": 2,'
        + '"debut": 0,'
        + '"nombre": 1000'
        + '},'
        + '"etablissements": ['
        + '{'
        + '"siren": "945143216",'
        + '"nic": "00046",'
        + '"siret": "94514321600046",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2021-01-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2021-01-01",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "COMPANY 5",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "5",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "RUE",'
        + '"libelleVoieEtablissement": "EMILE ZOLA",'
        + '"codePostalEtablissement": "94700",'
        + '"libelleCommuneEtablissement": "MAISONS-ALFORT",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "947001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2021-01-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": "COMPANY 5",'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '},'
        + '{'
        + '"siren": "945146975",'
        + '"nic": "00078",'
        + '"siret": "94514697500078",'
        + '"statutDiffusionEtablissement": "O",'
        + '"dateCreationEtablissement": "2021-01-01",'
        + '"trancheEffectifsEtablissement": null,'
        + '"anneeEffectifsEtablissement": null,'
        + '"activitePrincipaleRegistreMetiersEtablissement": null,'
        + '"dateDernierTraitementEtablissement": "2024-03-30T02:58:28.579",'
        + '"etablissementSiege": true,'
        + '"nombrePeriodesEtablissement": 1,'
        + '"uniteLegale": {'
        + '"etatAdministratifUniteLegale": "A",'
        + '"statutDiffusionUniteLegale": "O",'
        + '"dateCreationUniteLegale": "2021-01-01",'
        + '"categorieJuridiqueUniteLegale": "5499",'
        + '"denominationUniteLegale": "LA 5e COMPANY",'
        + '"sigleUniteLegale": "C3",'
        + '"denominationUsuelle1UniteLegale": null,'
        + '"denominationUsuelle2UniteLegale": null,'
        + '"denominationUsuelle3UniteLegale": null,'
        + '"sexeUniteLegale": null,'
        + '"nomUniteLegale": null,'
        + '"nomUsageUniteLegale": null,'
        + '"prenom1UniteLegale": null,'
        + '"prenom2UniteLegale": null,'
        + '"prenom3UniteLegale": null,'
        + '"prenom4UniteLegale": null,'
        + '"prenomUsuelUniteLegale": null,'
        + '"pseudonymeUniteLegale": null,'
        + '"activitePrincipaleUniteLegale": "62.01Z",'
        + '"nomenclatureActivitePrincipaleUniteLegale": "NAFRev2",'
        + '"identifiantAssociationUniteLegale": null,'
        + '"economieSocialeSolidaireUniteLegale": "N",'
        + '"societeMissionUniteLegale": null,'
        + '"caractereEmployeurUniteLegale": null,'
        + '"trancheEffectifsUniteLegale": null,'
        + '"anneeEffectifsUniteLegale": null,'
        + '"nicSiegeUniteLegale": "00011",'
        + '"dateDernierTraitementUniteLegale": "2024-03-22T09:28:19.000",'
        + '"categorieEntreprise": "PME",'
        + '"anneeCategorieEntreprise": "2021"'
        + '},'
        + '"adresseEtablissement": {'
        + '"complementAdresseEtablissement": null,'
        + '"numeroVoieEtablissement": "87",'
        + '"indiceRepetitionEtablissement": null,'
        + '"dernierNumeroVoieEtablissement": null,'
        + '"indiceRepetitionDernierNumeroVoieEtablissement": null,'
        + '"typeVoieEtablissement": "AVENUE",'
        + '"libelleVoieEtablissement": "JEAN JAURÈS",'
        + '"codePostalEtablissement": "94700",'
        + '"libelleCommuneEtablissement": "MAISONS-ALFORT",'
        + '"libelleCommuneEtrangerEtablissement": null,'
        + '"distributionSpecialeEtablissement": null,'
        + '"codeCommuneEtablissement": "947001",'
        + '"codeCedexEtablissement": null,'
        + '"libelleCedexEtablissement": null,'
        + '"codePaysEtrangerEtablissement": null,'
        + '"libellePaysEtrangerEtablissement": null,'
        + '"identifiantAdresseEtablissement": "060840242_B",'
        + '"coordonneeLambertAbscisseEtablissement": "1020236.6767952743",'
        + '"coordonneeLambertOrdonneeEtablissement": "6288687.991507278"'
        + '},'
        + '"adresse2Etablissement": {'
        + '"complementAdresse2Etablissement": null,'
        + '"numeroVoie2Etablissement": null,'
        + '"indiceRepetition2Etablissement": null,'
        + '"typeVoie2Etablissement": null,'
        + '"libelleVoie2Etablissement": null,'
        + '"codePostal2Etablissement": null,'
        + '"libelleCommune2Etablissement": null,'
        + '"libelleCommuneEtranger2Etablissement": null,'
        + '"distributionSpeciale2Etablissement": null,'
        + '"codeCommune2Etablissement": null,'
        + '"codeCedex2Etablissement": null,'
        + '"libelleCedex2Etablissement": null,'
        + '"codePaysEtranger2Etablissement": null,'
        + '"libellePaysEtranger2Etablissement": null'
        + '},'
        + '"periodesEtablissement": ['
        + '{'
        + '"dateFin": "",'
        + '"dateDebut": "2021-01-01",'
        + '"etatAdministratifEtablissement": "A",'
        + '"changementEtatAdministratifEtablissement": false,'
        + '"enseigne1Etablissement": null,'
        + '"enseigne2Etablissement": null,'
        + '"enseigne3Etablissement": null,'
        + '"changementEnseigneEtablissement": false,'
        + '"denominationUsuelleEtablissement": null,'
        + '"changementDenominationUsuelleEtablissement": false,'
        + '"activitePrincipaleEtablissement": "62.01Z",'
        + '"nomenclatureActivitePrincipaleEtablissement": "NAFRev2",'
        + '"changementActivitePrincipaleEtablissement": false,'
        + '"caractereEmployeurEtablissement": "N",'
        + '"changementCaractereEmployeurEtablissement": false'
        + '}'
        + ']'
        + '}'
        + ']'
        + '}';

        Map<TestMockFactory.MockEndpoint, HttpResponse> responses = new Map<TestMockFactory.MockEndpoint, HttpResponse>();

        responses.put(new TestMockFactory.MockEndpoint(tokenEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS', tokenResponse));
        responses.put(new TestMockFactory.MockEndpoint(requestEndpoint, -1), TestMockFactory.getHttpResponse(200, 'SUCCESS ', requestResponse));

        TestMockFactory mock = new TestMockFactory(responses);
        mock.setDefaultResponse(200, 'SUCCESS', requestResponse);

        Test.setMock(HttpCalloutMock.class, mock);

        Account account = getAccount('SARL company 5');
        CompanyInfosInput input = new CompanyInfosInput();
        input.name = account.Name;
        input.postalCode = account.BillingPostalCode;
        input.id = account.Id;
        Boolean fuzzySearch = true;

        Test.startTest();
        CompanyInfosResult result = DvsService.getCompanies(input, fuzzySearch);
        Test.stopTest();

        List<DvsDiscrepancy__c> discrepancyListAfter = getDiscrepancies();
        System.debug('Discrepancies number after test: ' + discrepancyListAfter.size());

        Assert.areEqual(0, discrepancyListAfter.size());

        Assert.areEqual(2, result.singleSearchSocieties.size());
        Assert.areEqual('94514321600046', result.singleSearchSocieties[0].get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945143216', result.singleSearchSocieties[0].get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('COMPANY 5', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('5 RUE EMILE ZOLA', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('94700', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('MAISONS-ALFORT', result.singleSearchSocieties[0].get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));
        
        Assert.areEqual('94514697500078', result.singleSearchSocieties[1].get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.singleSearchSocieties[1].get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('LA 5e COMPANY', result.singleSearchSocieties[1].get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('87 AVENUE JEAN JAURÈS', result.singleSearchSocieties[1].get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('94700', result.singleSearchSocieties[1].get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('MAISONS-ALFORT', result.singleSearchSocieties[1].get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));

        Assert.areEqual('SARL COMPANY 5', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.isNull(result.currentAccount.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.isNull(result.currentAccount.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
        Assert.areEqual('5 rue Émile Zola', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('94700', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Maisons-Alfort', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));

        Assert.areEqual('',result.message);
        Assert.isTrue(result.success);
    }

    @isTest
    public static void testGetDiscrepanciesThroughAccount() {
        
        Account account = getAccount('Company 4');

        DvsDiscrepancy__c discrepancy = new DvsDiscrepancy__c(
            DVSName__c = 'COMPANY 4',
            DVSStreet__c = '55 AVENUE JEAN JAURÈS',
            DVSPostalCode__c = '31160',
            DVSCity__c = 'Aspet',
            DVSId__c = '94514697500078',
            DVSId2__c = '945146975',
            SalesforceName__c = 'Company 4',
            SalesforceStreet__c = '4 avenue Jean Jaurès',
            SalesforcePostalCode__c = '31160',
            SalesforceCity__c = 'Aspet',
            SalesforceId__c = '94514697500078',
            SalesforceId2__c = '945146975',
            Account__c = account.Id
        );

        insert discrepancy;

        String objectName = 'Account';
        

        Test.startTest();
        CompanyInfosResult result = DvsService.getDiscrepancy(account.Id, objectName);
        Test.stopTest();

        Assert.areEqual(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, result.fieldLabels.get('Name'));
        Assert.areEqual(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, result.fieldLabels.get('Id1'));
        Assert.areEqual(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, result.fieldLabels.get('Id2'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_ADDRESS_FIELD_LABEL, result.fieldLabels.get('Address'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, result.fieldLabels.get('Street'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, result.fieldLabels.get('PostalCode'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, result.fieldLabels.get('City'));
        Assert.areEqual(ModalResultFieldLabels.FR_SEARCH_BY_ID_LABEL, result.fieldLabels.get('SearchById'));

        Assert.areEqual('COMPANY 4', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('55 AVENUE JEAN JAURÈS', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Aspet', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));
        Assert.areEqual('94514697500078', result.singleSearchSociety.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.singleSearchSociety.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));

        Assert.areEqual('The following discrepancy has been found', result.searchStatus);

        Assert.areEqual('COMPANY 4', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('4 avenue Jean Jaurès', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Aspet', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));
        Assert.areEqual('94514697500078', result.currentAccount.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.currentAccount.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
    }

    @isTest
    public static void testGetDiscrepanciesThroughDiscrepancy() {
        
        Account account = getAccount('Company 4');

        DvsDiscrepancy__c discrepancy = new DvsDiscrepancy__c(
            DVSName__c = 'COMPANY 4',
            DVSStreet__c = '55 AVENUE JEAN JAURÈS',
            DVSPostalCode__c = '31160',
            DVSCity__c = 'Aspet',
            DVSId__c = '94514697500078',
            DVSId2__c = '945146975',
            SalesforceName__c = 'Company 4',
            SalesforceStreet__c = '4 avenue Jean Jaurès',
            SalesforcePostalCode__c = '31160',
            SalesforceCity__c = 'Aspet',
            SalesforceId__c = '94514697500078',
            SalesforceId2__c = '945146975',
            Account__c = account.Id
        );

        insert discrepancy;

        String objectName = 'DvsDiscrepancy__c';
        

        Test.startTest();
        CompanyInfosResult result = DvsService.getDiscrepancy(discrepancy.Id, objectName);
        Test.stopTest();

        Assert.areEqual(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, result.fieldLabels.get('Name'));
        Assert.areEqual(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, result.fieldLabels.get('Id1'));
        Assert.areEqual(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, result.fieldLabels.get('Id2'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_ADDRESS_FIELD_LABEL, result.fieldLabels.get('Address'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, result.fieldLabels.get('Street'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, result.fieldLabels.get('PostalCode'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, result.fieldLabels.get('City'));
        Assert.areEqual(ModalResultFieldLabels.FR_SEARCH_BY_ID_LABEL, result.fieldLabels.get('SearchById'));

        Assert.areEqual('COMPANY 4', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('55 AVENUE JEAN JAURÈS', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Aspet', result.singleSearchSociety.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));
        Assert.areEqual('94514697500078', result.singleSearchSociety.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.singleSearchSociety.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));

        Assert.areEqual('The following discrepancy has been found', result.searchStatus);

        Assert.areEqual('COMPANY 4', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('4 avenue Jean Jaurès', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Aspet', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));
        Assert.areEqual('94514697500078', result.currentAccount.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.currentAccount.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
    }

    @isTest
    public static void testGetDiscrepanciesNoDiscrepancy() {
        
        Account account = getAccount('Company 4');

        String objectName = 'Account';
        

        Test.startTest();
        CompanyInfosResult result = DvsService.getDiscrepancy(account.Id, objectName);
        Test.stopTest();

        Assert.areEqual(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, result.fieldLabels.get('Name'));
        Assert.areEqual(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, result.fieldLabels.get('Id1'));
        Assert.areEqual(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, result.fieldLabels.get('Id2'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_ADDRESS_FIELD_LABEL, result.fieldLabels.get('Address'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, result.fieldLabels.get('Street'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, result.fieldLabels.get('PostalCode'));
        Assert.areEqual(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, result.fieldLabels.get('City'));
        Assert.areEqual(ModalResultFieldLabels.FR_SEARCH_BY_ID_LABEL, result.fieldLabels.get('SearchById'));

        Assert.isNull(result.singleSearchSociety);

        Assert.areEqual('The discrepancy search has not been performed yet or no discrepancy has been found', result.searchStatus);

        Assert.areEqual('COMPANY 4', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL));
        Assert.areEqual('4 avenue Jean Jaurès', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL));
        Assert.areEqual('31160', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL));
        Assert.areEqual('Aspet', result.currentAccount.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL));
        Assert.areEqual('94514697500078', result.currentAccount.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL));
        Assert.areEqual('945146975', result.currentAccount.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL));
    }

    @isTest
    public static void testApplyChanges() {
        
        Account account = getAccount('Company 4');

        DvsDiscrepancy__c discrepancy = new DvsDiscrepancy__c(
            DVSName__c = 'COMPANY 4',
            DVSStreet__c = '55 AVENUE JEAN JAURÈS',
            DVSPostalCode__c = '31160',
            DVSCity__c = 'Aspet',
            DVSId__c = '94514697500078',
            DVSId2__c = '945146975',
            SalesforceName__c = 'Company 4',
            SalesforceStreet__c = '4 avenue Jean Jaurès',
            SalesforcePostalCode__c = '31160',
            SalesforceCity__c = 'Aspet',
            SalesforceId__c = '94514697500078',
            SalesforceId2__c = '945146975',
            Account__c = account.Id
        );

        insert discrepancy;

        List<DvsDiscrepancy__c> discrepanciesListBefore = getDiscrepancies();
        Assert.areEqual(1, discrepanciesListBefore.size());

        Boolean discardChanges = false;

        Map<String, String> company = new Map<String, String>();
        company.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, discrepancy.DVSName__c);
        company.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, discrepancy.DVSStreet__c);
        company.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, discrepancy.DVSPostalCode__c);
        company.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, discrepancy.DVSCity__c);
        company.put(ModalResultFieldLabels.GLOBAL_COUNTRY_FIELD_LABEL, 'France');
        company.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, discrepancy.DVSId__c);
        company.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, discrepancy.DVSId2__c);


        Test.startTest();
        UpdateCompanyResult result = DvsService.applyChanges(company, account.Id, discardChanges);
        Test.stopTest();

        Account accountAfterApply = getAccount('Company 4');

        Assert.areEqual(discrepancy.DVSStreet__c, accountAfterApply.BillingStreet);
        Assert.isTrue(accountAfterApply.SynchronizedWithDvs__c);

        List<DvsDiscrepancy__c> discrepanciesList = getDiscrepancies();
        Assert.areEqual(0, discrepanciesList.size());
        
    }

    @isTest
    public static void testConfirmNoResults() {
        
        Account account = getAccount('Company 4');

        DvsDiscrepancy__c discrepancy = new DvsDiscrepancy__c(
            DVSName__c = 'COMPANY 4',
            DVSStreet__c = '55 AVENUE JEAN JAURÈS',
            DVSPostalCode__c = '31160',
            DVSCity__c = 'Aspet',
            DVSId__c = '94514697500078',
            DVSId2__c = '945146975',
            SalesforceName__c = 'Company 4',
            SalesforceStreet__c = '4 avenue Jean Jaurès',
            SalesforcePostalCode__c = '31160',
            SalesforceCity__c = 'Aspet',
            SalesforceId__c = '94514697500078',
            SalesforceId2__c = '945146975',
            Account__c = account.Id
        );

        insert discrepancy;

        List<DvsDiscrepancy__c> discrepanciesListBefore = getDiscrepancies();
        Assert.areEqual(1, discrepanciesListBefore.size());

        Boolean discardChanges = false;

        Map<String, String> company = new Map<String, String>();
        company.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, discrepancy.DVSName__c);
        company.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, discrepancy.DVSStreet__c);
        company.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, discrepancy.DVSPostalCode__c);
        company.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, discrepancy.DVSCity__c);
        company.put(ModalResultFieldLabels.GLOBAL_COUNTRY_FIELD_LABEL, 'France');
        company.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, discrepancy.DVSId__c);
        company.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, discrepancy.DVSId2__c);


        Test.startTest();
        UpdateCompanyResult result = DvsService.confirmNoResults(account.Id);
        Test.stopTest();

        Account accountAfterApply = getAccount('Company 4');

        Assert.areEqual('UNKNOWN', accountAfterApply.DvsAction__c);
        //Assert.isFalse(accountAfterApply.SynchronizedWithDvs__c);
    }

    @isTest
    public static void testDiscardChanges() {
        
        Account account = getAccount('Company 4');

        DvsDiscrepancy__c discrepancy = new DvsDiscrepancy__c(
            DVSName__c = 'COMPANY 4',
            DVSStreet__c = '55 AVENUE JEAN JAURÈS',
            DVSPostalCode__c = '31160',
            DVSCity__c = 'Aspet',
            DVSId__c = '94514697500078',
            DVSId2__c = '945146975',
            SalesforceName__c = 'Company 4',
            SalesforceStreet__c = '4 avenue Jean Jaurès',
            SalesforcePostalCode__c = '31160',
            SalesforceCity__c = 'Aspet',
            SalesforceId__c = '94514697500078',
            SalesforceId2__c = '945146975',
            Account__c = account.Id
        );

        insert discrepancy;

        List<DvsDiscrepancy__c> discrepanciesListBefore = getDiscrepancies();
        Assert.areEqual(1, discrepanciesListBefore.size());

        Boolean discardChanges = true;

        Map<String, String> company = new Map<String, String>();
        company.put(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL, discrepancy.DVSName__c);
        company.put(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL, discrepancy.DVSStreet__c);
        company.put(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL, discrepancy.DVSPostalCode__c);
        company.put(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL, discrepancy.DVSCity__c);
        company.put(ModalResultFieldLabels.GLOBAL_COUNTRY_FIELD_LABEL, 'France');
        company.put(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL, discrepancy.DVSId__c);
        company.put(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL, discrepancy.DVSId2__c);


        Test.startTest();
        UpdateCompanyResult result = DvsService.applyChanges(company, account.Id, discardChanges);
        Test.stopTest();

        Account accountAfterApply = getAccount('Company 4');

        Assert.areEqual(discrepancy.SalesforceStreet__c, accountAfterApply.BillingStreet);
        Assert.isTrue(accountAfterApply.SynchronizedWithDvs__c);

        List<DvsDiscrepancy__c> discrepanciesList = getDiscrepancies();
        Assert.areEqual(0, discrepanciesList.size());
        
    }

    private static List<DvsSetting__mdt> getDVSSettings(String countryCode) {

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
                ];
    }

    private static List<DvsDiscrepancy__c> getDiscrepancies() {

        return [SELECT Id, 
                        DvsName__c,
                        DvsId__c,
                        DvsId2__c,
                        DvsStreet__c,
                        DvsCity__c,
                        DvsPostalCode__c,
                        SalesforceName__c,
                        SalesforceId__c,
                        SalesforceId2__c,
                        SalesforceStreet__c,
                        SalesforceCity__c,
                        SalesforcePostalCode__c
                        FROM DvsDiscrepancy__c 
                        ORDER BY SalesforceName__c ASC
                        ];
    }

    private static Account getAccount(String accountName) {

        return [SELECT Id, 
        SynchronizedWithDvs__c, 
                        DvsLongError__c,
                        VAT_Number__c,
                        VAT_Number_2__c,
                        BillingStreet,
                        Name,
                        BillingPostalCode,
                        DvsAction__c
                FROM Account
                WHERE Name = :accountName];
    }
}