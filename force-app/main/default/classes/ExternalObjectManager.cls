public class ExternalObjectManager{
    //We create a static instance of the class that can be overridden
    static MockInterface instance = new MockInterface();

    /*
    @description Method that returns the records that are passed to it
    **********************************************************************************************/
    public static List<SObject> records(List<SObject> records){
        return instance.passThrough(records);
    }

    /*
    @description Method that is usable in a test class. Used to set the mock (SObject type) that this class will return.
    **********************************************************************************************/
    @TestVisible static void setMock(MockInterface mock){
        instance = mock;
    }
}