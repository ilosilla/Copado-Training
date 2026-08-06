/**
* @author 			Ramón Prades
* @date 			January 2022
* @group 			API
* @description 	    Interface a class must implement to be plugged into RESTStreamService
*/
public abstract class AbstractStreamParser {

    public String fileName {get; set;}      // Stream name
    public String content {get; set;}   // Content
    public String parentId {get; set;}  // sObject id

    /**
     * Empty constructor
     */
    public AbstractStreamParser() {
    }

    /**
     * Parses the stream
     * Can throw a ParseException
     */
    abstract public Boolean parse();

    /**
     * Executes the stream
     */
    abstract public String execute();

} // class