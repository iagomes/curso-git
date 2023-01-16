import { LightningElement, api,track, wire  } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { doCalloutWithStdResponse } from 'c/calloutService';
import changeQuoteItemTabulacao from '@salesforce/apex/BudgetDetailEditItemController.changeQuoteItemTabulacao';
import eraseQuoteItemAnswer from '@salesforce/apex/BudgetDetailEditItemController.eraseQuoteItemAnswer';
import customLabel from './customLabel.html';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CurrUserId from '@salesforce/user/Id';
import { CurrentPageReference} from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

export default class BudgetDetailResposta extends LightningElement {

    @wire(CurrentPageReference) pageRef;

    @track itens = [];
    @api oppId;
    @api tabulacaoN1PicklistValues;
    @api statusPicklistValues;
    @api maxRowSelection;
    @api isEditable;
    @api viewOnly = false;

    rowsChildren = {};
    budgetData;
    draftValues = [];
    quoteitem_;
    showSpinner;
    respostaSelected = [];
    respostaSelectedId = [];

    @api
    get resposta(){
        return this.respostaSelected[0];
    }
    set resposta(value){
        if(!!value && !!value.id){
            this.respostaSelected = [value];
            this.respostaSelectedId = [value.id];
        }else{
            this.respostaSelected = [];
            this.respostaSelectedId = [];
        }
    }

    constructor() {
        super();
     
        document.addEventListener("lwc://refreshView", () => {
            const evt = new ShowToastEvent({
                title: "Info",
                message: "received refreshView event",
                variant: "info",
            });
            this.dispatchEvent(evt);
        });
    }

    @api 
    get respostas(){
        return this.itens;
    }set respostas(value){
        this.itens = [...value];
        this.classFactory();
    }

    @api 
    get quoteitem(){
        return this.quoteitem_; 
    }
    set quoteitem(data){
        this.quoteitem_ = {...data};
        this.classFactory();
    }

    hideTabulacaoN1Picklist = ['Cotado','SEM OFERTA','COM OFERTA','FORA DE MALHA','SEM ESTOQUE','NÃO TEMOS NESSA APRESENTAÇÃO','NÃO TEMOS A VALIDADE SOLICITADA','NÃO TEMOS A QTDE SOLICITADA','NÃO TRABALHAMOS','NÃO TEM NO PORTIFÓLIO'];

    @api 
    get maxRow(){

        this.viewOnly = this.maxRowSelection == 0 ? true : false;
        return this.viewOnly; 
    }
    set maxRow(data){
        this.maxRowSelection = data;
        
        
    }

