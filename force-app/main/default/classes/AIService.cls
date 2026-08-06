/**
 * @author         Ramón Prades
 * @date           February 2025
 * @layer          Services
 * @description 
 *   
 * *Purpose:
 * *---------
 * AIService provides access to OpenAI's services through the API exposed by SAP CPI. 
 * It acts as an abstraction layer, ensuring that the underlying AI provider 
 * (currently OpenAI) can be replaced in the future without impacting the consuming 
 * applications. This design makes the transition between different AI engines 
 * seamless and transparent.
 * 
 * *Features:
 * *---------
 * - Connects to SAP CPI, which acts as a middleware for OpenAI API calls.
 * - Abstracts AI provider details, allowing for future AI engine changes.
 * - Provides a unified method for sending prompts and receiving AI-generated responses.
 * - Designed for easy extension to support additional AI providers in the future.
 * 
 * *Usage:
 * *-------
 * 
 * When you want a quick response to a simple prompt, use the static method:
 * 
 *      String response = AIService.getResponse('What is the capital of France?');
 *      System.debug(response);
 *
 * For more advanced usage, instantiate AIService to specify the role of the AI engine and the user role:
 * 
 *      AIService aiService = new AIService();
 *      aiService.setSystemRole('You are a geo service that answers geo questions in a brief and unabiguous manner');
 *      aiService.setUserRole('What is the capital of the state of California');
 *      String response = aiService.getResponse();
 *      System.debug(response); 
*/
public class AIService {   
    
    private String systemRole;
    private String userRole;
    private Decimal temperature = 0.5;
    private String model;
    private String jsonBody; 
    private String aiResponse;
    private Integer aiStatusCode;  
    private Integer timeout = 0;  

    /**
     * Sends a request to OpenAI via SAP CPI.
     * @param prompt The text input for AI processing.
     * @return The AI response.
     */
    public static String getResponse(String prompt) {
        AIService service = new AIService();
        service.setUserRole(prompt);
        return service.getResponse();
    }

    /**
     * Sets the system role
     */
    public void setSystemRole(String role) {
        this.systemRole = role;
    }

    /**
     * Sets the temperature
     */
    public void setTemperature(Decimal temperature) {
        this.temperature = temperature;
    }


    /**
     * sets the model
     */
    public void setModel(String model) {
        this.model = model;
    }

    /**
     * Sets the timeout
     */
    public void setTimeout(Integer milliseconds) {
        this.timeout = milliseconds;
    }

    /**
     * Sets the user role
     */
    public void setUserRole(String role) {
        this.userRole = role;
    }

    /**
     * Makes the query to the service
     */
    public String getResponse() {
        if (String.isBlank(this.userRole)) {
            throw new ValidationException('AIService Error: A prompt is required to generate a response. Please provide a valid input.');
        }
        this.jsonBody = this.buildJSONBody();
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.OPEN_AI_ENDPOINT);
        proxy.setMethod('POST');
        if (this.timeout > 0) {
            proxy.setTimeout(this.timeout);
        }
        proxy.setJSONBody(this.jsonBody);
        this.aiResponse = proxy.callCPI();
        this.aiStatusCode = proxy.getResponseCode();
        return this.parseAIResponse(this.aiResponse);
    }

    /**
     * Gets the AI response in the receivedf format
     */
    public String  getAIResponse() {
        return this.aiResponse;
    }

    /** 
     * Gets the status code
     */
    public Integer getStatusCode() {
        return this.aiStatusCode;
    }

    //*****************************************

    private String buildJSONBody() {
        AIRequestDTO request = new AIRequestDTO();
        request.model = this.model ?? SystemSettings.AIModel;
        request.temperature = this.temperature ?? 0.5;
        request.messages = new List<AIRequestMessageDTO>();        

        if (String.isNotBlank(this.systemRole)) {
            AIRequestMessageDTO systemMessage = new AIRequestMessageDTO();
            systemMessage.role = 'system';
            systemMessage.content = this.systemRole;
            request.messages.add(systemMessage);
        }

        if (String.isNotBlank(this.userRole)) {
            AIRequestMessageDTO userMessage = new AIRequestMessageDTO();
            userMessage.role = 'system';
            userMessage.content = this.userRole;
            request.messages.add(userMessage);
        }

        return JSON.serialize(request);
    }

    private String parseAIResponse(String jsonResponse) {
        try {
            // Parse the response JSON into a Map
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
    
            // Extract "choices" list
            List<Object> choices = (List<Object>) responseMap.get('choices');
            
            if (choices.isEmpty()) {
                throw new IllegalArgumentException('OpenAI response does not contain choices.');
            }
    
            // Extract the first choice
            Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
            Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
    
            // Extract and return the content
            return (String) message.get('content');
    
        } catch (Exception e) {
            throw new CalloutException('Error parsing OpenAI response: ' + e.getMessage());
        }
    }
    
    //*****************************************

    public class AIRequestDTO {
        public String model;
        public Decimal temperature;
        public List<AIRequestMessageDTO> messages;
    }

    public class AIRequestMessageDTO {
        public String role;
        public String content;
    }
    
}