/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Leads
* @description 	Class to create leads from a material bank project (in batch). Creates a lead and 
*               schedules the next to avoid hittin the governor limits.
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public class MaterialBankProject implements Database.Batchable<SObject>, Database.stateful {     

    List<MaterialBankParser.MBProject> projects;
    Integer index = -1;
    public List<Id> leadIds;
    public List<MaterialBankIssue> issues;
    public String fileName = '';
    public Boolean isEurope = false;    
    private String excludedCountries = '';

    static final String LEAD_SOURCE = 'Samples Request';
    static final String LEAD_TYPE = 'US Material Bank';
    static final String LEAD_TYPE_EU = 'EU Material Bank';
    static final String LEAD_SUBTYPE = 'Material Bank';
    static final String SOURCE = 'MBK';
    SystemLog logger;

    public MaterialBankProject(List<MaterialBankParser.MBProject> projects) {     
        this.logger = new SystemLog('MATERIAL-BANK');
        this.fileName = 'void';
        this.leadIds = new List<Id>();
        this.issues = new List<MaterialBankIssue>();
        this.projects = projects;
        this.index = 0;
    }
    
    public MaterialBankProject(String fileName, List<MaterialBankParser.MBProject> projects) {        
        this(projects);
        this.fileName = fileName;
    }

    public void setEurope(Boolean value) {
        this.excludedCountries = '';
        this.isEurope = value;
        if (this.isEurope) {
            this.excludedCountries = 'ES;PT;';
            this.logger.setTag('EUROPE');
        } else {
            this.logger.setTag('USA');
        }
    }

    public MaterialBankProject(String fileName, List<MaterialBankParser.MBProject> projects, List<Id> leadIds, List<MaterialBankIssue> issues, Integer index, SystemLog logger) {        
        this.fileName = fileName;
        this.leadIds = leadIds;
        this.issues = issues;
        this.projects = projects;
        this.logger = logger;
        this.index = index;
    } // Constructor

    public  Database.QueryLocator start(Database.BatchableContext bc) {  
        return Database.getQueryLocator('select Id from User limit 1');     // Para que se ejecute el execute
    }

    public void execute(Database.BatchableContext context, List<sObject> param) {     
        this.logger.addInfo('-----------------------------------') ;
        this.logger.addInfo('Procesando proyecto de MATERIAL BANK');
        this.logger.addInfo('IS_EUROPE vale ' + this.isEurope);
        this.logger.saveLog();
        MaterialBankParser.MBProject project = this.projects[this.index];        
        this.index++;
        Boolean excluded = this.excludedCountries.containsIgnoreCase(project.customer.COUNTRY + ';');
        if (!excluded && !this.leadExists(project.orderId)) {
            try {
                Lead lead = this.createMBLead(project);        
                this.logger.addInfo('Project ' + project.orderId + ' converted to Lead ' + lead.Id + ' ' + lead.Opportunity_Name__c);
                leadIds.add(lead.Id);
                USLeadMailer mailer = new USLeadMailer(lead.Id);
                mailer.setEurope(this.isEurope);
                mailer.newMaterialBankLead();    
            } catch (DmlException dex) {  
                MaterialBankIssue issue = new MaterialBankIssue();
                issue.projectName = project.projectName;
                issue.customerName = (project.customer.CONTACT1NAME ?? project.customer.SHIPPED1NAME);
                issue.isError = true;
                this.logger.addError('DMLError converting project ' + project.orderId);
                for (Integer i = 0; i < dex.getNumDml(); i++) {
                    issue.comments = '[' + dex.getDmlFieldNames(i) + '] ' + dex.getDmlMessage(i);
                }
                this.issues.add(issue);
                this.logger.addError(dex);
            } catch (Exception ex) {
                this.logger.addError(ex.getTypeName() + ' received converting project ' + project.orderId);
                this.logger.addError(ex);
                MaterialBankIssue issue = new MaterialBankIssue();
                issue.projectName = project.projectName;
                issue.customerName = (project.customer.CONTACT1NAME ?? project.customer.SHIPPED1NAME);
                issue.isError = true;
                issue.comments = ex.getTypeName() + '-' + ex.getMessage();
                this.issues.add(issue);
            }                    
        } else if (excluded){
            this.logger.addWarning('Project ' + project.orderId + ' excluded because of country ' + project.customer.COUNTRY);
            MaterialBankIssue issue = new MaterialBankIssue();
            issue.projectName = project.projectName;
            issue.customerName = (project.customer.CONTACT1NAME ?? project.customer.SHIPPED1NAME);
            issue.isError = false;
            issue.comments = 'Project ' + project.orderId + ' excluded (country is ' + project.customer.COUNTRY + ')';
            this.issues.add(issue);        
        } else {
            this.logger.addWarning('Project ' + project.orderId + ' already loaded');
            MaterialBankIssue issue = new MaterialBankIssue();
            issue.projectName = project.projectName;
            issue.customerName = (project.customer.CONTACT1NAME ?? project.customer.SHIPPED1NAME);
            issue.isError = false;
            issue.comments = 'Project ' + project.orderId + ' already loaded';
            this.issues.add(issue);
        }
        this.logger.saveLog();
    }
    
    public void finish(Database.BatchableContext BC) {
        if (this.index <this.projects.size()) {
            MaterialBankProject newProject = new MaterialBankProject(this.fileName, this.projects, this.leadIds, this.issues, this.index, this.logger);
            newProject.setEurope(this.isEurope);
            Database.executeBatch(newProject);
        } else {
            this.logger.saveLog(true);
            try {
                USLeadMailer.summaryMaterialBank(this.isEurope, this.fileName, this.leadIds, issues);                
            } catch(Exception ex) {
                this.logger.addError('Excepción recibida al enviar el resumen de la carga por email');
                this.logger.addError(ex);
            }
        }            
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private Boolean leadExists(String externalId) {
        Lead[] leads = [select Id, External_ID__c from Lead where External_Id__c = :externalId];
        return (leads.size() > 0);
    } // leadExists

    @testVisible private Lead createMBLead(MaterialBankParser.MBProject project) {     
        Lead lead = new Lead();
        String oppName = project.projectName;
        if (oppName.length() > 40 ) {
            oppName = oppName.substring(0, 40);
        }
        lead.Opportunity_Name__c = oppName;
        lead.LeadSource = MaterialBankProject.LEAD_SOURCE;
        lead.company = project.customer.company;
        if (String.IsNotEMpty(lead.company)) {
            if (lead.company.containsIgnoreCase('PORCELANOSA')) {
                lead.company = '';
            }
        }
        String customerName = project.customer.CONTACT1NAME;
        if (String.isBlank(customerName)) {
            customerName = project.customer.SHIPPED1NAME;
        }
        if (String.isBlank(customerName)) {
            customerName = project.customer.ORDERED1NAME;
        }
        Map<String, String> words = StringUtils.splitName(customerName);
        lead.FirstName = words.get('firstName');
        lead.LastName = words.get('lastName');
        lead.Title = project.customer.TITLE;
        lead.Email = project.customer.CONTACT1EMAIL;
        lead.Profile__c = LeadHelper.mapProfile(project.customer.TITLE);
        lead.Address__c = project.customer.STREET1;
        lead.Postcode__c = project.customer.ZIP;
        lead.CountryCode__c = project.customer.COUNTRY;

        if (!this.isEurope) {
            if (String.isBlank(lead.CountryCode__c)) {
                lead.CountryCode__c = 'US';
                String zip = lead.Postcode__c;
                if (String.isNotBlank(zip)) {
                    zip = zip.toUpperCase();
                    if (zip.containsAny('ABCDEFGHIJKLMNOPQRSTUVWXYZ')) {
                        lead.CountryCode__c = 'CA';
                    }
                }
            }        
            if (lead.CountryCode__c == 'CA') {
                lead.State__c = GeoUtils.getCAStateCode(project.customer.STATE);
            } else {
                lead.State__c = GeoUtils.getUSStateCode(project.customer.STATE);
            }
        }
        
        lead.City__c = project.customer.CITY;
        lead.MobilePhone = project.customer.CONTACT1PHONE;
        lead.Source__c = MaterialBankProject.SOURCE;
        if (this.isEurope) {
            lead.LeadType__c = MaterialBankProject.LEAD_TYPE_EU;
        } else {
            lead.LeadType__c = MaterialBankProject.LEAD_TYPE;
        }
       lead.LeadSubtype__c = MaterialBankProject.LEAD_SUBTYPE;
        lead.Description = '- Project Type : ' + project.projectType + '\n'
                         + '- Project Phase: ' + project.projectPhase + '\n'
                         + '- Order Id     : ' + project.orderId + '\n'
                         + '- Tracking No  : ' + project.TrackingNo + '\n'
                         + '- Contact Name : ' + project.customer.CONTACT1NAME + '\n'
                         + '- Ordered Name : ' + project.customer.ORDERED1NAME + '\n'
                         + '- Shipped Name : ' + project.customer.SHIPPED1NAME + '\n'
                         + '- Contact Pref.: ' + project.customer.CONTACTPREFERENCE + '\n'
                         + '\n'
                         + project.projectDescription;
        lead.External_ID__c = project.orderId;                        

        if (project.porcelanosaEmail != null) {
            String rep = '';
            try {
                rep = UserUtils.getUserIdFromEmail(project.porcelanosaEmail);            
            } catch (ObjectNotFoundException onf1) {
                rep = null;
            }
            lead.Representative__c = rep;
        }

        LeadHelper helper = new LeadHelper(lead);
        if (this.isEurope) {
            helper.setEUWebRequestFields();
        } else {
            helper.setUSWebRequestFields();
        }
        helper.setAccountAndOwner();
        lead.OwnerLocked__c = true;
        insert lead;

        ProductListItem__c[] products = new List<ProductListItem__c>();
        for (MaterialBankParser.MBItem item : project.items) {
            ProductListItem__c product = this.createProductItem(lead, item);
            products.add(product);
        }   
        if (products.size() > 0) {
            insert products;
        }
        return lead;
    } // createLead

    private ProductListItem__c createProductItem(Lead lead, MaterialBankParser.MBItem item) {
        ProductListItem__c product = new ProductListItem__c();
        product.CurrencyIsoCode = lead.CurrencyIsoCode;
        product.isSample__c = true;
        product.Lead__c = lead.Id;
        product.ProductCode__c = item.SKU;
        product.Name__c = item.NAME;
        if (item.COLOR !=null && item.COLOR.length() > 0) {
            product.Name__c += ' (' + item.COLOR + ')';
        }
        product.Quantity__c = item.QTYORIGINAL;
        product.Unit__c = 'PZS';
        product.Shipped__c = TypeConversionCommons.englishToBoolean(item.MBSHIPPED);
        return product;
    }

    /*********************************************************/
    /******************** INNER CLASSES **********************/
    /*********************************************************/

    public class MaterialBankIssue {
        public String projectName;
        public String customerName;
        public Boolean isError;
        public String comments;
    } // MaterialBankIssue

}