import { LightningElement, wire, api } from 'lwc';
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import NAME_FIELD from "@salesforce/schema/Contact.Name";
import EMAIL_FIELD from "@salesforce/schema/Contact.Email";
import ACCOUNT_FIELD from "@salesforce/schema/Contact.AccountId";
import recordTypeLabel from '@salesforce/label/c.RecordType';
import selectRecordTypeLabel from '@salesforce/label/c.SelectRecordType';

import getContactRecordtypesAvailable from '@salesforce/apex/RecordTypeLibrary.getAvailableRecordtypesList';

export default class ContactCreator extends LightningElement {

    label = {
        recordTypeLabel,
        selectRecordTypeLabel
    };

    //objeto cuenta
    contactObject = CONTACT_OBJECT;
    //campos a mostrar para los recordtypes que no son person account
    contactFields = [ACCOUNT_FIELD, NAME_FIELD, EMAIL_FIELD];
    //recordtypes de contacto a mostrar en el desplegable
    contactRecordtypesOptions;
    //lista de recordtypes obtenidos para el perfil del usuario con su detalle
    recordTypesList;
    //recordtype seleccionado
    contactRecordtypeSelected;
    //Nombre del contacto creado
    contactName;

    /**
     * visualizar el desplegable de recordtypes del contacto, en caso de que tenga recordtypes
     * disponibles (que no sean master) y que tenga mas de uno
     * A 12/2023 no tienen recordtypes (que no sean master), por lo que no deberia mostrarse
     * se controla por si en un futuro se crean
     */
    get showComboContactRecordTypes() {
        return this.recordTypesList != undefined && this.recordTypesList.length > 1;
    }

    /**
     * visualizar el formulario de creacion de contacto. Dependera de si han seleccionado
     * un recordtype de contacto
     */
    get showContactForm() {
        return this.contactRecordtypeSelected != undefined || this.recordTypesList == undefined || this.recordTypesList.length === 0;
    }

    /**
     * obtenemos los recordtypes disponibles para el usuario del objeto cuenta
     */
    @wire(getContactRecordtypesAvailable, { objectName: 'Contact' })
    loadAccountRecordtypes(result) {
        if (result.data) {
            this.recordTypesList = result.data;
            let newOptions = [];
            console.log('DATA')
            console.log(result.data)
            for (let recordtype of result.data) {
                
                newOptions.push({
                    value: recordtype.Id,
                    label: recordtype.Name,
                    description: recordtype.Description
                });
            }
            this.contactRecordtypesOptions = newOptions;
            if (this.recordTypesList.length === 1) {
                this.contactRecordtypeSelected = this.recordTypesList[0].Id;
            }
        } else {
            this.contactRecordtypeSelected = undefined;
        }
    }

    /**
     * acciones a realizar cuando clican el boton de guardar
     */
    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.contactName = `${fields.FirstName} ${fields.LastName}`;
        this.template.querySelector('lightning-record-form').submit(fields);
    }

    /**
     * acciones a realizar cuando se crea un contacto
     */
    handleSuccess(event) {
        const createdEvent = new CustomEvent('contactcreated', {
            detail: {
                id: event.detail.id,
                name: this.contactName
            }
        });
        this.dispatchEvent(createdEvent);
    }

    /**
     * acciones a realizar cuando se cancela la creacion de un contacto
     */
    handleCancel() {
        const cancelledEvent = new CustomEvent('contactcancelled');
        this.dispatchEvent(cancelledEvent);
    }

    /**
     * gestiona la seleccion de un elemento del desplegable de recordtypes de cuentas
     */
    handleChangeContactRecordTypes(event) {
        this.contactRecordtypeSelected = event.detail.value
    }

}