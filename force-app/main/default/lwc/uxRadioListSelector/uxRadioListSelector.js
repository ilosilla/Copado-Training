/**
 * Styling Hooks
 * -------------
 * This component exposes several CSS custom properties (styling hooks) so
 * parent components can override the visual style without modifying this code.
 *
 * Example hooks (defined in ux_radioListSelector.css):
 *   --ux-radio-list-border-color
 *   --ux-radio-list-background-color
 *   --ux-radio-list-row-border-width
 *   --ux-radio-list-row-border-color
 *   --ux-radio-list-row-hover-bg
 *   --ux-radio-list-radius
 *   --ux-radio-list-font-weight-label
 *   --ux-radio-list-font-size
 *   --ux-radio-list-text-color
 *   --ux-radio-list-text-color-secondary
 *   --ux-radio-list-selected-bg
 *   --ux-radio-list-selected-accent-color
 *   --ux-radio-list-selected-bold-weight
 * 
 *   --ux-radio-list-search-margin-top
 *   --ux-radio-list-search-border-color
 *   --ux-radio-list-search-bg
 *   --ux-radio-list-search-text-color
 *   --ux-radio-list-search-placeholder-color
 *   --ux-radio-list-search-radius
 *
 * Usage example in parent component CSS:
 *   c-ux-radio-list-selector {
 *       --ux-radio-list-border-color: #16325c;
 *       --ux-radio-list-row-hover-bg: #e8f1ff;
 *       --ux-radio-list-radius: 0.5rem;
 *       --ux-radio-list-font-size: 0.9rem;
 *       --ux-radio-list-text-color: #3e3e3c;
 *   }
 *
 * This allows flexible theming (shipping, billing, dark mode, etc.)
 * without changing the reusable component.
 */

// uxRadioListSelector.js
import { LightningElement, api } from 'lwc';

export default class UxRadioListSelector extends LightningElement {
    /**
     * Estructura esperada:
     * [
     *   { id: '1', label: 'Nombre', description: 'Info extra', tags: 'extended search tags' },
     *   ...
     * ]
     */
    @api options = [];

    /** Valor seleccionado */
    @api selectedValue;

    /** Título del grupo */
    @api label;

    /** Número de filas visibles antes del scroll */
    @api visibleRows = 5;

    /** Mostrar campo de búsqueda */
    @api showSearch;   // default: false

    /** Variante visual: 'radio' (por defecto) o 'list' */
    @api variant = 'radio';

    /** Texto del buscador */
    searchTerm = '';

    // --- getters de modo -------------------------------------------------

    get isSearchEnabled() {
        return Boolean(this.showSearch);
    }

    get isListVariant() {
        return this.variant === 'list';
    }

    get isRadioVariant() {
        return !this.isListVariant;
    }

    // Determina el alto máximo de la lista de opciones
    get optionsListStyle() {
        const rows = Number(this.visibleRows) > 0 ? Number(this.visibleRows) : 6;
        const heightRem = rows * 2;
        return `height: ${heightRem}rem;`;
    }

    // Filtro de búsqueda + flags de selección y clases CSS
    get filteredOptions() {
        const term = (this.searchTerm || '').toLowerCase();
        const baseOptions = this.options || [];

        let filtered = baseOptions;
        if (term) {
            filtered = baseOptions.filter(opt => {
                const searchText = `${opt.label || ''} ${opt.description || ''} ${opt.tags || ''}`.toLowerCase();
                const matches = searchText.includes(term);

                // si el elemento filtrado era el seleccionado, lo limpiamos
                if (!matches && this.selectedValue === opt.id) {
                    this.selectedValue = null;
                }
                return matches;
            });
        }

        const currentValue = this.selectedValue ?? '';

        return filtered.map(opt => {
            const checked = opt.id === currentValue;
            let itemClass = 'radio-item slds-p-xx-small';

            if (this.isListVariant && checked) {
                itemClass += ' radio-item--selected';
            }

            return {
                ...opt,
                checked,
                itemClass
            };
        });
    }

    get hasOptions() {
        return this.filteredOptions.length > 0;
    }

    // --- eventos ----------------------------------------------------------

    handleRadioChange(event) {
        // Solo aplica en modo radio
        if (!this.isRadioVariant) return;
        this.selectedValue = event.target.value;
        this.dispatchEvent(
            new CustomEvent('change', { detail: { value: this.selectedValue } })
        );
    }

    handleItemClick(event) {
        // Solo aplica en modo lista
        if (!this.isListVariant) return;
        const id = event.currentTarget.dataset.id;
        // Si vuelven a clicar la misma fila, deseleccionamos
        const newValue = this.selectedValue === id ? null : id;
        this.selectedValue = newValue;
        this.dispatchEvent(
            new CustomEvent('change', { detail: { value: this.selectedValue } })
        );
    }

    handleSearchChange(event) {
        event.stopPropagation();
        this.searchTerm = event.target.value || '';
    }
}