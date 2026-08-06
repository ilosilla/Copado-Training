public with sharing class SiretInfos {

    public Header header;
    public List<Etablissement> etablissements;

    public class Header {

        public Integer statut;
        public String message;
        public Integer total;
        public Integer debut;
        public Integer nombre;
    }
}