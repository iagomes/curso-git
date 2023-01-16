import { LightningElement, api } from 'lwc';
import changeOwner from '@salesforce/apex/CaseController.changeOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LABELS from './labels.js';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CaseChangeOwner extends LightningElement {

    @api recordId;
    @api groupName;

    labels = LABELS;

    handleChangeOwner(evt) {

        if (evt.detail.action == "confirm") {

            changeOwner({ recordId: this.recordId, groupName: this.groupName })
            .then(result => {
                this.showNotification(this.labels.The_case_was_successfully_forwarded);
                this.closeQuickAction();
            })
            .catch(error => {
                this.showNotification(error.body.message, this.labels.Error, 'error');
            });

        } else {
            console.log('should close');
            this.closeQuickAction();
        }

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