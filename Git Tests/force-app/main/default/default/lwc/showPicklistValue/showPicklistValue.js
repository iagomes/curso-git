import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import showPicklistValueComponent from '@salesforce/resourceUrl/showPicklistValueComponent';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class ShowPicklistValue extends LightningElement {
    @api disabledCustomLookup;
    @api picklistName;
    @api objectName;
    @api fieldName;
    @api fieldLabel;
    @api recordTypeId;
    @api value;
    @track options;
    apiFieldName;

    renderedCallback() {
        Promise.all([loadStyle(this, showPicklistValueComponent + '/showPicklistValueComponent/showPicklistValue.css')]).then(() => { console.log('Files loaded showpicklist.'); }).catch(error => { console.log('error: ' + JSON.stringify(error)); });
    }

    @wire(getObjectInfo, { objectApiName: '$objectName' })
    getObjectData({ error, data }) {
        if (data) {
            //console.log('data.fields: ' + JSON.stringify(data.fields))
            if (this.recordTypeId == null)
                this.recordTypeId = data.defaultRecordTypeId;
                //console.log('this.recordTypeId: ' + JSON.stringify(this.recordTypeId));
            this.apiFieldName = this.objectName + '.' + this.fieldName;
            //console.log('this.apiFieldName: ' + JSON.stringify(this.apiFieldName));
            //this.fieldLabel = data.fields[this.fieldName].label;
            //console.log('this.fieldLabel: ' + JSON.stringify(this.fieldLabel));
            
        } else if (error) {
            // Handle error
            console.log('==============Error1  ');
            console.log(JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$apiFieldName' })
    getPicklistValues({ error, data }) {
        if (data) {
            // Map picklist values
            //console.log('data.values picklist: ' + JSON.stringify(data.values));
            //console.log('data picklist: ' + JSON.stringify(data));
            this.options = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                    
                };
            });
            
        } else if (error) {
            // Handle error
            console.log('==============Error2  ' + error);
            console.log(JSON.stringify(error));
        }
    }

    handleChange(event) {
        this.value = event.detail.value;

        this.dispatchEvent(new CustomEvent('selectpicklist', {detail: {record: this.value}}));
    }
}