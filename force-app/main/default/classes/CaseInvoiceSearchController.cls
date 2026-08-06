/**
* @author 		Ramón Prades
* @date 		August 2022
* @group 		Cases
* @description 	Controller class for CaseInvoiceSearch component
* @Task: Escribir clase de test (Ramón 5 Sept 2022) 
*/
public class CaseInvoiceSearchController {

    private static final Integer numDays = 28;

    /**
     * Returns the initial valuies needed for the screen
     */
    @AuraEnabled(cacheable=true) public static String readInitialValues() {
        String recordTypeId = RecordTypeLibrary.Case_SAPInvoice;
        return recordTypeId;
    }

    /**
    * @description 	Reads the invoice passed by number or returns an exception if not found.
    */    
    @AuraEnabled(cacheable=false) public static InvoiceDTO readInvoiceData(String invoiceNumber, String caseId) {
        InvoiceDto dto = new InvoiceDTO();
        try {
            SAPInvoicesSelector selector = new SAPInvoicesSelector();
            Facturas_cabeceraSet__x invoice = selector.selectByNumber(invoiceNumber);
            dto.invoiceHeader = new SAPInvoiceHeader(invoice);
            Boolean hasPermission = UserCommons.hasAccessToSalesOrg((Id) UserInfo.getUserId(), dto.invoiceHeader.salesOrg);
            if (!hasPermission) {
                throw new SecurityException('Insufficient access to sales organization ' + dto.invoiceHeader.salesOrg);
            }
            dto.permission = true;
            dto.accountId = dto.invoiceHeader.accountId;
            if (String.isBlank(dto.accountId)) {
                dto.accountId = AccountUtil.getFromSAPCode(dto.invoiceHeader.SAPCustomer);
            }                        
            if (String.isNotBlank(dto.accountId)) {
                    dto.accountName = AccountUtil.getName(dto.accountId);
            }
            Decimal dnum = dto.invoiceHeader.docTotalAmount;
            List<User> reps = new UsersSelector().selectByRepCode(new Set<String>{dto.invoiceHeader.SAPRep1});
            if (reps.size() > 0) {
                dto.repName = reps[0].Name;
            }
            dto.salesOrgName = OrganizationUtil.getSalesOrgName(dto.invoiceHeader.salesOrg);
            dto.salesOfficeName = OrganizationUtil.getSalesOfficeName(dto.invoiceHeader.salesOffice);
            dto.formattedAmount = dto.invoiceHeader.docCurrency + ' ' + dnum.setScale(2).format();
            dto.invoiceLines = readInvoiceLines(invoiceNumber, caseId, true);
            checkStockProgram(dto.invoiceHeader.salesOrg, dto.invoiceLines);
            dto.numItems = dto.invoiceLines.size();
            Integer days = Math.abs(system.today().daysBetween(Date.valueOf(dto.InvoiceHeader.docDate)));            
            SAPCasesSettings__c settings = CasesDomain.getSAPSettings(dto.invoiceHeader.salesOrg);
            dto.numDays = ((Integer) settings?.COL_PolicyDays__c ?? 28);
            dto.customerReturns = settings?.COL_CustomerReturns__c ?? true;
            dto.daysWarning = (days > dto.numDays);
            dto.cpAddress = SAPAddressHelper.readInvoiceDeliveryAddress(invoiceNumber);
            String warehouses = settings?.COL_ReturnsWarehouse__c;
            dto.returnWarehouses = new List<String>();
            if (String.isNotBlank(warehouses)) {
                dto.returnWarehouses = warehouses.split(';');
            } 
            AddressCommons.completeAddressFields(dto.cpAddress);
        } catch (ObjectNotFoundException onf) {
            throw new AuraHandledException(onf.getMessage());            
        } catch (SecurityException sex) {
            throw new AuraHandledException(sex.getMessage());
        } /*catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/
        return dto;
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private static Map<String, ProductListItem__c> readProductListItems(String caseId) {
        Map<String, ProductListItem__c> result = new Map<String, ProductListItem__c> ();
        if (caseId != null) {
            ProductListItem__c[] items = [select Id, Quantity__c, Unit__c, QuantityCOnfirmed__c, QuantityConfirmedUnit__c, SAPNumber__c, SAPLine__c from ProductListItem__c where Case__c = :caseId];
            for (ProductListItem__c item : items) {
                String key = item.SAPNumber__c + ':' + item.sapLine__c;
                result.put(key, item);
            }
        }
        return result;
    }

    private static InvoiceLineDTO[] readInvoiceLines(String invoiceNumber, String caseId, Boolean convertPallets) {
        Map<String, String> unitNames = PicklistCommons.getValues(Product2.SalesUnit__c);
        Map<String, ProductListItem__c> items = readProductListItems(caseId);
        InvoiceLineDTO[] linesDTO = new InvoiceLineDTO[]{};
        Facturas_posicionesSet__x[] lines = new SAPInvoiceLinesSelector().selectByNumber(invoiceNumber);
        Map<String, Product2> productsMap = getProductsMap(lines);
        for (Facturas_posicionesSet__x line : lines) {
            SAPINvoiceline iLine = new SAPInvoiceLine(line);    
            InvoiceLineDTO lineDTO = new InvoiceLineDTO();
            lineDTO.lineNo = iLine.docLine;
            lineDTO.productCode = iLine.productCode;
            lineDTO.productName = iLine.productName;
            lineDTO.invoiced = iLine.quantity;
            lineDTO.unit = iLine.salesUnit;
            Product2 product = productsMap.get(lineDTO.productCode);
            if (product != null) {                
                if (convertPallets && lineDTO.unit == 'PAL') {
                    lineDTO.unit = 'CJ';
                    lineDTO.invoiced *= product.BoxXPal__c;
                }
                String itemGroup = product.SAPItemGroup__r.SAPGroup__c ?? 'PT';
                ProductConverter converter = new ProductConverter(product);                
                ProductConverter.UKUnits ukUnits = converter.convertToUKUnits((Double) iLine.quantity, iLine.salesUnit);
                lineDTO.isTile = ukUnits.isTile;
                lineDTO.invBoxes = ukUnits.boxes;
                lineDTO.invPieces = ukUnits.pieces;
                lineDTO.product2Id = product.Id;
                lineDTO.pcsxbox = (Integer) product.PcsXBox__c;
                lineDTO.mt2xbox = product.M2XBox__c;
                lineDTO.boxxpal = (Integer) product.BoxXPal__c;
                lineDTO.isService = (itemGroup.startsWith('MP') || itemGroup.startsWith('SE'));
                ProductListItem__c item = items.get(invoiceNumber + ':' + lineDTO.lineNo);
                if (item != null && lineDTO.unit == item.Unit__c) {
                    // Collected
                    lineDTO.collected = item.Quantity__c;
                    ProductConverter.UKUnits collected = converter.convertToUKUnits(DOuble.valueOf(item.Quantity__c), item.Unit__c);
                    lineDTO.colBoxes = collected.boxes;
                    lineDTO.colPieces = collected.pieces;                    

                    // Confirmed                    
                    if (item.QuantityConfirmed__c != null && item.QuantityConfirmed__c != 0) {
                        lineDTO.confirmed = item.QuantityConfirmed__c;
                        lineDTO.confUnit = item.QuantityConfirmedUnit__c;
                        ProductConverter.UKUnits confirmed = converter.convertToUKUnits(DOuble.valueOf(item.QuantityConfirmed__c), item.QuantityConfirmedUnit__c);
                        lineDTO.confBoxes = confirmed.boxes;
                        lineDTO.confPieces = confirmed.pieces;              
                    }

                }            
                lineDTO.lineOK = true;   
            } else {
                // Product not found - ignore and continue
                lineDTO.isTile = false;
                lineDTO.lineOK = false;   
            }
            Decimal aux = ((Decimal)lineDTO.invoiced).setScale(2);
            lineDTO.unitLabel = unitNames.get(lineDTO.unit) ?? lineDTO.unit;
            lineDto.invString = aux + ' ' + lineDTO.unitLabel;
            linesDTO.add(lineDTO);
        }
        return linesDTO;
    }

    private static void checkStockProgram(String salesOrg, InvoiceLineDTO[] invoiceLines) {
        Set<String> materialsSet = new Set<String>();
        for (InvoiceLineDTO line : invoiceLines) {
            if (!materialsSet.contains(line.productCode)) {
                materialsSet.add(line.productCode);
            }
        }
        ZSFMatOrgv__x[] mats = [select Material__c, Stkprog__c from ZSFMatOrgv__x where Vkorg__c = :salesOrg and Material__c in :materialsSet];
        Map<String, Boolean> dataMap = new Map<String, Boolean>();         
        for (ZSFMatOrgv__x mat : mats) {
            dataMap.put(mat.Material__c, mat.Stkprog__c);
        } 
        for (InvoiceLineDTO line2 : invoiceLines) {
            if (dataMap.containsKey(line2.productCode)) {
                line2.isStockProgram = dataMap.get(line2.productCode);
            }
        }
    }

    private static Map<String, Product2> getProductsMap(Facturas_posicionesSet__x[] lines) {
        Map<String, Product2> productsMap = new Map<String, Product2>();
        Set<String> codesSet = new Set<String>();
        for (Facturas_posicionesSet__x line : lines) {
            codesSet.add(line.Sku__c);
        }
        ProductsSelectorV2 selector = new ProductsSelectorV2();
        selector.addRelationshipField('SAPItemGroup__r.SAPGroup__c');
        Product2[] products = selector.selectBySKU(codesSet);
        for (Product2 product :products) {
            productsMap.put(product.ProductCode, product);
        }
        return productsMap;
    }

    public class InvoiceDTO {
        @AuraEnabled public String salesOrg;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String repName;
        @AuraEnabled public String salesOfficeName;
        @AuraEnabled public String salesOrgName;
        @AuraEnabled public String formattedAmount;        
        @AuraEnabled public Integer numItems;
        @AuraEnabled public Boolean permission; 
        @AuraEnabled public String message;
        @AuraEnabled public SAPInvoiceHeader invoiceHeader;
        @AuraEnabled public InvoiceLineDTO[] invoiceLines;
        @AuraEnabled public Integer collectionDays = CaseInvoiceSearchController.numDays;
        @AuraEnabled public Boolean daysWarning = false;
        @AuraEnabled public Integer numDays = 0;
        @AuraEnabled public Boolean customerReturns = true;
        @AuraEnabled public ContactPointAddress cpAddress;
        @AuraEnabled public String[] returnWarehouses;
    } // inner class

    public class InvoiceLineDTO {
        @AuraEnabled public Boolean lineOK = false;
        @AuraEnabled public Integer lineNo;
        @AuraEnabled public String productCode;
        @AuraEnabled public String productName;
        @AuraEnabled public Double invoiced;
        @AuraEnabled public String unit;
        @AuraEnabled public String unitLabel;
        @AuraEnabled public String invString;
        @AuraEnabled public String colString;
        @AuraEnabled public String confString;
        @AuraEnabled public Integer invBoxes;
        @AuraEnabled public Integer invPieces;   
        @AuraEnabled public Integer colBoxes = 0;
        @AuraEnabled public Integer colPieces = 0;   
        @AuraEnabled public Double collected = 0;   
        @AuraEnabled public Integer confBoxes = 0;
        @AuraEnabled public Integer confPieces = 0;
        @AuraEnabled public Double confirmed = 0;
        @AuraEnabled public String confUnit;
        @AuraEnabled public Boolean isTile = false;     
        @AuraEnabled public Boolean isService = false;     
        @AuraEnabled public String product2Id;
        @AuraEnabled public Integer pcsxbox = 0;
        @AuraEnabled public Integer boxxpal = 0;
        @AUraEnabled public Double mt2xbox;
        @AuraEnabled public Boolean isStockProgram = false;
        //@AuraEnabled public ContactPointAddress cpAddress = null;
    }


} // class