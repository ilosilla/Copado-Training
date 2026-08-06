({
    loadData : function(component) {
        component.set("v.spinner", true);
        var aux = this;
        Promise.all([
            this.getSalesOfficesData(component),
        	this.getUserSalesOffice(component),
            this.getPersonAccountRecordType(component)
		]
        ).then(function(results) {
            var salesOfficesData = results[0];
            var userSalesOfficeCode = results[1];
            var personAccountRecordType = results[2];
            component.set("v.userSalesOffice", userSalesOfficeCode);
            component.set("v.salesOfficesData", salesOfficesData);
            component.set("v.personAccountRecordType", personAccountRecordType);

            var userSalesOffice = JSON.parse(JSON.stringify(salesOfficesData.filter(function (el) {
                return el.SalesOffice__c.SalesOffice__c == userSalesOfficeCode;
            })));
            var defaultSalesOfficeValue = null;
                                    
            if (salesOfficesData.length > 0) {
             	if (userSalesOffice.length > 0) {
                    defaultSalesOfficeValue = userSalesOfficeCode;   
                } else {
                    defaultSalesOfficeValue = salesOfficesData[0].SalesOffice__c;
                }
                // Tranform date to local timezone
                var mydate = new Date().toLocaleDateString('fr-CA', {timeZone: $A.get("$Locale.timezone")});
                component.set("v.selectedDate", mydate);
                if ($A.get("$Browser.isPhone") == false) {
                    component.find("filterDate").set("v.value", mydate);   
                }
                component.set("v.selectedSalesOffice", defaultSalesOfficeValue);
                if ($A.get("$Browser.isPhone") == false) {
                    component.find("salesOfficeFilter").set("v.value", defaultSalesOfficeValue);
                }
                aux.setTableColumns(component);
                aux.refreshWaitingPersons(component);
                aux.getUsers(component);
            } else {
                component.set("v.spinner", false);
            }
            
            var listOptionsTransformed = [{'label': $A.get('$Label.c.dict_createPrivateAccount'), 'value': 'transformToAccount'},
                						{'label': $A.get('$Label.c.dict_createContact'), 'value': 'transformToContact'}];
           	component.set("v.transformOptions", listOptionsTransformed);
            
        }).catch(function (err) {
            console.log(err);
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            component.set("v.spinner", false);
        });
    },
    /**
     * Se encarga de recrear la tabla de waiting list
     */
    refreshWaitingPersons : function(component) {
        component.set("v.spinner", true);
        var aux = this;
        this.getWaitingPersonsData(component).then(function(results){
            var waitingPersonsData = results;
            waitingPersonsData.forEach(function(person){
                person['LocaleTime'] = new Date(person.CreatedDate).toLocaleTimeString([], {timeZone: $A.get("$Locale.timezone"), hour: '2-digit', minute:'2-digit'});
                person['SalespersonName'] = person.Salesperson__r != null ? person.Salesperson__r.Name : null;
                person['ContactUrl'] = person.Contact__c == null ? '' : '/lightning/r/Contact/' + person.Contact__c + '/view';
                person['AccountUrl'] = person.Account__c == null ? '' : '/lightning/r/Account/' + person.Account__c + '/view';
                person['ContactName'] = person.Contact__c == null ? '' : person.Contact__r.Name;
                person['AccountName'] = person.Account__c == null ? '' : person.Account__r.Name;
            });
            component.set("v.waitingPersonsData", waitingPersonsData);
            aux.filterWaitingPersons(component);
            var valueSelected = component.get("v.selectedSalesOffice");
            var salesOffices = component.get("v.salesOfficesData");
            var salesOfficeSelectedId = salesOffices.findIndex(item => item.SalesOffice__c == valueSelected);
            var salesOfficeTextSelected = '';
            if (salesOfficeSelectedId >= 0) {
                salesOfficeTextSelected = salesOffices[salesOfficeSelectedId].Name;
            }
            component.set("v.salesOfficeSelectedName", salesOfficeTextSelected);
            component.set("v.spinner", false);
        }).catch(function (err) {
            console.log(err);
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            component.set("v.spinner", false);
        });
    },
    /**
     * Recoge todos los usuarios de la oficina de venta seteada
     */
    getUsers : function(component) {
        var aux = this;
        this.getUsersAjax(component).then(function(results){
            var users = results;
            users.forEach(function(user){
                user['value'] = user.Id;
                user['label'] = user.Name;
            });
            component.set("v.usersData", users);
        }).catch(function (err) {
            console.log(err);
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            component.set("v.spinner", false);
        });
    },
    /**
     * Se encarga de refrescar la lista de entradas de Waiting List, según los filtros seteados
     */
  	getWaitingPersonsData : function(component) {
        var salesOfficeSelected = component.get("v.selectedSalesOffice");
        var dateSelected = component.get("v.selectedDate");
        console.log('***************');
        console.log(dateSelected);
      	var action = component.get("c.getWaitingPersonsData");
        action.setParams({
        	salesOffice: salesOfficeSelected,
            dateFilter: dateSelected
      	});
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) {
              var strStatus =  $A.get('$Label.c.dict_updatedAt');
              strStatus = strStatus.replace('&1', new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
              component.set("v.statusUpdatedAt", strStatus);
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {
                  reject(response.getError()[0]);
              }            
            }); 
            $A.enqueueAction(action);
        });       
  	},
    /**
     * Se encarga de recoger todas las of de venta que tiene waiting list activo
     */
    getSalesOfficesData : function(component) {
      	var action = component.get("c.getSalesOffice");
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });         
  	},
    /**
     * Recoge la oficina de venta del usuario activo
     */
    getUserSalesOffice : function(component) {
        var action = component.get("c.getUserSalesOffice");
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response, component) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
  	},
    /**
     * Recoge el recordType para crear el Person Account
     */
    getPersonAccountRecordType : function(component) {
        var action = component.get("c.getPersonAccountRecordType");
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response, component) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
  	},
    /**
     * Filtra la lista según el status
     */
    filterWaitingPersons : function(component) {
        var originalList = component.get("v.waitingPersonsData");
        var filteredList = {};
        var filterValueData = component.get("v.waitingPersonStatusFilter");
        if (originalList != null && originalList.length > 0) {
            filteredList = JSON.parse(JSON.stringify(originalList.filter(function (el) {
                if (filterValueData == 'WAITING') {
                    return el.Status__c == 'ONQUEUE' || el.Status__c == 'ASSIGNED';
                } else {
                 	return el.Status__c == filterValueData;   
                }
            })));
        }
        component.set("v.waitingPersonsDataFiltered", filteredList);
    },
    getRowActions: function (component, row, doneCallback) {
        var statusFilter = component.get("v.waitingPersonStatusFilter");
        var actions = [];
        var aux = new Date(component.get("v.selectedDate"));
        var mydate = new Date(new Date().toLocaleDateString('fr-CA', {timeZone: $A.get("$Locale.timezone")}));
    	var auxString = aux.getFullYear() + '-' + aux.getMonth() + '-' + aux.getDate();
   		var todayString =  mydate.getFullYear() + '-' + mydate.getMonth() + '-' + mydate.getDate();
        
        actions = [{ label: $A.get('$Label.c.dict_edit'), name: 'editEntry', iconName: 'utility:edit'}];
        
        if ( auxString == todayString ) {
            if (statusFilter == 'WAITING') {
                actions.push({ label: $A.get('$Label.c.wlist_assignSalesman'), name: 'assignSalesperson', iconName: "utility:change_owner", title: 'JAJAJAJ' });
                actions.push({ label: $A.get('$Label.c.dict_assist'), name: 'assist', iconName: 'utility:people', title: '----------' });
                actions.push({ label: $A.get('$Label.c.dict_lost'), name: 'lost', iconName: 'utility:block_visitor', isDraft: true, draftAlternativeText: 'AGAGAG' });
            }
            if (statusFilter == 'INPROGRESS') {
                actions.push({ label: $A.get('$Label.c.wlist_createAccContact'), title: 'AAAAAAAAAAAAA', name: 'toAccount', iconName: 'utility:adduser' });
                actions.push({ label: $A.get('$Label.c.dict_completed'), name: 'completed', iconName : 'utility:retail_execution' });   
            }
            if (statusFilter == 'COMPLETED') {
                if (row.Transformed__c == false || ( row.Account__c == null && row.Contact__c == null ) ) {
                    actions.push({ label: $A.get('$Label.c.wlist_createAccContact'), name: 'toAccount', iconName: 'utility:adduser' });
                 }
            }
        }

        // simulate a trip to the server
        setTimeout($A.getCallback(function () {
            doneCallback(actions);
        }), 200);
    },
    /**
     * Configura la tabla de Waiting list
     */
	setTableColumns : function(component) {
        var rowActions = this.getRowActions.bind(this, component);
        var statusFilter = component.get("v.waitingPersonStatusFilter");
            
        var columns = [];
        if ($A.get('$Browser.isPhone') == true) {
            columns.push({
                label: $A.get('$Label.c.dict_name'),
                fieldName: 'Name__c',
                type: 'text',
                cellAttributes: {alignment: 'left'}
            });
            columns.push({
                label: $A.get('$Label.c.dict_time'),
                fieldName: 'LocaleTime',
                type: 'text',
                cellAttributes: {alignment: 'center', width: '50px'}
            });
            columns.push({
                type: 'action',
                typeAttributes: { rowActions: rowActions, title: 'LLLLALALLA'}
            });  
        } else {
            columns.push({
            label: $A.get('$Label.c.dict_status'),
            fieldName: 'labelStatus',
            type: 'text',
            cellAttributes: {alignment: 'center', class: 'slds-color__background_gray-4 slds-text-title_caps'}
        });
        columns.push({
            label: $A.get('$Label.c.dict_name'),
            fieldName: 'Name__c',
            type: 'text',
            cellAttributes: {alignment: 'left'}
        });
        columns.push({
            label: $A.get('$Label.c.dict_email'),
            fieldName: 'Email__c',
            type: 'text',
            cellAttributes: {alignment: 'center'}
        });
        columns.push({
            label: $A.get('$Label.c.dict_phone'),
            fieldName: 'Phone__c',
            type: 'text',
            cellAttributes: {alignment: 'center'}
        });
        columns.push({
            label: $A.get('$Label.c.dict_time'),
            fieldName: 'LocaleTime',
            type: 'text',
            cellAttributes: {alignment: 'center', width: '50px'}
        });
        
        columns.push({
            label: 'Account name',
            fieldName: 'AccountUrl',
            type: 'url',
            cellAttributes: { alignment: 'center' },
            typeAttributes: { label: {fieldName: 'AccountName'}}
        });
        
        columns.push({
            label: 'Contact name',
            fieldName: 'ContactUrl',
            type: 'url',
            cellAttributes: { alignment: 'center' },
            typeAttributes: { label: {fieldName: 'ContactName'}}
        });
        
        columns.push({
            label: 'Has an Appointment?',
            fieldName: 'Appointment__c',
            type: 'boolean',
            cellAttributes: { alignment: 'center' }
        });
        
        columns.push({
            label: $A.get('$Label.c.dict_salesperson'),
            fieldName: 'SalespersonName',
            type: 'text',
            cellAttributes: {alignment: 'center'}
        });
        
            columns.push({
                type: 'action',
                typeAttributes: { rowActions: rowActions, title: 'LLLLALALLA'}
            });   
        }
        
        component.set('v.tableColumns', columns);
    },
     /**
     * Guarda el nuevo comercial seleccionado en 'asignar comercial'
     */
    salesmanSelected : function(component, userId) {
        var filteredUsers = JSON.parse(JSON.stringify(component.get("v.usersData").filter(function (el) {
                return el.Id == userId;
            })));
        var usrSelected = null;
        if (filteredUsers.length > 0) {
            usrSelected = filteredUsers[0];
            component.set("v.selectedSalesman",true);
        } else {
            usrSelected = null;
            component.set("v.selectedSalesman",false);
        }
        component.set("v.newSalesmanSelected",usrSelected);
	},
     /**
     * Cambia el comercial asignado a una entrada del Waiting list
     */
        assistCustomer : function(component) {
            component.set("v.spinner", true);
            var aux = this;
            var waitingPerson = component.get("v.selectedRow");
            
            if (waitingPerson.Salesperson__c == null) {
                this.assignAssistCustomerAjax(component).then(function(results){
                    aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_salesmanAssigned'));
                    aux.closeModals(component);
                    aux.refreshWaitingPersons(component);
                }).catch(function (err) {
                    console.log(err);
                    aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
                    component.set("v.spinner", false);
                });
            } else {
                this.assistCustomerAjax(component).then(function(results){
                    aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_salesmanAssigned'));
                    aux.closeModals(component);
                    aux.refreshWaitingPersons(component);
                }).catch(function (err) {
                    console.log(err);
                    aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
                    component.set("v.spinner", false);
                });
            }
        },
        assignSalesperson : function(component) {
            component.set("v.spinner", true);
            var aux = this;
            this.assignSalespersonAjax(component).then(function(results){
                aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_salesmanAssigned'));
                aux.closeModals(component);
                aux.refreshWaitingPersons(component);
            }).catch(function (err) {
                console.log(err);
                aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
                component.set("v.spinner", false);
            });
        },
     /**
     * Cambia el status de una entrada del Waiting List
     */
    changeWaitingPersonStatus : function(component, status) {
        component.set("v.spinner", true);
        var aux = this;
        this.changeStatusAjax(component, status).then(function(results){
            aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_statusChanged'));
        	aux.refreshWaitingPersons(component);
        }).catch(function (err) {
            console.log(err);
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
    },
     /**
     * Cierra el modal de los formularios y setea valores por defecto
     */
    closeModals : function(component) {
        var modalForms = component.find('modalForms');
        var backdrop = component.find('backdropId');
        $A.util.removeClass(modalForms, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        component.set("v.newSalesmanSelected",null);
        component.set("v.selectedSalesman",false);
        component.set("v.transformSelectedValue",null);
        component.set("v.formSelected", null);
    },
    showSuccessMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "success"
        });
        toastEvent.fire();
    },
    showErrorMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "error"
        });
        toastEvent.fire();
    },
    /**
     * Activa o desactiva el botón de 'Nueva entrada', según si la fecha en el filtro es hoy
     */
    checkNewEntryButton : function(component) {
        var aux = new Date(component.get("v.selectedDate"));
        var today = new Date();
    	var auxString = aux.getFullYear() + '-' + aux.getMonth() + '-' + aux.getDate();
   		var todayString =  today.getFullYear() + '-' + today.getMonth() + '-' + today.getDate();
    	if (auxString != todayString) {
    		component.set("v.newPersonDisabled", true);
        } else {
            component.set("v.newPersonDisabled", false);
        }
	},
     /**
     * Hace un filtrado de la tabla según el estado de las entradas
     */
        filterTable: function(component, filterValue) {
            component.set("v.spinner", true);
            component.set("v.waitingPersonStatusFilter",filterValue);
            this.filterWaitingPersons(component);
            this.setTableColumns(component);
            component.set("v.spinner", false);
        },
     /**
     * Se crea una nueva Person Account con los datos del formulario
     */
     createNewPersonAccount : function(component, accountData) {
        component.set("v.spinnerModal", true);
         var waitingPerson = component.get("v.selectedRow");
        var aux = this;
        this.submitNewAccountAjax(component, waitingPerson.Id, accountData).then(function(results){
            aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_newPrivateAccount'));
            aux.closeModals(component);
            aux.refreshWaitingPersons(component);
            component.set("v.savingSomething", false);
        }).catch(function (err) {
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            component.set("v.spinnerModal", false);
            component.set("v.savingSomething", false);
        });
    },
     /**
     * Se crea un nuevo Contact con los datos del formulario
     */
  	createNewContact : function(component, contactData) {
        component.set("v.spinnerModal", true);
        var waitingPerson = component.get("v.selectedRow");
        var aux = this;
        this.submitNewContactAjax(component, waitingPerson.Id, contactData).then(function(results){
            aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_contactCreated'));
            aux.closeModals(component);
            aux.refreshWaitingPersons(component);
            component.set("v.spinnerModal", false);
            component.set("v.savingSomething", false);
        }).catch(function (err) {
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            component.set("v.spinnerModal", false);
            component.set("v.savingSomething", false);
        });
    },
     /**
     * Se crea una nueva entrada en la lista de Waiting List con los datos del formulario
     */
     createNewWLEntry : function(component, entryData) {
        component.set("v.spinnerModal", true);
        var aux = this;
        this.submitNewWLEntryAjax(component, entryData).then(function(results){
            aux.showSuccessMessage(component, $A.get('$Label.c.dict_success') + '!', $A.get('$Label.c.wlist_newEntry'));
            aux.closeModals(component);
            aux.refreshWaitingPersons(component);
            component.set("v.spinnerModal", false);
            component.set("v.savingSomething", false);
        }).catch(function (err) {
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            component.set("v.spinnerModal", false);
            component.set("v.savingSomething", false);
        });
    },
     /**
     *
     *
     * Llamadas Ajax de funciones anteriores
     * 
     * 
     */
  	getUsersAjax : function(component) {
        var salesOfficeSelected = component.get("v.selectedSalesOffice");
        var action = component.get("c.getUsers");
        action.setParams({
        	salesOffice: salesOfficeSelected
      	});
        return this.returnPromiseAjax(action);
  	},
    assignAssistCustomerAjax : function(component) {
        var newSalesperson = component.get("v.newSalesmanSelected");
        var waitingPerson = component.get("v.selectedRow");
        var waitingPersonId = waitingPerson.Id;
        var action = component.get("c.assignAndAssistSalesperson");
        action.setParams({
            salespersonId: newSalesperson == null ? null : newSalesperson.Id,
            waitingId: waitingPersonId
      	});
        return this.returnPromiseAjax(action);
    },
    assistCustomerAjax : function(component) {
        var waitingPerson = component.get("v.selectedRow");
        var waitingPersonId = waitingPerson.Id;
        var action = component.get("c.assistCustomer");
        action.setParams({
            waitingId: waitingPersonId
      	});
        return this.returnPromiseAjax(action);
    },
    assignSalespersonAjax : function(component) {
        var newSalesperson = component.get("v.newSalesmanSelected");
        var waitingPerson = component.get("v.selectedRow");
        var waitingPersonId = waitingPerson.Id;
        var action = component.get("c.assignSalesperson");
        action.setParams({
            salespersonId: newSalesperson.Id,
            waitingId: waitingPersonId
      	});
        return this.returnPromiseAjax(action);
    },
    changeStatusAjax : function(component, status) {
        var waitingPerson = component.get("v.selectedRow");
        var waitingPersonId = waitingPerson.Id;
        var action = component.get("c.changeStatus");
        action.setParams({
            newStatus: status,
            waitingId: waitingPersonId
      	});
        return this.returnPromiseAjax(action);
    },
	submitNewAccountAjax : function(component, waitingId, accountData) {
        var action = component.get("c.createNewPersonAccount");
        action.setParams({
            waitingId: waitingId,
            accountData: accountData,
      	});
        return this.returnPromiseAjax(action);
    },
   	submitNewContactAjax : function(component, waitingId, contactData) {
        var action = component.get("c.createNewContact");
        action.setParams({
            waitingId: waitingId,
            contactData: contactData,
      	});
        return this.returnPromiseAjax(action);
    },
   	submitNewWLEntryAjax : function(component, entryData) {
        var action = component.get("c.createNewWListEntry");
        action.setParams({
            entryData: entryData,
      	});
        return this.returnPromiseAjax(action);
    },
        returnPromiseAjax : function(action) {
            return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) {
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {
                  var errors = action.getError();
                  if (errors) {
                      if (errors[0] && errors[0].message) {
                          // System Error
                          reject(errors[0]);
                      } else if (errors[0] && errors[0].pageErrors) {
                          // DML Error
                          // （This sample code is corner-cutting. It does not consider the errors in multiple records and fields.）
                          reject(errors[0].pageErrors[0]);
                      }
                  }
              }
          	});         
      		$A.enqueueAction(action);
        });
        }
})