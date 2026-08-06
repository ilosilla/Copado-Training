/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		Framework
* @description 	Domain class factory to return dynamic domain classes
*/
public class zflib_DomainConstructor {
    public static zflib_TriggerDomainClass construct(Type classType, List<SObject> records) {
        zflib_TriggerDomainClass domainClass =  (zflib_TriggerDomainClass) classType.newInstance();
        domainClass.Records = records;
        return domainClass.cast();
    }
}