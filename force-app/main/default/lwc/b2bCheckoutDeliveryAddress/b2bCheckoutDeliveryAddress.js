/**
 * DEUDA TECNICA:
 * 2- TODO: Consider only dispatching when shipping-relevant fields changed (postalCode/state/city/street/country).
 *          For now, always dispatch after save to keep delivery cost in sync.
 */
import { LightningElement, api } from 'lwc';

const K_SHIP_TO_CUSTOMER = 'SHIP-TO-CUSTOMER';
const K_CUSTOMER_PICKUP = 'CUSTOMER-PICKUP';

// Required API parameters that must be set before component initialization
const REQUIRED_PARAMS = ['addresses', 'addressId', 'deliveryCost', 'deliveryMethod'];

export default class B2bCheckoutDeliveryAddress extends LightningElement {

    /* =========================================================
       PUBLIC API
       ========================================================= */

    @api mode; // 'edit' | 'summary'

    @api accountId;
    
    @api
    set addresses(value) {  
        if (this.flag_initialized && JSON.stringify(value) !== JSON.stringify(this._addresses)) {  
            this.flag_initialized = false;
        } 
        this._addresses = (value || []).map(addr => ({ ...addr }));
        this.pendingParams.delete('addresses');
        this.tryInitialize();
    }   
    get addresses() {
        return this._addresses;
    }

    @api
    set deliveryMethod(value) {
        if (this.flag_initialized && value !== this.st_deliveryMethod) {
            this.flag_initialized = false;
        }

        this.st_deliveryMethod = value;
        this.pendingParams.delete('deliveryMethod');
        this.tryInitialize();
     }
    get deliveryMethod() {
            return this.st_deliveryMethod;  
    }

    @api
    set selectedAddressId(value) {
        this._selectedAddressId = value;
        this.pendingParams.delete('addressId');
        if (!this._addresses.length) {
            return;    
        }        
        this.tryInitialize();        
    }
    get selectedAddressId() {
        return this._selectedAddressId;
    }

    @api 
    set deliveryCost(value) {
        this.st_deliveryCost = {...value};
        this.pendingParams.delete('deliveryCost');
        this.tryInitialize();
    }
    get deliveryCost() {
        return this.st_deliveryCost;
    }

    @api
    set preparationMessage(value) {
        this.st_preparationMessage = value;
    }
    get preparationMessage() {
        return this.st_preparationMessage;
    }

    /* =========================================================
       INTERNAL STATE
       ========================================================= */
    _addresses = [];
    _selectedAddressId;

    st_deliveryCost = { loading: false, data: null, error: null };
    st_showAddressPanel = false;
    st_addressFormMode = 'create'; // o 'edit'
    st_addressToEdit = null;
    st_toastMessage = '';
    st_toastVariant = 'error';
    ui_showToast = false; // shown when the user tries to edit the account's own (non-editable) address
    st_deliveryMethod;
    st_preparationMessage = '';

    st_showExtendedPanel = false;
    st_addressFilter = '';

    // Track which required API params are still pending initialization
    pendingParams = new Set(REQUIRED_PARAMS);
    flag_initialized = false;

    unconfirmedSelectedAddressId = null;


    /* =========================================================
       LIFECYCLE
       ========================================================= */

    tryInitialize() {        
        if (this.flag_initialized) {
            return;            
        }        
        if (this.pendingParams.size > 0) {
            return;
        }        
        if (this._addresses.length > 0) {
            let selectedId = this._selectedAddressId && 
                this._addresses.some(a => a.id === this._selectedAddressId) ? this._selectedAddressId : null;
            if (!selectedId) {
                const def = this._addresses.find(a => a.isDefault);
                selectedId = def ? def.id : this._addresses[0].id;
            }
            this._selectedAddressId = selectedId;
            this.notifyAddressChange();
            this.applySelection(selectedId);            
            this.notifyAddressChange();
         }                        
         this.flag_initialized = true;
    }

    /* =========================================================
       GETTERS
       ========================================================= */

    get isDelivery() {
        return this.deliveryMethod === K_SHIP_TO_CUSTOMER;
    }

    get isPickup() {
        return this.deliveryMethod === K_CUSTOMER_PICKUP;
    }

    get isEditing() {
        return this.mode === 'edit';
    }

    get isSummary() {
        return this.mode === 'summary';
    }

    get shippingUnavailable() {
        if (this.isRecalculating || this.hasShippingError) return false;
        if (!this.deliveryCost?.data) return true;
        return this.deliveryCost.data.available === false;
    }

    get isConfirmDisabled() {
        return !this.isPickup && (this.isRecalculating || !this._selectedAddressId || this.shippingUnavailable || this.hasShippingError);
    }

