import { api, track, LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getTabulacaoValues from '@salesforce/apex/BudgetDetailTabulacaoController.getTabulacaoValues';
import getTabulacaoTeamMember from '@salesforce/apex/BudgetDetailTabulacaoController.getTabulacaoTeamMember';
import oppDueDateWasUpdatedByPortal from '@salesforce/apex/BudgetDetailTabulacaoController.oppDueDateWasUpdatedByPortal';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class BudgetDetailTabulacao extends LightningElement {

    @api recordId;
    @api budgetDetailDueDate;
    @api isEditable;
    @track tabulacaoN1;
    @track tabulacaoN2;
    @track tabulacaoN1Picklist;
    @track tabulacaoN2Picklist;
    isRendered = false;


    get viewOnly(){
        return (this.isEditable === false) ||(new Date(this.budgetDetailDueDate.dataVencimento).getTime() < new Date().getTime());        
    }
    get n1Values(){
        return this.tabulacaoN1Picklist  ? this.tabulacaoN1Picklist : null;
    }
    get n2Values(){
        return this.tabulacaoN2Picklist && this.tabulacaoN1Picklist ? this.tabulacaoN2Picklist[this.tabulacaoN1] : null;
    }

    
    @wire(getPicklistValues, { fieldApiName: 'OpportunityTeamMember.TabulacaoN1__c', recordTypeId: '01221000002ztofAAA' }) //random recordTypeId
    getPicklistTabulacaoN1Values({ error, data }){
        if (data) {
            this.tabulacaoN1Picklist = data.values.map(plValue => {
                return {
                    label: plValue.label,value: plValue.value
                };
            });
            this.tabulacaoN1Picklist = this.tabulacaoN1Picklist.filter(opt => {
                return (opt.value != 'Envio Automático') && (opt.value != 'Recusa')
            });
        } else if (error) {
            console.error('Tabulacao-error1  ' + error);
            console.error(JSON.stringify(error));
        }
    }
    @wire(getPicklistValues, { fieldApiName: 'OpportunityTeamMember.TabulacaoN2__c', recordTypeId: '01221000002ztofAAA' }) //random recordTypeId
    getPicklistTabulacaoN2Values({ error, data }){
        if (data) {
            this.tabulacaoN2Picklist = {};
            Object.keys(data.controllerValues).forEach(key=>{
                this.tabulacaoN2Picklist[key] = data.values.filter(val =>{return val.validFor.includes(data.controllerValues[key])}).map(plValue => {
                    if(true){
                        return {label: plValue.label,value: plValue.value}
                    }
                })
            });
            delete this.tabulacaoN2Picklist['Envio Automático'];
            delete this.tabulacaoN2Picklist['Recusa'];
        } else if (error) {
            console.error('Tabulacao-Error2  ' + error);
            console.error(JSON.stringify(error));
        }
    }

    @wire(getTabulacaoTeamMember, { oppId: '$recordId'})
    getTabulacaoTeamMember({data, error}){
        if (data){
            let tabulacaoTeamMember = data.data.tabulacaoTeamMember;
            let hasTabN1 =  'TabulacaoN1__c' in tabulacaoTeamMember;
            let hasTabN2 =  'TabulacaoN2__c' in tabulacaoTeamMember;
            if(hasTabN1 && hasTabN2){
                this.tabulacaoN1 = tabulacaoTeamMember.TabulacaoN1__c;
                this.tabulacaoN2 = tabulacaoTeamMember.TabulacaoN2__c;
            }
        }
        if (error){
            const event = new ShowToastEvent({
                title: 'Error',
                variant: 'error',
                message:
                    error,
            });
            this.dispatchEvent(event); 
        }
    }
    
    editTabulacaoN2PicklistWhenRender(){
        doCalloutWithStdResponse(this, getTabulacaoValues, {oppId:this.recordId})        
        .then(response =>{
            oppDueDateWasUpdatedByPortal({oppId:this.recordId})
            .then(data=>{
                if(data.updatedByPortal == false){
                    let tabn2 = response.data.tabulacao.TabulacaoN2__c;
                    if(this.tabulacaoN2Picklist && tabn2 != 'Envio Automático'){
                        let includesValue = this.tabulacaoN2Picklist['Aceite'].some(e => e.value === 'Envio Automático')
                        if(this.viewOnly == false && includesValue){
                            this.tabulacaoN2Picklist['Aceite'] = this.tabulacaoN2Picklist['Aceite'] .filter(opt => {
                                return (opt.value != 'Envio Automático')
                            });
                        }
                    }
                }else{
                    let style = document.createElement('style');
                    style.innerText = `
                    lightning-base-combobox-item:has(span[title="Envio Automático"]) {
                        display:none;
                    }
                    `;
                    this.template.querySelector('.style-element-container').appendChild(style);
                }

            })
        })
        .catch(error=>{            
            const event = new ShowToastEvent({
                title: 'Error',
                variant: 'error',
                message:
                    error,
            });
            this.dispatchEvent(event);            
        })
    }
    renderedCallback(){
        this.editTabulacaoN2PicklistWhenRender()
        if(!this.isRendered){
            this.enforceStyles();
            this.isRendered = true;
        }
    }
    enforceStyles(){
        let style = document.createElement('style');
        style.innerText = `
            c-budget-detail-tabulacao div.content div.section-content div.slds-col {
                padding: 5px 7px!important;
            }
            
            c-budget-detail-tabulacao div.content div.section-content .is-single-row-field .slds-form-element__control{
                padding-left: 16.3%!important;
            }

            c-budget-detail-tabulacao div.content .slds-input[readonly] {
                --slds-c-input-spacing-horizontal-start: var(--lwc-spacingSmall,0.75rem);
            }

            c-budget-detail-tabulacao div.content .section-content {
                padding-top: 10px;
            }
        `;// margin: 0 0 15px 0;
        this.template.querySelector('.style-element-container').appendChild(style);
    }

    handleChangetab1(event){
        this.tabulacaoN1 = event.target.value;
        this.tabulacaoN2 = null;
    }
    handleChangetab2(event){
        let includesValue = this.tabulacaoN2Picklist['Aceite'].some(e => e.value === 'Envio Automático')
        if(this.viewOnly == false && includesValue){
            this.tabulacaoN2Picklist['Aceite'] = this.tabulacaoN2Picklist['Aceite'] .filter(opt => {
                return (opt.value != 'Envio Automático')
            });
        }
        this.tabulacaoN2 = event.target.value;
    }

    @api getFields(){
        let tabs = {
            'TabulacaoN1__c':this.tabulacaoN1,
            'TabulacaoN2__c':this.tabulacaoN2,
        }
        return tabs;
    }
    @api setFields(value){
        let scope = this;
        if(value){
            //console.log("setFields:::",value, JSON.stringify(value));
            if(value.TabulacaoN1__c){
                if(value.TabulacaoN1__c == 'Envio Automático' || value.TabulacaoN1__c == 'Recusa'){
                    //remendo para adicionar valro que não está na picklist,
                    // o ideal é adicionar e depois filtrar os valores
                    scope.tabulacaoN1Picklist.push({label: value.TabulacaoN1__c, value: value.TabulacaoN1__c});
                    scope.tabulacaoN1Picklist = [...scope.tabulacaoN1Picklist];
                }
                //console.log('tabulacaoN1Picklist',scope.tabulacaoN1Picklist);
                scope.tabulacaoN1 = value.TabulacaoN1__c;
                let element1 = scope.template.querySelector('.TabulacaoN1__c');
                if(element1) element1.value = value.TabulacaoN1__c;
            }

            if(value.TabulacaoN2__c){
                if(value.TabulacaoN2__c == 'Envio Automático'  || value.TabulacaoN2__c == 'Cotação Vencida'){
                    scope.tabulacaoN2Picklist[value.TabulacaoN1__c]=[{label: value.TabulacaoN2__c, value: value.TabulacaoN2__c}];
                    scope.tabulacaoN2Picklist = {...scope.tabulacaoN2Picklist};
                }
                //console.log('tabulacaoN2Picklist',scope.tabulacaoN2Picklist);
                scope.tabulacaoN2 = value.TabulacaoN2__c;
                let element2 = scope.template.querySelector('.TabulacaoN2__c');

                if(element2) element2.value = value.TabulacaoN2__c;
            }
        }
    }
    
}