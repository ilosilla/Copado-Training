import { LightningElement, api } from 'lwc';

let uid = 0;

export default class B2bInputQuantity extends LightningElement {

    // ---------- API ----------
    @api label = 'Label';
    @api type = 'integer';            // 'integer' | 'decimal'
    @api decimals = 2;                // nº decimales si type='decimal'
    @api step = 1;                    // incremento de los botones
    @api digits = 8;                  // dígitos enteros deseados
    @api maxDigits;                   // Ancho en caracteres
    @api disabled = false;
    @api required = false;

    @api
        get value() {
            return this._value;
        }
        set value(v) {
            // Actualización programática: NO dispares evento aquí
            this._value = v ?? 0;
        }

    @api
        get negatives() {
            return this._negatives;
        }
        set negatives(value) {
            this._negatives = (String(value).toLowerCase === 'true');
        }

    // ---------- State ----------
    _value = 0;  
    _negatives =false;
    _uid = ++uid;
    _hasErrors = false;
    errorMessage = '';

    // ---------- IDs & ARIA ----------
    get inputId() { return `tnf-input-${this._uid}`; }    

    // ---------- Atributos del input ----------
    get displayValue() {
        return this._value;
    }

    get fieldClass() {
        return (this._hasErrors ? "triple triple-error" : "triple");
    }

    get positiveStep() { return String(Number(this.step)); }
    get negativeStep() { return String(-Number(this.step)); }

    get inputMode() {
        // numeric = teclado numérico móvil; decimal para decimales
        return this.type === 'decimal' ? 'decimal' : 'numeric';
    }

    get patternAttr() {
        // no bloquea realmente en desktop, pero ayuda a móviles/validación ligera
        if (this.type === 'decimal') {
            return this._negatives ? '^-?\\d*([\\.,]\\d+)?$' : '^\\d*([\\.,]\\d+)?$';
        } 
        return this._negatives ? '^-?\\d+$' : '^\\d+$';    
    }

    // ---------- Estilo de ancho en “ch” ----------
    // Total visible: dígitos + (decimales y punto) + (signo si procede)
    get widthInChars() {
        const base = Math.max(Number(this.digits ?? 0), Number(this.maxDigits ?? 0));
        const sign = this._negatives ? 1 : 0;
        const dec = this.type === 'decimal' && this.decimals > 0 ? (1 + Number(this.decimals)) : 0; // '.' + n dec
        return Math.max(1, base + sign + dec);
    }

    get hostStyle() {
        return `--tnf-ch: ${this.widthInChars}ch;`;
    }

    // ---------- Eventos ----------
    fireChange() {    
        this._hasErrors = false;
        const theEvent = new CustomEvent("change", {detail: { value: this.normalizeInputValue }});
        this.dispatchEvent(theEvent);
    }

    fireError(message) {
        this._hasErrors = true;
        const theEvent = new CustomEvent("error", {detail: { message: message }});
        this.dispatchEvent(theEvent);
    }

    // ---------- Helpers ----------
    get normalizeInputValue() {
        const v = String(this._value).replace(',', '.');
        const n = Number(v);
        return isNaN(n) ? null : n;
    }

    onBlur(e) {    
        // Normaliza valores vacíos/solo guion
        //let v = String(this.displayValue);
        this._value = e.target.value;
        let v = this.normalizeInputValue;
        if (v === '' || v === '-') {
            if (this.required) {                
                this.fireError('Field is required');
                return;
            }
            this._value = 0;
        }    

        // Valida decimal y fija el número de decimales
        if (this.type === 'decimal') {
            if (isNaN(parseFloat(v))) {
                this.fireError('Please enter a valid decimal number');
                return;
            }
            this._value = v.toFixed(this.decimals);
        }

        // Valida enteros
        if (this.type === 'integer') {
            if (!(Number.isInteger(v))) {
                this.fireError('Please enter a valid integer')
                return
            }
        }

        // Valida negativos
        if (!this._negatives && (v < 0)) {
            this.fireError('Negative numbers are not allowed')
            return
        }

        this.fireChange();
    }

    onStep(e) {
        if (this.disabled) return;
        const step = Number(e.currentTarget.dataset.step);
        let base = this.normalizeInputValue ?? 0;
        let next = base + step;

        // Redondeo para evitar flotantes
        if (this.type === 'decimal') {
        const places = Math.max(0, Number(this.decimals || 0) + 2);
        const m = Math.pow(10, places);
        next = Math.round(next * m) / m;
        } else {
        next = Math.round(next);
        }

        if (!this._negatives && next < 0) next = 0;

        this._value = next;
        this.fireChange();
    }
}