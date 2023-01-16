import { LightningElement, api, wire, track } from 'lwc';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { CurrentPageReference} from 'lightning/navigation';
import {unregisterAllListeners, fireEvent, registerListener } from 'c/pubsub';
import getFatorProduto from '@salesforce/apex/BudgetInfoCDController.getFatorProduto';
import updateProduct from '@salesforce/apex/BudgetInfoCDController.updateProduct';
export default class BudgetDetailInfoCDConverter extends LightningElement {

    @wire(CurrentPageReference) pageRef;

    tipoConversaoProd;
    fatorConversaoProd;
    limiteCaracter=4000;
    caracteresRestantes=4000;
    get trueFator(){
        if(this.fatorConversaoProd <= 0 || this.tipoConversaoProd == 'N'){
            return 1;
        }
        if(this.tipoConversaoProd == 'M') {
            return this.fatorConversaoProd;
        }
        if(this.fatorConversaoProd > 0){
            return 1/this.fatorConversaoProd;
        }
        return 1;
    }
    
    get fatorReal(){
        return {
            tipoConversaoProd : this.tipoConversaoProd,
            fatorConversaoProd : this.fatorConversaoProd,
            trueFator : this.trueFator,
        }
    }

    checkValidity(){
        let fatorComp = this.template.querySelector('div.fatorConversao lightning-input');
        console.log('fatorComp',!!fatorComp);
        if(!!fatorComp){
            fatorComp.reportValidity();
        }
    }

    @api resp;

    observacao_;
    @api
    get observacao(){
        return this.observacao_;
    }
    set observacao(value){
        this.observacao_ = value;
    }

    get radioOptionsConversao(){
		let radioOptionsConversao = [
				{ label: "Nenhuma", value: "N", checked: false },
				{ label: "Multiplicar",  value: "M", checked: false },
				{ label: "Dividir", value: "D", checked: false },
			];
        let checkedValue = radioOptionsConversao.find(item => {return item.value === this.tipoConversaoProd});
        if(checkedValue) checkedValue.checked = true;

		return radioOptionsConversao;
	}

    connectedCallback(){
        this.getInitFator();
        registerListener('newRespSelected', this.getInitFator, this);
    }

    renderedCallback(){
        this.caracteresRestantes = this.limiteCaracter - this.template.querySelector('lightning-textarea').value.length;
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }

    handleSelectedRadioConversao(event){
        this.tipoConversaoProd = event.target.dataset.id;
        let fat = this.fatorReal;
        this.atualizarProduto();
        fireEvent(this.pageRef, 'fatorSelected', fat);
	}

    handleFatorConversao(event){
        this.fatorConversaoProd = event.target.value;
        let fat = this.fatorReal;
        this.atualizarProduto();
        fireEvent(this.pageRef, 'fatorSelected', fat);
    }

    handleObservacao(event){
        this.observacao_ = event.target.value;
        this.atualizarProduto();
        fireEvent(this.pageRef, 'comentarioSelected', this.observacao_);
        this.caracteresRestantes = this.limiteCaracter - event.target.value.length;
    }
    
    getInitFator(parameters){
        let scope = this;
        let params = {
            prodId: (parameters?.prodId || scope.resp.prodId),
            quoteitemId: (parameters?.id || scope.resp.id),
        }
        // console.log('getinitFator PARAMS:', params, scope.resp.nome)
        doCalloutWithStdResponse(scope, getFatorProduto, params).then(response => {
			// console.log('getInitFator:',response.data);
			let result = JSON.parse(response.data);
            scope.tipoConversaoProd = result.tipoConversaoProd;
            scope.fatorConversaoProd = result.fatorConversaoProd;

		}).catch(error =>{
            console.error(error);
		}).finally(() =>{
            let fat = this.fatorReal;
            scope.checkValidity();
            fireEvent(scope.pageRef, 'fatorSelected', fat);
        })
    }

    updateTimer;
	atualizarProduto(){
		if(this.updateTimer != null){
			clearTimeout(this.updateTimer);
		}
		let params = {
			prod: JSON.stringify({
				Id: this.resp.prodId,
				FatorConversaoPortal__c: this.fatorConversaoProd ? this.fatorConversaoProd.toString() : '1',
				TipoConversaoPortal__c: this.tipoConversaoProd
			}),
            relatedOppLineItem : JSON.stringify({
                id : this.resp.itemId,
                comentarios__c : this.observacao_
            })
		};
		this.updateTimer = setTimeout(function() {
			doCalloutWithStdResponse(this, updateProduct, params).then(response =>{
				// console.log('ProdutoSalvo: ',JSON.stringify(response));
	
			}).catch(error =>{
				console.error('erro ao atualizar produto: ',error);
			});
		}, 1200);
	}
}