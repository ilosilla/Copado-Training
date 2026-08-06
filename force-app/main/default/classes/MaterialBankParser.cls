/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Leads
* @description 	Class to parse the XML received from Material Bank and to launch the lead creation process.
*               It implmenetes AbstractStreamParser because it can be called from RESTStreamService.
*               Use "MaterialBankParserTest" and "materialBankTest" to reach the coverage of this class.
*/
public virtual class MaterialBankParser extends AbstractStreamParser {

    Map<String, MBProject> projects;
    Map<String, Integer> projectKeys;
    Integer projectIdLength = 32;
    protected Boolean isEurope = false;
    SystemLog logger;

    public virtual void setEurope() {
        this.isEurope = false;
    }

    /**
     * Parses 
     */
    public override Boolean parse() {
        this.logger = new SystemLog('MATERIAL-BANK');
        if (this.isEurope) {
            this.logger.setTag('EUROPE');
            this.logger.addInfo('Parsing EUROPE project');
        } else {
            this.logger.setTag('USA');
            this.logger.addInfo('Parsing USA project');
        }
        this.setEurope();
        this.projects = new Map<String, MBProject>();
        projectKeys = new Map<String, Integer>();
        DOM.Document doc =new DOM.Document(); 
        try {        
            doc.load(this.content);        
            DOM.XmlNode rootNode = doc.getRootElement();     
            DOM.XmlNode topRow = rootNode.getChildElement('row', null);
            for (Dom.XmlNode child : topRow.getChildElements()) {
                if (child.getName() == 'row') {
                    this.readCustomer(child);
                }
            }
            this.logger.addInfo('Material Bank file parsed succesfully!');
            this.logger.saveLog(true);
        } catch (exception e) {        
            this.logger.addError(e);
            this.logger.saveLog(true);
            throw new ParseException('[MaterialBankParser] ' + e.getMessage());
        }
        return true;
    } // parse

    public override String execute() {
        this.setEurope();
        if (this.projects.values().size() > 0) {
            MaterialBankProject project = new MaterialBankProject(this.fileName, this.projects.values());
            project.setEurope(this.isEurope);
            Database.executeBatch(project);
        }
        return 'Job submitted - check logs ' + this.isEurope;
    } // execute

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    
    private MBCustomer readCustomer(Dom.XmlNode node) {
        MBCustomer customer = new MBCustomer();
        MBOrder[] orders = new List<MBOrder>();
        Map<String, Object> fields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(customer));
        for (Dom.XmlNode child : node.getChildElements()) {
            String key = child.getName().toUpperCase();
            if (key == 'ROW') {
                MBOrder order = this.readOrder(child);
                orders.add(order);
            } else if (fields.containsKey(key)) {
                fields.put(key, child.getText());
            }
        }    
        customer = (MBCustomer) JSON.deserialize(JSON.serialize(fields), MBCustomer.class);   
        this.consolidateProjects(customer, orders);
        return customer;
    }

    private MBOrder readOrder(Dom.XmlNode node) {
        MBOrder order = new MBOrder();
        MBItem[] items = new List<MBItem>();
        Map<String, Object> fields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(order));
        for (Dom.XmlNode child : node.getChildElements()) {
            String key = child.getName().toUpperCase();
            if (key == 'ROW') {
                MBItem item = this.readItem(child);
                items.add(item);
            } else if (fields.containsKey(key)) {
                fields.put(key, child.getText());
            } 
        }    
        order = (MBOrder)JSON.deserialize(JSON.serialize(fields), MBOrder.class);        
        order.items = items;
        return order;
    }
    
    private MBItem readItem(Dom.XmlNode node) {
        MBItem item = new MBItem();
        Map<String, Object> fields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(item));
        for (Dom.XmlNode child : node.getChildElements()) {
            String key = child.getName().toUpperCase();
            if (fields.containsKey(key)) {
                fields.put(key, child.getText());
            } 
        }    
        item = (MBItem)JSON.deserialize(JSON.serialize(fields), MBItem.class);        
        return item;
    }

    private void consolidateProjects(MBCustomer customer, MBOrder[] orders) {        
        for (MBOrder order: orders) {
            for (MBItem item : order.items) {
                MBProject project;
                String pid = this.buildProjectId(order.ORDERID, item.PROJECTNAME);
                if (this.projects.containsKey(pid)) {
                    project = this.projects.get(pid);
                    project.items.add(item);
                } else {
                    project = new MBProject();
                    project.id = pid;
                    project.orderId = pid;
                    project.trackingNo = order.TRACKINGNO;
                    project.customer = customer;
                    project.projectName = item.PROJECTNAME;
                    project.projectType = item.PROJECTTYPE;
                    project.projectPhase = item.PROJECTPHASE;
                    project.projectDescription = item.PROJECTDESCRIPTION;
                    project.items = new List<MBItem>();
                    project.items.add(item);
                    this.prepareProject(project);
                    this.projects.put(project.id, project);
                } // if
            } // items loop
        } // orders loop
    } // consolidateProjects

    private void prepareProject(MBProject project) {
        // Si no tenemos CONTACTNAME cogemos el SHIPPEDNAMe
        if (project.customer.CONTACT1NAME == null) {
            project.customer.CONTACT1NAME = project.customer.SHIPPED1NAME;
            if (project.customer.CONTACT1EMAIL.containsIgnoreCase('porcelanosa')) {
                project.porcelanosaEmail = project.customer.CONTACT1EMAIL;
                project.customer.CONTACT1EMAIL = project.customer.SHIPPED1EMAIL;
            }
        }
    } // prepareProject

    @testVisible private String buildProjectId(String orderId, String projectName) {
        if (projectName == null) {
            projectName = '';
        }
        String normalizedName = projectName.replace(' ', '#');
        normalizedName = normalizedName.toUpperCase();
        Integer maxlength = this.projectIdLength - orderId.length() - 2;
        maxLength = math.min(maxLength, projectName.length());
        normalizedName = normalizedName.substring(0, maxLength);
        return 'MB' + orderId + normalizedName;
    }

    /*********************************************************/
    /********************* INNER CLASSES *********************/
    /*********************************************************/

    public class MBProject { 
        public String id;       
        public String orderId;
        public String trackingNo;
        public String projectName;
        public String projectPhase;
        public String projectType;
        public String projectDescription;
        public String porcelanosaEmail;
        public MBCustomer customer;
        public MBItem[] items;
    }

    public class MBCustomer {
        public String CONTACT1NAME;
        public String ORDERED1NAME;
        public String SHIPPED1NAME;
        public String ENTITYID;
        public String CONTACT1EMAIL;
        public String SHIPPED1EMAIL;
        public String CONTACT1PHONE;
        public String STREET1;
        public String COMPANY;
        public String CITY;
        public String STATE;
        public String ZIP;
        public String COUNTRY;
        public String COMPANYPRACTICE;
        public String TITLE;
        public String CONTACTPREFERENCE;
    }
    public class MBOrder {
        public String ORDERID;
        public String TRACKINGNO;
        public MBItem[] ITEMS;
    }
    public class MBItem {
        public String PROJECTNAME;
        public Double QTYORIGINAL;
        public String SKU;
        public String NAME; 
        public String MBSHIPPED;
        public String MBSKU;
        public String SERIALSKU;
        public String COLOR;
        public String PROJECTTYPE;
        public String PROJECTPHASE;
        public String PROJECTDESCRIPTION;
    }
    public class CreatedLead {
        public Boolean success;
        public String name;
        public String id;
        public String comments;
    }
                     
} // class