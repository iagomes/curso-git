import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class BudgetSummaryItem extends NavigationMixin(LightningElement) {
    // APIs
    @api budgetData;
    @track desktop = false;

    connectedCallback() {
        this.desktop = FORM_FACTOR == 'Large';
    }

    navigateToBudget(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.budgetId,
                actionName: 'view'
            }
        });
    }
}