    get processedAddresses() {
        return (this.addresses || [])
            .map(addr => ({
                ...addr,
                isSelected: addr.id === this._selectedAddressId,
                isAccountAddress: addr.className === 'Account'
            }))
            .sort((a, b) => {
                // IsDefault primero (true antes que false)
                if (a.isDefault !== b.isDefault) return a.isDefault ? -1 : 1;
                // Luego stateCode
                if (a.stateCode !== b.stateCode) return (a.stateCode || '').localeCompare(b.stateCode || '');
                // Finalmente postCode
                return (a.postCode || '').localeCompare(b.postCode || '');
            });
    }

    get filteredAddresses() {
        const q = (this.st_addressFilter || '').trim().toLowerCase();
        const list = (this.processedAddresses || []).filter(a => {
            if (!q) {
                return true;
            }
            const haystack = [
                a.name, a.street, a.city, a.stateCode, a.postCode, a.country, a.countryCode
            ].filter(Boolean).join(' ').toLowerCase();
            return haystack.includes(q);
        });
        return list;
    }

    get selectedAddress() {
        return this.addresses?.find(a => a.id === this.selectedAddressId);
    }

    get selectedAddressLine() {
        const a = this.selectedAddress;
        if (!a) {
            return '';
        }

        const street = (a.street || '').trim();
        const cityLine = [a.postCode, a.city].filter(Boolean).join(' ').trim();
        const state = (a.stateCode || '').trim();

        const parts = [];
        if (street) {
            parts.push(street);
        }

        const cityState = [cityLine, state].filter(Boolean).join(', ').trim();
        if (cityState) {
            parts.push(cityState);
        }

        return parts.join(' · ');
    }

    get hasSelectedContactInfo() {
        return Boolean(this.selectedAddress?.phone1 || this.selectedAddress?.email);
    }
    
    get selectedContactLine() {
        const a = this.selectedAddress;
        if (!a) {
            return '';
        }

        const parts = [];
        if (a.phone1) {
            parts.push(`Phone: ${a.phone1}`);
        }
        if (a.email) {
            parts.push(`Email: ${a.email}`);
        }
        return parts.join(' · ');
    }

    /* Start of delivey cost getters */
    get hasShippingError() {
        return this.deliveryCost?.error ?? false;
    }

    get shippingMethod() {
        return this.deliveryCost?.data?.carrierName || '';
    }

    get estimatedWeight() {
        const kg = this.deliveryCost?.data?.weightKg;
        if (kg == null) return null;
        return (kg * 2.20462).toFixed(2) + ' lb';
    }

    get deliveryCostFormatted() {
        const fee = this.deliveryCost?.data?.cost;
        const currency = this.deliveryCost?.data?.currencyCode;
        if (fee === null || fee === undefined || fee === '' || !currency) {
            return 'N/A';
        }
        return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(fee);
    }

    get shippingHeadline() {        
        return this.shippingMethod + ' — ' +  this.deliveryCostFormatted;
    }

    get shippingDetails() {
        return 'Estimated shipment weight ' + this.estimatedWeight + ' · ' + this.shippingNote;
    }

    get isRecalculating() {
        return this.deliveryCost?.loading;
    }  
    
    get shippingNote() {
        if (this.isRecalculating) {
            return 'Recalculating shipping cost...';
        }
        return this.deliveryCost?.data?.explanation || '';
    }

    get componentTitle() {
        if (this.isDelivery) {
            return 'Delivery address';
        } else if (this.isPickup) {
            return 'Pickup location';
        }
        return '';
    }

    get componentIntro() {
        if (this.isDelivery) {
            return 'Your order will be delivered to the address selected below.';
        } else if (this.isPickup) {
            return 'Your order will be ready for pickup at the location selected below.';
        }   
        return '';
    }

    get pickupHours() {
        return this.selectedAddress?.additionalInfo || '';
    }

    get preparationMessage() {
        return this.selectedAddress?.preparationMessage || '';
    }

    get confirmButtonLabel() {
        if (this.isPickup) {
            return 'Confirm pickup location';
        } else if (this.isDelivery) {
            return 'Confirm delivery address';
        }
        return 'Confirm';
    }
    /* End of delivey cost getters */

    /* =========================================================
       GETTERS (SUMMARY MODE)
       ========================================================= */
    get summaryAddressName() {
        return this.selectedAddress.name;
    }

    get summaryAddressLine() {
        return this.selectedAddressLine;
    }

    get summaryCost() {
        if (this.isRecalculating) {
            return 'Waiting...';            
        } else {
            return this.shippingHeadline + ' (Shipment weight ' + this.estimatedWeight + ')';
        }
    }

    /* =========================================================
       OUTGOING COMMUNICATION (EVENTS)
       ========================================================= */

    notifyAddressChange() {
        const a = this.selectedAddress || null;
        this.dispatchEvent(new CustomEvent('addresschange', {
            detail: {
                addressId: this._selectedAddressId || null,
                address: a
            },
            bubbles: true,
            composed: true
        }));
    }

    /* =========================================================
       EVENT HANDLERS
       ========================================================= */

