import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';



export class B2B_LwcUtils extends NavigationMixin(LightningElement) {
 

    handleChange(event) {
        // Get the string of the "value" attribute on the selected option
        const selectedOption = event.detail.value;
        this.chosenValue = selectedOption;
    }
}

const proto = {
    add(className) {
        if (typeof className === 'string') {
            this[className] = true;
        } else {
            Object.assign(this, className);
        }
        return this;
    },
    invert() {
        Object.keys(this).forEach((key) => {
            this[key] = !this[key];
        });
        return this;
    },
    toString() {
        return Object.keys(this)
            .filter((key) => this[key])
            .join(' ');
    }
};

export function classSet(config) {
    if (typeof config === 'string') {
        const key = config;
        config = {};
        config[key] = true;
    }
    return Object.assign(Object.create(proto), config);
}

export function formatLabel(str) {
    const args = Array.prototype.slice.call(arguments, 1);
    let replacements = args;
    if (Array.isArray(args[0])) {
        [replacements] = args;
    }

    return str.replace(/{(\d+)}/g, (match, i) => {
        return replacements[i];
    });
}

export function join(separator, ...values) {
    return values.join(separator);
}

export function normalizeString(value, config = {}) {
    const { fallbackValue = '', validValues, toLowerCase = true } = config;
    let normalized = (typeof value === 'string' && value.trim()) || '';
    normalized = toLowerCase ? normalized.toLowerCase() : normalized;
    if (validValues && validValues.indexOf(normalized) === -1) {
        normalized = fallbackValue;
    }
    return normalized;
}

export function normalizeBoolean(value) {
    return typeof value === 'string' || !!value;
}