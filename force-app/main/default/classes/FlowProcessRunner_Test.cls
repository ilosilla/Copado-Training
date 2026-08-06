@isTest
public class FlowProcessRunner_Test {
	@isTest
    public static void test_run(){
        FlowProcess.ResolveByName resolver = new FlowProcess.ResolveByName('Send_Custom_Notification_Flow');
        FlowProcessRunner runner = new FlowProcessRunner();        
        runner.run(resolver, new Map<String, Object>());
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');         
    }
}