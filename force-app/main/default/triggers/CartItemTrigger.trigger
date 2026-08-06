trigger CartItemTrigger on CartItem (before update) {    
TriggerDispatcher.run(new CartItemTriggerHandler());
}