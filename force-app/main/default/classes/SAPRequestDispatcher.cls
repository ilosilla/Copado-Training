/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          SAP
 * @description    
 * 
 * SAPRequestDispatcher
 * ====================
 * 
 * This class is responsible for processing SAP request queue items one at a time, in the exact order 
 * they were inserted. It implements the Queueable interface and supports HTTP callouts to interact with 
 * external SAP services.
 * 
 * The class is designed to work asynchronously and sequentially:
 * - The process is initiated via the public static method `processQueue()`, which acquires a concurrency lock.
 * - It uses `System.enqueueJob(...)` to launch itself as a Queueable job from the static context `startProcessing(...)`.
 * - Each job processes a single item and re-enqueues itself for the next item until the queue is fully processed.
 * 
 * The use of Queueable is necessary to:
 * - Respect Salesforce limitations that prevent DML operations from occurring before callouts in a single transaction.
 * - Ensure ordered processing of multiple items in the queue.
 * 
 * ⚠️ IMPORTANT:
 * Do not call instance methods like `execute()` or `processCurrentItem()` directly. These methods are intended to be 
 * used internally by the asynchronous job engine and should only be triggered through `processQueue()` or `startProcessing()`.
 * 
 * Logging is handled via a shared `SystemLog` instance that collects structured info, debug, and error messages throughout the run.
 * 
 * 🔐 Integrity Guarantee:
 * The class ensures operation integrity by skipping any further actions on a given object (same target ID) if a previous 
 * request on that object has failed. This avoids cascading errors or inconsistent state due to partial processing.
 * 
 * **IMPORTANT
 * TO ACHIEVE THE DESIRED COVERAGE RUN THE FOLLOWING TEST CLASSES:
 * - SAPRequestDispatcherTest
 * - FactoryQualityAPIHandlerTest
 */
@SuppressWarnings('PMD.ExcessiveParameterList')
public class SAPRequestDispatcher implements Queueable, Finalizer, Database.AllowsCallouts {

    public static Integer BLOCK_SIZE = 50;

    // INTEGRATION TYPES
    public static final String REQUEST_TYPE_SAP = 'SAP';
    public static final String REQUEST_TYPE_CPI = 'CPI';

    // STATIC CONSTANTS
    public static final String STATUS_QUEUED = 'QUEUED';
    public static final String STATUS_PROCESSED = 'PROCESSED';
    public static final String STATUS_ERROR = 'ERROR';
    public static final String STATUS_EXCEPTION = 'EXCEPTION';
    public static final String STATUS_BLOCKED = 'BLOCKED';
    public static final Integer MAX_RETRIES = 3;
    public static final String LOG_SCENARIO = 'SAP-DISPATCHER';
    public static final String QUEUE_NAME = 'SAP-REQUEST-QUEUE';  
    
    // INSTANCE PROPERTIES
    /*
    private Integer index;
    private List<Id> queuedItems;
    private String pin;
    private SystemLog logger;
    */
    private SAPDispatcherContext context;

    private Boolean singleRun = false;

    //

    // Tracks object IDs (e.g. AccountId, OrderId) that have failed previously
    //private Set<Id> failedObjectIds = new Set<Id>();

    // ---------------------------------------- STATIC METHODS TO MANAGE THE QUEUE ------------------------------------

    public static Boolean processItem() {        
        // Check  if the queue is enabled
        BLOCK_SIZE = 1;
        if (!SystemSettings.SAPDispatcherEnabled) {
            return false;
        }
        return processQueueNow();
    } 

    public static Boolean processQueue() {        
        // Check  if the queue is enabled
        if (!SystemSettings.SAPDispatcherEnabled) {
            return false;
        }
        return processQueueNow();
    } 

    public static Boolean processQueueNow() {
        // Lock and process
        Boolean processed = true;
        String pin = RaceConditionFlag.lock(QUEUE_NAME);
        if (pin != null) {
            SAPRequestDispatcher.startProcessing(pin);
        }  else {
            processed = false;
            //throw new ContextException('Queue locked by another process');
        }
        return processed;
    }

