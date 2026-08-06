import { LightningElement, api } from 'lwc';

export default class LibExpandableSection extends LightningElement {
    @api id;
    @api label;
    @api fixed = false;

    @api 
        get closed() {
            return this._closed;
        }
        set closed(value) {
            this._closed = value;
        }

    @api
        get theme() {
            return this._theme;
        }
        set theme(value) {
            this._theme = value?.toLowerCase() ?? 'normal';            
            this.setThemeClasses();
        } 

    
    _shade = false;
    _shadeTexture = false;
    _closed = false;
    _theme;
    shadeClass = 'slds-theme_shade rounded-borders';
    textureClass = 'slds-theme_alert-texture';

    openedClasses = 'slds-section slds-is-open';
    closedClasses = 'slds-section slds-is-close';
    _backgroundClass = '';
    _headerClass = this.shadeClass;

    get baseClassName(){
        return this.buildClasses();
    }

    get headerClass() {
        let c = 'slds-section__title ' + this._headerClass;
        return c;
    }

    buildClasses() {
        let base = this.openedClasses;
        if (this._closed) {
            base = this.closedClasses;
        } 
        return base + ' ' + this._backgroundClass;
   }   

   setThemeClasses() {        
        switch (this._theme) {
            case 'shade':
                this._backgroundClass = this.shadeClass;
                this._headerClass = '';
                break;
            case 'shade-texture':
                this._backgroundClass = this.shadeClass + ' ' + this.textureClass;
                this._headerClass = this.shadeClass + ' ' + this.textureClass;
                break;
            default:
                this._theme = 'normal';
                this._backgroundClass = '';
                this._headerClass = this.shadeClass;
                break;
        }
   }

    toggleSection(event) {        
        this._closed = !this._closed;
        let buttonid = event.currentTarget.dataset.buttonid;
        let currentsection = this.template.querySelector('[data-id="' + buttonid + '"]');
        currentsection.className = this.buildClasses();
        /*
        if (currentsection.className.search('slds-is-open') === -1) {
            currentsection.className = 'slds-section slds-is-open';
        } else {
            currentsection.className = 'slds-section slds-is-close';
        }
        */
    }
}