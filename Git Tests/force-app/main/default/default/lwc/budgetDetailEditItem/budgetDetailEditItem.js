import { LightningElement, api, track, wire } from 'lwc';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import vincularProduto from '@salesforce/apex/BudgetDetailEditItemController.vincularProduto';
import getQuoteItemAnswers from '@salesforce/apex/BudgetDetailEditItemController.getQuoteItemAnswers';
import adicionarResposta from '@salesforce/apex/BudgetDetailEditItemController.adicionarResposta';
import {CurrentPageReference} from 'lightning/navigation';
import { registerListener, fireEvent, unregisterAllListeners } from 'c/pubsub';

export default class BudgetDetailEditItem extends LightningElement {

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

    @wire(CurrentPageReference)pageRef;
    @api showSpinner = false;
    @api quoteitem_;
    productsData;
    budgetData_;
    @track respostas = [];
    @track respostaSelecionada;
    showCardsCD;
    changePageDelay;
    pageStep = 0;

    @api oppId;
    @api itemIndex;
    @api lastIndex;
    @api listSize;
    @api tabulacaoN1PicklistValues;
    @api statusPicklistValues;

    @api isEditable;
    get maxRowSelection (){
        return this.isEditable ? 1 : 0;
    }

    get firstIndex(){
        return this.itemIndex === 1;
    }
    
    get modalTitle(){
        return 'Responder Produto' + (this.itemIndex != undefined && this.listSize ? ` (${this.itemIndex}/${this.listSize})` : '');
    }

    get showCdSelection(){
        return !!this.budgetData && !!this.respostaSelecionada && !!this.respostaSelecionada.prodCode && this.showCardsCD;
    }

    @api 
    get quoteitem(){
        return this.quoteitem_;
    }
    set quoteitem(data){
        if(data){
            this.quoteitem_ = {...data};
            this.getAnswers();
        }
    }

    getAnswers(){
        let scope = this;
        let params = {
            oppId: scope.oppId,
            idPortal: scope.quoteitem_.idPortal
        };

        doCalloutWithStdResponse(scope, getQuoteItemAnswers, params).then(response => {
            scope.respostas = JSON.parse(response.data);
        }).catch((error)=>{
            console.error(error);
        }).finally(()=>{
            
            if(!!scope.respostaSelecionada){
                scope.respostaSelecionada = {
                    ...scope.respostaSelecionada,
                    ...scope.respostas.find((resp)=>{resp.id === scope.respostaSelecionada.id})
                };
            }
            
            if(!scope.respostaSelecionada || !!scope.respostaSelecionada.tabulacaoN1){
                scope.template.querySelector('c-budget-detail-resposta').findUserResp();
            }
            this.refreshChildComponents();
            scope.showSpinner = false;
        });
    }

    refreshChildComponents(){
        let historicoVinculoElement = this.template.querySelector('c-budget-detail-historico-vinculos');
        if(historicoVinculoElement){
            historicoVinculoElement.respostaSelecionada = this.respostaSelecionada;
            historicoVinculoElement.idPortalItem = this.quoteitem_.idPortal;
            historicoVinculoElement.getHistoricoVinculos();
        }

    }

    @api 
    get budgetData(){
        return this.budgetData_;
    }
    set budgetData(data){
        if(data){
            this.budgetData_ = {...data};
        }
    }

    get showBudgetItemData(){
        return this.budgetData && this.quoteitem && Object.keys(this.quoteitem).length > 3;
    }

    connectedCallback(){
        //registerListener('handleEditItemNext', this.nextItemEvent, this);
        registerListener('editItemSpinner', this.handleChangeSpinner, this);
        registerListener('refreshQuoteItens', this.updateCdValues, this);
        registerListener('setViewOnly', this.handleCloseInfoCDClick, this); 
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }
    
