import { LightningElement, wire } from "lwc";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import BUSINESS_EMAIL_FIELD from "@salesforce/schema/Account.Business_Email__c";
import ACCOUNT_CLASSIFICATION_FIELD from "@salesforce/schema/Account.Account_Classification__c";
import BILLING_ADDRESS_FIELD from "@salesforce/schema/Account.BillingAddress";
import PERSON_EMAIL_FIELD from "@salesforce/schema/Account.PersonEmail";
import MAILING_ADDRESS_FIELD from "@salesforce/schema/Account.PersonMailingAddress";
import recordTypeLabel from '@salesforce/label/c.RecordType';
import selectRecordTypeLabel from '@salesforce/label/c.SelectRecordType';

import getAccountRecordtypesAvailable from '@salesforce/apex/RecordTypeLibrary.getAvailableRecordtypesList';
import getContactFromAccount from '@salesforce/apex/ContactsUtil.selectPersonAccountContactByAccountId';

/**
 * Creates Account records.
 */
export default class AccountCreator extends LightningElement {

    label = {
        recordTypeLabel,
        selectRecordTypeLabel
    };

    //objeto account
    accountObject = ACCOUNT_OBJECT;
    //campos a mostrar para los recordtypes que no son person account
    accountFields = [NAME_FIELD, PHONE_FIELD, BUSINESS_EMAIL_FIELD, ACCOUNT_CLASSIFICATION_FIELD, BILLING_ADDRESS_FIELD];
    //campos a mostrar para los recordtypes de person account
    personAaccountFields = [NAME_FIELD, PHONE_FIELD, PERSON_EMAIL_FIELD, MAILING_ADDRESS_FIELD];
    //campos a mostrar en el formulario de la cuenta (dependera de si es person account o no)
    accountFieldsToShow;
    //recordtypes de cuenta a mostrar en el desplegable
    accountRecordtypesOptions;
    //recordtype seleccionado
    accountRecordtypeSelected;
    //lista de recordtypes obtenidos para el perfil del usuario con su detalle
    recordTypesList;
    //indica si el recordtype de cuenta seleccionado se corresponde con un person account
    selectedPersonAccount = false;
    //identificador de la cuenta creada
    newAccountId;
    //nombre de la cuenta creada
    accountName;

    /**
     * visualizar la parte de la pagina para crear cuentas. Dependera de si nos proporcionan
     * o no una cuenta ya existente (para crear solo el contacto)
     */
    get showAccountCreation() {
        return this.newAccountId == undefined;
    }

    /**
     * visualizar el formulario de creacion de cuentas. Dependera de si han seleccionado
     * un recordtype de cuenta
     */
    get showAccountForm() {
        return this.accountRecordtypeSelected != undefined || this.recordTypesList == undefined || this.recordTypesList.length === 0;
    }

    /**
     * visualizar el desplegable de recordtypes de la cuenta, en caso de que tenga recordtypes
     * disponibles (que no sean master) y que tenga mas de uno
     */
    get showComboAccountRecordTypes() {
        return this.recordTypesList != undefined && this.recordTypesList.length > 1;
    }

    /**
     * obtenemos los recordtypes disponibles para el usuario del objeto cuenta
     */
    @wire(getAccountRecordtypesAvailable, { objectName: 'Account' })
    loadAccountRecordtypes(result) {
        if (result.data) {
            this.recordTypesList = result.data;
            let newOptions = [];
            for (let recordtype of result.data) {
                newOptions.push({
                    value: recordtype.Id,
                    label: recordtype.Name,
                    description: recordtype.Description
                });
            }
            this.accountRecordtypesOptions = newOptions;
            if (this.recordTypesList.length === 1) {
                this.selectRecordType(this.recordTypesList[0].Id);
            }
        } else {
            this.selectRecordType(undefined);
        }
    }

    /**
     * acciones a realizar cuando clican el boton de guardar
     */
    handleSubmit(event) {
        //Nos guardamos el nombre introducido para enviarlo al componente 'padre'
        if (this.selectedPersonAccount) {
            this.accountName = `${event.detail.fields.FirstName} ${event.detail.fields.LastName}`;
        } else {
            this.accountName = event.detail.fields.Name;
        }
    }

    /**
     * acciones a realizar cuando se crea una cuenta
     */
    async handleSuccess(event) {
        this.newAccountId = event.detail.id;

        let contactId;
        if (this.selectedPersonAccount) {
            let contact = await getContactFromAccount({ accountId: this.newAccountId });
            contactId = contact ? contact.Id : undefined;
        }

        const createdEvent = new CustomEvent('accountcreated', {
            detail: {
                id: event.detail.id,
                isPersonAccount: this.selectedPersonAccount,
                name: this.accountName,
                contactId: contactId
            }
        });
        this.dispatchEvent(createdEvent);
    }

    /**
     * acciones a realizar cuando se cancela la creacion de una cuenta
     */
    handleCancel() {
        const cancelledEvent = new CustomEvent('accountcancelled');
        this.dispatchEvent(cancelledEvent);
    }

    /**
     * gestiona la seleccion de un elemento del desplegable de recordtypes de cuentas
     */
    handleChangeAccountRecordTypes(event) {
        this.selectRecordType(event.detail.value);
    }

    /**
     * gestiona las acciones a realizar cuando se selecciona un recordtype
     */
    selectRecordType(recordTypeId) {
        this.accountRecordtypeSelected = recordTypeId;
        let isPersonAccountSelected = false;
        if (this.recordTypesList != undefined) {
            for (let recordtype of this.recordTypesList) {
                if (recordtype.Id === this.accountRecordtypeSelected && recordtype.IsPersonType ) {
                    isPersonAccountSelected = true;
                    break;
                }
            }
        }
        this.selectedPersonAccount = isPersonAccountSelected;
        this.accountFieldsToShow = isPersonAccountSelected ? this.personAaccountFields : this.accountFields;
    }

}