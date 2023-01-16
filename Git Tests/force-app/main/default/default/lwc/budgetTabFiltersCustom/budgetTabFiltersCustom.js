import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { doCalloutWithStdResponse } from 'c/calloutService';
import saveFixFilter from '@salesforce/apex/BudgetTabController.saveFixFilter';

export default class BudgetTabFiltersCustom extends LightningElement {
    @api paramsToSave;
    filterName;

    get paramsToDisplay(){
        let paramsCopy = Object.fromEntries(Object.entries(this.paramsToSave[1]).filter(([_, v]) => {return v != null && v != [] && v != '' && v != {}}));
        let paramsList = Object.keys(paramsCopy).map(key =>{
            return key + paramsCopy[key];
        });
        return paramsList;
    }
    closeModal(evt){
        this.dispatchEvent(new CustomEvent("closemodal"));
    }

    setFilterName(evt){
        this.filterName = evt.detail.value;
    }

    handleSaveClick(evt){
        let scope = this;
        let params = {filterName: scope.filterName, filterParams :JSON.stringify(scope.paramsToSave[0])};
        doCalloutWithStdResponse(scope, saveFixFilter, params).then(response => {
            scope.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: 'Filtro Salvo com sucesso', variant: 'success'}));
            scope.dispatchEvent(new CustomEvent('savenewfilter'));
        }).catch(error => {
            console.log('Error to get Users', JSON.stringify(error));
        });
    }
    
}