    handleChange() {
        this.dispatchEvent(new CustomEvent('changedata', {
            bubbles: true,
            composed: true
        }));
    }

    handleAddressChange(event) {        
        const selectedId = event.target.value;
        this.unconfirmedSelectedAddressId = selectedId;
    }

    handleConfirm() {
        const selected = this.addresses.find(
            a => a.id === this._selectedAddressId
        );

        this.dispatchEvent(
            new CustomEvent('confirmdata', {
                detail: {
                    addressId: selected.id,
                    address: selected
                },
                bubbles: true,
                composed: true
            })
        );
    }
    
    handleCreateNewAddress() {
        this.st_addressFormMode = 'create';
        this.st_addressToEdit = null;
        this.st_showAddressPanel = true;
    }

    handleEditAddress() {
        if (this.selectedAddress?.className === 'Account') {
            // Account's own (nominal) address — not editable from checkout.
            this.showToast("This is your account's default address. To change it, please contact your account representative.", 'warning');
            return;
        }
        this.st_addressFormMode = 'edit';
        this.st_addressToEdit = this.convertAddressToCPA(this.selectedAddress);
        this.st_showAddressPanel = true;
    }

    showToast(message, variant = 'success') {
        this.st_toastMessage = message;
        this.st_toastVariant = variant;
        this.ui_showToast = true;

        setTimeout(() => {
            this.ui_showToast = false;
        }, 9000);
    }

    get toastVariantClass() {
        return `checkout-toast-content checkout-toast-${this.st_toastVariant}`;
    }

    handleEditAddressFromRow(event) {
        const id = event.currentTarget.dataset.id;        
        this._selectedAddressId = id;
        this.handleEditAddress();
    }

    handleCloseAddressPanel() {
        this.st_showAddressPanel = false;
    }

    handleAddressSaved(event) {
        const addressData = event.detail;
        const address = this.convertCPAtoAddress(addressData);
        const savedIsDefault = Boolean(address.isDefault);
        let next = [...this.addresses];
        const existingIndex = next.findIndex(a => a.id === address.id);
        if (existingIndex >= 0) {
            next[existingIndex] = address;
        } else {
            next = [address, ...next];
        }
        if (savedIsDefault) {
            next = next.map(a => ({ ...a, isDefault: a.id === address.id }));
        }
        this._addresses = next;
        this._selectedAddressId = address.id;
        this.notifyAddressChange();
        this.st_showAddressPanel = false;
    }

    handleViewOnMap() {
        const addr = this.selectedAddress;
        if (!addr) {
            return;
        }
        const parts = [
            addr.street,
            addr.city,
            addr.stateCode || addr.state,
            addr.postCode,
            addr.countryCode || addr.country
        ].filter(Boolean);
        const query = encodeURIComponent(parts.join(', '));
        window.open(`https://www.google.com/maps/search/?api=1&query=${query}`, '_blank', 'noopener,noreferrer');
    }

    handleViewOnMapFromRow(event) {
        const id = event.currentTarget.dataset.id;
        this._selectedAddressId = id;
        this.handleViewOnMap();
    }


    handleOpenExtendedPanel() {
        this.st_showExtendedPanel = true;
    }
    
    handleCloseExtendedPanel() {
        this.st_showExtendedPanel = false;
        this.st_addressFilter = ''
        if (this.unconfirmedSelectedAddressId) {
            this._selectedAddressId = this.unconfirmedSelectedAddressId;
            this.unconfirmedSelectedAddressId = null;
            this.applySelection(this._selectedAddressId );
            this.notifyAddressChange();
        }
    }

    handleCancelExtendedPanel() {
        this.st_showExtendedPanel = false;
    }

    handleAddressFilterChange(event) {
        this.st_addressFilter = event.target.value || '';
    }

    /* ======================================================
       UTILITY METHODS
       ====================================================== */
    applySelection(selectedId) {
        this._addresses = this._addresses.map(addr => ({
            ...addr,
            isSelected: addr.id === selectedId
        }));
    }

    convertCPAtoAddress(addressData) {
        return {
            id: addressData?.address?.Id,
            name: addressData?.address?.Name,
            street: addressData?.address?.Street,
            city: addressData?.address?.City,
            stateCode: addressData?.address?.StateCode,
            state: addressData?.state,
            postCode: addressData?.address?.PostalCode,
            countryCode: addressData?.address?.CountryCode,
            country: addressData?.country,
            phone1: addressData?.address?.Phone__c,
            email: addressData?.address?.EMail__c,
            isDefault: Boolean(addressData?.address?.IsDefault),
        };
    }

    convertAddressToCPA(address) {
        return {
            Id: address?.id,
            Name: address?.name,
            Street: address?.street,
            City: address?.city,
            StateCode: address?.stateCode,
            PostalCode: address?.postCode,
            CountryCode: address?.countryCode,            
            Phone__c: address?.phone1,
            EMail__c: address?.email,
            IsDefault: address?.isDefault,
        };
    }


}