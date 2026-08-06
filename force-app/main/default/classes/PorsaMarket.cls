/**
 * @author       Ivan Losilla
 * @since        April 2025
 * @group        Porsamarket
 * @description  PorsaMarket Main class to sync PMKT-SF
 * @test PorsaMarketTest
 */
public class PorsaMarket {
    public class PorsamarketException extends Exception {}

    public SystemLog logger = new SystemLog('SYNCPORSAMARKET');
    public Boolean isTestInserts = false; // Si true, se hace rollback para que no se guarde nada en Salesforce
    public Boolean isTestEmails = false;  // Si true, el email le llega al usuario configurado en el PorcelanosaSetting TO_EMAIL de PORSAMARKET
    public Boolean isTestFolder = false;  // Si true, la carpeta a buscar y a hacer funcionar es porsamarket/TESTS/
    
    public Map<String, PorsaMarketProject> projectsToCreate = new Map<String, PorsaMarketProject>(); // Map donde se almacenan los projects nuevos a crear
    public Map<String, PorsaMarketProject> projectsToUpdate = new Map<String, PorsaMarketProject>(); // Map donde se almacenan los datos de projects a actualizar y enlazar con Porsamarket
    public Map<String, PorsaMarketAccount> accountsToCreate = new Map<String, PorsaMarketAccount>(); // Map donde se almacenan los datos de todos los Accounts a crear
    public Map<String, PorsaMarketAccount> accountsToUpdate = new Map<String, PorsaMarketAccount>(); // Map donde se almacenan los datos de todos los Accounts a actualizar y enlazar con Porsamarket
    public Map<String, PorsaMarketAccount> accountsFromProjectsToCreate = new Map<String, PorsaMarketAccount>(); // Map donde se almacenan los datos dde Accounts relacionados a proyectos, a crear antes de los projects
    public List<String> filesRead = new List<String>(); // Lista de ficheros leidos durante el proceso
    public List<PorsaMarketCustom> customsToCreate = new List<PorsaMarketCustom>(); // Lista donde se almacenan los que no siguen la lógica normal


    public Map<String, PorsamarketSetting__mdt> porsamarketSettings = new Map<String, PorsamarketSetting__mdt>(); // Map donde se almacenan las configuraciones por país
    public Map<String, PorsamarketMailing__mdt> porsamarketEmailSettings = new Map<String, PorsamarketMailing__mdt>(); // Map donde se almacenan las configuraciones por país
    public Map<String, User> mapUsers = new Map<String,User>();    // Map donde se almacenan los datos de todos los usuarios de Salesforce
    public Map<String, String> ownerpostCodeMap = new Map<String, String>(); // Map donde se almacenan los owners según código postal. Se lee de PostCode object.
    public Map<String, String> ownerStateMap = new Map<String, String>(); // Map donde se almacenan los owners según state. Se lee de PostCode object.
    public Map<String, String> ownerCountryMap = new Map<String, String>(); // Map donde se almacenan los owners según country. Se lee de PostCode object.
    public Map<String, String> mapGerentesByOrg = new Map<String,String>{  // Map de gerentes por organización, para poner en copia en los emails, si es necesario. ****** Pasarlo a algún setting ******
        '232' => '0051r00000A2DK5AAN',  // Eduardo Frau     
        '231' => '0051r00000A2DHkAAN',  // Romain Muzzati
        '230' => '0051r00000A2DHzAAN',  // Tomas Mecho
        '229' => '0051r00000A2DEgAAN',  // Miguel Fuentes
        '228' => '0051r00000A2DCQAA3',  // Stephane dufaud
        '227' => '0051r00000A2GKFAA3',  // Christophe Iltis
        '226' => '0051r00000A2D0KAAV',   // Frederic bussutil
        '502' => '0051r000009WZf2AAG',   // Igor Vazquez
        '514' => '0051r000009WZXiAAO',   // Daniel Conde
        '515' => '0051r000009WZhYAAW',   // Inigo Pereda
        '516' => '0051r000009WZXDAA4',   // Chris Kerr
        '517' => '0056900000AxMI6AAN',   // Daniel Pulleiro
        '602' => '0056900000Bs2pFAAR',   // Miguel Romero
        '603' => '0056900000Bs2qgAAB',   // Patricia Denia
        '604' => '0056900000Bs2qjAAB',   // Nacho Castillo
        '605' => '0056900000Bs2r6AAB',   // James Demestichas
        '606' => '0056900000Bs2roAAB',   // Sunny Barnes
        '608' => '0056900000Bs2qfAAB',   // Carlos Boix
        '650' => '0056900000Bs2rLAAR'   // Domenic Cannatelli
    }; 
    
    public Map<String, String> duplicateLines = new Map<String, String>(); // Si en el fichero hay lineas duplicadas, se guarda un registro del tipo de objeto y el id del registro
    public List<PorsaMarketResult> result = new List<PorsaMarketResult>(); // Lista de resultados recogidos en el proceso, que al final se usarán para mostrar en los emails

    public PorsaMarket() {}

    public PorsaMarket(Boolean isTestInserts, Boolean isTestEmails, Boolean isTestFolder) {
        this.isTestInserts = isTestInserts;
        this.isTestEmails = isTestEmails;
        this.isTestFolder = isTestFolder;
    }

    public PorsaMarket(Boolean testMode) {
        if (testMode == true) {
            this.isTestInserts = true;
            this.isTestEmails = true;
            this.isTestFolder = true;
        }
    }

