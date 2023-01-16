import { api, LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { MultiOption } from 'c/utilities';
export default class BudgetDetailProductsDatatableColumnPicklist extends LightningElement {
    
    @api recordId;
    @api recordTypeId = '0120j00000091K6AAI';
    @api disconnectFromParent;
    @api fieldApiName = 'OpportunityLineItem.TabulacaoN1__c';
    @api controllerValue;
    @api controllerFieldApiName;
    @api label;
    @api isEditable = false;
    @api picklistValues;
    isEditing = true;
    
    value_;

    get value(){
        return this.value_;
    }

    get options(){
        let options = [];
        // console.log('getPicklistWithControlledValues >> response.data:::', response.data);
        let values = this.value ? this.value.split(';') : [];
        let controllerId = this.picklistValues.controllerValues[this.controllerValue];
        options = this.picklistValues.values.filter(opt => {
            return opt.validFor.indexOf(controllerId) >= 0;
        }).map(opt => {
            // console.log(opt.label, opt.value, values, values.indexOf(opt.value));
            let option = new MultiOption(values.indexOf(opt.value) >= 0, opt.value, opt.label);
            // if(option.selected){
            //     this.selectedOptions = [option, ...this.selectedOptions];
            // }
            return option;
        });
        //console.log('options:::', options);
        return options;
    }

    @api
    set value(newValue){
        // console.log(this.recordId, 'controllerFieldApiName:::', this.controllerFieldApiName);
        if(this.value_){
            // console.log('value:::', this.value_);
            // console.log('this.options:::', this.options);
            // console.log('this.selectedOptions:::', this.selectedOptions);
            let option = this.options.find(opt => opt.value === this.value_);
            if(!option){
                this.options = [new MultiOption(true, newValue, newValue)];
            }
        }
        this.value_ = newValue;
    }

    get fieldName(){
        return this.fieldApiName.split('.')[1];
    }

    connectedCallback() {
        let itemregister = new CustomEvent('registerrowcustomcell', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                callbacks: {
                    registerDisconnectCallback: this.registerDisconnectCallback,
                    isVisible: this.isVisible,
                    recordId: this.recordId
                },
                recordId: this.recordId
            }
        });
     
        this.dispatchEvent(itemregister);
    }

    // Store the parent's callback so we can invoke later
    registerDisconnectCallback(callback) {
        this.disconnectFromParent = callback;
    }

    get isEditing_() {
        return this.recordId && this.isEditable && this.isEditing && this.options;
    }

    handleMultiValuesPickListValueChange(event){
        //console.log('event.detail:::', event.detail);
        this.isEditing = true;
        let draftValue = {
            Id: this.recordId
        };
        draftValue[this.controllerFieldApiName] = this.controllerValue;
        draftValue[this.fieldApiName.split('.')[1]] = JSON.parse(event.detail).selectedOptions.map(opt => opt.value).join(';');
        // console.log('handleMultiValuesPickListValueChange draftValue ::: ', draftValue, this.recordId);
        this.template.dispatchEvent(new CustomEvent('customvaluechange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: draftValue
        }));
    }
}