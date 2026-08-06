import { LightningElement, api } from 'lwc';
import getRelatedProducts from '@salesforce/apex/B2B_ServicesController.getRelatedProducts';
import communityBasePath from '@salesforce/community/basePath';
import { getSessionContext } from 'commerce/contextApi';

export default class B2bPdpRelatedProducts extends LightningElement {

    _productId;
    _pricebookEntryId;
    _relatedCodes;

    relatedProducts = [];
    accountId = null;
    buyerGroupId = null;
    isLoading = false;
    error;

    /* =======================
       API PROPERTIES
       ======================= */

    @api
    set productId(value) {
        this._productId = value;
        this.tryLoad();
    }
    get productId() {
        return this._productId;
    }

    @api
    set pricebookEntryId(value) {
        this._pricebookEntryId = value;
        this.tryLoad();
    }
    get pricebookEntryId() {
        return this._pricebookEntryId;
    }

    @api
    set relatedCodes(value) {
        this._relatedCodes = value;
        this.tryLoad();
    }
    get relatedCodes() {
        return this._relatedCodes;
    }

    /* =======================
       Load orchestration
       ======================= */

    tryLoad() {
        if (
            this._pricebookEntryId &&
            this._relatedCodes &&
            !this.isLoading &&
            this.relatedProducts.length === 0
        ) {
            this.loadRelatedProducts();
        }
    }

    /* =======================
       Data loading
       ======================= */

    async loadRelatedProducts() {
        this.isLoading = true;
        this.error = null;

        try {
            const session = await getSessionContext();
            this.accountId = session?.effectiveAccountId || null;
            if (session?.buyerGroups?.length > 0) {
                this.buyerGroupId = session.buyerGroups[0].id;
            }
            const result = await getRelatedProducts({                
                sourceCodesJson: JSON.stringify(this._relatedCodes),
                pricebookEntryId: this._pricebookEntryId,
                buyerGroupId: this.buyerGroupId 
            });
            this.relatedProducts = [];
            for (let dataItem of result) {
                const related = {...dataItem}
                related.Tags = this.normalizeTags(dataItem.Tag);
                related.Slug = `${communityBasePath}/product/${related.Id}`;
                this.relatedProducts.push(related);
            }
        } catch (e) {
            this.error = e;
            console.error('[RelatedProducts] load failed', e);
        } finally {
            this.isLoading = false;
        }
    }

    /* =======================  
       Getters
       ======================= */
    get hasRelatedProducts() {
        return this.relatedProducts && this.relatedProducts.length > 0;
    }

    normalizeTags(tagString) {
        if (!tagString) {
            return [];
        }

        return Array.from(
            new Set(
                tagString
                    .split('|')
                    .map(t => t.trim())
                    .filter(Boolean)
            )
        );
    }



}