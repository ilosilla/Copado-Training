/**
* @author 		Ramón Prades
* @date 		February 2023
* @group 		Main object in plural
* @description  Enter a description
*/
global class MasterProductSyncReporter implements Schedulable {

    private Boolean hasErrors = false;
    private Integer updatedPB;
    private Integer successPB;
    private Integer errorsPB;

    global void execute(SchedulableContext sc) {
        this.sendReport();
    }

    global void sendReport() {    
        this.successPB = 0;
        this.errorsPB = 0;
        String products = this.buildProductsPart();
        String retailBooks = this.buildPricebooksPart(true, false);
        String sampleBooks = this.buildPricebooksPart(false, true);
        String otherBooks = this.buildPricebooksPart(false, false);

        this.hasErrors = (this.errorsPB > 0);
        this.updatedPB = this.successPB + this.errorsPB;

        String html = '<p>Se han actualizado los libros de precions siguientes:</p>'
                    + '<ul>'
                    + '<li>Actualizados:&UPDATEDPB&</li>'
                    + '<li>Correctos:&SUCCESSPB&</li>'
                    + '<li>Erróneos:&ERRORSPB&</li>'
                    + '</ul>'
                    + '<h1>Product2</h1><p>&PRODUCTS&</p>'  
                    + '<h1>Libros RETAIL</h1><p>&RETAILBOOKS&</p>'  
                    + '<h1>Libros de MUESTRAS</h1><p>&SAMPLEBOOKS&</p>'  
                    + '<h1>Otros Libros</h1><p>&OTHERBOOKS&</p>';

        html = html.replace('&UPDATEDPB&', String.valueOf(this.updatedPB));
        html = html.replace('&SUCCESSPB&', String.valueOf(this.successPB));
        html = html.replace('&ERRORSPB&', String.valueOf(this.errorsPB));

        html = html.replace('&PRODUCTS&', products);
        html = html.replace('&RETAILBOOKS&', retailBooks);
        html = html.replace('&SAMPLEBOOKS&', sampleBooks);
        html = html.replace('&OTHERBOOKS&', otherBooks);

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(new List<String>{UserInfo.getUserEmail()});
        if (this.hasErrors) {
            m.setSubject('SF JOB ERROR: Informe de actualización de productos y precios con ERRORES');
        } else {
            m.setSubject('SF JOB SUCCESS: Informe de actualización de productos y precios OK');
        }        
        html = MailUtils.addHTMLTags(html);
        m.setHtml(html);
        m.send();
    }

    private String buildProductsPart() {
        Integer nproducts =  [select count()  from Product2];
        Integer nactivos =  [select count()  from Product2 where IsActive = true];
        Integer nsamples =  [select count()  from Product2 where IsActive = true and IsSample__c = true];
        Integer ncreated =  [select count()  from Product2 where createdDate = TODAY];
        Integer nmodified = [select count()  from Product2 where createdDate < TODAY and LastModifiedDate = TODAY];
        String html = '<table><tr><th colspan="2" class="col-header">Product2</th>' 
                    + '<tr><td class="row-header">Registros</td><td>' + nproducts + '</td></tr>'
                    + '<tr><td class="row-header">Activos</td><td>' + nactivos + '</td></tr>'
                    + '<tr><td class="row-header">Muestras</td><td>' + nsamples + '</td></tr>'
                    + '<tr><td class="row-header">Creados hoy</td><td>' + ncreated + '</td></tr>'
                    + '<tr><td class="row-header">Modificados hoy</td><td>' + nmodified + '</td></tr>'
                    + '</table>';
        return html;
    }

    private String buildPricebooksPart(Boolean retailBooks, Boolean samplesBooks) {
        
        Pricebook2[] books = [select Id, Name, ExecutionContext__c,  LastSyncResult__c, LastSync__c, IsRetailReferencePricebook__c, SamplesOnly__c  
                                from PriceBook2 
                                where IsActive = true 
                                  and IsDeleted = false 
                                  and IsRetailReferencePricebook__c = :retailBooks
                                  and SamplesOnly__c = :samplesBooks
                                order by LastModifiedDate desc]; 

        Set<Id> ids = TypeConversionCommons.listToSet(books);
        AggregateResult[] totalEntries = [select Pricebook2Id, count(Id) myCount from PricebookEntry where Pricebook2Id in :ids group by Pricebook2Id];
        AggregateResult[] createdEntries = [select Pricebook2Id, count(Id) myCount from PricebookEntry where Pricebook2Id in :ids and createdDate = TODAY group by Pricebook2Id];
        AggregateResult[] modifiedEntries = [select Pricebook2Id, count(Id) myCount from PricebookEntry where Pricebook2Id in :ids and createdDate < TODAY and LastModifiedDate = TODAY group by Pricebook2Id];

        Map<Id, Integer> totals = arToMap(totalEntries); 
        Map<Id, Integer> created = arToMap(createdEntries); 
        Map<Id, Integer> modified = arToMap(modifiedEntries); 
        
        String html = '<table><tr>'
                    + '<th class="col-header">Pricebook</th>'
                    + '<th class="col-header">Context</th>'
                    + '<th class="col-header">Retail?</th>'
                    + '<th class="col-header">Samples?</th>'
                    + '<th class="col-header">Sync</th>'
                    + '<th class="col-header">Resultado</th>'
                    + '<th class="col-header">Registros</th>'
                    + '<th class="col-header">Creados</th>'
                    + '<th class="col-header">Modificados</th><tr>';
        
        for (Pricebook2 book :books) {
            if (book.LastSyncResult__c == 'EXCEPTION') {
                this.errorsPB++;                
            } else {
                this.successPB++;
            }
            Integer nrecords = reset(totals.get(book.Id));
            Integer ncreated = reset(created.get(book.Id));
            Integer nmodified = reset(modified.get(book.Id));
            //if (nrecords > 0) {
            String row = '<tr>'
                        + '<td class="row-header"><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + book.Id + '">' + book.Name + '</a></td>'
                        + '<td>' + book.ExecutionContext__c + '</td>'
                        + '<td>' + book.IsRetailReferencePricebook__c + '</td>'
                        + '<td>' + book.SamplesOnly__c + '</td>'
                        + '<td>' + book.LastSync__c + '</td>'
                        + '<td>' + book.LastSyncResult__c + '</td>'
                        + '<td>' + nrecords + '</td>'
                        + '<td>' + ncreated + '</td>'
                        + '<td>' + nmodified + '</td>'
                        + '</tr>';
            html += row;
            //}
        }
        html += '</table>'; 
        return html;
    }

    private Integer reset(Integer i) {
        if (i == null) {
            return 0;
        } else {
            return i;
        }
    } // reset

    private Map<Id, Integer> arToMap(AggregateResult[] ars) {
        Map<Id, Integer> theMap = new Map<Id, Integer>();
        for (AggregateResult ar :ars) {
            Id book = (Id) ar.get('Pricebook2Id');
            Integer myCount = (Integer) ar.get('myCount');
            theMap.put(book, myCOunt);
        }
        return theMap;
    }        

} // class