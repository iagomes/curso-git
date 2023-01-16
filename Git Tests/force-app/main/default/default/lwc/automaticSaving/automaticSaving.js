import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ORDER_NUMBER from '@salesforce/schema/Order.OrderNumber';
import ORDER_LAST_MODIFIED from '@salesforce/schema/Order.LastModifiedDate';
import BUDGET_NUMBER from '@salesforce/schema/Opportunity.NumeroOrcamento__c';
import BUDGET_LAST_MODIFIED from '@salesforce/schema/Opportunity.LastModifiedDate';

export default class AutomaticSaving extends NavigationMixin(LightningElement) {
	@api isSaving = false;
	// @api objData = {};
	@track _objData = {};

	@api strObjData;
	@api isBudget;

	@api recId;
	@track listField = [];

	@wire(getRecord, { recordId: '$recId', fields: '$listField' })
	sobject;

	get recNumber() {
		console.log(this.sobject);
		if (this.sobject) {
			return this.isBudget ? getFieldValue(this.sobject.data, BUDGET_NUMBER) : getFieldValue(this.sobject.data, ORDER_NUMBER);
		}
		return null;
	}

	get recLastModified() {
		console.log(this.sobject);
		if (this.sobject && !this.recNumber()) {
			return (new Date()).toLocaleTimeString();
		}
		return null;
	}

	@api
	get objData() {
		return this._objData;
	}

	set objData(value) {
		if(value != undefined) {
			console.log('value objData => ' + JSON.stringify(value));
			if(value.lastSaveDate != '' && value.sobject != '') {
				this._objData = value;
			}
		}
	}

	connectedCallback() {
		console.log('AUTOMATIC SAVING');
		if (this.strObjData && this.strObjData != '{}') {
			this.objData = JSON.parse(this.strObjData);
		} else {
			this.objData = {
				registerName: '',
				sobject: this.isBudget ? 'Orçamento' : 'Pedido',
				lastSaveDate: ''
			}
		}
		this.listField = this.isBudget ? [BUDGET_NUMBER, BUDGET_LAST_MODIFIED] : [ORDER_NUMBER, ORDER_LAST_MODIFIED];
		console.log(this.listField);
		console.log(this.listField);
	}

	navigateToOrder(event) {
		console.log('Abrir pedido: ');
		console.log(event.currentTarget.dataset.orderId);
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: event.currentTarget.dataset.orderId,
				actionName: 'view'
			}
		});
	}
}