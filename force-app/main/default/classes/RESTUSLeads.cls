/**
* @author 			Ramón Prades
* @date 			March 2021
* @group 			API
* @description 	    REST service to create leads from US websites.
*/
@RestResource(urlMapping='/web-leads/us/*')
global class RESTUSLeads {

    @HttpGet global static void get () {
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"rest-service":"us web-leads GET is up and running!"}');
    } // get

    /**
     * Creates a lead.
     * - data: lead data (required)
     * - products: products requested (optional)
     * - file: files attached to the lead (optional)
     */
    @HttpPost global static void post (USWebLeadDTO data, List<ProductDTO> products, List<OAttachmentDTO> files) {
        // @refactor: Mover toda la lógica a una clase LeadsService.cls.createUSWebLead
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        try {
            Lead lead = createLead(data);
            if (products != null && products.size() > 0) {
                addProductsToLead(lead, products);
            }
            if (files != null && files.size() > 0) {
                for (OAttachmentDTO dto : files) {
                    dto.parentId = lead.Id;
                }
                OAttachmentsService.createAttachments(files);
            }
            RESTResult result = new RESTResult();
            result.id = lead.Id;
            result.success = true;
            response.statusCode = 201;
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(json.serializePretty(result));        
            /*
            if (!SystemUtils.getOnSandbox()) {
                if (SystemSettings.USNotifyWebLeads) {
                    emailLead(lead);
                }    
            }
            */
        } catch (Exception ex)  {
            response.statusCode = 409;
            response.responseBody = Blob.valueOf(ex.getMessage());   
            LoggerCommons.LogException('RESTUSLeads', JSON.serializePretty(data), ex);
            throw ex;
        }
    } // post

    /********************* PRIVATE METHODS ***********************/

    private static Lead createLead(USWebLeadDTO dto) {
        lead lead1 = new Lead();
        lead1.Source__c = 'USW';
        lead1.company = dto.company;
        lead1.FirstName = dto.firstname;
        lead1.LastName = dto.lastname;
        lead1.Title = dto.title;
        lead1.Email = dto.email;
        lead1.Profile__c = dto.profile;
        lead1.Address__c = dto.street;
        lead1.CountryCode__c = dto.countryCode;
        if (String.isEmpty(lead1.CountryCode__c)) {
            lead1.CountryCode__c = 'US';
        }
        lead1.State__c = dto.state;
        if (String.isEmpty(lead1.State__c)) {
            lead1.State__c = AddressCommons.getProvinceCode(lead1.CountryCode__c, dto.stateName);
        }
        lead1.AppointmentType__c = '';
        if (String.IsNotEmpty(dto.appointmentType)) {
            if (dto.appointmentType.substring(0,1) == 'V') {
                lead1.AppointmentType__c = 'VIRTUAL';
            } else if (dto.appointmentType.substring(0,1) == 'S') {
                lead1.AppointmentType__c = 'SHOWROOM';
            } 
        }
        lead1.Showroom__c = getSalesOfficeId(dto.showroom);
        lead1.Postcode__c = dto.postCode;
        lead1.City__c = dto.town;
        lead1.MobilePhone = dto.mobile;
        lead1.LeadType__c = dto.website;
        lead1.LeadSubtype__c = dto.campaign;
        lead1.Description = dto.comments;
        lead1.Opportunity_Name__c = dto.projectName;
        lead1.IsSupportOrWarranty__c = dto.isSupport;
        lead1.ReferredBy__c = dto.referredBy;
        lead1.Operation_Type__c = convertOperationType(dto.operationType);
        if (dto.categories != null) {
            List<String> cats =  PicklistCommons.validatePicklistValues(Lead.Product_Categories__c, dto.categories.split(';'));
            lead1.Product_Categories__c = String.join(cats, ';');
        }
        /*if (String.IsBlank(lead1.Title)) {
            lead1.Title = dto.profile;
        }*/
        LeadHelper helper = new LeadHelper(lead1);
        helper.setUSWebRequestFields();
        helper.setAccountAndOwner();
        insert lead1;
        return lead1;
    } // createLead

    private static String convertOperationType(String opType) {
        String pickListValue = '';
        if (String.IsNotBlank(opType)) {
            if (opType.toUpperCase() == 'NEW') {
                pickListValue = 'New construction';
            } else if (opType.toUpperCase() == 'REFURB') {
                pickListValue = 'Refurbishment';
            }
        }
        return pickListValue;
    } // convertOperationType

    private static void addProductsToLead(Lead lead, List<ProductDTO> products) {
        List<ProductListItem__c> items = new List<ProductListItem__c>();
        for (ProductDTO dto : products) {
            ProductListItem__c item = new ProductListItem__c();
            item.amount__c = dto.amount;
            item.currencyIsoCode = dto.currencyCode;
            if (dto.isSample == null) {
                dto.isSample = false;
            }
            item.isSample__c = dto.isSample;
            item.Name__c = dto.productName;
            item.ProductCode__c = dto.productCode;
            item.Quantity__c = dto.quantity;
            item.Unit__c = dto.unit;
            item.Lead__c = lead.Id;
            items.add(item);
        }
        insert items;
    } // addProductsToLead

    private static void emailLead(Lead lead) {
        USLeadMailer mailer = new USLeadMailer(lead.Id);
        mailer.emailLeadOwner();

        /** 
        Mail mail = new Mail();
        mail.setGeneric();
        mail.setTo((Id) UserInfo.getUserId());
        mail.setSubject('A new lead has been assigned to you');

        String url =  URL.getOrgDomainUrl().toExternalForm() + '/' + lead.Id;

        Map<String, String> m = new Map<String, String>();
        m.put('Lead Name', '<a href="' + url + '">' + lead.Opportunity_Name__c + '</a>');
        m.put('Name', lead.FirstName + ' ' + lead.LastName);
        m.put('Phone', lead.MobilePhone);
        m.put('EMail', lead.Email);
        m.put('Owner', lead.owner.name);
        m.put('Source', lead.LeadSource);
        m.put('Type', lead.LeadType__c);
        m.put('Subtype', lead.LeadSubtype__c);
        m.put('Description', lead.Description);
        String table = MailUtils.mapToTable(m, 'width:700px;');

        User usr =  [SELECT FirstName FROM User WHERE Id = :lead.OwnerId limit 1];

        String body = '<p>Dear ' + usr.FirstName + ',</p>' +
        + '<p>A lead has contacted us from one of our web sites. Please review the details below and follow the link to go to the CRM.</p>'
        + table +
        + '<p>Thank you,</p>'
        + '<p>CRM Team<br/>Porcelanosa USA</p>';
        body = MailUtils.addHTMLTags(body);
        mail.setHtml(body);
        mail.send();
        */
    }

    /*
    ---------------------------------------------------------------------------------------------
    private static void emailError(USWebLeadDTO data, String errorMessage) {
        Mail mail = new Mail();
        mail.setTo(new List<String>{'rprades@porcelanosagrupo.com'});
        mail.setSubject('WEBLEAD: Error en servicio RESTUSLeads.cls (' + errorMessage + ')');
        String text = '<p><b>Error: ' + errorMessage + '</b></p>';
        text += '<p><code>' + JSON.serializePretty(data) + '</code></p>';
        mail.setHtml(text);
        mail.send();
    } // emailError
    ----------------------------------------------------------------------------------------------
    */

    private static String getSalesOfficeId(String code) {
        String officeId = null;
        if (!String.isBlank(code)) {
            List<Sales_Office__c> offices = [select Id from Sales_Office__c where SalesOffice__c = :code];
            if (offices.size() > 0) {
                officeId = offices[0].Id ;
            }
        }
        return officeId;           
    }

    global class USWebLeadDTO { 
        global String projectName;
        global String company;
        global String lastname;
        global String firstname;
        global String email;
        global String profile;
        global String countryCode;
        global String postCode;
        global String state;
        global String stateName;
        global String street;
        global String town;
        global String mobile;        
        global String website;
        global String campaign;
        global String comments;
        global String title;
        global String language = 'en_US';
        global String operationType;
        global String categories;
        global boolean isSupport = false;
        global String appointmentType;
        global String showroom;
        global String referredBy;
    } // class USWebLeadDTO   
    
    global class ProductDTO {
        global String productCode;
        global String productName;
        global Decimal quantity;
        global String unit;
        global Decimal amount;
        global String currencyCode;
        global Boolean isSample;
    }

} // class