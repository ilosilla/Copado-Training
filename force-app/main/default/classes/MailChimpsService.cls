/**
* @author 			Ivan Losilla
* @date 			November-2022
* @group 			Mailchimp
* @description 	    Manage the Mailchimp API, using the MailchimpHelper class. More info on MailchimpHelper description
*/
public class MailChimpsService {

    /*
    * @description DTO with the info needed to use the Mailchimp API.
    */
    public class MailchimpDTO {
        public String context;  // required
        // public String listId;   // required
        public String email;    // required
        public String firstname = '';
        public String lastname = '';
        public String phone = '';
        public String language = 'en'; // accepted codes : https://mailchimp.com/es/help/view-and-edit-contact-languages/
    }

    /*  @description Inserts or modifies a mailchimp member as Subscribed */
    public static List<Boolean> addSubscription(List<MailchimpDTO> members) {
        List<Boolean> result = new List<Boolean>(); 
        for (MailchimpDTO member : members) {
            result.add(addSubscription(member));
        }
        return result;
    }

    /*  @description Inserts or modifies a mailchimp member as Subscribed */
    public static Boolean addSubscription(MailchimpDTO member) {
        MailChimpHelper aux = null;
        aux = new MailChimpHelper(member.email, member.context);
        
        if (String.IsNotBlank(member.firstname)) {
            aux.firstname = member.firstname;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.lastname = member.lastname;
        }
        if (String.IsNotBlank(member.phone)) {
            aux.phone = member.phone;
        }
        if (String.IsNotBlank(member.language)) {
            aux.language = member.language;
        }
        
        if (String.isBlank(aux.id)) {
            aux.status = 'subscribed';
            return aux.insertMember();
        } else {
            aux.status = 'subscribed';
            return aux.updateMember();
        }
    }
    
    /* @description Cancel the Subscription of a list of members */
    public static List<Boolean> cancelSubscription(List<MailchimpDTO> members) {
        List<Boolean> result = new List<Boolean>();

        for (MailchimpDTO member : members) {
            result.add(cancelSubscription(member));
        }
        return result;
    }

    /* @description Cancel the Subscription of an existing member */
    public static Boolean cancelSubscription(MailchimpDTO member) {
        MailChimpHelper aux = null;
        aux = new MailChimpHelper(member.email, member.context);

        if (String.IsNotBlank(member.firstname)) {
            aux.firstname = member.firstname;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.lastname = member.lastname;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.phone = member.phone;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.language = member.language;
        }
        
        if (String.isNotBlank(aux.id)) {
            aux.status = 'unsubscribed';
            return aux.updateMember();
        }
        return false;
    }

    /* @description Checks if a member is subscribed or not of a list of members */
    public static List<Boolean> isSubscribed(List<MailchimpDTO> members) {
        List<Boolean> result = new List<Boolean>();

        for (MailchimpDTO member : members) {
            result.add(isSubscribed(member));
        }
        return result;
    }

    /* @description Checks if a member is subscribed or not */
    public static Boolean isSubscribed(MailchimpDTO member) {
        MailChimpHelper aux = null;
        aux = new MailChimpHelper(member.email, member.context);
        if (String.isNotBlank(aux.id)) {           
            return aux.status == 'subscribed';
        }
        return false;
    }

    /* @description Updates the info of a list of member */
    public static List<Boolean> updateData(List<MailchimpDTO> members) {
        List<Boolean> result = new List<Boolean>();

        for (MailchimpDTO member : members) {
            result.add(updateData(member));
        }
        return result;
    }

    /* @description Updates the info of a member, if exists */
    public static Boolean updateData(MailchimpDTO member) {
        MailChimpHelper aux = null;
        aux = new MailChimpHelper(member.email, member.context);

        if (String.IsNotBlank(member.firstname)) {
            aux.firstname = member.firstname;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.lastname = member.lastname;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.phone = member.phone;
        }
        if (String.IsNotBlank(member.lastname)) {
            aux.language = member.language;
        }
        
        if (String.isNotBlank(aux.id)) {
            return aux.updateMember();
        }
        return false;
    }
}