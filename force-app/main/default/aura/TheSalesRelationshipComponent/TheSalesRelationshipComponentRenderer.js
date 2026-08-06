({

    rerender : function(cmp, helper){
        console.log("-- rerender --");        
        this.superRerender();
		cmp.set("v.reRender", true);
        
    }

})