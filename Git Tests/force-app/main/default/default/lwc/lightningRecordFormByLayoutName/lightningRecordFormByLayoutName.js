import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLayoutByName from '@salesforce/apex/PageLayoutController.getLayoutByName';
import getRecordTypeByName from '@salesforce/apex/UtilitiesController.getRecordTypeByName'
import { NavigationMixin } from 'lightning/navigation';
import { doCalloutWithStdResponse } from 'c/calloutService';

export default class LightningRecordFormByLayoutName extends NavigationMixin(LightningElement) {

    @track fields = [];
    @track layout;
    @track showSpinner = true;
    @track sectionsToDisplay = [];
    @track recordTypeId_;

    @api get recordTypeId() {
        return this.recordTypeId_;
    }
    set recordTypeId(value){
        this.recordTypeId_ = value;
    }
    
    // @api recordTypeId;
    @api recordType;
    @api recordId;
    @api objectApiName;
    @api layoutName;
    @api parentId;
    @api viewOnlyMode;
    @api initialValues;
    @api enforceValues;
    @api hideAccordions = false;
    @api skipStandardSubmit = false;
    @api fieldVisibilityAutomations;
    @api fieldAutomations;
    @api guid;

    fieldsToDisplayAsRow_ = [];

    @api 
    set fieldsToDisplayAsRow(value){
        if(value && value.length > 0){
            this.fieldsToDisplayAsRow_ = value.split(';');
        }
    }

    get fieldsToDisplayAsRow(){
        return this.fieldsToDisplayAsRow_;
    }

    isSingleRowField(fieldName){
        return this.fieldsToDisplayAsRow_.indexOf(fieldName) >= 0;
    }

    checkLayout(params) {
        if(params.layoutName.includes('Group')) {
            // console.log('Entrou');
            return true; 
        }
    }

    @api salvar(){

        // let element = this.template.querySelector('lightning-record-edit-form');

        let element = this.template.querySelector('.submit-button');

        if(element) {
            element.click();

        }
        
        // if(element) {
        //     element.submit();
        // }
    }

