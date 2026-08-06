/**
* @author Ivan Losilla
* @date Marzo 2021
* @group Tools
* @description  Gets a random owner from the sales office found from the country and the postcode.
*/
public class SalesOfficeAssignator extends AbstractOwnerAssignator {

  public override User getOwner() {
    String salesOffice = this.findSalesOffice();
    return userUtils.getSalesOfficeRandomUser(salesOffice);
  }

  /** 
    *******************************************************
    Private methods 
    *******************************************************    
  */
  
  private String findSalesOffice() {
    PostCodeObjectFinder objFinder = new PostCodeObjectFinder('SALES_OFFICE');
    objFinder.countryCode = this.countryCode;
    objFinder.postCode = this.postCode;
    objFinder.state = this.state;
    return objFinder.findFirst();
  } // findSalesOffice
    
} // class