    public static void releaseQueue(String pin) {
        RaceConditionFlag.unlock(SAPRequestDispatcher.QUEUE_NAME, pin);
    }

    private static void startProcessing(String pin) {
        try {
            List<SAPRequestQueue__c> items = SAPRequestDispatcher.loadNextBlock('', BLOCK_SIZE);
            if (!items.isEmpty()) {            
                SAPDispatcherContext ctx = new SAPDispatcherContext();
                ctx.pin = pin;
                ctx.items = items;
                ctx.index = 0;
                ctx.failedIds = new Set<Id>();
                ctx.blockSize = BLOCK_SIZE;
                SAPRequestDispatcher.openBlock(ctx);
                SAPRequestDispatcher dispatcher = new SAPRequestDispatcher(ctx);
                System.enqueueJob(dispatcher);
            }
        } catch(Exception ex) {
            SAPRequestDispatcher.releaseQueue(pin);            
            throw ex;
        }
    }

    public static void setBlockSize(Integer size) {
        if (size > 0) {
            BLOCK_SIZE = size;
        }
    }

    private static SAPRequestQueue__c[] loadNextBlock(String lastSequence, Integer blockSize) {
        return [SELECT
                    Id, IsDeleted, Name, CreatedDate, SAPEndpoint__c, SAPAPIHandler__c, RequesterId__c, ActionRequested__c, 
                    Status__c,  Retries__c, Sequence__c, IsMultiple__c, Payload__c, Parameter__c,
                    ResponseCode__c, Response__c, OwnerId, Owner.Email, Owner.FirstName
                FROM SAPRequestQueue__c
                WHERE Status__c != :STATUS_PROCESSED
                 AND Sequence__c > :lastSequence
               ORDER BY Sequence__c
               LIMIT :blockSize];        
    }

    private static void openBlock(SAPDispatcherContext ctx) {
        ctx.logger = new SystemLog(LOG_SCENARIO);
        ctx.blockNumber++;
        ctx.logger.addInfo('==> Procesando bloque ' + ctx.blockNumber + ' con ' + ctx.items.size() + ' peticiones en cola');        
    }

    private static void closeBlock(SAPDispatcherContext ctx) {
        ctx.logger.addInfo(SystemLog.splitter);
        ctx.logger.addInfo('Bloque de ' + ctx.items.size() + ' elementos procesado');
        ctx.logger.saveLog(true);
    }
    
    // --------- CONSTRUCTOR Y MÉTODOS DE INSTANCIA PARA PROCESAR CADA ITEM ------------------

    public SAPRequestDispatcher(SAPDispatcherContext context) {
        this.context = context;
    }

    public void execute(QueueableContext context) {
        try {
            this.processCurrentItem();
        } catch (Exception ex) {
            throw ex;
        } finally {
            this.context.index++;   
            if (this.context.index < this.context.items.size()) {
                 System.attachFinalizer(this);
            } else {
                SAPRequestDispatcher.closeBlock(this.context);
                String lastSequence = String.valueOf(this.context.items[this.context.items.size() - 1].Sequence__c);
                List<SAPRequestQueue__c> nextBlock = SAPRequestDispatcher.loadNextBlock(lastSequence, this.context.blockSize);
                if (!nextBlock.isEmpty()) {
                    // Cargar siguiente bloque y reanudar
                    this.context.index = 0;
                    this.context.items = nextBlock;
                    SAPRequestDispatcher.openBlock(this.context);
                    System.attachFinalizer(this);
                    //SAPRequestDispatcher dispatcher = new SAPRequestDispatcher(this.context);
                    //System.enqueueJob(dispatcher);
                } else {
                    // Fin de la cola: liberar y cerrar log
                    this.context.logger.addInfo(SystemLog.splitter);
                    this.context.logger.addInfo('Último ítem procesado - Se libera la cola');
                    SAPRequestDispatcher.releaseQueue(this.context.pin);
                    this.context.logger.addInfo('Has Errors = ' + this.context.logger.hasErrors());
                    if (this.context.logger.hasErrors()) {
                        this.context.logger.setSummary('Cola SAP procesada con ERRORES');
                    } else {
                        this.context.logger.setSummary('Cola SAP procesada OK');
                    }
                    this.context.logger.SaveLog();
                }                
            }
        }
    }

