/**
 * Factory of DVS service implementations.
 * When implementing a new country, this factory shall be updated to return the discrepancy service
 * corresponding to the new country.
 */
public with sharing class DvsFactory {
   
    /**
     * Returns the right service implementation depending on country code
     */
    public DiscrepancyService getDvsService(String countryCode) {

        switch on countryCode {
            when 'FR' {
                return new InseeDvsService();
            }
            when else {
                return null;
            }
        }
    }
}