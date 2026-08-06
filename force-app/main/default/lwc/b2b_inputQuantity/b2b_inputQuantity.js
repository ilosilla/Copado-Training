import { LightningElement, api } from 'lwc';

let uid = 0;

export default class B2b_inputQuantity extends LightningElement {

  // ---------- API ----------
  @api label = 'Label';
  @api type = 'integer';            // 'integer' | 'decimal'
  @api decimals = 2;                // nº decimales si type='decimal'
  @api allowNegative = false;
  @api step = 1;                    // incremento de los botones
  @api value = 0;                   // valor inicial (number)
  @api digits = 4;                  // dígitos enteros deseados
  @api extraChars = 0;              // suma opcional (p.ej. separador de miles si lo pintas tú)
  @api disabled = false;
  @api required = false;

  // ---------- State ----------
  current = '';
  errorMessage = '';

  _uid = ++uid;

  connectedCallback() {
    this.current = this.value ?? 0;
  }

  // ---------- IDs & ARIA ----------
  get inputId() { return `tnf-input-${this._uid}`; }
  get errorId() { return `tnf-err-${this._uid}`; }

  // ---------- Atributos del input ----------
  get stepAttr() {
    if (this.type === 'decimal') return this._normalizeStep(this.step ?? 0.01);
    return 1; // enteros
  }
  get posStep() { return String(this.stepAttr); }
  get negStep() { return String(-Number(this.stepAttr)); }

  get inputMode() {
    // numeric = teclado numérico móvil; decimal para decimales
    return this.type === 'decimal' ? 'decimal' : 'numeric';
  }
  get patternAttr() {
    // no bloquea realmente en desktop, pero ayuda a móviles/validación ligera
    if (this.type === 'decimal') {
      return this.allowNegative ? '^-?\\d*([\\.,]\\d+)?$' : '^\\d*([\\.,]\\d+)?$';
    } else {
      return this.allowNegative ? '^-?\\d+$' : '^\\d+$';
    }
  }

  // Evita mostrar 'true'/'false' sin comillas
  get invalidAttr() { return this.errorMessage ? 'true' : 'false'; }

  // ---------- Visualización del valor ----------
  get displayValue() {
    return (this.current ?? '') === '' ? '' : String(this.current);
  }

  // ---------- Estilo de ancho en “ch” ----------
  // Total visible: dígitos + (decimales y punto) + (signo si procede) + extraChars
  get totalChars() {
    const base = Number(this.digits || 0);
    const sign = this.allowNegative ? 1 : 0;
    const dec = this.type === 'decimal' && this.decimals > 0 ? (1 + Number(this.decimals)) : 0; // '.' + n dec
    const extra = Number(this.extraChars || 0);
    return Math.max(1, base + sign + dec + extra);
  }
  get hostStyle() {
    return `--tnf-ch: ${this.totalChars}ch;`;
  }

  // ---------- Clases ----------
  get errorClass() { return this.errorMessage ? 'error-msg show' : 'error-msg'; }

  // ---------- Eventos ----------
  fireChange() {
    this.dispatchEvent(new CustomEvent('change', {
      detail: { value: this.numberValue }
    }));
  }
  fireInvalid() {
    this.dispatchEvent(new CustomEvent('invalid', {
      detail: { message: this.errorMessage }
    }));
  }

  // ---------- Helpers ----------
  get numberValue() {
    const v = String(this.displayValue).replace(',', '.');
    const n = Number(v);
    return isNaN(n) ? null : n;
  }
  _normalizeStep(s) {
    const num = Number(s);
    if (!num || num <= 0) return 0.01;
    return num;
  }

  // ---------- Handlers ----------
  onInput = (e) => {
    let val = e.target.value;

    // Permitimos escritura parcial (vacío o '-' en negativos)
    if (val === '' || (this.allowNegative && val === '-')) {
      this.current = val;
      this.errorMessage = this.required ? 'Campo requerido' : '';
      return;
    }

    val = val.replace(',', '.');

    // Validaciones por tipo
    if (this.type === 'integer') {
      const intOk = this.allowNegative ? /^-?\d+$/.test(val) : /^\d+$/.test(val);
      if (!intOk) {
        this.errorMessage = 'Introduce un número entero válido';
        this.fireInvalid();
        return;
      }
      this.current = Number(val);
    } else {
      const decOk = this.allowNegative ? /^-?\d*(\.\d+)?$/.test(val) : /^\d*(\.\d+)?$/.test(val);
      if (!decOk) {
        this.errorMessage = 'Introduce un número válido (puede llevar decimales)';
        this.fireInvalid();
        return;
      }
      // Limitar decimales visualmente
      const [intP, decP = ''] = val.split('.');
      const trimmed = this.decimals >= 0 ? `${intP}${decP ? '.' + decP.slice(0, this.decimals) : ''}` : val;
      this.current = trimmed === '' || trimmed === '-' ? trimmed : Number(trimmed);
    }

    this.errorMessage = '';
    this.fireChange();
  };

  onBlur = (e) => {
    // Normaliza valores vacíos/solo guion
    let v = String(this.displayValue);
    if (v === '' || v === '-') {
      if (this.required) {
        this.errorMessage = 'Campo requerido';
        this.fireInvalid();
      } else {
        this.current = '';
      }
      return;
    }

    // En decimal: fija decimales
    if (this.type === 'decimal' && this.decimals > 0 && this.numberValue !== null) {
      const fixed = this.numberValue.toFixed(this.decimals);
      this.current = Number(fixed);
    }
  };

  onStep = (e) => {
    if (this.disabled) return;
    const step = Number(e.currentTarget.dataset.step);
    let base = this.numberValue ?? 0;
    let next = base + step;

    // Redondeo para evitar flotantes
    if (this.type === 'decimal') {
      const places = Math.max(0, Number(this.decimals || 0) + 2);
      const m = Math.pow(10, places);
      next = Math.round(next * m) / m;
    } else {
      next = Math.round(next);
    }

    if (!this.allowNegative && next < 0) next = 0;

    this.current = next;
    this.errorMessage = '';
    this.fireChange();

    // Sincroniza en el input DOM
    const inp = this.template.querySelector('input');
    if (inp) inp.value = this.displayValue;
  };
}