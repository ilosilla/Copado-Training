import { LightningElement, api, wire } from 'lwc';
import readRelatedProductsList from '@salesforce/apex/B2B_ServicesController.readRelatedProductsList';
import communityBasePath from '@salesforce/community/basePath';
//import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
//import B2B_RELATED_PRODUCTS from '@salesforce/messageChannel/B2BRelatedProducts__c';


export default class B2b_UsRelatedProducts extends LightningElement {    
    @api productId;
    @api productCode;  

     
    _pricebookEntryId;
    @api 
    get pricebookEntryId() {
        return this._pricebookEntryId;
    }
    set pricebookEntryId(value) {        
        this._pricebookEntryId = value ?? '01uRR00000Ubr9gYAB'; // ?? Colorstuck '01uRR00000Ubr7ZYAR'; // Capri '01uRR00000Ubr9gYAB';
    }

    _init = false;
    _handlers = null;
    _ro = null; // ResizeObserver
    _dataReady = false;

    relatedSkus = []
    pimData;
    pimProdct;
    relatedProducts;

    isOpen = true;

    get numberOfRelated() {
        return '(' + this.renderItems?.length + ')';
    }

    get hasRelated() {
        return (this.renderItems?.length > 0 ?? false);
    }

    get renderItems() {
        return this.relatedProducts ?? [];
    }

    get isAtStart() {
        return false;
    }

    get isAtEnd() {
        return false;
    }
    
    get toggleSymbol() {
        return this.isOpen ? 'utility:dash' : 'utility:add';
    }
    
    get bodyClass() {
        return `rc-section-body ${this.isOpen ? '' : 'is-closed'}`;
    }

    toggleOpen = (event) => {
        this.isOpen = !this.isOpen;
    };

    /* =========================================================================================================== 
     *  EVENTOS DEL COMPONENTE
     * =========================================================================================================== */

    renderedCallback() {
        if (this._init) return;
        this._init = true;

        const section = this.template.querySelector('.rc-section');
        if (!section) return;

        const content  = section.querySelector('.rc-section-content');
        const btnLeft  = section.querySelector('.rc-scroll-btn.left');
        const btnRight = section.querySelector('.rc-scroll-btn.right');
        if (!content || !btnLeft || !btnRight) return

        // Lee el gap real del contenedor (soporta 'gap' / 'columnGap')
        const getGap = () => {
        const cs = getComputedStyle(content);
        const gap = parseFloat(cs.gap || cs.columnGap || '0');
        return Number.isNaN(gap) ? 0 : gap;
        };

        // Ancho de un item (usa el primero como referencia)
        const getItemWidth = () => {
            const item = content.querySelector('.rc-card');
            if (!item) return 200;
            return item.getBoundingClientRect().width + getGap();
        };

        const updateButtons = () => {
            // ¿Hay overflow?
            const hasOverflow = content.scrollWidth > content.clientWidth + 1;
            // Izquierda visible solo si hay overflow y no estamos al inicio
            btnLeft.classList.toggle('hidden', !hasOverflow || content.scrollLeft <= 0);
            // Derecha visible solo si hay overflow y no estamos al final
            const atEnd = content.scrollLeft + content.clientWidth >= content.scrollWidth - 1;
            btnRight.classList.toggle('hidden', !hasOverflow || atEnd);
        };

        const onLeft  = () => content.scrollBy({ left: -getItemWidth(), behavior: 'smooth' });
        const onRight = () => content.scrollBy({ left:  getItemWidth(), behavior: 'smooth' });
        const onScroll = () => updateButtons();
        const onResize = () => updateButtons();

        btnLeft.addEventListener('click', onLeft);
        btnRight.addEventListener('click', onRight);
        content.addEventListener('scroll', onScroll);
        window.addEventListener('resize', onResize);

        // Guarda handlers para limpiar después
        this._handlers = { btnLeft, btnRight, content, onLeft, onRight, onScroll, onResize };

        // Observa cambios de tamaño del carrusel (p.ej. fuentes, imágenes, responsive)
        this._ro = new ResizeObserver(updateButtons);
        this._ro.observe(content);

        // Primer cálculo
        updateButtons();
    }

    disconnectedCallback() {
        // Limpia listeners
        const h = this._handlers;
        if (h && h.content) {
            h.btnLeft.removeEventListener('click', h.onLeft);
            h.btnRight.removeEventListener('click', h.onRight);
            h.content.removeEventListener('scroll', h.onScroll);
            window.removeEventListener('resize', h.onResize);
        }
        if (this._ro) this._ro.disconnect();
    }

    /* =========================================================================================================== 
     *  APEX METHODS 
     * =========================================================================================================== */
    @wire(readRelatedProductsList, { productId: "$productId", pricebookEntryId: "$_pricebookEntryId" })
        setRelatedProducts({error, data}) {
            if (error) {
                console.error("***** Error received in apex method readRelatedProductsList: " + JSON.stringify(error));
            } 
            if (data) {
                this.relatedProducts = [];
                for (let dataItem of data) {
                    const related = {...dataItem}
                    related.Slug = `${communityBasePath}/product/${related.Id}`;
                    this.relatedProducts.push(related);
                }
            }
            this._dataReady = true;
            this.isOpen = (this.relatedProducts?.length > 0 ?? false);
        }
}