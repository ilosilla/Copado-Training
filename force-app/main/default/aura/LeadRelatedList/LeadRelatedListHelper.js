({
  getComponentData : function(cmp) {
      var errorList = [];
      cmp.set("v.spinner", true);
      var action = cmp.get("c.getComponentData");      
      action.setParams({
          objectId : cmp.get("v.recordId")
      }); 
      action.setCallback(this, function(response) {
          var strStatus =  $A.get('$Label.c.dict_updatedAt');
          strStatus = strStatus.replace('&1', new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));  
          cmp.set("v.spinner", false);
          var state = response.getState();
          var serverResponse = response.getReturnValue(); 
          if(state === "SUCCESS"){
              if (serverResponse.length > 0) {
                  cmp.set("v.noData", false);
              } else {
                  cmp.set("v.noData", true);
              }
              var leads = this.transformData(serverResponse);
              cmp.set("v.summaryData", leads);
              this.setSummaryColumns(cmp, leads);
              this.filterList(cmp);
          } else if(state === "INCOMPLETE") {
          } else if(state === "ERROR") {                    
              this.handleErrors(cmp, response.getError());
          }            
      });         
      $A.enqueueAction(action);
  },
  transformData : function(leadList) {
      leadList.forEach(function(part, index, theArray) {
          theArray[index].urlLead = window.location.origin + '/' + theArray[index].Id;
          theArray[index].urlAccount = theArray[index].AccountId__r != null ? window.location.origin + '/' + theArray[index].AccountId__c : null;
          theArray[index].accName = theArray[index].AccountId__r != null ? theArray[index].AccountId__r.Name : null;
          theArray[index].ownerName = theArray[index].Owner.Name;
      });
      return leadList;
  },
  filterList : function(cmp) {
      var stateActive = 'NEW';
      var originalList = cmp.get("v.summaryData");
      if (originalList.length > 0) {
       	var filterValue = cmp.find("selectFilter").get("v.value");
          var filteredList = null;
          if (filterValue == 'ACTIVE' && originalList.length > 0) {
              filteredList = JSON.parse(JSON.stringify(originalList.filter(function (el) {
                    return el.Status.toUpperCase() == stateActive;
                  })));
          } else {
              filteredList = JSON.parse(JSON.stringify(originalList));
          }
          cmp.set("v.summaryDataFiltered", filteredList);
          if (filteredList.length > 0) {
              cmp.set("v.noDataFiltered", false);
          } else {
              cmp.set("v.noDataFiltered", true);
          }   
      }
  },
setSummaryColumns : function(cmp) {
      var objectId = cmp.get("v.recordId");
      var col1 = '{!$Label.c.saps_hdr_docType}';
      var columns = [{label: $A.get('$Label.c.dict_name'), fieldName: 'urlLead', type: 'url', typeAttributes: { label: {fieldName: 'Name'}}, cellAttributes: {class: 'text-bold'}, target : '_subtab'}];
      if (objectId.startsWith('00Q')) {
          columns.push({label: $A.get('$Label.c.dict_account'), fieldName: 'urlAccount', type: 'url', typeAttributes: { label: {fieldName: 'accName'}}, cellAttributes: {class: 'text-bold'}, target : '_subtab'});
      }
      columns.push({label: $A.get('$Label.c.dict_email'), fieldName: 'Email', type: 'text', initialWidth: 250, cellAttributes: {alignment: 'center'}});
      columns.push({label: $A.get('$Label.c.dict_phone'), fieldName: 'Phone', type: 'text', cellAttributes: {alignment: 'center'}});
      columns.push({label: $A.get('$Label.c.dict_type'), fieldName: 'LeadType__c', type: 'text', cellAttributes: {alignment: 'center'}});
      columns.push({label: $A.get('$Label.c.dict_status'), fieldName: 'Status', type: 'text', cellAttributes: {alignment: 'center'}});
      columns.push({label: $A.get('$Label.c.dict_created'), fieldName: 'CreatedDate', type: 'date', cellAttributes: {alignment: 'center'}});
      columns.push({label: $A.get('$Label.c.dict_owner'), fieldName: 'ownerName', type: 'text', cellAttributes: {alignment: 'center'}});
      
      cmp.set('v.summaryColumns', columns);
  }
})