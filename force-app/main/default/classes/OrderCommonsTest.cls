@isTest
private class OrderCommonsTest {
    @isTest
    static void testIsCollection() {
        // Configurar datos de prueba
        Order freeCollectionOrder = new Order();
        freeCollectionOrder.Type = OrdersDomain.FREE_COLLECTION_TYPE;
        
        Order collectionOrder = new Order();
        collectionOrder.Type = OrdersDomain.COLLECTION_TYPE;
        
        Order nonCollectionOrder = new Order();
        nonCollectionOrder.Type = 'SomeOtherType';
        
        // Llamar al método y verificar resultados
        System.assertEquals(true, OrderCommons.isCollection(freeCollectionOrder), 'Debe ser una orden de colección');
        System.assertEquals(true, OrderCommons.isCollection(collectionOrder), 'Debe ser una orden de colección');
        System.assertEquals(false, OrderCommons.isCollection(nonCollectionOrder), 'No debe ser una orden de colección');
    }
}