    get columns(){
        return [

            { 
                label: 'BU',
                initialWidth: 100,
                fieldName: 'categoriaVendedorDesc',
                cellAttributes: { class: {fieldName: 'styleClass'}, alignment: 'left' },
                wrapText: true,
            },
            { 
                label: 'Vendedor', 
                initialWidth: 120,
                fieldName: 'nomeVendedor', 
                cellAttributes: { class: {fieldName: 'styleClass'}, 
                    alignment: 'left' 
                },
                wrapText: true,
            },
            { 
                label: 'Produto',
                fieldName: 'productURL',
                initialWidth: 220,
                cellAttributes: { class: {fieldName: 'styleClass'}, alignment: 'left' },
                type: "url",
                typeAttributes: { 
                    label: { fieldName: 'nome' }
                },
                wrapText: true,
            },
            { 
                label: 'Marca',
                fieldName: 'marcaProdOfertado',
                initialWidth: 175,
                cellAttributes: { class: {fieldName: 'styleClass'}, alignment: 'left' },
                type: "text",
                wrapText: true,
            },
            { 
                label: 'CD',
                fieldName: 'cnpjCd',
                initialWidth: 116,
                // editable: true,
                cellAttributes: { class: {fieldName: 'styleClass'}, alignment: 'left' },
                type: "text",
                wrapText: true,
            },
            { 
                label: 'Nome CD',
                fieldName: 'nomeCd',
                // editable: true,
                initialWidth: 150,
                cellAttributes: { alignment: 'left', class:{fieldName: 'styleClass'} },
                type: "text",
                wrapText: true,
            },
            
            { 
                label: 'Vlr. Unit. Portal',
                fieldName: 'unitarioPortal',
                initialWidth: 100,
                cellAttributes: { class: {fieldName: 'styleClass'}, alignment: 'left' },
                type: "currency",
                typeAttributes: {
                    minimumFractionDigits: '2'
                },
                wrapText: true
            },
            { 
                label: 'Tabulação', 
                fieldName: 'tabulacaoN1', 
                type: 'CustomPicklist',
                cellAttributes: { class: {fieldName: 'styleClass'}},
                initialWidth: 171,
                typeAttributes: { 
                    recordId: {fieldName: 'id'},
                    recordTypeId: {fieldName:'recordTypeId'},
                    fieldApiName: 'QuoteItem__c.TabulacaoN1__c',
                    picklistValues: this.tabulacaoN1PicklistValues,
                    isEditable: this.isEditable,
                    controllerFieldApiName: "Status__c", 
                    controllerValue: {fieldName:"status"},
                    label: "Tabulação",
                    value: {fieldName:"tabulacaoN1"},
                    hideOptions: this.hideTabulacaoN1Picklist,
                }
            },  
            { 
                label: 'Status', 
                fieldName: 'status', 
                type: 'CustomPicklist',
                initialWidth: 160,
                cellAttributes: { class: {fieldName: 'styleClass'}},
                typeAttributes: { 
                    recordId: {fieldName: 'id'},
                    recordTypeId: {fieldName:'recordTypeId'},
                    fieldApiName: 'QuoteItem__c.Status__c',
                    picklistValues: this.statusPicklistValues,
                    isEditable: this.isEditable,
                    label: "Status",
                    value: {fieldName:"status"},
                    hideOptions: ['RESGATADO', 'Resgatado', 'Respondido','RESPONDIDA','Aprovado', 'Aguardando Integração', 'Falha na Integração','QUALIFICADO','NÃO IDENTIFICADO','IDENTIFICADO']
                },
            },
            {
                label:'',
                type:'CustomButton',
                initialWidth: 50,
                cellAttributes: { class: {fieldName: 'styleClass'}},
                typeAttributes: { 
                    recordId: {fieldName: 'id'},
                    toolTipLabel:'Apagar conteúdo da resposta',
                    iconName:'utility:clear',
                    hideButton: {fieldName:'hideEraseButton'},
                    actionClick: this.handleEraseClick,
                    scopeFather: this
                }
            },
            {
                label: 'Dt/Hr resposta',
                initialWidth: 83,
                fieldName: 'dataHoraResposta', 
                cellAttributes: { class: {fieldName: 'styleClass'}, 
                    alignment: 'left' 
                }, 
                type: 'text',
                wrapText: true,
            },
            { 
                label: 'Tipo Conversão',
                initialWidth: 100, 
                fieldName: 'tipoConversao',
                cellAttributes: { class: {fieldName: 'styleClass'}, alignment: 'left' },
                type: "text",
                wrapText: true,
            },

            { 
                label: 'Fator Conversão', 
                fieldName: 'fatorConversao',
                cellAttributes: { 
                    alignment: 'left' 
                }, 
                initialWidth: 105,
                type: 'number',
                wrapText: true,
            }
        ];
    }


    rejectErase;
    resolveErase;
    openConfirmationErase = false;
    handleEraseClick(rowId, scope){
        scope.openConfirmationErase = true;
        new Promise((resolve, reject) =>{
            scope.resolveErase = (result) => {
                resolve(result);
            }
        }).then(result =>{
            if(result){
                doCalloutWithStdResponse(scope, eraseQuoteItemAnswer, {qItemId: rowId}).then(response =>{
                    scope.dispatchEvent(new CustomEvent("refreshline", {
                        detail: response.data
                    }));
                });
            }
        });
        
    }
    
    handleCloseEraseModal(event){
        this.openConfirmationErase = false;
        if(this.resolveErase){
            this.resolveErase(false);
        }
    }

    handleConfirmEraseModal(event){
        this.openConfirmationErase = false;
        if(this.resolveErase){
            this.resolveErase(true);
        }
    }

    isRendered = false;
    renderedCallback(){
        this.classFactory();
        // if(!this.isRendered){
        //     console.log('entrou no rendered');
        //     this.findUserResp();
        // }
        this.isRendered = true;
    }

    @api findUserResp(){
        if(this.isEditable && this.maxRowSelection){
            let selectedRow = this.itens.filter(it =>{
                return it.vendedorId === CurrUserId && !it.tabulacaoN1;
            });
    
            if(selectedRow && selectedRow.length > 0){
                this.respostaSelected = [selectedRow[0]];
                this.respostaSelectedId = this.respostaSelected.map(resp =>{return resp.id});
            } else{
                this.respostaSelected = [];
                this.respostaSelectedId = [];
            }
    
            if(this.respostaSelected && this.respostaSelected.length > 0){
                this.sendProductRowSelection(this.respostaSelected);
            }
        }
    }