    closeVincularModal(){
        this.handleCloseProduto();
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    nextItemEvent(event){
        event.stopPropagation();
        this.nextItem();
    }

    nextItem(){
        this.changePage('nextitemclick');
    }

    previousItem(){
        this.changePage('previousitemclick');
    }

    changePage(directionEvent){
        let scope = this;
        if(scope.changePageDelay != null){
			clearTimeout(scope.changePageDelay);
		}
        scope.pageStep++;
        scope.respostaSelecionada = null;
        scope.handleCloseProduto();
        scope.showSpinner = true;
        scope.changePageDelay = setTimeout(() => {
            scope.dispatchEvent(new CustomEvent(directionEvent, {
                detail: scope.pageStep
            }));
            scope.pageStep = 0;
        }, 500);
    }

    handleRespSelecionada(event){
        event.stopPropagation();
        event.preventDefault();
        if(event.detail){
            this.respostaSelecionada = event.detail;
        }
        this.showCardsCD = true;
        if(this.respostaSelecionada){
            let params = {
                prodId: this.respostaSelecionada.prodId,
                id: this.respostaSelecionada.id,
            }
            this.refreshChildComponents();
            fireEvent(this.pageRef, 'newRespSelected', params);
        }
    }

    handleUpdateQuoteItem(event){
        this.dispatchEvent(new CustomEvent("updatequoteitem", {
            bubbles: true,
            cancelable: true,
            detail: {...event.detail}
        }));
    }

    handleCloseProduto(){
        this.showCardsCD = false;
    }

    handleCloseInfoCDClick(){
        this.showCardsCD = false;
        this.respostaSelecionada = null;
        let respostaComp = this.template.querySelector('c-budget-detail-resposta');
        if(!!respostaComp){
            respostaComp.setRespostaSelectedId([]);
        }
    }

    updateCdValues(event){
        let scope = this;
        scope.showSpinner = true;
        scope.processItemUpdateResult(scope, JSON.parse(event.data));
        setTimeout(() => {
            scope.template.querySelector('c-budget-detail c-budget-detail-edit-item div.topScroll').scrollIntoView();
            scope.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: 'O item foi preenchido com sucesso, preencha o próximo item.', variant: 'success' }));
        }, 100);
        this.respostaSelecionada = null;
        let budgetDetailResposta = scope.template.querySelector('c-budget-detail-resposta');
        budgetDetailResposta.respostas = [...scope.respostas];
        budgetDetailResposta.findUserResp();
        scope.showSpinner = false;
    }

    handleVincular(event) {
        this.vincularProduto(this.respostaSelecionada.id, event.detail.recordId, this.oppId);
    }

    loadSelectBUModal = false;
    callCheckExistingUserBUs() {
        this.showSpinner = true;
        this.loadSelectBUModal = true;
    }

    closeModalSelectBU() {
        this.showSpinner = false;
        this.loadSelectBUModal = false;
    }

    addQuoteItemRespose(event) {
        try {
            let scope = this;
            let params = {
                idPortal: scope.quoteitem_.idPortal,
                oppId: scope.oppId,
                selectedBU : event.detail
            };
            console.log('params', params);
            doCalloutWithStdResponse(scope, adicionarResposta, params).then(response => {
                scope.dispatchEvent(new ShowToastEvent({
                    title: 'Sucesso!',
                    message: 'Resposta criada com sucesso.',
                    variant: 'success'
                }));
                scope.respostas.push(JSON.parse(response.data));
                scope.processItemUpdateResult(scope, JSON.parse(response.data));
            }).finally(()=> {
                scope.refreshChildComponents();
                scope.closeModalSelectBU();
            });
            
        } catch (error) {
            console.error(error);
        }
    }

    handleSelectNewProduct(event) {
        const { productId } = event.detail;

        if (!!productId) {
            this.vincularProduto(this.respostaSelecionada.id, event.detail.productId, this.oppId);
        }
    }

    vincularProduto(cotacaoid, productId, oppId){
        let scope = this;
        scope.showSpinner = true;
        let params = { 
            quoteitemId: cotacaoid, 
            productId: productId,
            oppId: oppId
        };

        doCalloutWithStdResponse(scope, vincularProduto, params).then(response => {
            let updatedItem = JSON.parse(response.data);
            scope.processItemUpdateResult(scope, updatedItem);
            if(scope.respostaSelecionada && scope.respostaSelecionada.id){
                let buscarProdutoElement = scope.template.querySelector('c-multi-values-picklist-l-w-c[name="Produto"]');
                if(buscarProdutoElement){
                    buscarProdutoElement.handleClickLimpar(true);
                }
                let params = {
                    prodId: scope.respostaSelecionada.prodId,
                    id: scope.respostaSelecionada.id,
                } 
                scope.showCardsCD = true;
                fireEvent(this.pageRef, 'newRespSelected', params);
            }
            scope.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: 'Produto vinculado com sucesso.', variant: 'success' }));
        }).catch(error => {
            console.error(error);
            if(error == 'Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento'){
				fireEvent(scope.pageRef, 'setViewOnly', true);
                this.handleCloseInfoCDClick();
                return;
			}
            scope.showSpinner = false;
        });
    }

    processItemUpdateResult(scope, updatedItem){
        if(!!updatedItem){
            this.respostas = this.respostas.map(resp =>{

                if(resp.id === updatedItem.id){
                    return {...updatedItem};
                }else{
                    return resp;
                }
            });
            this.respostaSelecionada = {...updatedItem};
        }
        
        document.dispatchEvent(new CustomEvent("aura://refreshView"));
    }

    handleChangeSpinner(event){
        this.showSpinner = event;
    }

    handleRefreshLine(event){
        let updatedItem = JSON.parse(event.detail);
        this.processItemUpdateResult(this, updatedItem);
        let budgetDetailResposta = this.template.querySelector('c-budget-detail-resposta');
        budgetDetailResposta.respostas = [...this.respostas];
        budgetDetailResposta.findUserResp();
    }
}
