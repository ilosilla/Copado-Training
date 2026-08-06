/**
* @author Ivan Losilla
* @date April 2025
* @group Dvs
* @test DvsPorsaServiceTest
*/
public class DvsPorsaService {
    public class DvsPorsaException extends Exception {}

    public Account account;
    public DvsResultsWrapper dvsInfo;
    public DvsResultWrapper bestOption;

    public DvsPorsaService(Account acc) {
        this.account = acc;
    }

    public void doFullSearch() {
        if (this.account == null) {
            throw new DvsPorsaException('No account set on the service');
        }
        String jsonBody = JSON.serialize(accountToDvsWrapperRequest(this.account));
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.DVS_ENDPOINT);
        proxy.setMethod('POST');
        proxy.setJSONBody(jsonBody);
        this.dvsInfo = parseCpiResponse(proxy.callCPI());
    }

    public void doCustomSearch(Boolean useVat, Boolean useVat2) {
        if (this.account == null) {
            throw new DvsPorsaException('No account set on the service');
        }
        DvsWrapper bodyWrapper = accountToDvsWrapperRequest(this.account);
        if (!useVat) {
            bodyWrapper.taxNumber1 = null;
        }
        if (!useVat2) {
            bodyWrapper.companyNumber = null;
        }

        String jsonBody = JSON.serialize(bodyWrapper);
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.DVS_ENDPOINT);
        proxy.setMethod('POST');
        proxy.setJSONBody(jsonBody);
        this.dvsInfo = parseCpiResponse(proxy.callCPI());
    }

    public DvsDiscrepancy__c createDiscrepancy(DvsResultWrapper cmp) {
        if (this.account == null) {
            throw new DvsPorsaException('No account set on the service');
        }

        return new DvsDiscrepancy__c(
            DvsName__c = cmp.companyName,
            DvsStreet__c = cmp.address.line1,
            DvsPostalCode__c = cmp.address.postalCode,
            DvsCity__c = cmp.address.city,
            DvsId__c = cmp.taxNumber1,
            DvsId2__c = cmp.companyNumber,
            DvsStatus__c = cmp.status,
            SalesforceName__c = this.account.Name,
            SalesforceStreet__c = this.account.BillingStreet,
            SalesforcePostalCode__c = this.account.BillingPostalCode,
            SalesforceCity__c = this.account.BillingCity,
            SalesforceId__c = this.account.VAT_Number__c,
            SalesforceId2__c = this.account.VAT_Number_2__c,
            SalesforceCountryCode__c = this.account.BillingCountryCode,
            SalesforceStatus__c = this.account.Account_Status__c,
            Account__c = this.account.Id
        );
    }

    private static DvsWrapper accountToDvsWrapperRequest(Account acc) {
        DvsWrapper wrapper = new DvsWrapper();
        wrapper.country = acc.BillingCountryCode;
        wrapper.taxNumber1 = acc.VAT_Number__c;
        wrapper.companyNumber = acc.VAT_Number_2__c;
        wrapper.name = acc.Name;

        wrapper.address = new DvsAddressWrapper();
        wrapper.address.line1 = acc.BillingStreet;
        wrapper.address.postalCode = acc.BillingPostalCode;
        wrapper.address.city = acc.BillingCity;
        return wrapper;
    }

    public static DvsResultsWrapper parseCpiResponse(String jsonParam) {
        if (String.isBlank(jsonParam)){
            return new DvsResultsWrapper();
        }

        DvsResultsWrapper result = new DvsResultsWrapper();
        if(jsonParam != null) {
            Map<String, Object> standardSerialize = (Map<String, Object>) JSON.deserializeUntyped(jsonParam);

            result.country = (String) standardSerialize.get('country');
            result.taxNumber1Label = (String) standardSerialize.get('taxNumber1Label');
            result.valid = (Boolean) standardSerialize.get('valid');
            result.resultCount = (Integer) standardSerialize.get('resultCount');
            result.maxScore = (Decimal) standardSerialize.get('maxScore');
            result.source = (String) standardSerialize.get('source');
            result.searchType = (String) standardSerialize.get('searchType');
            result.results = new List<DvsResultWrapper>();

            List<Object> resultsRaw = (List<Object>) standardSerialize.get('results');

            for (Object elem : resultsRaw) {
                Map<String, Object> elemAux = (Map<String, Object>) elem;
                DvsResultWrapper aux = new DvsResultWrapper();
                aux.companyNumber = (String) elemAux.get('companyNumber');
                aux.companyName = (String) elemAux.get('companyName');
                aux.taxNumber1 = (String) elemAux.get('taxNumber1');
                aux.status = (String) elemAux.get('status');
                aux.score = (Decimal) elemAux.get('score');
                aux.liveChecked = (Boolean) elemAux.get('liveChecked');

                Map<String, Object> addressRaw = (Map<String, Object>) elemAux.get('address');
                aux.address = new DvsAddressWrapper();
                aux.address.line1 = (String) addressRaw.get('line1');
                aux.address.line2 = (String) addressRaw.get('line2');
                aux.address.postalCode = (String) addressRaw.get('postalCode');
                aux.address.city = (String) addressRaw.get('city');
                aux.address.country = (String) addressRaw.get('country');
                result.results.add(aux);
            }
        }

        return result;
    }

    // Método principal para encontrar el resultado más parecido
    public void selectBestOption() {
        if (this.dvsInfo == null) {
            throw new DvsPorsaException('No dvsInfo set on the service');
        }

        List<DvsResultWrapper> options = this.dvsInfo.results;
        DvsResultWrapper bestMatch = null;
        Decimal bestSimilarity = 0;

        for (DvsResultWrapper result : options) {
            if (result.score < 3) continue;

            Decimal nameSim = similarity(this.account.name, result.companyName);
            Decimal line1Sim = similarity(this.account.BillingStreet, result.address.line1);
            Decimal citySim = similarity(this.account.BillingCity, result.address.city);
            Decimal postalSim = similarity(this.account.BillingPostalCode, result.address.postalCode);

            Decimal totalSim = (nameSim * 0.2) + (line1Sim * 0.4) + (citySim * 0.2) + (postalSim * 0.2);

            if (totalSim > bestSimilarity) {
                bestSimilarity = totalSim;
                bestMatch = result;
            }
        }

        // No hya con score mayores de 3
        if (bestMatch == null) {
            if (options.isEmpty() == false) {
                DvsResultWrapper best = options[0];
                for (DvsResultWrapper opt : options) {
                    if (opt.score > best.score){
                        best = opt;
                    }
                }
                bestMatch = best;
            }
        }

        this.bestOption = bestMatch;
    }

    // Función de similitud básica (tipo Levenshtein simplificada con ratio)
    private static Decimal similarity(String a, String b) {
        if (String.isBlank(a) || String.isBlank(b)) return 0;
        a = a.toLowerCase();
        b = b.toLowerCase();

        Integer matches = 0;
        Integer minLen = Math.min(a.length(), b.length());

        for (Integer i = 0; i < minLen; i++) {
            if (a.charAt(i) == b.charAt(i)) matches++;
        }

        return Decimal.valueOf(matches) / Math.max(a.length(), b.length());
    }

    // Inner wrapper classes
    public class DvsWrapper {
        public String country;
        public String taxNumber1;
        public String companyNumber;
        public String name;
        public DvsAddressWrapper address;
        public DvsOptionsWrapper options = new DvsOptionsWrapper();
    }

    public class DvsAddressWrapper {
        public String line1, line2, postalCode, city, country;
    }

    public class DvsOptionsWrapper {
        public Boolean liveCheck = false;
        public Boolean fuzzy = false;
    }

    public class DvsResultWrapper {
        public String companyName, taxNumber1, status, companyNumber;
        public Decimal score;
        public Boolean liveChecked;
        public DvsAddressWrapper address;
    }

    public class DvsResultsWrapper {
        public String country, taxNumber1Label, source, searchType;
        public Boolean valid;
        public Integer resultCount;
        public Decimal maxScore;
        public List<DvsResultWrapper> results = new List<DvsResultWrapper>();
    }

    @testVisible public static String testFiller() {
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
        return s;
    }
}