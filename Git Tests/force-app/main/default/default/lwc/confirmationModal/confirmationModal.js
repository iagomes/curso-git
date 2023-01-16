import { LightningElement, api } from 'lwc';

export default class ConfirmationModal extends LightningElement {

    @api title;
    @api textLabel;
    @api cancelLabel;
    @api confirmationLabel;
    @api showSpinner;

    handleCloseModal(){
        this.dispatchEvent(new CustomEvent('closemodal'));
    }
    handleConfirmModal(){
        this.dispatchEvent(new CustomEvent('confirm'));
    }
}