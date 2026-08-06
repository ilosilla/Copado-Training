/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Data Factories
 * @description    Returns test data for SAP documents stored in external objects.
*/
public class DataFactorySAPSalesDocs {

    public DataFactorySAPSalesDocs() {
        if (!Test.isRunningTest()) {
            throw new ContextException('Class accesible when testing only');
        }
    }

    public List<Facturas_cabeceraSet__x> getInvoiceHeaders(Set<String> numbers) {
        Account theAccount = [select Id from Account limit 1];
        List<Facturas_cabeceraSet__x> facturas = new List<Facturas_cabeceraSet__x>();
        for (String num : numbers) {
            Facturas_cabeceraSet__x f1 = new Facturas_cabeceraSet__x(
                Ordernum__c = num,
                Orderdate__c = System.today(),
                Account__c = theAccount.Id,
                Salesorg__c = '502',
                Dtotal__c = 500
            );
            facturas.add(f1);
        }
        return facturas;
    }

    public List<Facturas_posicionesSet__x> getInvoiceLines(Set<String> numbers) {        
        Product2 theProduct = [select Id, ProductCode, Name, Umv__c from Product2 limit 1];
        List<Facturas_posicionesSet__x> posis = new List<Facturas_posicionesSet__x>();
        for (String num : numbers) {
            Facturas_posicionesSet__x pos = new Facturas_posicionesSet__x(
                Ordernum__c = num,
                Orderlin__c = '1',
                Name__c = theProduct.Name,
                Sku__c = theProduct.ProductCode,
                Quantity__c = 5,
                Vrkme__c = theProduct.Umv__c
            );
            posis.add(pos);
            Facturas_posicionesSet__x pos2 = new Facturas_posicionesSet__x(
                Ordernum__c = num,
                Orderlin__c = '2',
                Name__c = theProduct.Name,
                Sku__c = theProduct.ProductCode,
                Quantity__c = 5,
                Vrkme__c = 'MT2'
            );
            posis.add(pos2);

        }
        return posis;
    }

}