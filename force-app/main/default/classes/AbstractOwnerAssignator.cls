/**
* @author Ivan Losilla
* @date Marzo 2021
*
* @group OwnerAssignator
* @group-content ../../ApexDocContent/AbstractOwnerAssignator.htm
*
* @description Abstract class of the interface
*/
public abstract class AbstractOwnerAssignator  {

  // These variables are used in the owner determinations
  protected String countryCode;    // ISO country code
  protected String state;          // State or province
  protected String postCode;       
  protected String profile;        // Customer profile (consumer4, architect, etc)
  protected String productLine;    // Façade, Krion, Kitchen, etc)
  protected String variant;        // To provide a mechanism for variations

  public void setVariant(String v) {
    this.variant = v;
  }

  public void setCountry(String countryCode) {
    this.countryCode = countryCode;
  }

  public void setState(String state) {
    this.state = state;
  }

  public void setPostCode(String postCode) {
    this.postCode = postCode;
  }

  public void setProfile(String profile) {
    if (String.IsNotBlank(profile)) {
      this.profile = profile.toUpperCase();
    } else {
      this.profile = null;
     }
  }

  public void setProductLine(String productLine) {    
    if (String.IsNotBlank(productLine)) {
      this.productLine = productLine.ToUpperCase();
    } else{
      this.productLine = null;
    }
  }


  // This is thew method that MUST be implemented
  public abstract User getOwner();

  /*
  public User getOwnerBySalesOffice(String salesOffice) {
    Id result = null;
    List<User> listUsers = new List<User>();
    
    if (String.isNotBlank(salesOffice)) {
      listUsers = [Select Id,Default_Sales_Organization__c,Distribution_channel_default__c,Email,Execution_Context__c,FirstName,IsActive,LastName,Sales_Office__c From User where IsActive = true AND Appointment__c=true AND Sales_Office__c =: salesOffice];
    }
    
    Integer randomIndex = (Math.random() *(listUsers.size()-1)).intValue();

    for (User elem : listUsers){
        if (randomIndex == 0){
          return elem;
        }
        randomIndex--;
    }
    return null;
  }
  */
}