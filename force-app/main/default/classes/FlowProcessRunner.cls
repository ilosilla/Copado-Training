/**
 * Internal class interacts with the Apex Flow API to invoke a flow, pass inputs and collect outputs 
 *   @see FlowProcess
 **/
public class FlowProcessRunner {

    public Map<String, Object> run(FlowProcess.Resolver resolver, Map<String, Object> inputs) {
        Map<String, Object> responseObject = new Map<String, Object>();
        
        try{
            String flowName = resolver.resolve();
            Flow.Interview flow = Flow.Interview.createInterview(flowName, inputs);
            flow.start();            
        } catch(Exception ex){
            responseObject.put('error', ex.getMessage());            
        }        
        return responseObject;
    }

}