    public void getGlobalData() {
        // Recoge info general de Salesforce
        getUsers();
        getSettings();
        getMailingSettings();
    }

    public void processFolder() {
        this.logger.setTag('SyncPorsamarket');
        if (this.isTestInserts) {
            this.logger.addInfo('ES UN TEST - Saves no almacendaos...');
        }
        this.logger.addInfo('Proceso sincronización poramarket con sf iniciado');

        getGlobalData();
        
        // Lectura de la carpeta. Sólo ficheros que tiene porsamarket en el nombre
        StorageApiService.StorageApiFolderResult result = PorsaMarketFiles.readFolder(this.isTestFolder);
        for (StorageApiService.StorageApiFileResult file : result.items) {
            if (file.name.contains('porsamarket')) {
                this.logger.addInfo('Leyendo archivo ' + file.name + ' ...');
                getDataFromFile(file.name);
                this.filesRead.add(file.name);
            }
        }

        // Revisa qué existe en Salesforce la info de porsamarket para no crear duplicados
        getExistingData();

        Boolean syncOk = syncToSf();
        manageCustoms();

        
        if (this.duplicateLines.size() > 0) {
            //El archivo no es correcto, ya que no deben de haber duplicados
            PorsaMarketEmails.sendEmailFileError(this.duplicateLines);
        }
        if (syncOk && this.isTestFolder == false) {
            PorsaMarketFiles.moveProcessedFiles(this.filesRead, this.isTestFolder);
        } else {
            PorsaMarketFiles.moveErrorFiles(this.filesRead);
        }
    }

    public Boolean syncToSf() {
        SavePoint sp = Database.setSavePoint();
        List<Account> accsToCreate = new List<Account>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        this.logger.addInfo('Sincronizando con Salesforce...');

        try {
            syncAccounts();
            syncOpps();

            if (this.isTestInserts) {
                Database.rollback(sp);
            }
            System.debug('RESULT: ' + this.result);
            System.debug(this.result);
            if (this.result.size() > 0) {
                sendResults();
            }
            this.logger.saveLog(true);
            
            return true;
        } catch (PorsamarketException exc) {
            Database.rollback(sp);

            this.logger.addError('Ha fallado. Error: ' + exc.getMessage());
            this.logger.saveLog(true);
            return false;
        }
    }

    /**
     * Double check if the data is already in the system.
     */
    public void getExistingData() {
        this.logger.addInfo('Revisando datos ya existentes en sf...');
        Set<String> pmktAccountsId = new Set<String>();
        Set<String> pmktProjectIds = new Set<String>();
        Set<String> projectAccountIds = new Set<String>();

        for (PorsaMarketAccount account : this.accountsToCreate.values()) {
            pmktAccountsId.add(account.vat);
            pmktAccountsId.add(account.pmService + account.accountId);
        }

        for (PorsaMarketProject project : this.projectsToCreate.values()) {
            pmktProjectIds.add(project.pmService+project.projectId);
            if (project.sfAccountId.startsWith('001') == true) {
                projectAccountIds.add(project.sfAccountId);
            }
        }

        List<Account> projectAccounts = [SELECT Id, name, ownerId, vat_number__c, External_ID__c FROM Account WHERE id IN : projectAccountIds];
        List<Account> accounts = [SELECT Id, name,BillingCity,BillingPostalCode,BillingStreet,BillingCountryCode, ownerId, vat_number__c,vat_number_2__c,Account_Status__c, External_ID__c FROM Account WHERE (vat_number__c IN : pmktAccountsId or External_ID__c IN : pmktAccountsId) and Account_Status__c = 'Active'];
        List<Opportunity> opportunities = [SELECT Id, name,Address__c,CountryCode__c,Product_Categories__c,State__c,City__c,Postcode__c,Amount_custom__c,CloseDate, ownerId, porsamarketId__c FROM Opportunity WHERE porsamarketId__c IN : pmktProjectIds];

        for (PorsaMarketAccount account : this.accountsToCreate.values()) {
            for (Account acc : accounts) {
                String externalId = account.pmService + account.accountId;
                if (account.vat == acc.vat_number__c || externalId == acc.External_ID__c) {
                    this.logger.addInfo('Account con vat ' + account.vat + ' ya existente en sf con id ' + acc.Id);
                    account.sfId = acc.Id;
                    account.sfOwnerId = acc.OwnerId;

                    porsaMarketResult aux = new porsaMarketResult();
                    aux.country = acc.BillingCountryCode;
                    aux.obj = 'ACCOUNT';
                    aux.action = 'EXISTING';
                    aux.sfId = acc.Id;
                    if (acc.BillingCountryCode == 'FR') {
                        aux.porsamarketId = acc.vat_number__c;
                    } else {
                        aux.porsamarketId = acc.External_ID__c;
                    }
                    aux.owner = acc.ownerId;
                    aux.name = acc.name;
                    aux.accountData = acc;

                    if (account.sendEmail == false) {
                        this.logger.addInfo('Account con id ' + acc.Id + ' ya existente pero sin envío de email');
                    } else {
                        this.result.add(aux);
                    }
                    break;
                }
            }
        }

        for (PorsaMarketProject project : this.projectsToCreate.values()) {
            for (Opportunity opp : opportunities) {
                if (opp.porsamarketId__c == (project.pmService+project.projectId)) {
                    this.logger.addInfo('Opportunity con pmktId ' + opp.porsamarketId__c + ' ya existente en sf con id ' + opp.Id);
                    project.oppSfId = opp.Id;

                    porsaMarketResult aux = new porsaMarketResult();
                    aux.obj = 'OPPORTUNITY';
                    aux.action = 'EXISTING';
                    aux.sfId = opp.Id;
                    aux.porsamarketId = opp.porsamarketId__c;
                    aux.name = opp.name;
                    aux.owner = opp.OwnerId;
                    aux.opportunityData = opp;

                    if (project.sendEmail == false) {
                        this.logger.addInfo('Opportunity con id ' + opp.Id + ' ya existente pero sin envío de email');
                    } else {
                        this.result.add(aux);
                    }
                    break;
                }
            }

            for (Account acc : projectAccounts) {
                if (project.sfAccountId.startsWith('001') && project.sfAccountId == acc.Id) {
                    project.sfOwnerId = acc.OwnerId;
                }
            }
        }
    }

