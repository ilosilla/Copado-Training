public with sharing class DvsResponseDto {
    
    public String message;
    public Map<Id, Company> companiesMap;

    public class Company {
        public String message;
        public Boolean success;
        public String name;
        public String lastName;
        public String firstName;
        public String siret;
        public String siren;
        public String street;
        public String postalCode;
        public String city;
        public Boolean active;

        public Company() {
            this.success = false;
        }
    }
}