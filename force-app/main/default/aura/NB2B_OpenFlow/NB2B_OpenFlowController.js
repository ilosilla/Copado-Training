({
    init : function (component) {
       
        var action = component.get("c.searchSku");
        if(component.get('v.textBox') != null && component.get('v.textBox') != ''){
            
        
            action.setParams({
                searchTerm : component.get('v.textBox').trimStart()
            });            
            //action.setCallback(this, response => this.showButton(component, response));
            action.setCallback(this, function(response) {
                var state = response.getState();
                var wrapper = response.getReturnValue();
                if (state === "SUCCESS" && wrapper != null && wrapper.isCorrect) {
                    var url;
                    if(wrapper.goToDetail){
                    	url = component.get("v.url");                        
                    }
                    if(wrapper.goToSearch){
                    	url = component.get("v.urlSearch");                        
                    }

                    var mode = component.get("v.mode");
                    var id = wrapper.productId;
                    var target = '_blank';
                    var urlRedirect = url + id;
                    var features = '';
                    //            alert(mode);
                    switch (mode) {
                        case 'replace':
                            target = '_self';
                            break;
                        case 'newWindow':
                            features = features + 'height=100';
                            break;
                        default:
                            break;
                    }
                    //var urlEvent = $A.get("e.force:navigateToURL");
                    //urlEvent.setParams({
                     //   "url": urlRedirect
                    //});
                    //urlEvent.fire();
                    location.replace( urlRedirect, target, features );
                    resolve();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "No product found"
                    });
                    toastEvent.fire();
                }
                // window.open( url, target, features );
                
                
            });
            $A.enqueueAction(action);     
        }
    }
})