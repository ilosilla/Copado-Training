import { LightningElement, api, wire, track } from 'lwc';
import { FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';
import accountLabel from '@salesforce/label/c.account';
import contactLabel from '@salesforce/label/c.contact';
import chooseAccountLabel from '@salesforce/label/c.chooseAccount';
import chooseContactLabel from '@salesforce/label/c.chooseContact';
import newLabel from '@salesforce/label/et4ae5.new';
import newAccountLabel from '@salesforce/label/c.NewAccount';
import newContactLabel from '@salesforce/label/c.NewContact';
import fillRequiredLabel from '@salesforce/label/c.dict_fill_required';
import userId from '@salesforce/user/Id';
import LANG from "@salesforce/i18n/lang";

import getKeyAccounts from '@salesforce/apex/UserCommons.getKeyAccounts';
import getKeyOpportunities from '@salesforce/apex/UserCommons.getKeyOpportunities';
import saveWeeklyComments from '@salesforce/apex/ReportsHelper.saveWeeklyReportComments';

export default class WeeklyReportCommentsLWC extends LightningElement {
    isrendered = false;
    lang = LANG;
    internalErrorToRender = "";
    isLoading = false;

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

    @api comments = '';
    @api isLoginFlow = false;
    @api keyAccountComments = '';
    @api keyOppsComments = '';
    @api mainComments = '';

    @track keyAccounts = [];
    @track keyOpportunities = [];
    @track loaded = false;
    @track changedComments = false;
    @track changedMainComments = false;
    @track changedKeyAccountComments = false;
    @track changedKeyOpportunityComments = false;
    @track invalidForm = false;

    get options() {
        if (this.lang == 'fr') {
            return [
                { label: '', value: null },
                { label: 'Non contacté', value: 'NOCONTACTED' },
                { label: 'Contacté', value: 'CONTACTED' },
                { label: 'Développer une relation', value: 'DEVELOPMENT' },
                { label: 'Étudier les opportunités', value: 'STUDYINGOPPS' },
                { label: 'Produire', value: 'PRODUCING' },
                { label: 'Stoppé', value: 'FREEZED' },
            ];
        }
        return [
            { label: '', value: null },
            { label: 'Not contacted', value: 'NOCONTACTED' },
            { label: 'Contacted', value: 'CONTACTED' },
            { label: 'Developing a relationship', value: 'DEVELOPMENT' },
            { label: 'Studying Opportunities', value: 'STUDYINGOPPS' },
            { label: 'Producing', value: 'PRODUCING' },
            { label: 'Stopped', value: 'FREEZED' },
        ];
    }

    get keyOppsText() {
        if (this.lang == 'fr') {
            return 'Veuillez faire un commentaire général sur les événements récents liés à l\'opportunité'
        } else {
            return 'Please make a general comment about the recent events related to the opportunity'
        }
    }

    get keyOppsSection() {
        if (this.lang == 'fr') {
            return 'Section sur les opportunités clés'
        } else {
            return 'Key opportunities section'
        }
    }

    get keyAccsText() {
        if (this.lang == 'fr') {
            return 'Veuillez remplir l\'échéance de vente et faire un commentaire général sur les événements récents liés au compte'
        } else {
            return 'Please fill the sales maturity and make a general comment about the recent events related to the account'
        }
    }

    get keyAccsSection() {
        if (this.lang == 'fr') {
            return 'Section des grands comptes'
        } else {
            return 'Key accounts section'
        }
    }

    get MainCommentText() {
        if (this.lang == 'fr') {
            return `Principaux commentaires (veuillez faire un commentaire général sur la semaine. Mettez l'accent sur les interactions pertinentes avec les clients, les réclamations ou tout autre besoin)`;
        } else {
            return `please make a general comment of the week. Focus on relevant customer interactions, claims or any needs`;
        }
    }

    get SalesMaturityText() {
        if (this.lang == 'fr') {
            return 'Maturité des ventes'
        } else {
            return 'Sales Maturity'
        }
    }

    get errorMessage() {
        if (this.lang == 'fr') {
            return 'Veuillez compléter toutes les sections';
        } else {
            return 'Please complete all sections';
        }
    }

    handleChangeKeyAccountRating(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        // Creamos una copia del array para mantener la reactividad
        let updatedAccounts = [...this.keyAccounts];
        updatedAccounts[index].rating = value;

        this.keyAccounts = updatedAccounts;
    }

    handleChangeKeyAccountComment(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        // Creamos una copia del array para mantener la reactividad
        let updatedAccounts = [...this.keyAccounts];
        updatedAccounts[index].comment = value;

        this.keyAccounts = updatedAccounts;
    }

    handleChangeKeyOppComment(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        // Creamos una copia del array para mantener la reactividad
        let updatedOpps = [...this.keyOpportunities];
        updatedOpps[index].comment = value;

        this.keyOpportunities = updatedOpps;
    }

    get hasKeyAccounts(){
        //return this.keyAccounts.length > 0;
        return false;
    }

    get hasKeyOpportunities(){
        //return this.keyOpportunities.length > 0;
        return false;
    }

    get hasKeyRecords() {
        return this.hasKeyAccounts || this.hasKeyOpportunities;
    }

    getInternalErrorMessageIfInvalid() {
        let valid = true;
        let message = 'Please complete all sections';
        if (this.lang == 'fr') {
            message = 'Veuillez compléter toutes les sections';
        }

        if (this.hasKeyAccounts) {
            this.keyAccounts.forEach(function (entry) {
                if (entry.rating == null || entry.comment == null) {
                    return message;
                }
            })
        }

        if (this.hasKeyOpportunities) {
            this.keyOpportunities.forEach(function (entry) {
                if (entry.comment == null) {
                    return message;
                }
            })
        }
        
        return null;
    }
    
    @api
    validate() {
        const internalError = this.getInternalErrorMessageIfInvalid();
        return {
        isValid: internalError === null,

        errorMessage: internalError,
        };
    }

    changeMainComment(event) {
        this.mainComments = event.target.value;
    }

    @wire(getKeyAccounts, { userId: userId })
    keyAccounts(result) {
        if (result.data) {
            if (result.data.length > 0) {
                this.keyAccounts = result.data.map(account => ({
                    id: account.Account__r.Id,
                    name: account.Account__r.Name,
                    rating: null,
                    comment: null
                }));
            }

            getKeyOpportunities({userId: userId })
            .then( (response) => {
                if (response.length > 0) {
                    this.keyOpportunities = response.map(opp => ({
                        id: opp.Opportunity__r.Id,
                        name: opp.Opportunity__r.Name,
                        comment: null
                    }));
                }
            })
            .catch( (error) => {
                this.keyOppsComments = '';
                console.log(error);
                console.info("error: " + error.body.message);
            });

            this.loaded = true;
            
        } else {
            console.error('Error loading key accounts:', result);
            this.comments = '';
            this.keyAccountComments = '';

            getKeyOpportunities({userId: userId })
            .then( (response) => {
                if (response.length > 0) {
                    this.keyOpportunities = response.map(opp => ({
                        id: opp.Id,
                        name: opp.Name,
                        comment: null
                    }));
                }
            })
            .catch( (error) => {
                console.error('Error loading opp accounts:', response);
                console.log(error);
                console.info("error: " + error.body.message);
            });

            this.loaded = true;
        }
    }

    adjustHeight(event) {
        const textarea = event.target;
        textarea.style.height = 'auto'; // Reset the height to auto
        textarea.style.height = textarea.scrollHeight + 'px'; // Set the height based on content
    }

    handlePrevious() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    handleSubmit() {
        this.isLoading = true;
        this.invalidForm = false;
        let aux = this;

        if (this.mainComments == null || this.mainComments == '') {
            this.invalidForm = true;
        }

        if (this.hasKeyAccounts) {
            this.keyAccounts.forEach(function (entry) {
                console.log(entry.rating)
                console.log(entry.comment)
                if (entry.rating == null || entry.rating == '' || entry.comment == null || entry.comment == '') {
                    aux.invalidForm = true;
                }
            })
        }

        if (this.hasKeyOpportunities) {
            this.keyOpportunities.forEach(function (entry) {
                console.log(entry.comment == null)
                if (entry.comment == null || entry.comment == '') {
                    aux.invalidForm = true;
                }
            })
        }
        
        this.comments = this.mainComments;
        if (this.hasKeyAccounts) {
            this.comments += '\n\n* Key Account Comments *\n'
            this.keyAccounts.forEach(function (entry) {
                let commentAccount = '----------------------------\n';
                commentAccount += entry.name + ' [ ' + entry.rating + ' ]\n';
                commentAccount += entry.comment + '\n';
                aux.comments += commentAccount;
              }, this);
        }

        if (this.hasKeyOpportunities) {
            this.comments += '\n* Key Opportunities Comments *\n'
            this.keyOpportunities.forEach(function (entry) {
                let commentOpp = '----------------------------\n';
                commentOpp += entry.name + '\n';
                commentOpp += entry.comment + '\n';

                aux.comments += commentOpp;
              }, this);
        }

        const attributeChangeEvent = new FlowAttributeChangeEvent('comments', this.comments);
        this.dispatchEvent(attributeChangeEvent);

        if (this.invalidForm == false) {
            saveWeeklyComments({ keyAccounts: this.keyAccounts, keyOpportunities: this.keyOpportunities })
            .then( (response) => {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            })
            .catch( (error) => {
                console.log(error);
                console.info("error: " + error.body.message);
                this.isLoading = false;
            });
        } else {
            this.isLoading = false;
        }
    }

}