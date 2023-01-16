import { api, LightningElement }        from 'lwc';
import { doCalloutWithStdResponse }     from 'c/calloutService';
import getOrdersListWonFromCurrentUser  from '@salesforce/apex/OrderListWonController.getOrdersListWonFromCurrentUser';


const columns = [
    { label: 'Nº do pedido',           fieldName: 'OrderUrl',typeAttributes: {label: { fieldName: 'OrderNumber' }, tooltip:{fieldName: 'OrderNumber' }}, cellAttributes:{alignment:'left'}, initialWidth: 130, type:'url' },
    { label: 'Nome do cliente',        fieldName: 'AccountNameUrl', typeAttributes: {label: { fieldName: 'AccountName' },tooltip:{fieldName: 'AccountName' }},cellAttributes:{alignment:'left'}, wrapText:true, type:'url'},
    { label: 'Data de emissão',        fieldName: 'EffectiveDate',initialWidth: 130, type: 'date-local', typeAttributes: {day: "2-digit", month: "2-digit"}, cellAttributes:{alignment:'left'} },
    { label: 'Valor total do pedido',  fieldName: 'TotalAmount',initialWidth: 180,   type: 'currency', cellAttributes:{alignment:'left'} },
    { label: 'Status',                 fieldName: 'Status',initialWidth: 130, cellAttributes:{alignment:'left'} },
    { label: 'ID Integradora',         fieldName: 'CodigoIntegradora__c',initialWidth: 130, cellAttributes:{alignment:'left'} },
    { label: 'CD(s)',                  fieldName: 'CentroDistribuicao__c',cellAttributes:{alignment:'left'},initialWidth: 450, wrapText:true}

];

export default class OrderListWon extends LightningElement {

    data        = [];
    columns     = columns;
    rowOffset   = 0;

    payloadRefactor(record){        
        let centroDistribuicao= ''

        if('OrderItems' in record){
            console.log(record.OrderItems.map(item=>item.CentroDistribuicao__c).join());
            centroDistribuicao = record.OrderItems.map((item,index)=>(index+1)+'º: '+item.CentroDistribuicao__c+'\n').join('')
        }else{
            centroDistribuicao = 'Indisponível'
        }
        
        let refactoredRecord = {
            OrderNumber:record.OrderNumber,
            OrderUrl:`/${record.Id}`,
            AccountName:record.Account['Name'],
            AccountNameUrl:`/${record.Account.Id}`,
            EffectiveDate:record.EffectiveDate,
            TotalAmount:record.TotalAmount,
            Status:record.Status,
            CodigoIntegradora__c:'CodigoIntegradora__c' in record ? record.CodigoIntegradora__c:'Indisponível',
            CentroDistribuicao__c: centroDistribuicao
        }
        return refactoredRecord;        
    }
    @api getOrdersListWon(){
        let scope = this;
        doCalloutWithStdResponse(scope, getOrdersListWonFromCurrentUser, {}).then(response => {
            scope.data = response.data.records.map(record =>this.payloadRefactor(record));
        }).catch(error => {
            console.error('Error to get orders', JSON.stringify(error));
        });
    }

    connectedCallback() {
        this.getOrdersListWon();
    }

}