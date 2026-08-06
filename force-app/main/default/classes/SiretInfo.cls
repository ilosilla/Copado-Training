public with sharing class SiretInfo {

    public Header header;
    public Etablissement etablissement;

    public class Header {

        public Integer statut;
        public String message;
    }
}