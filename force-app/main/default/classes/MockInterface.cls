public virtual inherited sharing class MockInterface{
    /*
     * @description A method that is overriden in the test class.
     * When used outside of a test, returns the records.
     * When used in a test class, will return the overridden method in the class that is defined in the test class,
     * this overidden method returns a list of whatever object is defined in the test class
     **************************************************************/
    public virtual List<SObject> passThrough(List<SObject> records){
       return records;
    }
}