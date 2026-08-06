@isTest public with sharing class materialBankParserTest {

    // Casi todo se prueba desde RESTStreamService.post

    @isTest private static void testBuildProjectId() {
        MaterialBankParser parser = new MaterialBankParser();        
        
        // No need to truncate name
        String orderId = '1234567890123';
        String projectName = 'Saunders Homes';
        String pid = parser.buildProjectId(orderId, projectName);
        System.assertEquals('MB1234567890123SAUNDERS#HOMES', pid, 'Project Id not expected');

        // Name has to be truncated
        orderId = '1234567890123';
        projectName = 'Saunders Living Homes ';
        pid = parser.buildProjectId(orderId, projectName);
        System.assertEquals('MB1234567890123SAUNDERS#LIVING#H', pid, 'Project Id not expected');

        // Null name
        orderId = '1234567890123';
        projectName = null;
        pid = parser.buildProjectId(orderId, projectName);
        System.assertEquals('MB1234567890123', pid, 'Project Id not expected');


    }
    
}