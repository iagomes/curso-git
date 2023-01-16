import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import closeCase from '@salesforce/apex/CaseController.closeCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class CloseCaseActionButton extends NavigationMixin(LightningElement) {

    @api recordId;

    handleConfirmationModalResult(event) {
        debugger;
        if (event.detail.action == 'confirm') {
        
            closeCase({ recordId: this.recordId })
            .then(result => {
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Sucesso!',
                        message: "Caso encerrado com sucesso!",
                        mode:"sticky",
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CustomEvent('closeAction'));
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erro!',
                        message: error.body.message,
                        mode:"sticky",
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CustomEvent('closeAction'));
            });
        } else {
            this.dispatchEvent(new CustomEvent('closeAction'));
        }
    }   

}