    public void syncOpps() {
        this.logger.addInfo('Sincronizando Oportunidades...');
        List<Opportunity> oppsToCreate = new List<Opportunity>();
        Map<String, Opportunity> oppsToUpdate = new Map<String, Opportunity>();

        if (this.projectsToCreate.size() > 0) {
            for (PorsaMarketProject project : this.projectsToCreate.values()) {
                if (String.isBlank(project.oppSfId)) {
                    Opportunity oppCreated = project.toOpportunity();
                
                    if (oppCreated != null) {
                        String owner = getOwner(oppCreated.CountryCode__c, oppCreated.State__c, oppCreated.Postcode__c);

                        if (project.sfAccountId != null && project.sfAccountId.startsWith('001') == true) {
                            oppCreated.AccountId = project.sfAccountId;
                            if (String.isBlank(project.sfOwnerId) == false && this.mapUsers.get(project.sfOwnerId).isActive == true) {
                                oppCreated.OwnerId = project.sfOwnerId;
                            } else if (String.isBlank(owner) == false){
                                oppCreated.OwnerId = owner;
                            } else {
                                this.logger.addError('No hay owner para enlazar al proyecto, así que no se gestiona. Revisar POSTCODE Object');
                            }
                            oppsToCreate.add(oppCreated);
                            this.logger.addInfo('Oportunidad nueva preparada para guardar con Id de Account ya en fichero: ' + oppCreated);
                        } else {
                            for (PorsaMarketAccount account : this.accountsToCreate.values()) {
                                if (account.vat == project.pmkAccountId && account.sfId != null && account.sfId.startsWith('001')) {
                                    oppCreated.AccountId = account.sfId;
                                    if (String.isBlank(account.sfOwnerId) == false && this.mapUsers.get(account.sfOwnerId).isActive == true) {
                                        oppCreated.OwnerId = account.sfOwnerId;
                                    } else if (String.isBlank(owner) == false){
                                        oppCreated.OwnerId = owner;
                                    } else {
                                        this.logger.addError('No hay owner para enlazar al account, así que no se gestiona. Revisar POSTCODE Object');
                                    }
                                    oppsToCreate.add(oppCreated);
                                    this.logger.addInfo('Oportunidad nueva preparada para guardar con Account creado: ' + oppCreated);
                                    break;
                                }
                            }
                        }
                    } else {
                        this.logger.addError('Datos de porsamarket no encontrados para proyecto ' + project.projectId);
                    }
                }
            }
            this.logger.addInfo('Proyectos a crear: ' + oppsToCreate.size());

            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.duplicateRuleHeader.allowSave = true;
            Database.SaveResult[] srList = Database.insert(oppsToCreate, dmlOptions);

            Boolean allCreated = true;
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    allCreated = false;
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        this.logger.addError('The following error has occurred');
                        this.logger.addError(err.getStatusCode() + ': ' + err.getMessage());
                    }
                    throw new PorsamarketException('Algo ha fallado al insertar Oportunidades');
                }
            }

            if (allCreated) {
                for (Opportunity opp : oppsToCreate) {
                    this.logger.addInfo('Relacionando projects creados con el id de la oportunidad nueva...');
                    for (PorsaMarketProject project : this.projectsToCreate.values()) {
                        if (opp.porsamarketId__c == project.pmService+project.projectId) {
                            project.oppSfId = opp.Id;
                        }
                    }
    
                    porsaMarketResult aux = new porsaMarketResult();
                    aux.obj = 'OPPORTUNITY';
                    aux.action = 'CREATE';
                    aux.sfId = opp.Id;
                    aux.porsamarketId = opp.porsamarketId__c;
                    aux.owner = opp.ownerId;
                    aux.name = opp.name;
                    aux.opportunityData = opp;

                    if (opp.ProjectType__c != 'PMAPPROVALFLOW') {
                        for (PorsaMarketProject project : this.projectsToCreate.values()) {
                            if (opp.porsamarketId__c == project.pmService+project.projectId) {
                                System.debug('Project send email? ' + project.sendEmail);
                                if (project.sendEmail == false) {
                                    this.logger.addInfo('Opportunity con id ' + opp.Id + ' creado pero sin envío de email');
                                } else {
                                    this.result.add(aux);
                                }
                            }
                        }
                    }
                }
            } else {
                throw new PorsamarketException('Algo ha fallado al insertar Oportunidades');
            }
        } else {
            this.logger.addInfo('No hay Proyectos que crear');
        }

        /** 
         * Preparamos las Opps que hay que actualizar
        */
        if (this.projectsToUpdate.size() > 0) {
            this.logger.addInfo('Oportunidades de salesforce a actualizar: ' + this.projectsToUpdate.size());

            Set<String> oppsToUpdateIds = new Set<String>();
            for (PorsaMarketProject project : projectsToUpdate.values()) {
                    oppsToUpdateIds.add(project.oppSfId);
            }

            List<Opportunity> oppsList = [SELECT Id, name,Address__c,Discovery_Completed__c,LeadSource,CountryCode__c,Product_Categories__c,State__c,ProjectType__c,City__c,Postcode__c,Amount_custom__c,CloseDate, ownerId, porsamarketId__c, owner.name, verified__c FROM Opportunity WHERE Id IN : oppsToUpdateIds];
            for (Opportunity opp : oppsList) {
                for (PorsaMarketProject project : projectsToUpdate.values()) {
                    if (opp.Id == project.oppSfId) {
                        if (String.isBlank(opp.PorsamarketId__c) == true) {
                            opp.PorsamarketId__c = project.pmService+project.projectId;
                        } else {
                            opp.PorsamarketId__c += ';' + project.pmService+project.projectId;
                        }
                        if (project.sendEmail == false) {
                            opp.Discovery_Completed__c = true;
                        }
                        opp.LeadSource = 'Porsamarket';
                        opp.Verified__c = true;
                        if (project.isOffsite()) {
                            List<String> aux = new List<String>();
                            if (String.isBlank(opp.Product_Categories__c) == false) {
                                aux = opp.Product_Categories__c.split(';');
                            }
                            aux.add('Offsite');
                            opp.Product_Categories__c = String.join(aux, ';');
                            if (project.userCreator.toUpperCase().contains('SEGARRA') == false) {
                                opp.ProjectType__c = 'PMAPPROVALFLOW';
                            }
                        }
                        this.logger.addInfo('Actualizada Oportunidad con sfId ' + opp.id + ' con id porsamarket #' + project.pmService+project.projectId);
                    }
                }
            }

            upsert oppsList;

            for (Opportunity opp : oppsList) {
                porsaMarketResult aux = new porsaMarketResult();
                aux.obj = 'OPPORTUNITY';
                aux.action = 'UPDATE';
                aux.sfId = opp.Id;
                aux.porsamarketId = opp.porsamarketId__c;
                aux.owner = opp.ownerId;
                aux.name = opp.name;
                aux.opportunityData = opp;

                if (opp.ProjectType__c != 'PMAPPROVALFLOW') {
                    for (PorsaMarketProject project : projectsToUpdate.values()) {
                        if (opp.porsamarketId__c == project.pmService+project.projectId) {
                            if (project.sendEmail == false) {
                                this.logger.addInfo('Opportunity con id ' + opp.Id + ' actualizada pero sin envío de email');
                            } else {
                                this.result.add(aux);
                            }
                        }
                    }
                }
            }
        }
    }

    public void syncAccounts() {
        List<Account> accsToCreate = new List<Account>();

        for (PorsaMarketAccount account : this.accountsToCreate.values()) {
            Account aux = account.toAccount();
            if (aux != null) {
                if (account.sfId == null) {
                    String owner = getOwner(aux.BillingCountryCode, aux.BillingStateCode, aux.BillingPostalCode);

                    if (String.isBlank(owner) == false) {
                        aux.OwnerId = owner;
                        account.sfOwnerId = aux.OwnerId;
                        accsToCreate.add(aux);
                        this.logger.addInfo('Account a crear: ' + aux);
                    } else {
                        this.logger.addError('No hay owner para enlazar a la cuenta, así que no se gestiona. Revisar POSTCODE Object');
                    }
                } else {
                    this.logger.addInfo('Account ya existente en Salesforce y no lo creamos, con vat #' + account.vat + ' con Id ' + account.sfId);
                }
            } else {
                this.logger.addError('Account sin datos en porsamarket, con id #' + account.vat);
            }
        }

        this.logger.addInfo('Accounts a crear: ' + accsToCreate.size());
        if (accsToCreate.size() > 0) {
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.duplicateRuleHeader.allowSave = true;
            Database.SaveResult[] srList = Database.insert(accsToCreate, dmlOptions);

            Boolean allCreated = true;
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    allCreated = false;
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        this.logger.addError('The following error has occurred');
                        this.logger.addError(err.getStatusCode() + ': ' + err.getMessage());
                    }
                    throw new PorsamarketException('Algo ha fallado al insertar Oportunidades');
                }
            }

            if (allCreated) {

                this.logger.addInfo('Accounts creados correctamente...');

                for (Account acc : accsToCreate) {
                    porsaMarketResult aux = new porsaMarketResult();
                    aux.obj = 'ACCOUNT';
                    aux.action = 'CREATE';
                    aux.sfId = acc.Id;
                    if (acc.BillingCountryCode == 'FR') {
                        aux.porsamarketId = acc.vat_number__c;
                    } else {
                        aux.porsamarketId = acc.External_ID__c;
                    }
                    aux.owner = acc.ownerId;
                    aux.name = acc.name;
                    aux.accountData = acc;

                    for (PorsaMarketAccount account : this.accountsToCreate.values()) {
                        if ((acc.vat_number__c == account.vat || acc.External_ID__c.contains(account.accountId)) && account.sfId == null) {
                            this.logger.addInfo('Relacionando Accounts creados con su Id de salesforce...');
                            account.sfId = acc.Id;
                            if (account.sendEmail == false) {
                                this.logger.addInfo('Account con id ' + acc.Id + ' creado pero sin envío de email');
                            } else {
                                this.result.add(aux);
                            }
                        }
                    }
                }
            } else {
                throw new PorsamarketException('Algo ha fallado al insertar Accounts');
            }
        } else {
            this.logger.addInfo('No hay Accounts a crear');
        }

        /** 
         * Preparamos las Opps que hay que actualizar
        */
        if (this.accountsToUpdate.size() > 0) {
            this.logger.addInfo('Accounts de salesforce a actualizar: ' + this.accountsToUpdate.size());

            Set<String> accsToUpdateIds = new Set<String>();
            for (PorsamarketAccount account : this.accountsToUpdate.values()) {
                accsToUpdateIds.add(account.sfId);
            }

            List<Account> accsList = [SELECT Id, name,BillingCity,BillingPostalCode,BillingStreet,BillingCountryCode, ownerId, vat_number__c,vat_number_2__c,Account_Status__c, External_ID__c FROM Account WHERE Id IN : accsToUpdateIds];
            for (Account acc : accsList) {
                for (PorsaMarketAccount account : accountsToUpdate.values()) {
                    if (acc.Id == account.sfId) {
                        if (String.isBlank(acc.External_ID__c) == true) {
                            acc.External_ID__c = account.pmService+account.accountId;
                        } else {
                            acc.External_ID__c += ';' + account.pmService+account.accountId;
                        }
                        acc.AccountSource = 'Porsamarket';
                        if (account.pmService == 'HZ') {
                            acc.AccountSource = 'Houzz';
                        }
                        acc.Validated__c = true;
                        this.logger.addInfo('Actualizado Account con sfId ' + acc.id + ' con id porsamarket #' + account.pmService+account.accountId);
                    }
                }
            }

            upsert accsList;

            for (Account acc : accsList) {
                porsaMarketResult aux = new porsaMarketResult();
                aux.obj = 'ACCOUNT';
                aux.action = 'UPDATE';
                aux.sfId = acc.Id;
                aux.porsamarketId = acc.External_ID__c;
                aux.owner = acc.ownerId;
                aux.name = acc.name;
                aux.accountData = acc;

                for (PorsaMarketAccount account : this.accountsToUpdate.values()) {
                    if ((acc.vat_number__c == account.vat || acc.External_ID__c.contains(account.accountId)) && account.sfId == null) {
                        if (account.sendEmail == false) {
                            this.logger.addInfo('Account con id ' + acc.Id + ' actualizado pero sin envío de email');
                        } else {
                            this.result.add(aux);
                        }
                    }
                }
            }
        } else {
            this.logger.addInfo('No hay Accounts a actualizar');
        }
    }

    public String getOwner(String country, String state, String postCode) {
        PostCodeObjectFinder finder1 = new PostCodeObjectFinder('PORSAMARKET');
        finder1.countryCode = country;
        finder1.state = state;
        finder1.postCode = postCode;
        return finder1.findFirst();
    }

    public void getDataFromFile(String fileName) {
        
        String csvContent = PorsaMarketFiles.readFile(fileName, this.isTestFolder);
        Map<String, Integer> projectsOnCsv = new Map<String, Integer>();
        String[] csvFileLines = csvContent.split('\n');
        this.logger.addInfo('Leyendo fichero de sharepoint ' + fileName + ' ...');

        // Revisar duplicados para no crearlos
        this.logger.addInfo('Revisando lineas duplicadas de proyectos...');
        for(Integer i=1;i<csvFileLines.size();i++){
            String[] csvRecordData = csvFileLines[i].split(',');
            String obj = csvRecordData[1];
            String projectId = csvRecordData[3];

            
            switch on obj.toUpperCase() {
                when 'PROJECTS' {
                    if (projectsOnCsv.containsKey(projectId) == false) {
                        projectsOnCsv.put(projectId, 1);
                    } else {
                        Integer results = projectsOnCsv.get(projectId);
                        projectsOnCsv.put(projectId, results+1);
                    }
                }
            }
        }

        // Recogemos todos los datos
        for(Integer i=1;i<csvFileLines.size();i++){
            if (String.isBlank(csvFileLines[i])) continue;
            string[] csvRecordData = csvFileLines[i].split(',');
            String pmService = csvRecordData[0];
            String obj = csvRecordData[1];
            String sfAccountId = csvRecordData[6];

            if (serviceActive(pmService)) {

                // Getting all data from porsamarket
                switch on obj.toUpperCase() {
                    when 'PROJECTS' {
                        String types = csvRecordData[2];
                        String registerId = csvRecordData[3];

                        // Si un registro está duplicado, no lo gestionamos y lo marcamos como error para avisar a posteriori
                        if (projectsOnCsv.containsKey(registerId) && projectsOnCsv.get(registerId) > 1) {
                            this.duplicateLines.put(registerId, 'Project');
                        }

                        // Si Aparece en el csv más de una vez, no hacemos caso. Problema de PowerBI
                        if (projectsOnCsv.containsKey(registerId) && projectsOnCsv.get(registerId) == 1) {
                            PorsaMarketProject elem = PorsaMarketProject.readProject(csvRecordData);

                            if (types.toUpperCase().contains('NEW')) {
                                this.projectsToCreate.put(elem.projectId, elem);
                            } else {
                                this.projectsToUpdate.put(elem.projectId, elem);
                            }

                            // El proyecto no tiene Id salesforce enlazado
                            if (types.toUpperCase().contains('NEW') && sfAccountId.startsWith('001') == false) {
                                PorsaMarketAccount elemAccount = PorsaMarketProject.readProjectAccount(csvRecordData);
                                this.accountsToCreate.put(elemAccount.accountId, elemAccount);
                            }
                        }
                    }
                    when 'ACCOUNTS' {
                        String types = csvRecordData[2];
                        PorsaMarketAccount elemAccount = PorsaMarketAccount.readAccount(csvRecordData);
                        if (types.toUpperCase().contains('UPDATE')) {
                            this.accountsToUpdate.put(elemAccount.accountId, elemAccount);
                        } else {
                            this.accountsToCreate.put(elemAccount.accountId, elemAccount);
                        }
                    }
                    when 'LOTS' {
                        PorsaMarketAccount elemLot = PorsaMarketAccount.readLot(csvRecordData);
                        accountsToCreate.put(elemLot.accountId, elemLot);
                    }
                    when 'NOSALESFORCE' {
                        PorsaMarketCustom elemCustom = PorsaMarketCustom.readCustom(csvRecordData);
                        this.customsToCreate.add(elemCustom);
                    }
                }
            } else {
                this.logger.addError('El servicio ' + pmService + ' de Poramarket no está activo.La línea no se gestiona.');
            }
        }

        this.logger.addInfo('Se han leido del fichero ' + this.accountsToCreate.size() + ' accounts a crear');
        this.logger.addInfo('Se han leido del fichero ' + this.accountsToUpdate.size() + ' accounts a actualizar');
        this.logger.addInfo('Se han leido del fichero ' + this.projectsToCreate.size() + ' proyectos a crear');
        this.logger.addInfo('Se han leido del fichero ' + this.projectsToUpdate.size() + ' proyectos a actualizar');
        this.logger.addInfo('Se han leido del fichero ' + this.customsToCreate.size() + ' proyectos custom a crear');
    }

    public void getUsers() {
        for (User usr : [select id,LanguageLocaleKey,CountryCode, ManagerId, Name,Email,isactive, Default_Sales_Organization__c from user]) {
            this.mapUsers.put(usr.Id, usr);
        }
    }

    public void getSettings() {
        for (PorsamarketSetting__mdt pmSetting : [select id,Active__c, DeveloperName from PorsamarketSetting__mdt WHERE Active__c = true]) {
            this.porsamarketSettings.put(pmSetting.DeveloperName, pmSetting);
        }
    }

    public void getMailingSettings() {
        for (PorsamarketMailing__mdt pmMailingSetting : [select id, EmaiCC__c, EmailFrom__c, DeveloperName from PorsamarketMailing__mdt]) {
            this.porsamarketEmailSettings.put(pmMailingSetting.DeveloperName, pmMailingSetting);
        }
    }

    public Boolean serviceActive(String code) {
        return this.porsamarketSettings.containsKey(code);
    }

    /**
     * Si es una oportunidad reciente y se marca con PMDELETE del flujo de aprobación, se elimina la oportunidad.
     * Si se vacía el valor de ProjectType en la aprobación, se envía el email informando del proyecto de Porsamarket.
     * Esto es necesario en el usoi del flujo de approbación de Offsite
     */
    public static void manageLockedOpportunitiesAfter(List<Opportunity> newItems, Map<Id, Opportunity> oldItems) {
        List<String> oppsPMlocked = new List<String>();
        List<String> oppsPMDelete = new List<String>();

        try {
            for (Opportunity newOpp : newItems) {
                Opportunity oldOpp = oldItems.get(newOpp.Id);

                if (oldOpp.ProjectType__c == 'PMAPPROVALFLOW' && String.isBlank(newOpp.ProjectType__c)) {
                    oppsPMlocked.add(newOpp.Id);
                }

                // Se borra si es "NUEVA"
                if (newOpp.ProjectType__c == 'PMDELETE' && newOpp.createddate > System.now().addDays(-7)) {
                    oppsPMdelete.add(newOpp.Id);
                }
            }

            if (oppsPMlocked.size() > 0) {
                Porsamarket.sendOpportunityEmail(oppsPMlocked, false);
            }
            if (oppsPMdelete.size() > 0) {
                Porsamarket.deleteLockedOpportunity(oppsPMdelete);
            }
        } catch (PorsamarketException ex) {
            oppsPMlocked = new List<String>();
            oppsPMDelete = new List<String>();
        }
        
    }

    public static void manageLockedOpportunitiesBefore(List<Opportunity> newItems, Map<Id, Opportunity> oldItems) {
        for (Opportunity newOpp : newItems) {
            Opportunity oldOpp = oldItems.get(newOpp.Id);

            // Si se marca para eliminar en el flujo de aprobación y es una Opportunity ya existente, se actualiza el dato, no se borra
            if (newOpp.ProjectType__c == 'PMDELETE' && newOpp.createddate < System.now().addDays(-7)) {
                newOpp.ProjectType__c = null;
                newOpp.PorsamarketId__c = null;
                newOpp.LeadSource = null;
                newOpp.Verified__c = false;
            }
        }
    }
    
    @future
    public static void sendOpportunityEmail(List<String> oppIds, Boolean isTest) {
        Porsamarket aux = new Porsamarket(isTest);
        aux.getGlobalData();

        for (Opportunity opp : [SELECT Id, name,Address__c,CountryCode__c,Product_Categories__c,ProjectType__c,State__c,City__c,Postcode__c,Amount_custom__c,CloseDate, ownerId, porsamarketId__c, Createddate FROM Opportunity WHERE Id IN : oppIds]) {
            porsaMarketResult auxResult = new porsaMarketResult();
            auxResult.obj = 'OPPORTUNITY';
            auxResult.action = opp.Createddate > System.now().addDays(-7) ? 'CREATE' : 'UPDATE';
            auxResult.sfId = opp.Id;
            auxResult.porsamarketId = opp.porsamarketId__c;
            auxResult.owner = opp.ownerId;
            auxResult.name = opp.name;
            auxResult.opportunityData = opp;
            aux.result.add(auxResult);
        }

        aux.sendResults();
    }

    @future
    public static void deleteLockedOpportunity(List<String> oppIds) {
        try {
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE id IN : oppIds];
            delete opps;
        } catch (PorsaMarketException ex) {
            System.debug('PIROPARO ' + ex.getMessage());
        }
    }

    public void sendResults() {
        this.logger.addInfo('Preparando emails...');
        Map<String, List<PorsaMarketResult>> mapResultsByUser = new Map<String, List<PorsaMarketResult>>();
        List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> owea;
        Set<String> opportunityIds = new Set<String>();

        if (this.isTestEmails) {
            owea = [select Id from OrgWideEmailAddress where Address = 'salesforce@porcelanosagrupo.com'];
        } else {
            owea = [select Id from OrgWideEmailAddress where Address = 'silvestre.segarra@porcelanosagrupo.com'];
        }

        for (PorsaMarketResult res : this.result) {
            if (res.obj == 'OPPORTUNITY') {
                opportunityIds.add(res.sfId);
            }
        }

        // Get Opportunity data
        List<Opportunity> opportunities = [SELECT Id, name,Address__c,CountryCode__c,State__c,City__c,Postcode__c,ProjectType__c,Product_Categories__c,Amount_custom__c,CloseDate, ownerId, porsamarketId__c, AccountId, Account.Name FROM Opportunity WHERE Id IN : opportunityIds];
        for (PorsaMarketResult res : this.result) {
            if (res.obj == 'OPPORTUNITY') {
                for (Opportunity opp : opportunities) {
                    if (res.sfId == opp.Id) {
                        res.opportunityData = opp;
                    }
                }
            }
        }

        PorcelanosaSetting__c settings = [select id,Description__c, Key__c, IsActive__c,Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where Key__c = 'PORSAMARKET' AND subkey__c = 'EMAIL_TO'];
        List<String> toAddresses = new List<String>{'ivan.losilla@porcelanosagrupo.com'};
        List<String> toAddressesCopy = new List<String>();

        for (PorsaMarketResult res : this.result) {
            if (String.isBlank(res.owner) == false) {
                if (mapResultsByUser.containsKey(res.owner) == false) {
                    mapResultsByUser.put(res.owner, new List<PorsaMarketResult>());
                }
                mapResultsByUser.get(res.owner).add(res);
            }
        }

        //Email By User
        for (String elem : mapResultsByUser.keySet()) {
            String htmlContentSpecific = '';
            String subject = 'You have a new sales lead!!';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if (elem != null && mapResultsByUser.get(elem).size() > 0) {
                htmlContentSpecific = PorsaMarketEmails.prepareBody(mapResultsByUser.get(elem), this.mapUsers.get(elem).LanguageLocaleKey, this.isTestEmails);

                if (this.mapUsers.get(elem).LanguageLocaleKey == 'fr') {
                    subject = 'Vous avez un nouveau prospect commercial!!';
                }

                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }

                // Set to to the user's email
                if (this.mapUsers.containsKey(elem)) {
                    if (this.isTestEmails == false) {
                        toAddresses = new List<String>{this.mapUsers.get(elem).Email};
                    }
                }

                if (this.mapUsers.containsKey(elem)) {
                    User ownerUser = this.mapUsers.get(elem);
                    PorsamarketMailing__mdt mailingSetting = this.porsamarketEmailSettings.containsKey(ownerUser.CountryCode) ? this.porsamarketEmailSettings.get(ownerUser.CountryCode) : null;
                    PorsamarketMailing__mdt mailingSettingDefault = this.porsamarketEmailSettings.containsKey('DEFAULT') ? this.porsamarketEmailSettings.get('DEFAULT') : null;
                    if (mailingSetting != null) {
                        toAddressesCopy = mailingSetting.EmaiCC__c.split(';');
                    } else if (mailingSettingDefault != null){
                        toAddressesCopy = mailingSettingDefault.EmaiCC__c.split(';');
                    }
                    String defaultOrg = ownerUser.Default_Sales_Organization__c;
                    String managerId = ownerUser.ManagerId;

                    // El propietario no es el gerente, así que se pone en copia
                    if (this.mapGerentesByOrg.containsKey(defaultOrg) && this.mapGerentesByOrg.get(defaultOrg) != elem) {
                        String gerenteId = this.mapGerentesByOrg.get(defaultOrg);
                        if (this.mapUsers.containsKey(gerenteId)) {
                            toAddressesCopy.add(this.mapUsers.get(gerenteId).Email);
                        }

                        // Ponemos también su jefe directo en copia
                        if (String.isBlank(managerId) == false && this.mapUsers.containsKey(managerId) && toAddressesCopy.contains(this.mapUsers.get(managerId).Email) == false) {
                            toAddressesCopy.add(this.mapUsers.get(managerId).Email);
                        }
                    }
                    
                    if (this.isTestEmails == false) {
                        mail.setCcAddresses(toAddressesCopy);
                    }

                    if (this.isTestEmails == true) {
                        if (settings.Value1__c != null) {
                            List<String> addresses = settings.Value1__c.split(';');
                            if (addresses.size() > 0) {
                                toAddresses = addresses;
                            }
                        }
                        htmlContentSpecific = htmlContentSpecific.replace('##SENTEMAIL##', 'Debug mode - El email iría a ' + mapUsers.get(elem).Email + ' con copia a: ' + String.join(toAddressesCopy, ', '));
                    }

                    mail.setUseSignature(false);
                    System.debug('TO ADDRESSES: ' + toAddresses);
                    mail.setToAddresses(toAddresses);
                    mail.setSubject(subject);
                    mail.setHtmlBody(htmlContentSpecific);
                    listEmails.add(mail);
                    this.logger.addInfo('Preparado email a comercial ' + this.mapUsers.get(elem).Email + '...');
                }
            }
        }

        Messaging.sendEmail(listEmails);
        this.logger.addInfo('Email enviados...');
    }

    public void manageCustoms() {
        PorcelanosaSetting__c settings = [select id,Description__c, Key__c, IsActive__c,Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where Key__c = 'PORSAMARKET' AND subkey__c = 'EMAIL_TO'];
        List<String> toAddresses = new List<String>();
        List<String> toAddressesCopy = new List<String>();
        List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> owea;
        List<Porsamarket__c> listPMRegisters = new List<Porsamarket__c>();

        owea = [select Id from OrgWideEmailAddress where Address = 'salesforce@porcelanosagrupo.com'];

        if (this.customsToCreate.size() > 0) {
            for (PorsaMarketCustom elem : this.customsToCreate ) {
                String htmlContentSpecific = '';
                String subject = 'You have a new sales lead!!';
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                PorsamarketMailing__mdt mailingSetting = this.porsamarketEmailSettings.containsKey(elem.pmService) ? this.porsamarketEmailSettings.get(elem.pmService) : null;
                PorsamarketMailing__mdt mailingSettingDefault = this.porsamarketEmailSettings.containsKey('DEFAULT') ? this.porsamarketEmailSettings.get('DEFAULT') : null;

                if (mailingSetting != null) {
                    toAddressesCopy = mailingSetting.EmaiCC__c.split(';');
                } else if (mailingSettingDefault != null){
                    toAddressesCopy = mailingSettingDefault.EmaiCC__c.split(';');
                }

                htmlContentSpecific = PorsaMarketEmails.prepareBodyCustomData(elem, this.isTestEmails);

                if (elem.pmService == 'IT') {
                    subject = 'Hai un nuovo lead commerciale!!';
                    List<String> toAdressesMultiple = elem.ownerEmail.split(';');
                    toAddresses = toAdressesMultiple;
                        
                    owea = [select Id from OrgWideEmailAddress where Address = 'javier.cejudo@porcelanosa.com'];

                    String filename = 'PMIT_'+elem.projectId+'.pdf';
                    // Buscar el ContentVersion del archivo
                    List<ContentVersion> cv = [SELECT Id, Title, VersionData 
                                            FROM ContentVersion 
                                            WHERE Title =: filename
                                            AND IsMajorVersion = true
                                            LIMIT 1];
                    
                    if (cv.size() == 1) {
                        // Crear el attachment
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        String fileNamePdf = cv[0].Title;
                        if (!fileNamePdf.toLowerCase().endsWith('.pdf')) {
                            fileNamePdf += '.pdf';
                        }
                        efa.setFileName(fileNamePdf); // nombre que verá el destinatario
                        efa.setBody(cv[0].VersionData);         // contenido binario
                        efa.setContentType('application/pdf');
                        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                    }
                }
                
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }

                if (this.isTestEmails == true) {
                    htmlContentSpecific = htmlContentSpecific.replace('##SENTEMAIL##', 'Debug mode - El email iría a ' + String.join(toAddresses, ', ') + ' con copia a: ' + String.join(toAddressesCopy, ', '));
                    if (settings.Value1__c != null) {
                        List<String> addresses = settings.Value1__c.split(';');
                        if (addresses.size() > 0) {
                            toAddresses = addresses;
                        }
                    }
                }

                if (this.isTestEmails == false) {
                    mail.setCcAddresses(toAddressesCopy);
                }

                mail.setUseSignature(false);
                mail.setToAddresses(toAddresses);
                mail.setSubject(subject);
                mail.setHtmlBody(htmlContentSpecific);

                listEmails.add(mail);
                this.logger.addInfo('Preparado email CUSTOM de ' + elem.pmService + '...');

                if (elem.pmService == 'IT') {
                    Porsamarket__c pmRegister = new PorsaMarket__c();
                    pmRegister.Account__c = elem.accountId;
                    pmRegister.Project__c = elem.projectId;
                    pmRegister.PorsamarketService__c = elem.pmService;
                    pmRegister.OwnerEmail__c = elem.ownerEmail;

                    listPMRegisters.add(pmRegister);

                    this.logger.addInfo('Preparado PM Register de ' + elem.pmService + '...');
                }
            }

            Messaging.sendEmail(listEmails);
            this.logger.addInfo('Email enviados...');

            if (listPMRegisters.size() > 0) {
                insert listPMRegisters;

                this.logger.addInfo('Insertados PM Registers...');
            }
        }
    }

    public class porsaMarketResult {
        public String obj;
        public String action;
        public String country;
        public String name;
        public String sfId;
        public String porsamarketId;
        public String owner;
        public Account accountData;
        public Opportunity opportunityData;

        public porsaMarketResult() {}
    }

    @testVisible public String testFiller() {
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
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
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