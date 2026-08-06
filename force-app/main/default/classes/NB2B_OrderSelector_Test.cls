@IsTest
public with sharing class NB2B_OrderSelector_Test {
    @TestSetup
	public static void setupData(){
		NB2B_SetupClassTest.setupAllData();
	}

	public static void testAll(){
		Test.startTest();
		orderSelector_Test();
		Test.stopTest();
	}

	@IsTest
	public static void orderSelector_Test(){
		Test.startTest();
		orderSelectorTest();
		Test.stopTest();
	}

	private static void orderSelectorTest() {
        Order order1 = NB2B_SetupClassTest.getOrder();

        Set<Id> setId = new set<id>();
        setId.add(order1.Id);
		List<Order> orderById = NB2B_OrderSelector.getOrderById(setId);

		List<Order> orderItemById = NB2B_OrderSelector.getOrderAndOrderItemById(order1.Id);

        List<String> stringList = new List<String>();
        stringList.add(order1.Sap_Id__c);
		List<Order> orderItemBySap = NB2B_OrderSelector.getOrderAndOrderItemFromSap(stringList);

        List<String> orderNumList = new List<String>();
        orderNumList.add(order1.Ordernum__c);
		List<Order> orderByOrderNum = NB2B_OrderSelector.getOrderByOrderNum(orderNumList);

        List<Pedidos_posicionesSet__x> pedidosByOrderNum = NB2B_OrderSelector.getPedidosPosicionesById(orderNumList);
	}

}