      public void execute(FinalizerContext ctx) {
        if (ctx.getResult() == ParentJobResult.SUCCESS) {
             SAPRequestDispatcher dispatcher = new SAPRequestDispatcher(this.context);
             System.enqueueJob(dispatcher);
        } 
    }

    private void processCurrentItem() {      
        try {            
            SAPRequestQueue__c item = this.readItem();
            Boolean success = false;
            if (item.Retries__c < MAX_RETRIES) {
                success = this.dispatch(item); // internal method now
                update item;
            }
            if (!success & item.RequesterID__c != null) {
                this.context.failedIds.add(item.RequesterID__c);
            }
        } catch (Exception ex2) {
            this.context.logger.addError(ex2);
        }
    }

    private Boolean dispatch(SAPRequestQueue__c item) {
        Boolean result = false;        
        this.context.logger.addInfo(SystemLog.splitter);
        this.context.logger.addInfo(' Procesando item ' + this.context.index);  
        this.context.logger.addInfo(' Handler: ' + item.SAPAPIHandler__c);      

        if (item.RequesterID__c != null && this.context.failedIds.contains(item.RequesterID__c)) {
            item.Status__c = STATUS_BLOCKED;
            item.Message__c = fitQueueMessage('Item blocked by previous error');
            return true;
        }
    
        
        try {
            SAPAbstractAPIHandler apiHandler = this.getAPIHandler(item.SAPAPIHandler__c);
            item.Skipped__c = false;
            item.Retries__c++;            
            apiHandler.setSAPRequestItem(item);
            String payload = apiHandler.getPayload();         

            CalloutDTO resultDTO = new CalloutDTO();
            if (apiHandler.getRequestType() == REQUEST_TYPE_SAP) {
                resultDTO = this.dispatchSAPRequest(apiHandler, item, payload);
            } else if (apiHandler.getRequestType() == REQUEST_TYPE_CPI) {
                resultDTO = this.dispatchCPIRequest(apiHandler, item, payload);
            } else {
                throw new ContextException('Request type not supported');
            }
            if (String.isNotBlank(payload)) {
                if (payload.length() > 130000) {
                    item.Payload__c = payload.substring(0, 130000);
                } else {
                    item.Payload__c = payload;
                }
            }
            item.ResponseCode__c = resultDTO.statusCode;
            if (String.isNotBlank(resultDTO.response)) {
                if (resultDTO.response.length() > 32000) {
                    item.Response__c = resultDTO.response.substring(0, 32000);
                } else {
                    item.Response__c = resultDTO.response;
                }
            }
            if (resultDTO.success) {
                result = true;
                item.Status__c = SAPRequestDispatcher.STATUS_PROCESSED;
                item.Message__c = '';
                item.SAPKey__c = apiHandler.processResponse(item.RequesterID__c, (Integer) item.ResponseCode__c, item.Response__c);
            } else {
                item.Status__c = SAPRequestDispatcher.STATUS_ERROR;
                item.Message__c = fitQueueMessage(apiHandler.parseErrors(item.RequesterID__c, item.Response__c));
            }
            if (item.Status__c == SAPRequestDispatcher.STATUS_ERROR && item.Retries__c == SAPRequestDispatcher.MAX_RETRIES) {
                apiHandler.processError(item.RequesterID__c, (Integer) item.ResponseCode__c, item.Message__c, item.Response__c);
            }   
        } catch(SkipFlagException sex) {
            result = true;
            item.ResponseCode__c = 204; // No Content
            item.Status__c = SAPRequestDispatcher.STATUS_PROCESSED;
            item.Skipped__c = true;
            item.Message__c = fitQueueMessage(sex.getMessage());            
            this.context.logger.addInfo(' Item saltado por el handler: ' + item.Status__c + '-' + item.Message__c);     
            //apiHandler.processSkipped(item.RequesterID__c, item.Message__c);
        } catch(Exception ex) {
            result = false;
            item.Status__c = SAPRequestDispatcher.STATUS_EXCEPTION;
            item.Message__c = fitQueueMessage(ex.getMessage());
            this.context.logger.addError(' Excepción recibida en dispatch: ' + item.Status__c + '-' + item.Message__c);
            this.context.logger.addError(ex);
        } 
        return result;
    }

