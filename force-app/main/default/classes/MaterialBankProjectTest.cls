@isTest public with sharing class MaterialBankProjectTest {
    private String managersGroup = 'USMBManagers';

    @testSetup private static void testSetup() {
        Group[] groups = [select Id, DeveloperName from Group where DeveloperName = 'USMBManagers'];
        if (groups.size() == 0) {
            Group test = new Group();
            test.Name = 'USMBManagers';
            insert test;

            GroupMember member = new GroupMember();
            member.GroupId = test.Id;
            member.UserOrGroupId = UserInfo.getUserId();
            insert member;
        }
    }

    @isTest private static void MBCreateLead() {
        List<MaterialBankParser.MBProject> projects = new List<MaterialBankParser.MBProject>();
        projects.add(getProjectEU());
        MaterialBankProject mb = new MaterialBankProject(projects);
        Lead lead = mb.CreateMBLead(projects[0]);
        System.assertNotEquals(null, lead.Id);
        USLeadMailer mailer = new USLeadMailer(lead.id);
        Test.startTest();
        mailer.emailLeadOwner();
        Integer nsent = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertNotEquals(0, nsent, 'An email should have been sent');
    }

    @isTest private static void MBExecute() {
        List<MaterialBankParser.MBProject> projects = new List<MaterialBankParser.MBProject>();
        projects.add(getProject());
        projects.add(getProject()); // repetimos para testear excepciones
        MaterialBankProject mb = new MaterialBankProject(projects);
        Test.startTest();
        Database.executeBatch(mb);
        //USLeadMailer.summaryMaterialBank(ids, issues);
        Limits.getEmailInvocations();          
        Test.stopTest();
        Lead[] leads = [select Id from Lead];
        System.assertNotEquals(0, leads.size());
    }

    @isTest private static void MBCreateLeadEU() {
        List<MaterialBankParser.MBProject> projects = new List<MaterialBankParser.MBProject>();
        projects.add(getProject());
        MaterialBankProject mb = new MaterialBankProject(projects);
        mb.setEurope(true);
        Lead lead = mb.CreateMBLead(projects[0]);
        System.assertNotEquals(null, lead.Id);
        USLeadMailer mailer = new USLeadMailer(lead.id);
        mailer.setEurope(true);
        Test.startTest();
        mailer.emailLeadOwner();
        Integer nsent = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertNotEquals(0, nsent, 'An email should have been sent');    
    }

    @isTest private static void MBExecuteEU() {
        List<MaterialBankParser.MBProject> projects = new List<MaterialBankParser.MBProject>();
        projects.add(getProjectEU());
        projects.add(getProjectEU()); // repetimos para testear excepciones
        MaterialBankProject mb = new MaterialBankProject(projects);
        mb.setEurope(true);
        Test.startTest();
        Database.executeBatch(mb);
        //USLeadMailer.summaryMaterialBank(ids, issues);
        //Integer nsent = Limits.getEmailInvocations();          
        Test.stopTest();
        Lead[] leads = [select Id from Lead];
        System.assertEquals(0, leads.size());
    }


    ///////////////////////////////////////////////////////////

    private static MaterialBankParser.MBProject getProject() {

        MaterialBankParser.MBItem item = new MaterialBankParser.MBItem();
        item.PROJECTNAME = 'Retail';
        item.QTYORIGINAL = 1.0000;
        item.SKU = '100291822';
        item.NAME = 'Glass Blanco'; 
        item.MBSHIPPED = 'Y';
        item.MBSKU = '100046075';
        item.COLOR = 'Blanco';
        item.PROJECTTYPE = 'Other';
        item.PROJECTPHASE = 'Concept Design';
        item.PROJECTDESCRIPTION = 'Residential';

        MaterialBankParser.MBOrder order = new MaterialBankParser.MBOrder();
        order.ORDERID = '0007032161002';
        order.TRACKINGNO = '526729111079';
        order.items = new List<MaterialBankParser.MBItem>();
        order.items.add(item);

        MaterialBankParser.MBCustomer customer = new MaterialBankParser.MBCustomer();
        customer.CONTACT1NAME = 'Interior Oprions';
        customer.ORDERED1NAME = 'Michon Proctor';
        customer.SHIPPED1NAME = 'Interior Options';
        customer.ENTITYID = '32754';
        customer.CONTACT1EMAIL = 'design@interioroptions.cxm';
        customer.SHIPPED1EMAIL = 'design@interioroptions.cxm';
        customer.CONTACT1PHONE = '484-751';
        customer.STREET1 = '3500 Stotts Alley'; 
        customer.COMPANY = 'ID Enterprise';
        customer.CITY = 'Philadelphia';
        customer.STATE = 'Pennsylvania';
        customer.ZIP = '19129-1720';
        customer.COMPANYPRACTICE = 'Manufacturer/Distributor';
        customer.TITLE = 'Customer Service';
        customer.CONTACTPREFERENCE = 'Any';
    
        MaterialBankParser.MBProject project = new MaterialBankParser.MBProject();
        project.orderId = 'MB-0007032161002';
        project.trackingNo = '526729111079';
        project.projectName = 'Retail';
        project.projectPhase = 'Concept Design';
        project.projectType = 'Other';
        project.projectDescription = 'Residential';
        project.porcelanosaEmail = 'mproctor@porcelanosa-usa.cxm';
        project.customer = customer;
        project.items = order.items;

        return project;

    } // getProject

    private static MaterialBankParser.MBProject getProjectEU() {

        MaterialBankParser.MBItem item = new MaterialBankParser.MBItem();
        item.PROJECTNAME = 'Retail';
        item.QTYORIGINAL = 1.0000;
        item.SKU = '100291822';
        item.NAME = 'Glass Blanco'; 
        item.MBSHIPPED = 'Y';
        item.MBSKU = '100046075';
        item.COLOR = 'Blanco';
        item.PROJECTTYPE = 'Other';
        item.PROJECTPHASE = 'Concept Design';
        item.PROJECTDESCRIPTION = 'Residential';

        MaterialBankParser.MBOrder order = new MaterialBankParser.MBOrder();
        order.ORDERID = '0007032161002';
        order.TRACKINGNO = '526729111079';
        order.items = new List<MaterialBankParser.MBItem>();
        order.items.add(item);

        MaterialBankParser.MBCustomer customer = new MaterialBankParser.MBCustomer();
        customer.CONTACT1NAME = 'Interior Oprions';
        customer.ORDERED1NAME = 'Michon Proctor';
        customer.SHIPPED1NAME = 'Interior Options';
        customer.ENTITYID = '32754';
        customer.CONTACT1EMAIL = 'design@interioroptions.cxm';
        customer.SHIPPED1EMAIL = 'design@interioroptions.cxm';
        customer.CONTACT1PHONE = '484-751';
        customer.STREET1 = 'Calle Mayor 23'; 
        customer.COMPANY = 'ID Enterprise';
        customer.CITY = 'Almassora';
        customer.STATE = 'Castellón';
        customer.COUNTRY = 'ES';
        customer.ZIP = '12666';
        customer.COMPANYPRACTICE = 'Manufacturer/Distributor';
        customer.TITLE = 'Customer Service';
        customer.CONTACTPREFERENCE = 'Any';
    
        MaterialBankParser.MBProject project = new MaterialBankParser.MBProject();
        project.orderId = 'MB-0007032161002';
        project.trackingNo = '526729111079';
        project.projectName = 'Retail';
        project.projectPhase = 'Concept Design';
        project.projectType = 'Other';
        project.projectDescription = 'Residential';
        project.porcelanosaEmail = 'mproctor@porcelanosa-usa.cxm';
        project.customer = customer;
        project.items = order.items;

        return project;

    } // getProjectEU

}