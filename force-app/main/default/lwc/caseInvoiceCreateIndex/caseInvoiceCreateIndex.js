/**
 * caseInvoiceCreate - Index Bar
 * 
 * Ramón Prades
 * January 2025
 * 
 * Index bar
 * 
 * As this is a relatively complex component, it has been divided into several subcomponents, each representing a step of the wizard.
 * 
 * Translation prefix tr0009
 * 
 */
import { LightningElement, api } from 'lwc';
import { LABELS } from './labels';

const ICON_CURRENT = 'utility:forward';
const ICON_DONE = 'utility:check';
const ICON_PENDING = 'utility:choice';
const CASE_TYPE_CLAIM = 'CLAIM';

const CLAIMS_STEPS_SUMMARY = [
    { index: 1, dataid: 'icon1', icon: ICON_CURRENT, title: LABELS.tr0009_003, description: LABELS.caseCreateStep1Text },
    { index: 2, dataid: 'icon2', icon: ICON_PENDING, title: LABELS.tr0009_005, description: LABELS.caseCreateStep2Text },
    { index: 3, dataid: 'icon3', icon: ICON_PENDING, title: LABELS.tr0009_007, description: LABELS.caseCreateStep3Text },
    { index: 4, dataid: 'icon4', icon: ICON_PENDING, title: LABELS.tr0009_009, description: LABELS.caseCreateStep4Text }
];

const CLAIMS_STEPS_RETURN = [
    { index: 1, dataid: 'icon1', icon: ICON_CURRENT, title: LABELS.tr0009_003, description: LABELS.tr0009_004 },
    { index: 2, dataid: 'icon2', icon: ICON_PENDING, title: LABELS.tr0009_005, description: LABELS.tr0009_006 },
    { index: 3, dataid: 'icon3', icon: ICON_PENDING, title: LABELS.tr0009_007, description: LABELS.tr0009_008 },
    { index: 4, dataid: 'icon4', icon: ICON_PENDING, title: LABELS.tr0009_009, description: LABELS.tr0009_010 }
];

export default class CaseInvoiceCreateIndex extends LightningElement {
    
    _step; 

    @api caseType;
    @api 
    get step() {
        return this._step;
    }
    set step(value) {
        const lastStep = this._step;
        this._step = value;
        if (lastStep !== this._step) {
            this.setIcons(this._step, lastStep);
        }
    }

    labels = LABELS;

    get mainTitle() {
        return (this.caseType === CASE_TYPE_CLAIM ? this.labels.caseCreateClaimTitle : this.labels.tr0009_001 );
    }

    get introText() {
        return (this.caseType === CASE_TYPE_CLAIM ? this.labels.caseCreateClaimIntro : this.labels.tr0009_002 );
    }

    get stepsSummary() {
        return (this.caseType === CASE_TYPE_CLAIM ? CLAIMS_STEPS_SUMMARY : CLAIMS_STEPS_RETURN );
    }

    setIcons(currentStep, lastStep) {        
        if (currentStep > lastStep) {
            this.setStepIcon(lastStep, ICON_DONE);
        } else if (currentStep < lastStep) {
            this.setStepIcon(lastStep, ICON_PENDING);            
        }
        this.setStepIcon(currentStep, ICON_CURRENT)            
    }

    setStepIcon(iconStep, iconName) {
        const dataId = 'icon' + iconStep;
        const control = this.template.querySelector('[data-id="' + dataId +'"]');
        if (control) {
            control.iconName = iconName;
        }
    }
}