    @api setRespostaSelectedId (value){
        this.respostaSelectedId = value;
    }
    handleButtonClick(event){
        event.stopPropagation();
        event.preventDefault();
        if(event.detail.recordId){
            this.quoteitem = event.detail.quoteitem;
            if(event.detail.button == 'mostrar-produto'){
                if(this.rowsChildren){

                    // hide unselected rows
                    let element = this.template.querySelector('c-budget-detail > div.dynamic-style-container');
                    if(element){
                        if(element.firstElementChild){
                            element.firstElementChild.remove();
                        }
                        let style = document.createElement('style');
                        style.innerText = `
                            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y table tbody tr[data-row-key-value]:not([data-row-key-value="${event.detail.recordId}"]) {
                                display: none;
                            }

                            c-budget-detail div.row-content c-budget-detail-product div[data-name="divAllProducts"] {
                                margin-top: 0!important;
                            }
                        `;
                        element.appendChild(style);
                    }
                  
                }
                this.budgetData.Itens.forEach(item => {
                    item.show = item.id == event.detail.recordId;
                });
                this.budgetData = {...this.budgetData};
                this.showProduto = true;
            } else if(event.detail.button == 'vincular' || event.detail.button == 'editar-vinculo'){
                this.showVincularModal_ = true;
                
            }
        }
    }

    enforceStyle(){
        style = `
      
        `;
    }

    handleRegisterRowCustomCell(event){
        event.stopPropagation();
        event.preventDefault();
        this.rowsChildren[event.detail.recordId] = event.detail;
    }

    handleProductRowSelection(event){
        if(!this.isRendering){
            this.respostaSelected = event.target.getSelectedRows();
            this.respostaSelectedId = this.respostaSelected.map(row =>{return row.id});
        }
        this.sendProductRowSelection(this.respostaSelected);
    }

    sendProductRowSelection(selectedRows){

        this.template.dispatchEvent(new CustomEvent('respselecionada', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: selectedRows && selectedRows[0]
        }));
    }

    handleCustomValueChange(event) {
        event.stopPropagation();
        event.preventDefault();
        let record = {...event.detail};
        if(record.Id){
            this.changeQuoteItemTabulacao([record.Id], record["Status__c"], record["TabulacaoN1__c"]);
        }

    }

    classFactory(){
        let style = document.createElement('style');
        
        
        let innerText =``;
        let lastBackground;

        if(this.quoteitem_ && this.respostas){
            this.respostas.forEach(item => {
                let background = lastBackground == '#a0fba1' ? '#8cd38c' : '#a0fba1';
                lastBackground = background;
                if(item.status && (item.tabulacaoN1 &&  item.tabulacaoN1 != '')){
                    innerText +=`
                    c-budget-detail-edit-item  c-budget-detail-resposta c-budget-detail-resposta-data-table table tbody tr[data-row-key-value="${item.id}"]{
                        background-color:  ${background}  !important;
                        --lwc-colorBackgroundRowHover:
                        ${background};
                    
                        --lwc-colorBackgroundRowSelected:
                        ${background};
                    }
        
                    `;
                }
                    
            });
        }
        let element = this.template.querySelector('.style-element-color-bg-edit-item');
        if(element){

            while (element.firstChild) {
                element.removeChild(element.lastChild);
            }
            
            if(innerText){
                style.innerText = innerText;
                element.appendChild(style);
            }
        }
    }

    changeQuoteItemTabulacao(ids, status, tabulacaoN1){
        let scope = this;
        let record = {
            id: ids[0],
            status: status,
            tabulacaoN1: tabulacaoN1,
        };
        let params = {jsonReqBody: JSON.stringify(record), oppId: scope.oppId};
        doCalloutWithStdResponse(scope, changeQuoteItemTabulacao, params).then(response => {
            scope.dispatchEvent(new CustomEvent("refreshline", {
                detail: response.data
            }));
            
        }).catch((error)=> {
            console.error(error);
            if(error == 'Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento'){
				fireEvent(scope.pageRef, 'setViewOnly', true);
                return;
			}
            scope.showSpinner = false;
        });
    }
}