    @api closeScreen(){

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });

        eval("$A.get('e.force:refreshView').fire();");
    }

    connectedCallback() {

        if(this.enforceValues){
            if(typeof this.enforceValues === 'string'){
                this.enforceValues = JSON.parse(this.enforceValues);
            }
        }

        // console.log('LightningRecordFormByLayoutName');
        
        this.showSpinner = true;

        this.buildParams().then((data)=> {
            let params = data;

            // console.log('Record Type ::: ' , this.recordType);
            // console.log('Record Type Id ::: ' , this.recordTypeId , this.recordTypeId_);
            
            this.recordType;
            this.loadLayout(this, params);
        });

    }

    isRendered;
    renderedCallback() {
        if(!this.isRendered){
            this.isRendered = true;
            this.enforceStyles();
        }
    }

    enforceStyles(){
        let style = document.createElement('style');
        style.innerText = `
            c-lightning-record-form-by-layout-name div.content div.section-content div.slds-col {
                padding: 5px 7px!important;
            }
            
            c-lightning-record-form-by-layout-name div.content div.section-content .is-single-row-field .slds-form-element__control{
                padding-left: 16.3%!important;
            }

            c-lightning-record-form-by-layout-name div.content .slds-input[readonly] {
                --slds-c-input-spacing-horizontal-start: var(--lwc-spacingSmall,0.75rem);
            }

            c-lightning-record-form-by-layout-name div.content .slds-accordion__content {
                padding-top: 1.5em;
            }
        `;// margin: 0 0 15px 0;
        this.template.querySelector('.style-element-container').appendChild(style);
    }

    loadLayout(scope, params){
        // console.log('loadLayout start...');
        doCalloutWithStdResponse(scope, getLayoutByName, params).then((response) => {

            // console.log('response ::: ', response, JSON.stringify(response));
            // console.log('this.recordId', this.recordId);

            if(response && !response.hasError){

                this.layout = JSON.parse(response.data.layouts)[0];

                // console.log('layout :::', this.layout ? this.layout.fullName : null, this.layout, JSON.stringify(this.layout));
                // console.log('layout.fullName ', this.layout.fullName);

                this.sectionsToDisplay = [];
                let columnsCssClasses = 'slds-form__item slds-form-element slds-form-element_horizontal slds-col ';
                this.layout.layoutSections.forEach(section => {

                    section.shouldDisplay = false;

                    // console.log('this.recordType', this.recordType);
                    // console.log('section.label', section.label);

                    if(section.layoutColumns && section.label != 'Hidden Fields') {

                        let columnsLength = section.layoutColumns.length;
                        let orderedFields = {};

                        for(let columnIndex = 0; columnIndex < section.layoutColumns.length ; columnIndex++ ){

                            let column = section.layoutColumns[columnIndex];
                            
                            if(column.layoutItems) {

                                for(let itemIndex = 0; itemIndex < column.layoutItems.length ; itemIndex++ ){

                                    let item = column.layoutItems[itemIndex];

                                    item.shouldDisplay = false;
                                    
                                    if(item.field) {
                                        let isSingleRowField = this.isSingleRowField(item.field);
                                        item.cssClasses = columnsCssClasses + ' ' + item.field + ' ' + ((section.style && !section.style.includes('TwoColumns') ) || isSingleRowField ? 'slds-size_12-of-12' : 'slds-size_6-of-12');    
                                        if(isSingleRowField){
                                            item.cssClasses += ' is-single-row-field '
                                        }
                                        
                                        item.shouldDisplay = true;
                                        item.isRequired = item.behavior == 'Required';
                                        item.isReadonly = item.behavior == 'Readonly';

                                        if(!this.sectionsToDisplay.includes(section.label)){
                                            section.shouldDisplay = true;
                                            this.sectionsToDisplay = [...this.sectionsToDisplay, section.label];
                                        }

                                    }

                                    if(!orderedFields.hasOwnProperty(itemIndex)){
                                        orderedFields[itemIndex] = [];
                                    }
                                    orderedFields[itemIndex].push(item);
                                }
                                // column.layoutItems.forEach(item => {
                                // });
                            }

                        }
                        
                        let newColumn = {layoutItems:[]};
                        Object.keys(orderedFields).forEach(fieldRowIndex => {
                            orderedFields[fieldRowIndex].forEach(field => {
                                newColumn.layoutItems.push(field)
                            });
                        })
                        section.layoutColumns = [newColumn];
                        // section.layoutColumns.forEach(column => {
                        // });

                    }
                    
                });

                this.layout = {...this.layout};
                
                // console.log('This.layout ::: ' ,this.layout, JSON.stringify(this.layout));
            }
        });
    }

    handleRecordLoaded() {
        this.loadValues();
                
        if(this.fieldVisibilityAutomations){
            this.template.querySelectorAll('lightning-input-field').forEach(input => {
            
                this.setFieldsVisibility(input.name, input.value, 'onload');
            });
        }


        if(this.fieldAutomations){
            // console.log('this.fieldAutomations:::', this.fieldAutomations, JSON.stringify(this.fieldAutomations));
            this.addEventListeners();
        }
    }

    addEventListeners(){
        
        this.template.querySelectorAll('lightning-input-field').forEach(input => {
            if(this.fieldAutomations.hasOwnProperty(input.name)){
                let automationFunctions = this.fieldAutomations[input.name];
                // console.log(input.name, Object.keys(this.fieldAutomations[input.name]), this.fieldAutomations[input.name], JSON.stringify(this.fieldAutomations[input.name]));
                Object.keys(automationFunctions).forEach(eventAttributeName => {
                    input.addEventListener(eventAttributeName, (event) => {(automationFunctions[eventAttributeName])(event, {
                        'changeFields': (fields) => {
                            if(fields){
                                this.changeFields(fields)
                            }
                        }
                    })});
                });
            }
        });
    }

    changeFields(fields){

        Object.keys(fields).forEach(fieldName => {
            // console.log('fields:::', JSON.stringify(fields), fieldName);
            let inputs = this.template.querySelectorAll('lightning-input-field');
            if(inputs){
                inputs.forEach(input => {
                    if(input.name == fieldName){
                        // console.log('fieldName:::', fieldName, input);
                        if(fields[fieldName].value){
                            input.value = fields[fieldName].value;
                        }
                    }
                });
            }
        });
    }
    
    @api loadValues = () => {

        
        if(this.initialValues){
            Object.keys(this.initialValues).forEach((fieldName) => {

                let element = this.template.querySelector('.' + fieldName);
                console.log(fieldName, 'element' , element);
        
                if(element) {
        
                    element.value = this.initialValues[fieldName];
                    console.log('this.initialValues', this.initialValues, this.initialValues[fieldName]);
                }
            });
        }

        // let element = this.template.querySelector('.CNPJ__c');
        // console.log('element' , element);

        // if(element) {

        //     this.documentNumber = element.value;
        //     element.value = this.cnpj;
            // console.log('documentNumber', this.documentNumber, this.cnpj , element , element.value);
        // } else {
        //     this.documentNumber = this.cnpj;
            // console.log('documentNumber' , this.documentNumber);
        // }


        // if(this.documentNumber) {

        //     callApexMethod({'cnpj': this.documentNumber}).then((response) => {

        //         if(response.data.record) {

                    // console.log('callApexMethod ::: ' , response);

        //             if(!response.hasError) {

        //                 this.fieldName = response.data.record.FieldName;
                        // console.log('FieldName ::: ' , this.fieldName);

        //             } else {
        //                 this.showToast('Atenção', 'Dados do registro não encontrados', 'erro');
        //             }
        //         }
        //     }).finally(() => {
        //         this.dispatchLoadedEvent();
        //     });

        // } else {
        //     this.dispatchLoadedEvent();
        // }
    };

    dispatchLoadedEvent() {
        
        let fields = {};

        this.template.querySelectorAll('lightning-input-field').forEach(input => {
            fields[input.name] = input.value;
        });

        this.dispatchEvent(new CustomEvent('load', {
            detail: {
                fields: fields
            }
        }));
    }

    handleSuccess(event) {

        // console.log('handleSuccess : ' , event); 

        this.recordId = event.detail.id;

        this.dispatchEvent(new CustomEvent("saveresult", {
            detail: JSON.stringify({
                success: true,
                guid: this.guid,
                recordId : this.recordId
            })
        }));
    }

    @api submit() {
        // console.log('submit start...');
        this.handleSubmit();
    }

    handleSubmit(event) {
        // console.log('handleSubmit' , event);
        this.submitMethod(this.getFields(event));
    }

    @api getFields(event){
        
        // console.log('getFields >> event', event);
        let fields = {};

        if(event){
    
            event.preventDefault();       // stop the form from submitting
    
            fields = event.detail.fields;
        } else {
            // console.log('a');
            this.template.querySelectorAll('lightning-input-field').forEach(input => {
                fields[input.name] = input.value;
            });
        }
        // console.log('b', fields);

        if(this.enforceValues){
            Object.keys(this.enforceValues).forEach((field) => {
                fields[field] = this.enforceValues[field];
            });
        }

        if(this.parentId) {
            fields.ParentId = this.parentId;
        }

        if(this.recordTypeId){
            fields.RecordTypeId = fields.recordTypeId = this.recordTypeId;
        }

        if(this.recordId){
            fields.Id = fields.recordId = this.recordId;
        }
        
        return fields;
    }

    @api submitMethod = (fields) => {
        // console.log('submitMethod::: fields:', fields);
        // console.log('skipStandardSubmit:::', this.skipStandardSubmit);
        if(!this.skipStandardSubmit){
            if(fields && Object.keys(fields).length > 0){
                this.template.querySelector('lightning-record-edit-form').submit(fields);
            } else {
                this.template.querySelector('lightning-record-edit-form').submit(this.enforceValues);
            }
        } else {
            let details = {
                fields: fields,
                guid: this.guid
            };
            this.dispatchEvent(new CustomEvent('submit', {
                bubbles: true,
                detail: details
            }));
        }
    }


    handleChange(event) {
        event.stopPropagation();
        // console.log('handleChange event.detail', event.detail);
        // console.log('handleChange event.target', event.target.name, event.target, event.target.value, typeof event.target.value, event.target.value ? true : false);

        const fieldName = event.target.name;
        // console.log('fieldName', fieldName);

        this.setFieldsVisibility(fieldName, event.target.value, event.target.value ? 'onfill' : 'onclear');
    }

    setFieldsVisibility(fieldName, value, action){
        if(this.fieldVisibilityAutomations && this.fieldVisibilityAutomations[fieldName]){
            let fieldAutomations = this.fieldVisibilityAutomations[fieldName] ? this.fieldVisibilityAutomations[fieldName] : null;
    
            // console.log('fieldAutomations:::', fieldAutomations, JSON.stringify(fieldAutomations));
            this.sectionsToDisplay = [];
            this.layout.layoutSections.forEach(section => {
                section.shouldDisplay = false;
                if(section.layoutColumns && section.label != 'Hidden Fields') {
    
                    section.layoutColumns.forEach(column => {
    
                        if(column.layoutItems) {
    
                            column.layoutItems.forEach(item => {
                                
                                // console.log('item.field:::', item.field);
    
                                if(item.isVisible) {
    
                                    let fieldAutomationsByEventType = fieldAutomations[action];
                                    if(
                                        fieldAutomationsByEventType && 
                                        fieldAutomationsByEventType.hidefields && 
                                        fieldAutomationsByEventType.hidefields.indexOf(item.field) >= 0){
                                        item.shouldDisplay = false;
                                        // item.value = 
                                    } else if(
                                        fieldAutomationsByEventType && 
                                        fieldAutomationsByEventType.displayfields && 
                                        fieldAutomationsByEventType.displayfields.indexOf(item.field) >= 0){
                                        item.shouldDisplay = true;
                                    }
    
                                    let fieldAutomationsBySpecificValue = fieldAutomations['value='+value];
                                    if(
                                        fieldAutomationsBySpecificValue && 
                                        fieldAutomationsBySpecificValue.hidefields && 
                                        fieldAutomationsBySpecificValue.hidefields.indexOf(item.field) >= 0){
                                        item.shouldDisplay = false;
                                    } else if(
                                        fieldAutomationsBySpecificValue && 
                                        fieldAutomationsBySpecificValue.displayfields && 
                                        fieldAutomationsBySpecificValue.displayfields.indexOf(item.field) >= 0){
                                        item.shouldDisplay = true;
                                    }
                                    
                                    if(item.shouldDisplay){
                                        section.shouldDisplay = true;
                                        this.sectionsToDisplay = [...this.sectionsToDisplay, section.label];
                                    }
                                }
    
                            });
    
                        }
    
                    });
    
                }
                
            });
            this.layout = {...this.layout};
        }
    }

    handleError(event){

        // console.log('handleError : ' , event, JSON.stringify(event.detail)); 
        
        this.showToast(event.detail.message, event.detail.detail, 'error');
        this.showSpinner = true;
    }

    showToast(title, message, variant){
        const evt = new ShowToastEvent({ title, message, variant, mode: "sticky" });
        this.dispatchEvent(evt);
    }
    
    buildParams() {
        return new Promise((resolve, reject) => {
            // console.log('a');
            if(this.objectApiName === undefined){
                // console.log('layoutName:::', this.layoutName);
                throw "Não foi possível carregar o formulário, objeto não identificado!";
            } else if(this.layoutName === undefined){
                // console.log('objectApiName:::', this.objectApiName);
                throw "Não foi possível carregar o formulário, layout não identificado!";
            }
            let params = { 
                layoutName: this.objectApiName + '-' + this.layoutName
            };
    
            if(this.recordType) {
                // console.log('b.1');
                params.layoutName +=  '-' + this.recordType;
                this.takeRecordTypeByName().then(() => {
                    // console.log('b.1.1');
                    resolve(params);
                });
                // console.log('b.2');
            } else {
                // console.log('c');
                resolve(params);
            }
        });
    }

    takeRecordTypeByName() {
        return new Promise((resolve, reject) => {
            // console.log('takeRecordTypeByName')
    
            getRecordTypeByName({name: this.recordType, objectApiName: this.objectApiName}).then((response) => {
    
                // console.log('Get record type by name - Response' , response);
    
                if(!response.hasError && response.data) {
                    if(typeof response.data.record === 'string'){
                        this.recordTypeId_ = response.data.record;
                    } else if(response.data.record.hasOwnProperty('Id')){
                        this.recordTypeId_ = response.data.record.Id;
                    }
                    // console.log('Get record type by name', 'object:::', this.objectApiName, 'recordType:::', this.recordType, 'this.recordTypeId:::' , this.recordTypeId_);
                } else {
                    this.showToast('Erro', 'Não foi possível encontrar o tipo de resgistro, por favor, entre em contato o Administrador.', 'Error');
                }
                resolve();
            }).catch(error => {
                throw error;
            });
        });
    }

    get shouldRender() {
        return this.layout && ((!this.recordType && !this.recordTypeId) || this.recordTypeId);
    }

    @api
    setEnforcedValues(values) {
        if(!this.enforceValues){
            this.enforceValues = {};
        }
        this.enforceValues = Object.assign(this.enforceValues, values);
    }
}