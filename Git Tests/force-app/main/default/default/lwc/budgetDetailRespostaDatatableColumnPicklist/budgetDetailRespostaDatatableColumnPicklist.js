import { api, LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { MultiOption } from 'c/utilities';

export default class BudgetDetailRespostaDatatableColumnPicklist extends LightningElement {

    @api recordId;
    @api disconnectFromParent;
    @api fieldApiName; //  = 'OpportunityLineItem.TabulacaoN1__c'
    @api controllerValue;
    @api controllerFieldApiName;
    @api label;
    @api isEditable = false;
    @api picklistValues;
    isEditing = true;
    @track options_ = [];
    
    value_;
    get value(){
        return this.value_;
    }

    hideOptions_;
    @api
    get hideOptions(){
        return this.hideOptions_ ? this.hideOptions_.filter(opt => {return opt !== this.value_}) : this.hideOptions_;
    }

    set hideOptions(value){
        return this.hideOptions_ = value;
    }

    get options(){
        let scope = this;
        let result;
        let values = scope.value ? scope.value.split(';') : [];
        if(scope.controllerFieldApiName && scope.picklistValues.controllerValues && Object.keys(scope.picklistValues.controllerValues).length > 0){
            let controllerId = scope.picklistValues.controllerValues[scope.controllerValue];
            result = scope.picklistValues.values.filter(opt => {
                return opt.validFor.indexOf(controllerId) >= 0;
            }).map(opt => {
                return new MultiOption(values.indexOf(opt.value) >= 0, opt.value, opt.label);
            });
        } else {
            result = scope.picklistValues.values.map(opt => {
                return new MultiOption(values.indexOf(opt.value) >= 0, opt.value, opt.label);
            });
        }
        if(!result.some(opt => opt.value === scope.value_)){
            result = [new MultiOption(true, scope.value_, scope.value_), ...result];
        }
        return result;
    }

    @api
    set value(newValue){
        this.value_ = newValue;
    }

    get fieldName(){
        return this.fieldApiName.split('.')[1];
    }

    get isEditing_() {
        return this.recordId && this.isEditable && this.isEditing && this.options && this.value_ != 'RESGATADO' && this.value_ != 'Aprovado';
    }

    renderedCallback() {
            let cmp = this.template.querySelector('c-multi-values-picklist-l-w-c');
            if(cmp){
                const style = document.createElement('style');
                style.innerText = `
                c-multi-values-picklist-l-w-c .main-div .option-value {
                    white-space: normal;
                }
                c-multi-values-picklist-l-w-c .main-div div.custom-dropdown {
                    width:100%;
                }
                .TabulacaoN1__c:has(span[title="Cotado"]) {
                    pointer-events:none;
                }
                .Status__c:has(span[title="Respondido"]) {
                    pointer-events:none;
                }
                `;
                this.template.querySelector('.content').appendChild(style);
            }
        }

    handleMultiValuesPickListValueChange(event){

        this.options_ = this.options_.filter(opt => {
            return this.hideOptions.some(opt.value);
        });
        
        this.isEditing = true;
        let draftValue = {
            Id: this.recordId
        };
        draftValue[this.fieldApiName.split('.')[1]] = JSON.parse(event.detail).selectedOptions.map(opt => opt.value).join(';');
        if(this.controllerFieldApiName){
            draftValue[this.controllerFieldApiName] = this.controllerValue;
        }
        this.template.dispatchEvent(new CustomEvent('customvaluechange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: draftValue
        }));
    }
}