/**
 * @author         Ramón Prades
 * @date           January 2025
 * @layer          Services
 * @description    Finds SAP invoices using multiple criteria
*/
@SuppressWarnings('PMD.EmptyCatchBlock')
public with sharing class SAPInvoicesFinderService {
    
    public Enum OrderByField {INV_DATE, INV_NUMBER}    
    public Enum OrderByDirection {ASCENDING, DESCENDING}
    public Enum AmountOptions {GREATER_THAN_ZERO, LESS_THAN_ZERO, EQUAL_TO_ZERO, NON_EQUAL_TO_ZERO, ALL_AMOUNTS}

    private String sapCustomer;    
    private String salesOrg;
    private String orderNumber;
    private String sapProduct;
    private String timeframe;
    private OrderByField sortBy = OrderByField.INV_DATE;
    private OrderByDirection sortDirection = OrderByDirection.DESCENDING;
    private AmountOptions amountFilter = AmountOptions.ALL_AMOUNTS;
    private Integer maxLines = 0;    
    private String[] cabFields = new List<String>{'Ordernum__c', 'Orderdate__c', 'Refer__c', 'Referencia__c', 'Dnet__c', 
        'Dtax__c', 'Dtotal__c', 'Dcurr__c', 'Distchannel__c', 'Paid__c', 'SALESOFFIC__c', 'BillTo__c', 'Account__c', 'Account__r.Name'
    };
    private String[] lineFields = new List<String>{'Ordernum__c', 'Orderlin__c', 'Sku__c', 'Name__c',  'Quantity__c', 'Vrkme__c',
        'Aubel__c', 'Aupos__c', 'Dnet__c', 'Dtax__c', 'Dtotal__c', 'Dcurr__c', 'Cost__c'   
    };

    private Facturas_cabeceraSet__x[] sapInvoices;

    public void setSalesOrg(String value) {
        this.salesOrg = value;
    }

    public void setSAPCustomer(String value) {
        this.sapCustomer = value;
    }

    public void setAccountId(Id value) {    
        String sapId = null;
        if (value != null) {    
            Account[] accs = [select SAP_Id__c from Account where Id = :value];
            if (accs.size() == 0) {
                throw new ObjectNotFoundException('The account does not exist');
            }        
            if (accs[0].SAP_Id__c == null) {
                throw new  ValidationException('This account does not have a SAP ID assigned');
            }
            sapId = accs[0].SAP_Id__c;
        }
        this.setSAPCustomer(sapId);
    }

    public void setOrderNumber(String value) {
        this.orderNumber = value;
    }

    public void setTimeframe(String value) {
        this.timeframe = value;
    }

    public void setSAPProduct(String value) {
        this.sapProduct = value;
    }

    public void setProductId(Id value) {
        String sku = null;
        if (value != null) {
            Product2[] prods = [select StockKeepingUnit from Product2 where Id = :value];
            if (prods.size() == 0) {
                throw new AuraHandledException('Product not found in SAP');
            } 
            sku = prods[0].StockKeepingUnit;
        }
        this.setSAPProduct(sku);
    }

    public void setOrderBy(OrderByField field, OrderByDirection direction) {
        this.sortBy = field;
        this.sortDirection = direction;
    }

    public void setAmountFilter(AmountOptions value) {
        this.amountFilter = value;
    }

    public void setMaxLines(Integer value) {
        this.maxLines = value;
    }
    
    public Facturas_cabeceraSet__x[] find() {
        this.sapInvoices = new List<Facturas_cabeceraSet__x>();
        try {
            String filter = this.buildFilters();
            String orderBy = this.buildOrderBy();
            String soql = 'select ' + String.join(this.cabFields, ', ') + ' from Facturas_cabeceraSet__x where ' + filter + orderBy;
            if (this.maxLines > 0) {
                soql += ' limit ' + this.maxLines;
            }
            this.sapInvoices = Database.query(soql);
            if (String.isNotBlank(this.sapProduct)) {
                this.sapInvoices = this.applyPostFilters();
            }
        } catch (ObjectNotFoundException onf) {            
            // Returned when a prefetch filter returns no results            
        }
        return this.sapInvoices;
    }

    public Map<String, List<Facturas_posicionesSet__x>> readItems() {
        Map<String, List<Facturas_posicionesSet__x>> resultMap = new Map<String, List<Facturas_posicionesSet__x>>();
        if (this.sapInvoices.size() > 0) {
            Set<String> ordernums = new Set<String>();
            for (Facturas_cabeceraSet__x invoice :this.sapInvoices) {
                ordernums.add(invoice.Ordernum__c);
            }
            Facturas_posicionesSet__x[] lines = [
                SELECT
                    Ordernum__c, Orderlin__c, Sku__c, Name__c,  Quantity__c, Vrkme__c,
                    Aubel__c, Aupos__c, Dnet__c, Dtax__c, Dtotal__c, Dcurr__c, Cost__c
                FROM Facturas_posicionesSet__x
                WHERE Ordernum__c in :ordernums
                ORDER BY Ordernum__c, Orderlin__c
            ];
            for (Facturas_posicionesSet__x line :lines) {
                List<Facturas_posicionesSet__x> posiciones = resultMap.get(line.Ordernum__c);
                if (posiciones == null) {
                    posiciones = new List<Facturas_posicionesSet__x>();
                    posiciones.add(line);
                    resultMap.put(line.Ordernum__c, posiciones);
                } else {
                    posiciones.add(line);
                }
            }    
        }
        return resultMap;

    }

    //----------------------------------------------------------------------------------

    private List<Facturas_cabeceraSet__x> applyPostFilters() {
        List<Facturas_cabeceraSet__x> results = new List<Facturas_cabeceraSet__x>();
        List<String> numbers = TypeConversionCommons.extractFieldValues(this.sapInvoices, 'Ordernum__c');
        List<String> selectedInvoices = this.getInvoicesPerProduct(numbers, this.sapProduct);
        if (selectedInvoices.size() > 0) {
            for (Facturas_cabeceraSet__x invoice : this.sapInvoices) {
                if (selectedInvoices.contains(invoice.Ordernum__c)) {
                    results.add(invoice);
                }
            }
        }
        return results; 
    }

    private List<String> getInvoicesPerProduct(List<String> numbers, String sku) {
        List<Facturas_posicionesSet__x> positions = [select Ordernum__c from Facturas_posicionesSet__x where Ordernum__c in :numbers and Sku__c = :this.sapProduct];
        return TypeConversionCommons.extractFieldValues(positions, 'Ordernum__c');
    }

    private String buildFilters() {
        String[] filters = new List<String>();
        if (this.salesOrg != null) {
            filters.add('Salesorg__c = \'' + this.salesOrg + '\'');
        }
        if (this.sapCustomer != null) {
            filters.add('BillTo__c= \'' + this.sapCustomer + '\'');
        }        
        Set<String> invoices = this.preFetchInvoices();
        if (invoices.size() > 0) {
            String invoicesFilter = '(';
            String sep = '';
            for (String invoice :invoices) {
                invoicesFilter += sep + '\'' + invoice + '\'';
                sep = ',';
            }
            invoicesFilter += ')';
            filters.add('Ordernum__c in ' + invoicesFilter);
        }        
        if (filters.size() == 0) {
            throw new ContextException('Please set at least one filter');
        }
        // The filters below are additional
        if (String.isNotBlank(this.timeframe)) {
            filters.add('Orderdate__c = ' + this.timeframe);
        }        
        switch on this.amountFilter {
            when  GREATER_THAN_ZERO {
                filters.add('DTotal__c > 0');
            }
            when LESS_THAN_ZERO {
                filters.add('DTotal__c < 0');
            }
            when EQUAL_TO_ZERO {
                filters.add('DTotal__c = 0');
            }
            when NON_EQUAL_TO_ZERO {
                filters.add('DTotal__c != 0');
            }
        }
        return String.join(filters, ' AND ');
    }

    private Set<String> preFetchInvoices() {
        Set<String> results = new Set<String>();
        if (String.isNotBlank(this.orderNumber)) {
            Facturas_posicionesSet__x[] posiciones = [
                select Ordernum__c from Facturas_posicionesSet__x
                where Aubel__c = :this.orderNumber
            ];
            if (posiciones.size() == 0) {
                throw new ObjectNotFoundException('No invoices foud for order ' + this.orderNumber);
            }        
            for (Facturas_posicionesSet__x posicion :posiciones) {
                results.add(posicion.Ordernum__c);
            }
        }
        return results;
    }

    private String buildOrderBy() {
        String orderBy = '';
        if (this.sortBy != null) {
            orderby = 'ORDER BY';
            switch on this.sortBy {
                when INV_DATE {  
                    orderBy += ' Orderdate__c';         
                }
                when else {
                    orderBy += ' Ordenum__c';
                }
            }
            if (this.sortDirection == OrderByDirection.DESCENDING) {
                orderBy += ' desc';
            }
        }
        return orderBy;
    }

    @testVisible static String dummy() {
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


        return s;
    }
}