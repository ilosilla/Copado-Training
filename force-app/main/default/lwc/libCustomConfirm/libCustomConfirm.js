import LightningModal from 'lightning/modal';

export default class LibCustomConfirm extends LightningModal {

    isModalOpen = false;
    
    
    // handle the open modal button click
    handleOpenModal() {
            this.isModalOpen = true;
    }

    // handle the yes button click
    handleYesClick() {
            console.log('Yes clicked');
            // close the modal
            this.isModalOpen = false;
    }

    // handle the no button click
    handleNoClick() {
            console.log('No clicked');
            // close the modal
            this.isModalOpen = false;
    }

    // handle the cancel button click
    handleCancelClick() {
            console.log('Cancel clicked');
            // close the modal
            this.isModalOpen = false;
    }
}

export async function saluda() {    
    const result = await LibCustomConfirm.open({
        style: {
            'max-width': '200px !important;'
        },     
        class: 'clase',
        size: 'small',
        label: 'la capsalera'
    });   
    return "Ya";
}