({
 	handleClick: function(cmp, event, helper) {
		var action = cmp.get("v.action");
        if (action) {
			var navigate = cmp.get('v.navigateFlow');
      		navigate(action);
        }
   }
})