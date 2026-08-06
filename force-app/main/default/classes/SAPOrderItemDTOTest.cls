@isTest public with sharing class SAPOrderItemDTOTest {

    @isTest static void testTouch() {
        SAPOrderItemDTO dto = new SAPOrderItemDTO();
        dto.ProductCode = 'TEST';
        dto.touch();
        System.assertEquals('TEST', dto.ProductCode, 'Product code should remain unchanged after touch');
    }

}