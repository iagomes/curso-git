import { LightningElement, api, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setItemCd from '@salesforce/apex/BudgetInfoCDController.setItemCd';
import getDistCenter from '@salesforce/apex/BudgetInfoCDController.getDistCenter';
import getGroup from '@salesforce/apex/BudgetInfoCDController.getGroup';
import calcProducts from '@salesforce/apex/CalcScore.calcProductsScreen';
import {CurrentPageReference} from 'lightning/navigation';
import { registerListener, fireEvent, unregisterAllListeners } from 'c/pubsub';
import { stringToNumber } from 'c/utilities';


export default class BudgetDetailInfoCDContent extends LightningElement {

	@wire(CurrentPageReference)pageRef;
	showSpinner = false;

	@api oppId;
	@api resp;
	@api cnpj;
	@api pricebook;
	@api condpag;
	@api uf;
	@api quantidade;
	@api accountid;
	@api accountType;
	@api cdsBloqueados;
	verMargem = false;
	
	malhaCallout;

    selectedMalhaType = 'saldo';
	foraMalha = false;
	fatorConversaoProd;
	tipoConversaoProd;
	comentario;
	trueFator;
	@track cdList = [];
	cdListStandard = [];
	stopMalha;
	// selectedCd; //precisa ser usado para informações do cd selecionado anteriormente. 

	@track visibleCds = [];

    get optionsMalha (){
		let optionsMalha = [
			{ label: "Com saldo", value: "saldo", checked: false },
			{ label: "Todos os itens",  value: "todos", checked: false }
		];
		return optionsMalha.map(opt =>{
			opt.checked = opt.value == this.selectedMalhaType;
			return opt;
		});
	} 

	get foraMalhaLabel(){
		return this.foraMalha ? "Esconder fora malha" : "Buscar fora malha";
	}

	get showCDs(){
		return !!this.trueFator && !!this.cdListStandard && this.cdListStandard.length > 0;
	}

	connectedCallback(){
		Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {}).catch(error => {console.error('error: ' + JSON.stringify(error));});
		this.searchMalhaAsync();
		this.getUserGroup();
		registerListener('fatorSelected', this.handleFatorConversao , this);
		registerListener('comentarioSelected', this.handleComentario , this);
		registerListener('newRespSelected', this.handleSearchMalha, this);
	}

	disconnectedCallback(){
		this.showSpinner = false;
		unregisterAllListeners(this);
		this.stoppingMalha();
	}

	getUserGroup(){
		doCalloutWithStdResponse(this, getGroup,{}).then(response => {
			this.verMargem = response.data == true;
		}).catch((error)=>{
			console.error(error);
		});
	}

    handleSelectedMalhaType(event){
        this.selectedMalhaType = event.target.value;
		this.handleFatorConversao();
	}

	async handleFatorConversao(event){
		if(!!event){
			this.fatorConversaoProd = event.fatorConversaoProd;
			this.tipoConversaoProd = event.tipoConversaoProd;
			this.trueFator = event.trueFator;
		}
		if(this.showCDs){
			let scoreList = await this.calcAllScoreCalc();
			this.cdList = this.cdListStandard.map(cd =>{
				
				cd = {...cd};
				let qElfa = Math.round(cd.quantidadePortal * this.trueFator);
				cd.quantidadeElfa = qElfa > 0 ? qElfa : 1;
				cd.valorPortal = (cd.valorElfa * this.trueFator).toFixed(6);
				cd.valorTotal = (cd.valorPortal * cd.quantidadePortal);

				let cdScore = (!!scoreList && scoreList.find(res =>{return res.cdId === cd.id}));

				if(!!cdScore){
					cd.margem = (cdScore.margem || cd.margem);
					cd.margemAlvo = (cdScore.margemAlvo || cd.margemAlvo);
					cd.score = (cdScore.score || cd.score);
					cd.badScore = (cd.score <= 80);
				}
				
				return cd;
			}).filter(cd =>{
				if(this.selectedMalhaType == 'saldo'){
					return !!cd.estoque && cd.estoque > 0;
				}else{
					return true;
				}
			});
		}
	}

	handleComentario(event){
		this.comentario = event;
	}
	
	handleQuantityChange(event){
		const currentCdId = event.target.dataset.cdId;
		let currentCd = this.cdList.find(cd =>{return cd.id == currentCdId});
		if(!!currentCd && currentCd.quantidadeElfa != event.target.value){
			currentCd.quantidadeElfa = event.target.value;
			currentCd.quantidadePortal = Math.round(event.target.value / this.trueFator);
			currentCd.valorTotal = currentCd.quantidadePortal * currentCd.valorPortal;
			this.calcScore(currentCd);
		}
	}

	hanldeValueChange(event){
		const currentCdId = event.target.dataset.cdId;
		let currentCd = this.cdList.find(cd =>{return cd.id == currentCdId});
		if(!!currentCd && currentCd.valorElfa != event.target.value){
			currentCd.valorElfa = event.target.value;
			currentCd.valorPortal = (event.target.value * this.trueFator).toFixed(6);
			currentCd.desconto = (!!currentCd.preco) && currentCd.valorElfa < currentCd.preco ? (100-((currentCd.valorElfa/currentCd.preco)*100)).toFixed(2) : 0;
			currentCd.valorTotal = currentCd.quantidadePortal * currentCd.valorPortal;
			this.calcScore(currentCd);
		}
	}

	hanldeValuePortalChange(event){
		const currentCdId = event.target.dataset.cdId;
		let currentCd = this.cdList.find(cd =>{return cd.id == currentCdId});
		if(!!currentCd && currentCd.valorPortal != event.target.value){
			currentCd.valorPortal = event.target.value;
			currentCd.valorElfa = (event.target.value / this.trueFator).toFixed(6);
			currentCd.desconto = (!!currentCd.preco) && currentCd.valorElfa < currentCd.preco ? (100-((currentCd.valorElfa/currentCd.preco)*100)).toFixed(2) : 0;
			currentCd.valorTotal = currentCd.quantidadePortal * currentCd.valorPortal;
			this.calcScore(currentCd);
		}
	}

	hanldeDiscountChange(event){
		const currentCdId = event.target.dataset.cdId;
		let currentCd = this.cdList.find(cd =>{return cd.id == currentCdId});
		if(!!currentCd && currentCd.desconto != event.target.value){
			currentCd.desconto = event.target.value;
			currentCd.valorElfa = (currentCd.preco * (100-currentCd.desconto) / 100).toFixed(6);
			currentCd.valorPortal = (currentCd.valorElfa * this.trueFator).toFixed(6);
			currentCd.valorTotal = currentCd.quantidadePortal * currentCd.valorPortal;
			this.calcScore(currentCd);
		}
	}

	checkFieldValidity(event){
		const currentCdId = event.target.dataset.cdId;
		let inputFields = this.template.querySelectorAll(`c-budget-detail c-budget-detail-edit-item c-budget-detail-info-c-d-content lightning-input[data-cd-id="${currentCdId}"]`);
		inputFields?.forEach(input =>{
			input.checkValidity();
			input.reportValidity();
		});
	}

	calcScore(currentCd) {
		let calcScoreObj = [{
			cdId: currentCd.cnpj,
			productBu: this.resp.categoria,//(currentProd.categoria == '' || currentProd.categoria == undefined) ? 'SEM BU' : currentProd.categoria,
			productCode: this.resp.prodCode,
			cost: currentCd.custo,
			quantity: currentCd.quantidadeElfa,
			unitPrice: stringToNumber(currentCd.valorElfa, 6),
			listPrice: stringToNumber(currentCd.preco, 6), // stringToNumber(currentProd.precoTabelaCx, 6),
			taxPercent: currentCd.aliquota,
			SequenciaOC: this.resp.SequenciaOC,
			isContract: !!this.resp.valorBloqueado ? currentCd.valorBloqueado : false,
			isCampaign: false,
		}];

		calcProducts({clListString: JSON.stringify(calcScoreObj)}).then(result => {
			if(!!result){

				let resultObj = JSON.parse(result)[0];
				currentCd.margem = stringToNumber(resultObj.margem, 2);
				currentCd.margemAlvo = stringToNumber(resultObj.margemAlvo, 2);
				currentCd.score = stringToNumber(resultObj.scoreFinal, 2);
				currentCd.badScore = (currentCd.score <= 80);
			}
			
		}).catch(error => {
			console.error(error);
		});
	}

	async calcAllScoreCalc() {
		let calcScoreObj = this.cdListStandard.map(cd =>{
			return {
				cdId: cd.cnpj,
				productBu: this.resp.categoria,//(currentProd.categoria == '' || currentProd.categoria == undefined) ? 'SEM BU' : currentProd.categoria,
				productCode: this.resp.prodCode,
				cost: cd.custo,
				quantity: cd.quantidadeElfa,
				unitPrice: stringToNumber(cd.valorElfa, 6),
				listPrice: stringToNumber(cd.preco, 6), // stringToNumber(currentProd.precoTabelaCx, 6),
				taxPercent: cd.aliquota,
				SequenciaOC: this.resp.SequenciaOC,
				isContract: !!this.resp.valorBloqueado ? cd.valorBloqueado : false,
				isCampaign: false,
			}
		})
		return calcProducts({clListString: JSON.stringify(calcScoreObj)}).then(result => {
			return JSON.parse(result);
		}).catch(error => {
			console.error(error);
			return;
		});
	}

    handleForaMalha(event){
       this.foraMalha = !this.foraMalha;
	   this.searchMalhaAsync();
    }

	handleSearchMalha(event){
		this.searchMalhaAsync();
	}

	searchMalhaTimeout;
	@api searchMalhaAsync(){
		let scope = this;
		scope.stoppingMalha();
		scope.searchMalhaTimeout = setTimeout(() => {
			scope.searchMalha();
		}, 1000);
	}

	stoppingMalha(){
		if(this.searchMalhaTimeout){
			if(this.stopMalha){
				this.stopMalha();
			}

			clearTimeout(this.searchMalhaTimeout);
		}
		this.showSpinner = false;
	}

	@api async searchMalha(){
		let scope = this;
		scope.showSpinner = true;
		let paramsMalha = { 
			cnpj: this.cnpj, 
			UF: this.uf, 
			productCode: this.resp.prodCode, 
			pricebookExternalId: this.pricebook, 
			condPagamento: this.condpag, 
			calcMargem: true, 
			isForaMalha: this.foraMalha,
		};
		this.malha = paramsMalha;
		let paramsProd = {
			unidadePrincipal: this.resp.unidadePrincipal,
			quantidadeSolicitada: this.quantidade,
			cdsBloqueados: this.cdsBloqueados,
			accountId: this.accountid,
			accountType: this.accountType,
			unidadeSecundaria: this.resp.unidadeSecundaria,
			tipoConversao: this.resp.tipoConversaoProd,
			fatorConversao: this.resp.fatorConversaoProd
		}

		let params = {
			malha: JSON.stringify(paramsMalha),
			produto: JSON.stringify(paramsProd),
		}
		scope.cdList = [];
		scope.cdListStandard = [];


		scope.malhaCallout = new Promise((resolve, reject) =>{

			let isRunning = true;
			scope.stopMalha = () =>{
				isRunning = false;
				reject('stopMalha');
			}

			doCalloutWithStdResponse(scope, getDistCenter, params).then(response => {
				if(scope.searchMalhaTimeout && isRunning){
					if(!!response.data.erro){
						swal('Aviso ERP',`Malha indisponível para item "${this.resp.prodCode} - ${this.resp.nome}".\n
						Verifique se há saldo para o item no CD desejado e acione o time responsável pela MALHA`,'warning');
						fireEvent(scope.pageRef, 'enableRefreshMalha', false);
						return;
					}
					let dados = JSON.parse(response.data.content);
					if(dados.length == 0){
						swal('Atenção', `Malha indisponível, tente atualizar novamente em alguns instantes \n \nAcione o(a) "Key User" responsável`, 'warning');
						fireEvent(scope.pageRef, 'enableRefreshMalha', false);
						return;
					}else{
						scope.cdList = dados.filter(cd =>{
							if(scope.selectedMalhaType == 'saldo'){
								return !!cd.estoque && cd.estoque > 0;
							}else{
								return true;
							}
						});
						scope.cdListStandard = dados;
					}
				}

			}).catch(error =>{
				if(scope.searchMalhaTimeout && isRunning){
					swal('Atenção', `Malha indisponível, tente atualizar novamente em alguns instantes \nAcione o(a) "Key User" responsável`, 'warning');
					fireEvent(scope.pageRef, 'enableRefreshMalha', false);
				}
				console.error('malha -- CATCH: ',scope.searchMalhaTimeout,isRunning);
				console.error(error);
				scope.showSpinner = false;
			}).finally(() =>{
				if(scope.searchMalhaTimeout && isRunning){
					scope.handleFatorConversao();
					fireEvent(scope.pageRef, 'controllSpinner', false);
					resolve('malhaExecutada');
				}
				scope.showSpinner = false;
			});
		})
	}
	istrue = true;
	async handleSaveCd(event){
		try{
			let cdId = event.target.dataset.cdId;
			let selectedCd = this.cdList.find(cd =>{return cd.id == cdId});
			let hasError = false;
			let keepSaving = true;
			console.log(this.resp.sequenceWithSameProduct);
			if(!selectedCd.quantidadeElfa || selectedCd.quantidadeElfa < 1){
				swal("Aviso!", 'Quantidade deve ser maior ou igual a 1',"error");
				hasError = true;
			}else if(!selectedCd.valorElfa || selectedCd.valorElfa <= 0){
				swal("Aviso!", 'Valor unitário deve ser maior que 0',"error");
				hasError = true;
			}else if( !this.fatorConversaoProd || stringToNumber(this.fatorConversaoProd) <= 0 || !!(stringToNumber(this.fatorConversaoProd) % 1)){
				swal("Atenção!", 'Cadastre um valor válido para o fator de conversão do produto Elfa',"error");
				hasError = true;
			}else if(selectedCd.estoque == 0 || selectedCd.estoque < selectedCd.quantidadeElfa){
				keepSaving = await this.keepSavingModal();
			}
			if(!!this.resp.sequenceWithSameProduct){
				keepSaving = await this.hasAlreadyProductModal();
			}
			let extra = {
				foraMalha: this.foraMalha,
				fatorConversaoProd: this.fatorConversaoProd,
				tipoConversaoProd: this.tipoConversaoProd,
				comentario: this.comentario,
				oppId: this.oppId
			}
			let params = {
				cd: JSON.stringify(selectedCd),
				resp: JSON.stringify(this.resp),
				extra: JSON.stringify(extra),
			};
			if(!hasError && keepSaving){
				this.updateCdValues(params);
			}

		}catch(e){
			console.error(e);
		}
	}

	async keepSavingModal(){
		return await swal({
			title: "Aviso!",
			text: "O CD selecionado esta com estoque menor que quantidade solicitada, deseja continuar?", 
			icon: "warning",
			buttons: {
				Cancelar: {
					text: "Não", value: false,
				},
				Gerar: {
					text: "Sim", value: true,
				},
			},
			dangerMode: true,
		}).then((value) =>{
			return value;
		});
	}

	async hasAlreadyProductModal(){
		return await swal({
			title: "Atenção!",
			text: `Produto já cotado no item "${this.resp.sequenceWithSameProduct}", verifique se realmente deseja cotar este produto novamente!`, 
			icon: "warning",
			buttons: {
				Cancelar: {
					text: "Cancelar", value: false,
				},
				Gerar: {
					text: "Continuar", value: true,
				},
			},
			dangerMode: true,
		}).then((value) =>{
			return value;
		});
	}

	updateCdValues(params){
		let scope = this;
		scope.showSpinner = true;
		doCalloutWithStdResponse(scope, setItemCd, params, {processStandardResponse: false}).then(response => {
			scope.showSpinner = false;
			if(response.messages?.length > 0){
				this.dispatchEvent(new ShowToastEvent({ title: 'Aviso!', message: response.messages[0], variant: 'warning' }));
			}
			if(!!response && !!response.data && response.data != 'viewOnly'){
				fireEvent(scope.pageRef, 'refreshQuoteItens', response);

			}
		}).catch((error)=> {
			console.error(error);
			this.dispatchEvent(new ShowToastEvent({ title: 'Erro!', message: error, variant: 'error' }));
			if(error == 'Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento'){
				fireEvent(scope.pageRef, 'setViewOnly', true);
                return;
			}
		});
	}
}