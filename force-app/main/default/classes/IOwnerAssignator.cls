/**
* @author 			Ramón Prades
* @since 			  April 2021
* @group 			  Deprecated
* @description 	Replaced by AbstractOwnerAssignator on April 2021
*/
public interface IOwnerAssignator {
  void setCountry(String countryCode);
  void setState(String state);
  void setPostCode(String postCode);
  void setProfile(String profile);
  void setProductLine(String productLine);
  User getOwner();
  // User getOwnerBySalesOffice(String salesOffice);
}