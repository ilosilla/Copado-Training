import { api, track } from 'lwc';
import LwcUtils from 'c/lwcUtils';

export default class Nb2bShippingAddressSearch extends LwcUtils {
	//public
	@api addresses;
	@api selectedAddress;
	@api accountId;
	//labels
	@api addAddressLabel;

	get modalTitle() {
		return this.addAddressLabel;
		//return join(' ', labels.Add, labels.Address);
	}

	openModal() {
		const dialog = this.template.querySelector('c-nb2b-dialog');
		dialog.show();
	}

	closeModal() {
		const dialog = this.template.querySelector('c-nb2b-dialog');
		dialog.hide();
	}

	handleSave(event) {
		event.stopPropagation();
		try{
			let addressId = this.handleDoInit(event);
			super.fireEvent('newaddress', addressId);
			this.closeModal();
		} catch(e){ console.error(e); }
	}

	handleAddressSelection(event) {
		let address = event.detail.value;
		this.selectedAddress = address;
		super.fireEvent('selection', address);
	}
}