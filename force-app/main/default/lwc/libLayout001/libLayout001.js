/**
 * 
 * Layout for a large MODAL window with:
 * Ramón, Jan 2025
 * 
 * - Header
 * - Header form
 * - Main content area
 * - Collapsible sidebar on the right
 * - Footer
 * 
 * We create generic layouts to avoid solving the same problem multiple times.
 * 
 */
import { LightningElement, api } from 'lwc';

import dict_button_ok from "@salesforce/label/c.dict_button_ok";
import dict_button_cancel from "@salesforce/label/c.dict_button_cancel";

export default class LibLayout001 extends LightningElement {

    labels = {dict_button_ok, dict_button_cancel}

    @api headerIcon;
    @api headerTitle = '';
    @api headerSubtitle = '';
    @api showFormHeader = false;    
    @api showSidePanel = false;
    @api sidePanelIcon;
    @api sidePanelTitle;
    @api showClosePanelButton = false;
    @api disableOkButton = false;
    @api disableCancelButton = false;

    
    get mainTitleClass() {
        let base = "slds-page-header__title";
        if (this.headerSubtitle?.length === 0) {
            base += " slds-var-m-top_x-small";
        }
        return base;
    }

    handleCloseDetailClick() {
        this.dispatchEvent(new CustomEvent('sidepanelclosed'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancelclick'));
    }

    handleOkay() {
        this.dispatchEvent(new CustomEvent('okclick'));
    }


}