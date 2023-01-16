import { LightningElement, api } from 'lwc';
import changeOwner from '@salesforce/apex/CaseController.changeOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LABELS from './labels.js';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ChangeCaseOwner extends LightningElement {

    @api recordId;

    labels = LABELS;

    handleChangeOwner(evt) {

            changeOwner({ recordId: this.recordId })
            .then(result => {
                this.showNotification(this.labels.The_case_was_successfully_forwarded);
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.closeQuickAction();
            })
            .catch(error => {
                this.showNotification(error.body.message, this.labels.Error, 'error');
            });

    }

    showNotification(message, title = 'Success', variant = "success") {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }    

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }    
}