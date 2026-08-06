/**
* @author Ivan Losilla
* @date July 2022
*
* @group PricebooksAssignator
*
* @description Interface class of the interface
*/
public interface IPricebookAssignator  {

    void setAccount(Id accId);

    void setUser(Id userId);
    
    Pricebook2 getPricebook();
  }