import { LightningElement, api, wire, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import Id from "@salesforce/user/Id";
import getAccountContacts from '@salesforce/apex/AccountUtil.getRelatedContacts';
import accountLabel from '@salesforce/label/c.account';
import contactLabel from '@salesforce/label/c.contact';
import chooseAccountLabel from '@salesforce/label/c.chooseAccount';
import chooseContactLabel from '@salesforce/label/c.chooseContact';
import newLabel from '@salesforce/label/et4ae5.new';
import newAccountLabel from '@salesforce/label/c.NewAccount';
import newContactLabel from '@salesforce/label/c.NewContact';
import fillRequiredLabel from '@salesforce/label/c.dict_fill_required';

import getTeamMembersAccountsId from '@salesforce/apex/AccountUtil.getTeamMembersAccountsId';
import getExecutionContext from '@salesforce/apex/ExecutionContext.getUserExecutionContext';

export default class AccountAndContactSelector extends LightningElement {

    label = {
        accountLabel,
        contactLabel,
        chooseAccountLabel,
        chooseContactLabel,
        newLabel,
        newAccountLabel,
        newContactLabel,
        fillRequiredLabel
    };

    @api accountId;
    @api selectedContactId;

    contactOptions;
    disabled = false;
    requireContact = false;
    personAccount = false;

    userId = Id;
    renderLookup = false;
    
    @track isLoading = true;
    @track filter = {
        criteria: [
            {
                fieldPath: 'OwnerId',
                operator: 'eq',
                value: this.userId,
            },
            {
                fieldPath: 'Id',
                operator: 'in',
                value: '',
            },
            {
                fieldPath: 'BillingCountryCode',
                operator: 'eq',
                value: 'FR',
            },
            {
                fieldPath: 'BillingCountryCode',
                operator: 'eq',
                value: 'GB',
            },
        ],
        filterLogic: '1 OR 2 OR 3 OR 4',
    };
    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['Owner.LastName'],
    };
    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        //additionalFields: [{ fieldPath: 'Phone' }],
    };

    creatingAccount = false;
    creatingContact = false;

    createdAccount = false;
    createdContact = false;

    accountName;
    contactName;

    allowCreate = false;

    @wire(getExecutionContext)
    loadExecutionContext(result) {
        if (result.data) {
            this.allowCreate = result.data.lFlowAllowCreate;
        }
    }

    @wire(getTeamMembersAccountsId)
    loadAccounts(result) {
        this.isLoading = false;
        if (result.data) {
            console.log(result.data.length)
            if (result.data.length > 10) {
                this.filter.criteria[1].value = result.data.slice(0,10)
            } else {
                this.filter.criteria[1].value = result.data;
            }
        }
        this.renderLookup = true;
    }

    get showAccountsCombo() {
        return !this.createdAccount && !this.creatingAccount;
    }

    get showNewAccountButton() {
        return this.allowCreate && !this.createdAccount && !this.creatingAccount;
    }

    get showNewAccountForm() {
        return this.creatingAccount && !this.createdAccount;
    }

    get showNewAccountInfo() {
        return this.createdAccount;
    }

    get showContactsCombo() {
        return this.accountId != undefined && !this.creatingContact && !this.createdContact;
    }

    get showNewContactButton() {
        return this.allowCreate && !this.createdContact && this.accountId != undefined && !this.creatingContact;
    }

    get showNewContactForm() {
        return this.creatingContact && !this.createdContact && this.accountId != undefined;
    }

    get showNewContactInfo() {
        return this.createdContact && !this.personAccount;
    }

    get comboboxLayoutSize() {
        return this.allowCreate ? '9' : '12';
    }

    @wire(getAccountContacts, { accountId: '$accountId' })
    loadContacts(result) {
        if (result.data) {
            let newOptions = [];
            if (result.data.length == 1 && result.data[0].IsPersonAccount) {
                newOptions.push({
                    label: result.data[0].Name,
                    value: result.data[0].Id
                });
                this.selectedContactId = result.data[0].Id;
                this.disabled = true;
                this.personAccount = true;
            } else {
                for (let contact of result.data) {
                    newOptions.push({
                        label: contact.Name,
                        value: contact.Id
                    });
                }
                this.disabled = false;
                this.requireContact = true;
                this.personAccount = false;
            }
            this.contactOptions = newOptions;
        }
    }

    /*@api 
    validate(){
        let isValid = true;
        if (this.accountId == null) {
            isValid = false;
        }
        if (this.requireContact && this.selectedContactId == null) {
            isValid = false;
        }
        if(!isValid) { 
            return {
                isValid: false,
                errorMessage: this.label.fillRequiredLabel
            }
        }        
    }*/

    handleChangeAccount(event) {
        console.log(event.detail.recordId)
        this.accountId = event.detail.recordId;
        const attributeChangeEvent = new FlowAttributeChangeEvent('accountId', this.accountId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this.selectedContactId = event.detail.value;
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedContactId', this.selectedContactId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleNewAccount() {
        this.creatingAccount = true;
        this.accountId = undefined;
    }

    handleNewContact() {
        this.creatingContact = true;
    }

    handleAccountCreated(event) {
        this.accountId = event.detail.id;
        this.personAccount = event.detail.isPersonAccount;
        this.accountName = event.detail.name;
        const attributeChangeEvent = new FlowAttributeChangeEvent('accountId', this.accountId);
        this.dispatchEvent(attributeChangeEvent);
        //mostrar creacion de contacto si no es person account
        this.creatingContact = !this.personAccount;
        this.creatingAccount = false;
        this.createdAccount = true;
        if (this.personAccount) {
            this.contactCreated(event.detail.contactId, this.accountName);
        }
    }

    handelAccountCancelled() {
        this.creatingAccount = false;
    }

    contactCreated(contactId, name) {
        this.selectedContactId = contactId;
        this.contactName = name;
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedContactId', this.selectedContactId);
        this.dispatchEvent(attributeChangeEvent);
        this.creatingContact = false;
        this.createdContact = true;
    }

    handleContactCreated(event) {
        this.contactCreated(event.detail.id, event.detail.name);
    }

    handelContactCancelled() {
        this.creatingContact = false;
    }

}