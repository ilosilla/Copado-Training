public with sharing class Etablissement {
		
    public String siren;
    public String nic;
    public String siret;
    public String statutDiffusionEtablissement;
    public String dateCreationEtablissement;
    public String trancheEffectifsEtablissement;
    public String anneeEffectifsEtablissement;
    public String activitePrincipaleRegistreMetiersEtablissement;
    public String dateDernierTraitementEtablissement;
    public Boolean etablissementSiege;
    public String nombrePeriodesEtablissement;
    public UniteLegale uniteLegale;
    public AdresseEtablissement adresseEtablissement;
    public Adresse2Etablissement adresse2Etablissement;
    public PeriodesEtablissement[] periodesEtablissement;

    public class UniteLegale {
		public String etatAdministratifUniteLegale;
		public String statutDiffusionUniteLegale;
        public Boolean unitePurgeeUniteLegale;
        public String dateCreationUniteLegale;
		public String categorieJuridiqueUniteLegale;
        public String denominationUniteLegale;
		public String sigleUniteLegale;
		public String denominationUsuelle1UniteLegale;
		public String denominationUsuelle2UniteLegale;
		public String denominationUsuelle3UniteLegale;
		public String sexeUniteLegale;
		public String nomUniteLegale;
		public String nomUsageUniteLegale;
		public String prenom1UniteLegale;
		public String prenom2UniteLegale;
		public String prenom3UniteLegale;
		public String prenom4UniteLegale;
		public String prenomUsuelUniteLegale;
		public String pseudonymeUniteLegale;
        public String activitePrincipaleUniteLegale;
        public String nomenclatureActivitePrincipaleUniteLegale;
		public String identifiantAssociationUniteLegale;
		public String economieSocialeSolidaireUniteLegale;
		public String societeMissionUniteLegale;
		public String caractereEmployeurUniteLegale;
		public String trancheEffectifsUniteLegale;
		public String anneeEffectifsUniteLegale;
		public String nicSiegeUniteLegale;
		public String dateDernierTraitementUniteLegale;
        public String categorieEntreprise;
		public Integer anneeCategorieEntreprise;
    }

    public class AdresseEtablissement {
         
        public String complementAdresseEtablissement;
        public String numeroVoieEtablissement;
        public String typeVoieEtablissement;
        public String libelleVoieEtablissement;
        public String codePostalEtablissement;
        public String libelleCommuneEtablissement;
        public String libelleCommuneEtrangerEtablissement;
        public String distributionSpecialeEtablissement;
        public String codeCommuneEtablissement;
        public String codeCedexEtablissement;
        public String libelleCedexEtablissement;
        public String codePaysEtrangerEtablissement;
        public String libellePaysEtrangerEtablissement;
        public String indiceRepetitionEtablissement;
    }

    public class Adresse2Etablissement {
        public String complementAdresse2Etablissement;
        public String numeroVoie2Etablissement;
        public String indiceRepetition2Etablissement;
        public String typeVoie2Etablissement;
        public String libelleVoie2Etablissement;
        public String codePostal2Etablissement;
        public String libelleCommune2Etablissement;
        public String libelleCommune2EtrangerEtablissement;
        public String distributionSpeciale2Etablissement;
        public String codeCommune2Etablissement;
        public String codeCedex2Etablissement;
        public String libelleCedex2Etablissement;
        public String codePaysEtranger2Etablissement;
        public String libellePaysEtranger2Etablissement;
    }

    public class PeriodesEtablissement {
        public String dateFin;
        public String dateDebut;
        public String etatAdministratifEtablissement;
        public Boolean changementEtatAdministratifEtablissement;
        public String enseigne1Etablissement;
        public String enseigne2Etablissement;
        public String enseigne3Etablissement;
        public Boolean changementEnseigneEtablissement;
        public String denominationUsuelleEtablissement;
        public Boolean changementDenominationUsuelleEtablissement;
        public String activitePrincipaleEtablissement;
        public String nomenclatureActivitePrincipaleEtablissement;
        public Boolean changementActivitePrincipaleEtablissement;
        public String caractereEmployeurEtablissement;
        public Boolean changementCaractereEmployeurEtablissement;
    }
}