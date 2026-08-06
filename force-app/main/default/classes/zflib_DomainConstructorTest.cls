@isTest public with sharing class zflib_DomainConstructorTest {

    @isTest static void testDomainConstructor() {
        // Usamos LeadsDomain
        zflib_TriggerDomainClass domain = zflib_DomainConstructor.construct(LeadsDomain.class, new List<Lead>());
        Boolean casted = (domain instanceOf LeadsDomain);
        System.assert(true, casted);                  
    }
}