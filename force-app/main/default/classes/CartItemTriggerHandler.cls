public class CartItemTriggerHandler extends BaseTriggerHandler {
	public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
    }
    public static String loremIpsum() {
        string s = 'Lorem';
        s += 'Lorem';
        return s;
    }
}