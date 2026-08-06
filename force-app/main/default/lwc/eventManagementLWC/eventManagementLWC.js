import { LightningElement, api, wire, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import Id from "@salesforce/user/Id";
import getAccountContacts from '@salesforce/apex/AccountUtil.getRelatedContacts';
import getContact from '@salesforce/apex/ContactsHelper.getContact';
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

export default class EventManagementLWC extends LightningElement {

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
    @api contactsArray;
    @api fullPage;
    @api eventId;

    contactOptions;
    disabled = false;
    requireContact = false;
    personAccount = false;

    userId = Id;
    renderLookup = false;

    @track selectedOtherContacts = [];
    @track isLoading = false;
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
                value: 'US',
            },
            {
                fieldPath: 'BillingCountryCode',
                operator: 'eq',
                value: 'CA',
            },
            {
                fieldPath: 'BillingCountryCode',
                operator: 'eq',
                value: 'GB',
            },
            {
                fieldPath: 'BillingCountryCode',
                operator: 'eq',
                value: 'AU',
            },
        ],
        filterLogic: '1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7',
    };

    @track filterContacts = {
        criteria: [
            {
                fieldPath: 'OwnerId',
                operator: 'eq',
                value: this.userId,
            },
            {
                fieldPath: 'AccountId',
                operator: 'ne',
                value: '',
            },
            {
                fieldPath: 'Id',
                operator: 'in',
                value: '',
            }
        ],
        filterLogic: '1 OR 2 OR 3',
    };

    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['Owner.LastName'],
    };
    displayInfoContact = {
        primaryField: 'Name',
        additionalFields: ['Account.Name'],
    };
    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        //additionalFields: [{ fieldPath: 'Phone' }],
    };

    creatingAccount = false;
    creatingContact = false;

    createdAccount = false;

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
        if (result.data) {
            this.filter.criteria[1].value = result.data;
            this.renderLookup = true;
        }
    }

    get isFullPage() {
        return this.fullPage == 'true' || this.fullPage == 'True'
    }

    connectedCallback(){
        if (this.contactsArray != null) {
            this.contactsArray.forEach(function (entry) {
                if (entry.RelationId.startsWith("003")) {
                    getContact({id: entry.RelationId})
                    .then((response) => {
                        this.selectedOtherContacts.push(response)
                    })
                    .catch( (error) => {
                        console.log(error)
                    });
                }
              }, this);
        }
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
        return this.accountId != undefined && !this.creatingContact;
    }

    get showNewContactButton() {
        return this.allowCreate && this.accountId != undefined && !this.creatingContact;
    }

    get showNewContactForm() {
        return this.creatingContact;
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

    handleChangeAccount(event) {
        this.accountId = event.detail.recordId;
        const attributeChangeEvent = new FlowAttributeChangeEvent('accountId', this.accountId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this.selectedContactId = event.detail.recordId;
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedContactId', this.selectedContactId);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChangeOtherContacts(event) {
        if (this.contactsArray == undefined) {
            this.contactsArray = []
        }
        if (event.detail.recordId != undefined) {
            let found = this.contactsArray.find(o => o.RelationId === event.detail.recordId);
            if (found == undefined) {
                getContact({id: event.detail.recordId})
                .then((response) => {
                    this.selectedOtherContacts.push(response)
                    let newEntry = {
                        'EventId' : this.eventId,
                        'IsWhat' : false,
                        'IsParent' : true,
                        'RelationId' : event.detail.recordId
                    };
                    this.contactsArray = [ ...this.contactsArray, newEntry ]
                })
                .catch( (error) => {
                    console.log(error)
                });
            }

            this.refs.contactPickerRef.clearSelection();
            const attributeChangeEvent = new FlowAttributeChangeEvent('contactsArray', this.contactsArray);
            this.dispatchEvent(attributeChangeEvent);
        }
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
        this.creatingContact = false;
        this.updateContacts(this.accountId)
    }

    handleContactCreated(event) {
        this.contactCreated(event.detail.id, event.detail.name);
    }

    handelContactCancelled() {
        this.creatingContact = false;
    }

    updateContacts(accountId) {
        getAccountContacts({accountId: accountId})
            .then((response) => {
                if (response) {
                    let newOptions = [];
                    if (response.length == 1 && response[0].IsPersonAccount) {
                        newOptions.push({
                            label: response[0].Name,
                            value: response[0].Id
                        });
                        this.selectedContactId = response[0].Id;
                        this.disabled = true;
                        this.personAccount = true;
                    } else {
                        for (let contact of response) {
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
            })
            .catch( (error) => {
                console.log(error)
            });
    }

}