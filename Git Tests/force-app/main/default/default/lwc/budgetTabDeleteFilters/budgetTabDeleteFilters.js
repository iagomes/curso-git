import { LightningElement, api, track } from 'lwc';
import deleteFixedFilters from '@salesforce/apex/BudgetTabController.deleteFixedFilters';
import { doCalloutWithStdResponse } from 'c/calloutService';

export default class BudgetTabDeleteFilters extends LightningElement {
    @api personalizedFilters;
    @track filtersSelected = [];

    handleChangeDualListbox(event){
        this.filtersSelected = event.detail.value;
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent("closemodal"));
    }

    handleDeleteFilters(){
        let scope = this;
        let params = {filtersList: [...scope.filtersSelected]};
        doCalloutWithStdResponse(scope, deleteFixedFilters, params).then(response => {
            scope.dispatchEvent(new CustomEvent("delete"));
        }).catch(error =>{
            console.error(error);
        });
    }
}