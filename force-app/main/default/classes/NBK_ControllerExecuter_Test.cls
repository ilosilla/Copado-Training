/**
 * @description       : 
 * @author            : alberto.martinez@nubika.com
 * @group             : 
 * @last modified on  : 10-18-2021
 * @last modified by  : alberto.martinez@nubika.com
**/
@isTest
public class NBK_ControllerExecuter_Test {

    /* ------------------*/
    /*     EXCLUSIONS    */
    /* ------------------*/
    public static Set<String> excludeClassesList = new Set<String>{
        'NBK_ControllerFactory',
        'NBK_ControllerExecuter_Test',
        'NBK_ControllerManager',
        'NBK_IController'
    };


    /* ------------------*/
    /*        SETUP      */
    /* ------------------*/
    @TestSetup
    static void setupData(){}


    /* ----------------------*/
    /*      TEST METHODS     */
    /* ----------------------*/

    /* EXAMPLE CONTROLLER */
    @isTest
    static void executeExampleControllerMethodTest(){
        Test.startTest();
            executeExampleControllerMethod();
        Test.stopTest();
    }

    /* BASE TESTS */
    @isTest
    static void executerExceptionsTest(){
        Test.startTest();
            executerExceptionsMethod();
        Test.stopTest();
    }

    /* ----------------------*/
    /*    PRIVATE METHODS    */
    /* ----------------------*/

    private static void executeExampleControllerMethod(){
        executeControllers('Example', null);
        executeControllers('Example', new Map<String, Object>{
            NBK_ControllerExecuterConstants.PARAM_ACTION => 'action1'
        });
        executeControllers('Example', new Map<String, Object>{
            NBK_ControllerExecuterConstants.PARAM_ACTION => 'action2'
        });
    }

    private static void executerExceptionsMethod(){
        NBK_ControllerExecuter.getControllerData(null);
        NBK_ControllerExecuter.getControllerData(JSON.serialize(new map<String,Object>()));
        NBK_ControllerExecuter.executeAction(null);
        NBK_ControllerExecuter.executeAction(JSON.serialize(new map<String,Object>()));
    }

    /* ----------------------*/
    /*        TEST ALL       */
    /* ----------------------*/
    public static void testAll(){
        Test.startTest();
            executeExampleControllerMethod();
            executerExceptionsMethod();
        Test.stopTest();
    }


    /* -----------------------*/
    /*    PRIVATE EXECUTER    */
    /* -----------------------*/
    private static void executeControllers(String typeKey, Map<String, Object> customParams){
        String likeController = '%' + NBK_ControllerExecuterConstants.TEST_LIKE_CONTROLLER + '%';
        String likeNBK = NBK_ControllerExecuterConstants.TEST_LIKE_PREFFIX + '%';
        String likeType = '%' + typeKey + '%';
        
        List<ApexClass> apexClasses = [SELECT Id, Name FROM ApexClass 
            WHERE Name LIKE :likeNBK 
            AND Name LIKE :likeController 
            AND Name LIKE :likeType 
            AND (NOT Name LIKE '%test') 
            AND NAME NOT IN :excludeClassesList
        ];

        System.debug('### NBK_ControllerExecuter_Test - executeControllers() - [excludeClassesList]: ' + excludeClassesList);
        System.debug('### NBK_ControllerExecuter_Test - executeControllers() - [apexClasses.size()]: ' + apexClasses.size());
        
        System.debug('Excluded apexClasses: -- ' + excludeClassesList);
        for(ApexClass apexClassItem : apexClasses){
            System.debug('### NBK_ControllerExecuter_Test - executeControllers() - [Testing Class]: ' + apexClassItem.Name);
            Map<String, Object> params = new Map<String, Object>{
                NBK_ControllerExecuterConstants.PARAM_CONTROLLER => apexClassItem.Name
            };

            if(customParams != null) params.putAll(customParams);

            NBK_ControllerExecuter.getControllerData(JSON.serialize(params));
            NBK_ControllerExecuter.executeAction(JSON.serialize(params));
        }
    }


}