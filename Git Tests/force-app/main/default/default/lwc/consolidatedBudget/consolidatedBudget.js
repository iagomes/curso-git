import { api, track, LightningElement } from 'lwc';
// import getConsolidatedBudget from '@salesforce/apex/BudgetController.getConsolidatedBudget';

// const columns = [
//     { label: 'ID PDC',  fieldName: 'Id',  type: 'url',  editable: false, typeAttributes: { label: { fieldName: 'Product2.Name' },    target:'_self', tooltip: 'Ir Produto'}, hideDefaultActions: true},
//     { label: 'CNPJ hospital', fieldName: 'Account.CNPJ__c', type: 'text' },
//     { label: 'Nome do hospital',  fieldName: 'AccountId',  type: 'url',  editable: false, typeAttributes: { label: { fieldName: 'Account.Name' },    target:'_self', tooltip: 'Ir Conta'}, hideDefaultActions: true},
//     { label: 'UF', fieldName: 'Account.UF__c', type: 'text' },
//     { label: 'Cidade', fieldName: 'Account.CPF__c', type: 'text' },
// ];

const columns = [
    { label: 'ID PDC',  fieldName: 'idPdcConsolidador',  type: 'text'},
    { label: 'CNPJ hospital', fieldName: 'cnpjConsolidador', type: 'text'},
    { label: 'Nome do hospital',  fieldName: 'nomeHospitalConsolidador',  type: 'text'},
    { label: 'UF', fieldName: 'uf', type: 'text'},
    { label: 'Cidade', fieldName: 'cidade', type: 'text'},
];
// idPdcConsolidador
// nomeHospitalConsolidador
// cnpjConsolidador
// uf
// cidade
export default class ConsolidatedBudget extends LightningElement {
	
    @api recordId;
    @api budgetData;

    columns = columns;

    connectedCallback() {

        // getConsolidatedBudget({ oppId: this.recordId })
        // .then(result => {
        //     console.log('getConsolidatedBudget: entrou certo!');
        //     console.log(result);
        //     if (result != null) {
        //         this.data = result;
        //     }

        // }).catch(error => {
        //     console.log('getConditionPayment: ERRO!');
        //     console.log(error);
        //     this.isLoadingProducts = false;
        // });

    }

}