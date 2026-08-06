({
    
   selectRecord : function(cmp, evt, hlpr){
       
       console.log('selectRecord');
       
       var selectedRecord = cmp.get("v.record");
       console.log('selectedRecord ' + JSON.stringify(selectedRecord));
       
       
       var event = cmp.getEvent("oSelectedRecordEvent"); 
       event.setParams({"recordByEvent" : selectedRecord});  
       event.fire();
       
    }
    
})