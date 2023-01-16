import { api, track, wire, LightningElement } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getConditionPayment from '@salesforce/apex/ConditionPaymentBudgetController.getConditionPayment';
import { stringToNumber } from 'c/utilities';

import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ConditionPaymentBudget extends LightningElement {
	@api recordId;
    @api budgetData;
    @track tabs = [];
    @track resp = 0;
    @track total = 0;
    @track totItem = 0;
    @track mapOfCNPJ = new Map();
    @api isEditable;
    @api viewOnly;

    freteOptions = [];
    condPagOptions = [];

    get showTabs(){
      return this.tabs && this.tabs.length > 0;
    }


    @wire(getPicklistValues, { fieldApiName: 'CondicaoPagamentoPorCD__c.FretePicklist__c', recordTypeId:'012000000000000AAA'}) //random recordTypeId
    getFreteValues({ error, data }){
        if (data) {

            //console.log('FretePicklist',data);
            this.freteOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            //console.log(this.freteOptions);

        } else if (error) {
            console.error('Error1  ' + error);
            console.error(JSON.stringify(error));
        }
    }
    @wire(getPicklistValues, { fieldApiName: 'CondicaoPagamentoPorCD__c.CondicaoPagamentoPL__c', recordTypeId:'012000000000000AAA'}) 
    getCondPagValues({ error, data }){
        if (data) {
            //console.log('CondicaoPagamentoPL',data);
            this.condPagOptions = data.values.filter(value =>{
                return value.validFor.includes(data.controllerValues.Bionexo);
            }).map(plval =>{
                return {value: plval.value, label: plval.label}
            });
            //console.log(this.condPagOptions);
        } else if (error) {
            console.error('Error2  ' + error);
            console.error(JSON.stringify(error));
        }
    }

    handleChangeCloseDate(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = event.target.value;
        currentCd.CloseDate = value;
    }

    handleChangeCondicaoPagamentoPL(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = event.target.value;
        currentCd.CondicaoPagamentoPL = value;
    }

    handleChangePrazoValidade(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = stringToNumber(event.target.value);
        currentCd.PrazoValidade = value;
    }

    handleChangeMinimumBilling(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = event.target.value;
        currentCd.MinimumBilling = value;
    }

    handleChangePrazoEntrega(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = stringToNumber(event.target.value);
        currentCd.PrazoEntrega = value;
    }

    handleChangeFretePicklist(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = event.target.value;
        currentCd.FretePicklist = value;
    }

    handleChangeObservacoesLongText(event){
        let currentCd = this.tabs.find((tab)=>{return tab.Id === event.target.dataset.targetId});
        let value = event.target.value;
        currentCd.ObservacoesLongText = value;
    }

    @api getCurrentValues(){

        console.log('this.tabs: ',JSON.stringify(this.tabs));
        if(this.tabs && this.tabs.length > 0){
            let result = false;
            let params = JSON.stringify(this.tabs);
            return params;
        }else{
            return undefined;
        }
    }
    connectedCallback() {
        //this.getConditionPayment();
    }

    @api getConditionPayment(){
        let scope = this;

        getConditionPayment({ oppId: scope.recordId })
        .then(result => {
            if (result != null && result.data != '[]'){
                scope.tabs = JSON.parse(result.data);
            }
        }).catch(error => {
            console.error(error);
            scope.isLoadingProducts = false;
        });
    }
}