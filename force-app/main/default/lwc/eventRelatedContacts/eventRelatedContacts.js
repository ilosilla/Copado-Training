import { LightningElement, api, wire } from 'lwc';
import getRelatedContacts from '@salesforce/apex/EventContactsController.getRelatedContacts';
import relatedContactsLabel from '@salesforce/label/c.dict_related_contacts';
import accountNameLabel from '@salesforce/label/c.dict_account_Name';
import contactNameLabel from '@salesforce/label/c.dict_contact_name';
import emailLabel from '@salesforce/label/c.dict_email';
import phoneLabel from '@salesforce/label/c.dict_phone';

export const columns = [
    //{ label: 'Account', fieldName: 'UrlAccount', type: 'url' },
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Correo Electrónico', fieldName: 'Email', type: 'email' },
    { label: 'Teléfono', fieldName: 'Phone', type: 'phone' }
];

export default class EventRelatedContacts extends LightningElement {
    @api recordId;
    columnsParam = columns;

    contacts = [];
    error;

    label = {
        relatedContactsLabel,
        accountNameLabel,
        contactNameLabel,
        emailLabel,
        phoneLabel
    }

    // Llamada al método Apex para obtener los contactos relacionados
    @wire(getRelatedContacts, { eventId: '$recordId' })
    wiredContacts({ error, data }) {
        var listContacts = [];
        if (data) {
            var este = this;
            data.forEach(function(contact) {
                var aux = { ...contact };
                aux.UrlAccount = window.location.origin + "/" + contact.AccountId;
                aux.UrlContact = window.location.origin + "/" + contact.Id;
                listContacts.push(aux)
            });
            this.contacts = listContacts;
            console.log(data)
            console.log(this.contacts);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = [];
        }
    }
}