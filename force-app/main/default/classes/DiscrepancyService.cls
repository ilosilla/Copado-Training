/**
 * Definition of the Discrepancy service
 * For each country, an implementation of this abstract class shall be provided.
 */
public abstract class DiscrepancyService {

    /**
     * From a list of accounts and a DVS configuration, retrieves the company official information call the API
     */
    public abstract DvsResponseDto getOfficialInformation(List<Account> accounts, DvsSetting__mdt dvsSettings, Boolean fuzzySearch);

    /**
     * Checks whether there is a difference between Account fields and returned company information
     */
    public abstract Boolean isInformationDifferent(Account account, DvsResponseDto.Company companyDto);
    
    /**
     * Creates and fill discrepancy custom object information.
     * If a discrepancy already exists for the given account, then it updates it.
     */
    public abstract DvsDiscrepancy__c createDiscrepancy(Account account, DvsResponseDto.Company companyDto);

    /**
     * Applies discrepancies to the account fields
     */
    public abstract List<Account> correctDiscrepancies(List<DvsDiscrepancy__c> discrepancies, List<Account> accounts);

    /**
     * Checks whether at least one account field relative to discrepancy verification has been modified
     */
    public abstract Boolean hasDiscrepancyChanged(Account newAccount, Account oldAccount);

    /**
     * Ignore the discrepancy.
     * This is independant of the service implementation (only check Account check box)
     */
    public virtual List<Account> ignoreDiscrepancies(List<Account> accounts) {
        for (Account account : accounts) {
            account.SynchronizedWithDvs__c = true;
        }
        
        return accounts;
    }

    /**
     * Retrieve official information from DVS service. Search initiated in the account 
     */
    public abstract CompanyInfosResult getCompanies(CompanyInfosInput input, Account account, DvsSetting__mdt dvsSettings, Boolean fuzzySearch);

    public abstract UpdateCompanyResult applyNoResults(Account account);

    public abstract UpdateCompanyResult applyChanges(Map<String, String> company, Account account, Boolean discardChanges);

    public abstract CompanyInfosResult getDiscrepancy(Id accountId);
}