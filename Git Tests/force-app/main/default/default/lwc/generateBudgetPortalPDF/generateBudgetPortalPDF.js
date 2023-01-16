import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPdfPage from '@salesforce/apex/BudgetDetailController.getPdfPage';
import { doCalloutWithStdResponse } from 'c/calloutService';

export default class GenerateBudgetPortalPDF extends NavigationMixin(LightningElement) {
    @api recordId;
 
    @api invoke() {
        doCalloutWithStdResponse(this, getPdfPage, {oppId: this.recordId}).then(response => {
            console.log(response.data);
            window.open(response.data);

            
        });

    }
}