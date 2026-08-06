/**
 * @author       Ivan Losilla
 * @since        Marzo 2021
 * @group        Tools
 * @description  Returns the instance of AbstractOwnerAssignator depending on the object and context set
 */
public class OwnerAssignator {
  // Objetos permitidos: ACCOUNT, LEAD, OPPORTUNITY

  public static AbstractOwnerAssignator getInstance(String objectName) {
    return getInstance(objectName, ExecutionContext.getUserExecutionContext());
  } // getInstance

  public static AbstractOwnerAssignator getInstance(
    String objectName,
    ExecutionContext context
  ) {
    return getInstance(objectName, context.ownerAssignation);
  }

  public static AbstractOwnerAssignator getInstance(
    String objectName,
    String algorithm
  ) {
    // Objetos permitidos: ACCOUNT, LEAD, OPPORTUNITY
    AbstractOwnerAssignator assignatorObject;
    if (algorithm == 'USA') {
      assignatorObject = new USAAssignator();
    } else if (algorithm == 'MBK-EUR') {
      assignatorObject = new CountryOwnerAssignator();
      assignatorObject.setVariant(algorithm);
    } else {
      assignatorObject = new SalesOfficeAssignator();
    }
    return assignatorObject;
  }
}