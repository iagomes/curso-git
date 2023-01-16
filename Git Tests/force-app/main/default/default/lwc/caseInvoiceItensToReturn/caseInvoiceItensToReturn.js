import { LightningElement, wire, api } from 'lwc';
import { getRecord, createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_INVOICE from '@salesforce/schema/Case.NotaFiscal__c';
import ORIGINAL_ITEM_NAME from '@salesforce/schema/ItensNotaFiscal__c.Name';
import ORIGINAL_ITEM_PRODUCT_NAME from '@salesforce/schema/ItensNotaFiscal__c.Produto__r.Name';
import ORIGINAL_ITEM_QTY from '@salesforce/schema/ItensNotaFiscal__c.Quantidade__c';


const originalItemsColumns = [
    { label: 'Item', fieldName: 'Name', type: 'text', initialWidth: 80 },
    { label: 'Produto', fieldName: 'ProductName', type: 'text'},
    { label: 'Quantidade para devolução', fieldName: 'Quantity', type: 'number', initialWidth: 130 }
];

const actions = [
    { label: 'Remover', name: 'delete' },
];

const itemColumns = [
    { label: 'Item', fieldName: 'ItemName', type: 'text', initialWidth: 80 },
    { label: 'Produto', fieldName: 'ProductName', type: 'text'},
    { label: 'Lote', fieldName: 'Batch', type: 'text', editable: true },
    { label: 'Qtd Dev', fieldName: 'Quantity', type: 'number',typeAttributes: {
        maximumFractionDigits: '0',
    }, initialWidth: 95, editable: true },
    { label: 'Qtd NF', fieldName: 'OriginalQuantity', type: 'text', initialWidth: 85 },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

let whereClause = '{ and: [ { Id: { ne: "" } } ] }';

export default class CaseInvoiceItensToReturn extends LightningElement {

    _recordId;

    @api set recordId(value) {
        this._recordId = value;
        this.caseRelatedId = value;
    }
    
    get recordId() {
        return this._recordId;
    }

    itemsRecords;
    caseRelatedId;
    notaFiscalId;
    originalNotaFiscalId;
    originalItemsRecords;
    addItems = false;
    originalItemsColumns = originalItemsColumns;
    itemColumns = itemColumns;
    returnItensIds = [];

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_INVOICE]})
    wiredRecord({ error, data }) {
        if (data) {
            this.originalNotaFiscalId = data.fields.NotaFiscal__c.value;
        }  else if (error) {
            this.error = error;
            this.originalNotaFiscalId = undefined;
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$notaFiscalId',
        relatedListId: 'ItensNotaFiscal__r',
        fields: ['ItensNotaFiscal__c.Id','ItensNotaFiscal__c.Name','ItensNotaFiscal__c.Produto__r.Name', 'ItensNotaFiscal__c.Quantidade__c'],
        where:  whereClause
    }) listInvoiceItemsInfo({ error, data }) {
   
        if (data) {

            let records = [];
            data.records.forEach( obj => {

                let record = {};
                record.Id = obj.fields.Id.value;
                record.Name = obj.fields.Name.value;
                record.ProductName = obj.fields.Produto__r.value.fields.Name.value;
                record.Quantity = obj.fields.Quantidade__c.value;
                records.push( record );

            } );

            this.originalItemsRecords = records;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.originalItemsRecords = undefined;
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$caseRelatedId',
        relatedListId: 'Caso_Itens_da_Nota_Fiscal__r',
        fields: ['Caso_Item_da_Nota_Fiscal__c.Id','Caso_Item_da_Nota_Fiscal__c.Item_da_nota_fiscal__c','Caso_Item_da_Nota_Fiscal__c.Informacao_do_Lote__c','Caso_Item_da_Nota_Fiscal__c.Item_da_nota_fiscal__r.Name', 'Caso_Item_da_Nota_Fiscal__c.Item_da_nota_fiscal__r.Produto__r.Name', 'Caso_Item_da_Nota_Fiscal__c.Quantidade__c', 'Caso_Item_da_Nota_Fiscal__c.Quantidade_Original__c']
    }) listCaseInvoiceItemsInfo({ error, data }) {
        debugger;
        if (data && !this.itemsRecords) {

            let records = [];
            data.records.forEach( obj => {

                let record = {};
                record.Id = obj.fields.Id.value;
                record.ItemName = obj.fields.Item_da_nota_fiscal__r.value.fields.Name.value;
                record.ItemId = obj.fields.Item_da_nota_fiscal__c.value;
                record.Batch = obj.fields.Informacao_do_Lote__c.value;
                record.ProductName = obj.fields.Item_da_nota_fiscal__r.value.fields.Produto__r.value.fields.Name.value;
                record.Quantity = obj.fields.Quantidade__c.value;
                record.OriginalQuantity = obj.fields.Quantidade_Original__c.value;
                records.push( record );
                this.returnItensIds.push(obj.fields.Item_da_nota_fiscal__c.value);

            } );

            this.buildWhereClause();
            this.itemsRecords = records;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }    

    handleAddItems(event) {
        this.addItems = true;
        this.notaFiscalId = this.originalNotaFiscalId;
    }

    handleCancel(event) {
        this.addItems = false;
        const dt = this.template.querySelector('lightning-datatable');
        dt.selectedRows = [];
    }

    handleSave(event) {
    
        const dt = this.template.querySelector('lightning-datatable');

        let createRecords = [];
        dt.selectedRows.forEach(recId => {
            createRecords.push(this.createRecord(recId));
        });

        Promise.all(createRecords).then(responses => {

            responses.forEach( response => {
    
                let record = {};
                record.Id = response.id;
                record.ItemName = response.fields.Item_da_nota_fiscal__r.value.fields.Name.value;
                record.ItemId = response.fields.Item_da_nota_fiscal__c.value;
                record.ProductName = response.fields.Product__c.value;
                record.Quantity = response.fields.Quantidade__c.value;
                record.OriginalQuantity = response.fields.Quantidade_Original__c.value;
                this.itemsRecords.push(record);

                this.returnItensIds.push(response.fields.Item_da_nota_fiscal__c.value);
            });

            this.buildWhereClause();
            this.showNotification('Registros atualizados com sucesso!');
            this.caseRelatedId = this.recordId;
            this.addItems = false;
            this.notaFiscalId = undefined;

        }).catch(error => {
            console.dir(error);
            this.showNotification(error.body.message, this.labels.Error, 'error');
            this.addItems = false;
        });;

    }

    createRecord(itemId) {
        const fields = {};
        const originalRecord = this.originalItemsRecords.find(record => record.Id == itemId);
        fields['Caso__c'] = this.recordId;
        fields['Item_da_nota_fiscal__c'] = originalRecord.Id;
        fields['Quantidade__c'] = originalRecord.Quantity;
        const recordInput = { apiName: 'Caso_Item_da_Nota_Fiscal__c', fields };
        return createRecord(recordInput);
    }

    handleInlineSave(event) {

        let updateRecords = [];
        event.detail.draftValues.forEach(draftValue => {
            updateRecords.push(this.updateRecord(draftValue));
        });

        Promise.all(updateRecords).then(responses => {
            const dt = this.template.querySelector('lightning-datatable');

            this.itemsRecords.forEach(function(item) {
                event.detail.draftValues.forEach(draftValue => {
                    if (draftValue.Id == item.Id) {
                        if (draftValue.hasOwnProperty('Quantity')) {
                            item.Quantity = draftValue.Quantity;
                        }

                        if (draftValue.hasOwnProperty('Batch')) {
                            item.Batch = draftValue.Batch;
                        }
                        return;
                    }
                });
            });

            dt.draftValues = null;
            this.showNotification('Registros atualizados com sucesso!');
        }).catch(error => {
            console.dir(error);
            this.showNotification(error.body.message, this.labels.Error, 'error');
        });
    }

    updateRecord(draftValue) {
        const fields = {};
        fields['Id'] = draftValue.Id;
        fields['Quantidade__c'] = draftValue.Quantity;
        fields['Informacao_do_Lote__c'] = draftValue.Batch;
        const recordInput = { fields };
        return updateRecord(recordInput);
    }

    showNotification(message, title = 'Success', variant = "success") {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }  

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.handleDelete(row);
                break;
            default:
        }
    }

    handleDelete(record) {
        deleteRecord(record.Id)
        .then(() => {
            this.showNotification('Registro removido com sucesso!');

            this.itemsRecords = this.itemsRecords.filter(function(item) {
                return item.Id !== record.Id;
            });

            this.returnItensIds = this.returnItensIds.filter(function(itemId) {
                return itemId !== record.ItemId;
            });
            this.buildWhereClause();
            this.notaFiscalId = undefined;
        })
        .catch(error => {
            this.showNotification(error.body.message, this.labels.Error, 'error');
        });
    }

    buildWhereClause() {
        let whereClauses = [];
        this.returnItensIds.forEach(recId => {
            whereClauses.push('{ Id: { ne: ' + recId + ' } }');
        });
        whereClause = '{ and: [ ' + whereClauses.join(',') + '] }';
    }

}