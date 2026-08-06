import { LightningElement, wire } from 'lwc';
import hasCollectionsPermission from "@salesforce/customPermission/CASE_COLLECTIONS_USER";
import hasClaimsPermission from "@salesforce/customPermission/CASE_CLAIMS_USER";
import profileName from '@salesforce/schema/User.Profile.Name';
import { getFocusedTabInfo, setTabLabel, closeTab } from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';

/*
 * I leave a few lines commented just in case they are neeeded in the futute. They
 * retrieve the list of record types. This list can be used to build de options
 * of the selection radio group.
 */
/* RADIOS
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
*/

import newCaseLabel from "@salesforce/label/c.case_new_case_title";
import cancelButtonLabel from "@salesforce/label/c.dict_button_cancel";
import nextButtonLabel from "@salesforce/label/c.dict_button_next";
import caseNoPermission from "@salesforce/label/c.case_no_permission";
import caseSelectionPrompt from "@salesforce/label/c.case_selection_prompt";
import caseOpenClaim from "@salesforce/label/c.case_open_claim";
import caseOpenCollection from "@salesforce/label/c.case_open_collection";

export default class NewCaseMenu extends NavigationMixin(LightningElement) {
    label = {
        newCaseLabel,
        cancelButtonLabel,
        nextButtonLabel,
        caseNoPermission,
        caseSelectionPrompt,
        caseOpenClaim,
        caseOpenCollection
    }

    get noPermissions() {
        return !(this.areClaimsVisible || this.areCollectionsVisible);
    }

    get areCollectionsVisible() {
        return (profileName === 'System Administrator' || hasCollectionsPermission);
    }

    get areClaimsVisible() {
        return (profileName === 'System Administrator' || hasClaimsPermission);
    }

    caseOptions = [];
    defaultOption;
    showSpinner = true;

    connectedCallback() {
        this.buildRadioOptions();
        this.setTabTitle();
        this.showSpinner = false;
    }

    /* RADIOS
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT }) buildPageOptions({ error, data }) {
        if (data) {
            alert(JSON.stringify(data.recordTypeInfos));
        }
    }
    */

    buildRadioOptions() {
        this.caseOptions = [];

        if (this.areCollectionsVisible) {
            const option3 = {}
            option3.value = 'COLLECTION';
            option3.label = this.label.caseOpenCollection
            this.caseOptions.push(option3);         
        }

        if (this.areClaimsVisible) {
            const option2 = {};
            option2.value = 'CLAIM';
            option2.label = this.label.caseOpenClaim
            this.caseOptions.push(option2);
        }

        if (this.caseOptions.length > 0) {
            this.defaultOption = this.caseOptions[0].value;
        } 
    }

    handleCancelClick() {
        this.closeTab();
    }

    handleNextClick() {    
        const selected = this.refs.radioGroup?.value;
        if (selected === 'CLAIM') {
            this.showSpinner = true;
            this.openClaimCase();
        } else if (selected === 'COLLECTION') {
            this.showSpinner = true;
            this.openCollectionCase();
        }
    }

    async setTabTitle() {
        const { tabId } = await getFocusedTabInfo();
        setTabLabel(tabId, this.label.newCaseLabel);
    }

    async closeTab() {
        const { tabId } = await getFocusedTabInfo();
        await closeTab(tabId);
    }


    /**
     * Opens a case using the standard layout defined for the record type
     *
    openStandardCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'            
            },
            state: {
                recordTypeId: recordTypeId
            }
        });
    }
    */

    /**
     * Opens a claim using a custom compoent
     */
    openClaimCase() {
        this[NavigationMixin.Navigate]({
            'type': 'standard__component',
            'attributes': {
                'componentName': 'c__CaseClaimForm'
            },
        }, true);   
    }        

    /**
     * Opens a collection using a custom compoent
     */
    openCollectionCase() {
        this[NavigationMixin.Navigate]({
            'type': 'standard__component',
            'attributes': {
                'componentName': 'c__CaseCollectionForm'
            },
        }, true);
    }

    handleNavigation() {
        this[NavigationMixin.Navigate]({
         type: 'standard__component',
         attributes: {
             componentName: 'c__MyLightningComponent'
         },
         state: {
             c__counter: '5'
         }
     });
    }
}