/**
 * @author       Ivan Losilla
 * @since        September 2025
 * @group        Porsamarket
 * @description  PorsaMarket Custom figure class
 * @test PorsaMarketCustomTest
 */
public class PorsaMarketCustom {
    public class PorsamarketCustomException extends Exception {}

    public String accountId;        // Porsamarket Id. SIret on France
    public String pmService;      // Servie of Poramarket. GB, US, HH, etc
    public String projectId;        // if exists on Salesforce, the Id of the Owner
    public Account dataAccount;  // Data taken from porsamarket
    public Opportunity dataProject;  // Data taken from porsamarket
    public String ownerEmail;
    public String ownerName;

    public PorsaMarketCustom() {}

    public static PorsaMarketCustom readCustom(List<string> csvLine) {
        String pmService = csvLine[0];
        String pmProjectId = csvLine[2];
        String pmAccountId = csvLine[3];
        String user = csvLine[4];
        String ownerEmail = csvLine[5];
        String ownerName = csvLine[6];
        String dateParam = csvLine[7];

        PorsaMarketAccount elemAccount = new PorsaMarketAccount();
        elemAccount.accountId = pmAccountId;
        elemAccount.pmService = pmService;
        elemAccount.type = 'ACCOUNT';
        elemAccount.getData();

        PorsaMarketProject elemProject = new PorsaMarketProject();
        elemProject.projectId = pmProjectId;
        elemProject.pmService = pmService;
        elemProject.getData();

        PorsaMarketCustom elemCustom = new PorsaMarketCustom();
        elemCustom.accountId = pmAccountId;
        elemCustom.pmService = pmService;
        elemCustom.projectId = pmProjectId;
        elemCustom.ownerEmail = ownerEmail;
        elemCustom.ownerName = ownerName;
        elemCustom.dataAccount = elemAccount.toAccount();
        elemCustom.dataProject = elemProject.toOpportunity();

        return elemCustom;
    }
}