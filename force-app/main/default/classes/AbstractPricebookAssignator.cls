/**
* @author Ivan Losilla
* @date July 2022
*
* @group PricebooksAssignator
*
* @description Abstract class of the interface
*/
public abstract class AbstractPricebookAssignator  {
    
    public abstract void setAccount(Id accId);
    public abstract void setUser(Id userId);
    public abstract Pricebook2 getPricebook();
  }