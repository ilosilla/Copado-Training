({
    startFlow : function( component ) {
        var flowName = component.get( 'v.flowName' );
        if ( $A.util.isEmpty( flowName ) ) {
            return;
        }
        
        // dynamically creating components is done asynchronously
        // so we use a promise to chain our actions sequentially
        var p = new Promise( function( resolve, reject ) {
            $A.createComponent(
                'lightning:flow',
                {
                    'aura:id' : 'flow',
                    'onstatuschange' : component.getReference( 'c.handleFlowStatusChange' )                    
                },
                function( newCmp, status, errorMessage ) {
                    if ( status === 'SUCCESS' ) {
                        resolve( newCmp );
                    } else {
                        reject( errorMessage || status );
                    }
                }
            );            
        }).then( $A.getCallback( function( newFlowCmp ) {
            component.set("v.innerEvent", true);
            var flowContainer = component.find( 'flowContainer' );            
            flowContainer.get( 'v.body' ).forEach( function( cmp, idx ) {
                cmp.destroy();
            });            
            flowContainer.set( 'v.body', newFlowCmp );            
            var inputVariables = [
                {
                    name : 'recordId',
                    type : 'String',
                    value : component.get( 'v.recordId' )
                }
            ];            
            newFlowCmp.startFlow( flowName, inputVariables );             
        })).catch( $A.getCallback( function( err ) {            
            console.error( 'Error creating flow component' );
            console.error( err );            
        }));        
    },
    
    setComponentTitle : function (component, event) {
		var outputVars =  event.getParam('outputVariables');  
        if (outputVars) {
            outputVars.forEach( function(outputVar){
                if (outputVar.name == "v_flow_title") {
                    if (outputVar.value != null) {
                        component.set("v.title", outputVar.value);
                    }
                }
             } );
        }
    } // setComponentTItle
})