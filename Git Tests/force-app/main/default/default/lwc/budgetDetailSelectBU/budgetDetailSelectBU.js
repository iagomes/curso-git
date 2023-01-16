import { api, track, LightningElement } from 'lwc';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserCategories from '@salesforce/apex/BudgetDetailController.getUserCategories';

export default class BudgetDetailSelectBU extends LightningElement {

    userBUList = [];
    selectedBU = '';
    selectedBUList = [];
    showSpinner = false;
    @track showSelectedBUModal = false;
    
    standardBUsList = [
        {value: 'M', label: 'Materiais', selected: false},
        {value: 'G', label: 'Genérico', selected: false},
        {value: 'S', label: 'Especialidade', selected: false}
    ];
    get categorias_ (){
        if(this.categorias.length == 0){
            return this.standardBUsList;
        }else{
            return this.standardBUsList.filter(cat =>{
                return this.categorias.includes(cat.value);
            });
        }
    }

    @api label;
    @api categorias = [];
    @api quoteItemId;
    @api opportunityId;
    @api type = 'radio';

    @api
    get controlSpinner(){
        return this.showSpinner;
    }
    set controlSpinner(value){
        this.showSpinner = value;
    }
    get isRadio(){
        return this.type === 'radio';
    }
    get isCheckbox(){
        return this.type === 'checkbox';
    }

    connectedCallback() {
        if(this.isRadio){
            this.checkExistingUserBUs();
        }else if(this.isCheckbox){
            this.showSelectedBUModal = true;
        }
    }

    checkExistingUserBUs(){
        this.showSpinner = true;
        let params = {
            opportunityId: this.opportunityId
        };
        doCalloutWithStdResponse(this, getUserCategories, params).then( (response) => {
            this.showSpinner = false;
            if(!!response && !!response.data) {
                this.userBUList = JSON.parse(response.data);
                if(this.userBUList.length == 1){
                    this.selectedBU = this.userBUList[0].value;
                    this.handleButtonClickAdicionar();
                }else{
                    this.showSelectedBUModal = true;
                }
            } else{
                this.userBUList = [...this.standardBUsList];
                this.showSelectedBUModal = true;
            }
        }).finally(()=>{
            this.showSpinner = false;
        });
    }

    addButtonTimeout;
    handleButtonClickAdicionar(event) {
        let scope = this;
		if(this.addButtonTimeout != null){
			clearTimeout(this.addButtonTimeout);
		}

        let detailValue;
        if(this.isRadio){
            detailValue = this.selectedBU;
        }else if(this.isCheckbox){
            detailValue = this.selectedBUList.length > 0 ? this.selectedBUList : null;
        }
        if(!!detailValue){
            this.showSpinner = true;
            this.addButtonTimeout = setTimeout(function() {
                scope.dispatchEvent(new CustomEvent('processitemupdateresult', {detail: detailValue}));
            }, 500);
        }else{
            this.showSpinner = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Aviso!',
                message: 'Para adicionar a resposta, selecione a BU desejada.',
                variant: 'warning'
            }));
        }
    }

    closeSelectBUModal() {
        this.selectedBU = null;
        this.selectedBUList = [];
        this.dispatchEvent(new CustomEvent('closemodalselectbu', null));
    }

    handleSelectedBUValue(event) {
        this.selectedBU = event.target.value;
    }

    handleCheckbox(event){
        this.selectedBUList = event.target.value;
    }
}