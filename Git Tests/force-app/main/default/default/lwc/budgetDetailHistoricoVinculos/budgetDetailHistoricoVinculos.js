import { LightningElement, api, track } from 'lwc';
import { doCalloutWithStdResponse } from 'c/calloutService';
import getHistoricoVinculos from '@salesforce/apex/BudgetHistoricoVinculosController.getHistoricoVinculos';

export default class BudgetDetailHistoricoVinculos extends LightningElement {

    @api productsData = [];
    @api recordId;
    
    @track respostaSelecionada_;
    @api
    get respostaSelecionada(){
        return this.respostaSelecionada_;
    }
    set respostaSelecionada(value){
        this.respostaSelecionada_ = value;
    }

    @track idPortalItem_;
    @api
    get idPortalItem(){
        return this.idPortalItem_;
    }
    set idPortalItem(value){
        this.idPortalItem_ = value;
    }

    productColumns_;

    setProductColumns() {
        this.productColumns_ = [
            // {
            //     label: 'Código (Cliente)',
            //     initialWidth: 90,
            //     fieldName: 'idCustomer',
            //     cellAttributes: { alignment: 'left' },
            // },
            {
                label: 'ERP',
                initialWidth: 90,
                fieldName: 'prodCode',
                cellAttributes: { alignment: 'left' },
            },
            { 
                label: 'Produto', 
                fieldName: 'nome', 
                cellAttributes: { alignment: 'left' } 
            },
            { 
                label: 'Fornecedor', 
                fieldName: 'fornecedor', 
                cellAttributes: { alignment: 'left' } 
            },
            { 
                label: 'Princípio Ativo', 
                fieldName: 'principioAtivo', 
                cellAttributes: { alignment: 'left' } 
            },
            { 
                label: 'Un. Medida', 
                fieldName: 'unidadePrincipal', 
                cellAttributes: { alignment: 'left' } 
            },
            { 
                label: 'Tipo de Conversão', 
                fieldName: 'tipoConversao', 
                cellAttributes: { alignment: 'left' } 
            },
            { 
                label: 'Fator de Conversão', 
                fieldName: 'fatorConversao', 
                cellAttributes: { alignment: 'left' } 
            },
            {
                label:'Ultima Oferta',
                fieldName:'lastOferDate',
                initialWidth: 200, type: 'customString',
                typeAttributes: {
                    date:   {fieldName: 'lastOferDate'  },
                    stage:  {fieldName: 'lastOferStage' },
                    amount: {fieldName: 'lastOferAmount'}
                }       
            },
            {
                label: '',
                fieldName:'id',
                initialWidth: 50,
                type: 'customCircle',
                typeAttributes: {
                    simbol : {fieldName:'CategoriaComercial'}
                }
            },
            {
                label: 'Ações',
                fieldName:'id',
                initialWidth: 85,
                type: 'customButtons',
                typeAttributes: {itemData: this.respostaSelecionada_}
            },
        ];
    }

    connectedCallback(){
        //this.getHistoricoVinculos();
    }
    

    @api getHistoricoVinculos(){
        let scope = this;
        if(scope.idPortalItem_){
            doCalloutWithStdResponse(scope, getHistoricoVinculos, {idPortalItem: scope.idPortalItem_, oppId: scope.recordId}).then(response => {
                scope.productsData = response.data.vinculos && response.data.vinculos.length > 0 ? response.data.vinculos : false;
                scope.respostaSelecionada_ = {...scope.respostaSelecionada_};
                scope.setProductColumns();
                scope.setProductsData();
                
            });
        }
    }

    setProductsData(){
        if(this.productsData){
            this.productsData = this.productsData.map(prod => { return {...prod}}).sort((a,b)=>{
                let fisrtEl = !!a.updateAt ? (new Date(a.updateAt)).getTime() : 0;
                let secondEl = !!b.updateAt ? (new Date(b.updateAt)).getTime() : 0;
                return secondEl - fisrtEl;
            });
        } else {
            this.productsData = null;
        }
    }



}