    private static String fitQueueMessage(String message) {
        Integer maxLength = SAPRequestQueue__c.Message__c.getDescribe().getLength();
        return StringCommons.truncate(message, maxLength);
    }


    /**
     * Dispatch a request to SAP
     * 
     * Returns the SAP Key assigned or a CalloutException in case of error
     */
    private CalloutDTO dispatchSAPRequest(SAPAbstractAPIHandler apiHandler, SAPRequestQueue__c item, String payload) {        
        CalloutDTO result = new CalloutDTO();
        SAPProxy proxy = new SAPProxy(apiHandler.getServiceName());
        proxy.method = apiHandler.getHttpMethod(item.ActionRequested__c);
        proxy.inputJSON = payload;
        result.success = proxy.connectToSAP();
        result.statusCode = proxy.statusCode;
        result.response = proxy.receivedJSON;
        this.context.logger.addInfo(' Item procesado con status ' + proxy.statusCode);
        return result;
    }  // dispatchSAPRequest

    private CalloutDTO dispatchCPIRequest(SAPAbstractAPIHandler apiHandler, SAPRequestQueue__c item, String payload) {
        CalloutDTO result = new CalloutDTO();
        SAPCPIProxy proxy = new SAPCPIProxy(apiHandler.getServiceName());
        proxy.setMethod(apiHandler.getHttpMethod(item.ActionRequested__c));
        proxy.setJSONBody(payload);
        Integer timeout = apiHandler.getTimeout();
        if (timeout > 0) {
            proxy.setTimeout(timeout);
        }
        result.response = proxy.callCPI();
        result.statusCode = proxy.getResponseCode();
        result.success = (result.statusCode >= 200 && result.statusCode < 300);
        return result;
    } // dispatchCPIRequest

    private SAPRequestQueue__c readItem() {
        return this.context.items[this.context.index];
    }


    private SAPAbstractAPIHandler getAPIHandler(String handlerName) {
        Type customType = Type.forName(handlerName);
        if (customType == null) {
            throw new ObjectNotFoundException('APIHandler ' + handlerName + ' not found!');
        }
        return ((SAPAbstractAPIHandler) customType.newInstance()) ?? null;
    }
    
    private static Id[] readQueueIds() {
        // and  Retries__c < :MAX_RETRIES
        List<SAPRequestQueue__c> items = [select Id from SAPRequestQueue__c
            where Status__c != :STATUS_PROCESSED 
            order by Sequence__c];  
        return TypeConversionCommons.extractListOfIds(items);
    }

    public class SAPDispatcherContext {
        public String pin;
        public List<SAPRequestQueue__c> items;
        public Integer index;
        public Set<Id> failedIds;
        public SystemLog logger;
        public Integer blockSize = 50; // Valor por defecto
        public Integer blockNumber = 0;
    }

    private class CalloutDTO {
        private Boolean success;
        private Integer statusCode;
        private String sapKey;
        private String message;
        private String response;
    }

    public class SkipFlagException extends Exception {
    }
    
}