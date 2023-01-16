import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getHistorico from '@salesforce/apex/OrderScreenController.getHistorico';
import getRecommendations from '@salesforce/apex/OrderScreenController.getRecommendations';
import setRecommendationReaction from '@salesforce/apex/OrderScreenController.setRecommendationReaction';
import getProduct from '@salesforce/apex/OrderScreenController.getProduct';
import getProductCampaign from '@salesforce/apex/ProductCampaignController.getProductCampaign';
import getMalha from '@salesforce/apex/OrderScreenController.getMalha';
import getPricebookExternalId from '@salesforce/apex/OrderScreenController.getPricebookExternalId';
import calcProducts from '@salesforce/apex/CalcScore.calcProductsScreen';
import reverseCalcScreen from '@salesforce/apex/CalcScore.reverseCalcScreen';
import calcAllProducts from '@salesforce/apex/CalcScore.calcProducts';
import generateBudget from '@salesforce/apex/OrderScreenController.generateBudget';
import generateOrder from '@salesforce/apex/OrderScreenController.generateOrder';
import editOrder from '@salesforce/apex/OrderScreenController.editOrder';
import editBudget from '@salesforce/apex/OrderScreenController.editBudget';
import buscaCodigoLoja from '@salesforce/apex/OrderScreenController.buscaCodigoLoja';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {optionsRefuseUtils, radioOptionsUtils, orderOptionsUtils, validityOptionsUtils} from './constantUtility';
import TargetQueueId from '@salesforce/schema/MessagingChannel.TargetQueueId';
import getFirstMalha from '@salesforce/apex/OrderScreenController.getFirstMalha';

export default class OrderProduct extends NavigationMixin(LightningElement) {
	// variáveis para definição de edição ou inserção de pedido ou orçamento

	productCampaingButtonShow = false;
	resumoButtonShow = false;
	buttonsGroupShow = true;
	backButtonShow = true;
	@track count = 0;
	showHeader = true;
	iconNamePin = "utility:pinned";
	alternativeTextIconPin = "Desfixar cabeçalho";
	iconName = 'utility:down';
	iconPinned = true;
	classIconPin = 'pin-icon pin-color-gray';
	@track mapProductToInventoryList;
	@api isBudget;
	@api isEdit;
	@api newRecordId;
	// variáveis cabeçalho (orçamento e pedido)
	@api productToSearch;
	@api recordId;
	@api numOrcamento;
	@api valorTotal;
	@api score;
	@api clienteEmissorId;
	@api clienteEmissor;
	@api clienteEmissorCGC;
	@api tabelaPreco;
	@api tabelaPrecoNome;
	@api tabelaPrecoExternalId;
	@api canalEntrada;
	@api condicaoPagamento;
	@api condicaoPagamentoNome;
	@api formaPagamento;
	@api contatoOrcamento;
	@api prazoValidade;
	@api dtValidade;
	@api observacaoCliente;
	@api observacao;
	@api observacaoNF;
	@api observacaoPedido;
	@api isCoordenador;
	@api dtParcelas;
	@api fretesPorCd;
	@api pedidoComplementar;
	@api orderListReturned;
	@api Idportalcotacoes;
	@api createOrderDt;
	@track CodigoLoja;
	@track dtValidadeFormatada;
	@track resumo = "";

	// variáveis exclusivas de pedido
	@api medico;
	@api medicoId;
	@api medicoCRM;
	@api tipoFrete;
	@api valorFrete;
	@api numeroPedidoCliente;
	@api canalVendas;
	@api tipoOrdem;
	@api dtPrevistaEntrega;
	@api clienteRecebedor;
	@api clienteRecebedorCGC;
	@api enderecoEntregaId;
	@api enderecoEntrega;
	@api enderecoEntregaContaOrdem;
	@api utilizarEnderecoAdicional;

	@track headerInfoData = {};
	@api alreadySaved = false;
	@api savingStrData;
	@track isSaving = false;
	@track savingObjData = {};
	@track automaticSave = true;
	@track hasOnlyCampaign = true;
	@track hasOnlyContract = true;
	@track hasOnlyLab = true;
	@track badgeTextoCampanha;

	@track listProdCampaign = [];
	@track qtdProductCampaign;
	@track enableProdCampaignButton = false;
	@track isLoadingScore = false;
	@track disableAdvance = false;
	@track verMargem = true;
	@track calcScoreObj = [];
	@track calcAllScoreObj = [];
	@track totalOrderValue = 0;
	@track savedCdData = [];
	@track isForaMalha = false;
	@track hasMalha = true;
	@track currentSelectedProdCode;
	@track selectedProduct;
	@track isLoading = false;
	@track isLoadingProducts = false;
	@track offSetValue = 0;
	@track searchGenericValue = '';
	@track searchFabricanteValue = '';
	@track showMoreProduct = true;
	@track showHistoric = false;
	@track HistoricSection = '';
	@track showHistoricSection = true;
	@track showProductDescriptionModal = false;
	@track showCDDescriptionModal = false;
	@track showCheckoutModal = false;
	@track productInput = '';
	@track selected = 'Com saldo';
	@track current = 0;
	@track currentCd = 0;
	@track selectedSortProduct;
	@track selectedProductModal;
	@track HistoricListTotal = [];
	@track HistoricList = [];
	@track mockedProdList = [];
	@track prodList = [];
	@track cdList = [];
	@track allValues = [];
	@track isOrderListReturned = false;
	@track scoreFinalGeral;
	@track margemAtualGeral;
	@track margemAtualAlvo;
	@track cdListClone = this.cdList;
	@track prodFilterList = [];
	@track prodFilterRecommendedList = [];
	@track filterLst = [];
	@api hasPermissionERB;
	@api goToCheckout;
	@track isMixClientOpen = false;
	@track isRecommendation = false;
	@track isProdReject = false;
	@api allRecAnswered;
	@api getRecommendation;
	@track refusingItem = false;
	@track rejectText = '';
	@track rejectPicklist = '';
	@track currentRejectProduct;
	@track rejectReasonPicked = false;
	@track distributeQuantity = false;

	@track objectProdCdList = [];
	@track orderList = this.cdList;
	@track orderListFiltered = this.orderList;
	@track orderCdList = [];

	@track valorBusca;
	@track desktop;
	@track headerStyle = '';
	@track headerClass = '';

	@track productFilter = "Com saldo";
	@track allCds = true;
	@track lastProduct;
	@track count = 0;
	@track tamanho = 0;
	@track pageNumber = 0; 
	@track isFirstPage = true;
	@track isLastPage = true;

	@api filtroPDF = 'Ordem de inserção';
	
	get optionsRefuse() {
		return optionsRefuseUtils();
	}

	get radioOptions(){
		return radioOptionsUtils();
	}

	get orderOptions(){
		return orderOptionsUtils();
	}

	get validityOptions(){
		return validityOptionsUtils();
	}

	cloneObj(value) {
		return JSON.parse(JSON.stringify(value));
	}

	refreshCdWithCart(checkCart) {
		if (checkCart) {
			this.orderList.forEach(cdFromCart => {
				this.cdList.find(cd => {
					if (cd.id == cdFromCart.id) {
						cd = this.cloneObj(cdFromCart);
						cd.valorZerado = cd.validadeMinima == "Shelf Life" ? true : cdFromCart.valorZerado;
						cd.isCampaign = cdFromCart.valorCampanha == undefined ? false : (cdFromCart.valorCampanha == 0 && !cdFromCart.showBadgeShelflifeCNPJ ) ? cdFromCart.showBadgeCampanhaCD : true;
						cd.isLab = cdFromCart.laboratorio == undefined ? false : true;
					}
				});
			});
			if(this.filterLst.length > 0){
				this.orderListFiltered = [];
				this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
			}else{
				this.orderListFiltered = this.orderList;
			}
		}
		if (checkCart) {
			this.selectedRadioCd();
		}
	}

	renderedCallback() {
		var box1 = document.querySelector('#box1');
		if(box1){
			box1.addEventListener('touchmove', function(e) {
				e.stopPropagation();
			}, false); 
		}
	}

	calcRefresh(selectedCd) {
		this.orderList.find(cdCart => {
			if (cdCart.id == selectedCd.id) {
				cdCart = this.cloneObj(selectedCd);
				cdCart.quantidadeScreen = Number(selectedCd.quantidade).toFixed(4);
				cdCart.isCampaign = selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? selectedCd.showBadgeCampanhaCD : true;
				cdCart.isLab = selectedCd.laboratorio == undefined ? false : true;
			}
		});
		this.calcValorTotal(selectedCd);
		this.calcTotalOrderPrice();
		this.calcValorTotal(selectedCd);
		if (this.filterLst.length > 0) {
			this.orderListFiltered = [];
			this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
		} else {
			this.orderListFiltered = this.orderList;
		}
	}

	calcPriceUnit(event){
		console.log('entrou calcpriceunit');
		let unit = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);
		if (unit == 0 && this.isProductInserted(selectedCd)) {
			swal({
				title: "Remover item do carrinho?",
				text: "Caso remova será recalculado os valores no carrinho!",
				icon: "warning",
				buttons: ["Cancelar", "Remover"],
				dangerMode: true,
			}).then((willDelete) => {
					if (willDelete) {
						this.orderListFiltered = this.orderList.filter(prod => prod.id !== cdId);
						this.orderList = this.orderList.filter(prod => prod.id !== cdId);
						selectedCd.quantidade = Number(unit);
						selectedCd.quantidadeScreen = Number(unit).toFixed(4);
						selectedCd.quantidadeCx = selectedCd.tipoConversao == 'M' ? (unit / parseFloat(selectedCd.conversaoUnidadeCx)) : (unit * parseFloat(selectedCd.conversaoUnidadeCx));
						selectedCd.desconto = 0;
						selectedCd.unitario = Number(selectedCd.desconto > 0 ? selectedCd.tipoConversao == 'M' ? (selectedCd.inicialUnitario * (1 - selectedCd.desconto / 100)) : (selectedCd.inicialUnitario / (1 - selectedCd.desconto / 100)) : selectedCd.inicialUnitario).toFixed(6);
						selectedCd.caixa = Number(selectedCd.desconto > 0 ? selectedCd.inicialCaixa * (1 - selectedCd.desconto / 100) : selectedCd.inicialCaixa).toFixed(6);
						selectedCd.adicionado = false;
						this.calcRefresh(selectedCd);
						swal("Poof! Produto removido do carrinho!", {icon: "success",});
						if (this.orderListFiltered.length > 0) this.keepSavingOrEditing();
					} else {
						unit = selectedCd.quantidade;
						event.target.value = unit;
						event.detail.value = unit;
						selectedCd.quantidade = Number(unit);
						selectedCd.quantidadeScreen = Number(unit).toFixed(4);
						selectedCd.quantidadeCx = (unit / parseFloat(selectedCd.conversaoUnidadeCx));
						this.calcRefresh(selectedCd);
					}
				});
		} else {
			if (selectedCd.quantidadeScreen != unit) {
				selectedCd.quantidade = Number(unit);
				selectedCd.quantidadeScreen = Number(unit).toFixed(4);
				selectedCd.quantidadeCx = selectedCd.tipoConversao == 'M' ? Number(unit / parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(6) : (unit * parseFloat(selectedCd.conversaoUnidadeCx));
				let novoPrecoTabela = null;//deletar depois 
				selectedCd.precoTabelaCx = novoPrecoTabela == null ? selectedCd.precoTabelaCx : novoPrecoTabela;
				if (Number(selectedCd.quantidadeCx) % 1 != 0) {
					swal("Aviso!", 'Quantidade principal do produto não pode ser fracionada!');
				}
				this.calcValorTotal(selectedCd);
				this.orderList.forEach(cd => {
					if (cd.id == selectedCd.id) {
						cd.quantidade = selectedCd.quantidade;
						cd.quantidadeScreen = Number(selectedCd.quantidade).toFixed(4);
						cd.quantidadeCx = selectedCd.quantidadeCx;
					}
				});
				let currentProd = this.getCurrentProduct(selectedCd.prodCode);
				this.fillCalcScoreObj(selectedCd, currentProd);
				this.refreshCdScoreCalc();
				this.getScoreCalcApi(selectedCd);
			}
			this.calcRefresh(selectedCd);
		}

	}

	calcPriceUnitCx(event){
		console.log('calcPriceUnitCx');
		let qtdcx = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);
		if (qtdcx == 0 && this.isProductInserted(selectedCd)) {
			swal({
				title: "Remover item do carrinho?",
				text: "Caso remova será recalculado os valores no carrinho!",
				icon: "warning",
				buttons: ["Cancelar", "Remover"],
				dangerMode: true,
			}).then((willDelete) => {
					if (willDelete) {
						this.orderList = this.orderList.filter(prod => prod.id !== cdId);
						this.orderListFiltered = this.orderList.filter(prod => prod.id !== cdId);

						selectedCd.quantidade = Number(qtdcx);
						selectedCd.quantidadeScreen = Number(qtdcx).toFixed(4);
						selectedCd.quantidadeCx = selectedCd.tipoConversao == 'M' ? (qtdcx / parseFloat(selectedCd.conversaoUnidadeCx)) : (qtdcx * parseFloat(selectedCd.conversaoUnidadeCx));
						selectedCd.desconto = 0;
						selectedCd.unitario = Number(selectedCd.desconto > 0 ? selectedCd.tipoConversao == 'M' ? (selectedCd.inicialUnitario * (1 - selectedCd.desconto / 100)) : (selectedCd.inicialUnitario / (1 - selectedCd.desconto / 100)) : selectedCd.inicialUnitario).toFixed(6);
						selectedCd.caixa = Number(selectedCd.desconto > 0 ? selectedCd.inicialCaixa * (1 - selectedCd.desconto / 100) : selectedCd.inicialCaixa).toFixed(6);
						selectedCd.adicionado = false;

						this.calcRefresh(selectedCd);
						this.calcTotalOrderPrice();
						this.refreshCdScoreCalc();
						this.getScoreCalcApi(selectedCd);

						this.orderList.forEach(cd => {
							if (cd.id === selectedCd.id) {
								this.refreshCdScoreCalc();
							}
						})
						if(this.filterLst.length > 0){
							this.orderListFiltered = [];
							this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
						}else{
							this.orderListFiltered = this.orderList;
						}				
			
						swal("Poof! Produto removido do carrinho!", {
							icon: "success",
						});
						
						if (this.orderListFiltered.length > 0) {
							this.keepSavingOrEditing();
						}
					} else {
						qtdcx = selectedCd.quantidade;
						event.target.value = qtdcx;
						event.detail.value = qtdcx;
						selectedCd.quantidade = Number(qtdcx);
						selectedCd.quantidadeScreen = Number(qtdcx).toFixed(4);
						selectedCd.quantidadeCx = (qtdcx / parseFloat(selectedCd.conversaoUnidadeCx));
						this.calcTotalOrderPrice();
						this.refreshCdScoreCalc();
						this.getScoreCalcApi(selectedCd);

						this.orderList.forEach(cd => {
							if (cd.id === selectedCd.id) {
								this.refreshCdScoreCalc();
							}
						})
						if(this.filterLst.length > 0){
							this.orderListFiltered = [];
							this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
						}else{
							this.orderListFiltered = this.orderList;
						}				

					}
				});
		} else {
			this.refreshOrderList(selectedCd, qtdcx);
		}
	}

	calcUnitValue(event){
		let unitValue = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);

		if (selectedCd.unitario != unitValue) {
			selectedCd.unitario = Number(unitValue).toFixed(6);
			selectedCd.caixa = selectedCd.tipoConversao == 'M' ? Number(parseFloat(unitValue) * parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(6) : Number(parseFloat(unitValue) / parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(6);

			let currentProd = this.getCurrentProduct(selectedCd.prodCode);

			this.fillCalcScoreObj(selectedCd, currentProd);

			console.log(this.calcScoreObj);

			this.getScoreCalcApi(selectedCd);

			this.orderList.forEach(cd => {
				if (cd.id === selectedCd.id) {
					this.refreshCdScoreCalc();
				}
			})
			if(this.filterLst.length > 0){
				this.orderListFiltered = [];
				this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
			}else{
				this.orderListFiltered = this.orderList;
			}				
		}
	}

	calcCxValue(event){
		let cxValue = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);
		if (selectedCd.caixa != cxValue) {
			selectedCd.caixa = Number(cxValue).toFixed(6);
			selectedCd.unitario = selectedCd.tipoConversao == 'M' ? Number(cxValue / parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(6) : Number(cxValue * parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(6);
	
			let currentProd = this.getCurrentProduct(selectedCd.prodCode);
			this.fillCalcScoreObj(selectedCd, currentProd);
			this.calcValorTotal(selectedCd);

			this.orderList.forEach(cd => {
				if (cd.id == selectedCd.id) {
					cd.quantidade	   = selectedCd.quantidade;
					cd.quantidadeScreen = Number(selectedCd.quantidade).toFixed(4);
					cd.quantidadeCx	 = selectedCd.quantidadeCx;
					cd.desconto		 = selectedCd.desconto;
					cd.margem		   = selectedCd.margem;
					cd.verMargem		= selectedCd.verMargem;
					cd.margemAlvo	   = selectedCd.margemAlvo;
					cd.caixa			= selectedCd.caixa;
					cd.unitario		 = selectedCd.unitario;
					cd.valorTotal	   = selectedCd.valorTotal;
					cd.score			= selectedCd.score;
					cd.validadeMinima   = selectedCd.validadeMinima;
					cd.SequenciaOC = selectedCd.SequenciaOC;
					cd.isCampaign 		= selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? selectedCd.showBadgeCampanhaCD : true;
					cd.isLab	 		= selectedCd.laboratorio == undefined ? false : true;
					cd.observacaoComercial   = selectedCd.observacaoComercial;
			}
			})
			this.refreshCdScoreCalc();

			this.getScoreCalcApi(selectedCd);
			this.calcTotalOrderPrice();

			if(this.filterLst.length > 0){
				this.orderListFiltered = [];
				this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
			}else{
				this.orderListFiltered = this.orderList;
			}				
		}

	}

	calcDiscount(event){
		let discount = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);

		if (selectedCd.desconto != discount) {

			selectedCd.desconto = discount;
			selectedCd.unitario = (Number(selectedCd.desconto > 0 ? Number(selectedCd.inicialUnitario) * (1 - selectedCd.desconto / 100) : Number(selectedCd.inicialUnitario)).toFixed(6));
			selectedCd.caixa = Number(selectedCd.desconto > 0 ? Number(selectedCd.inicialCaixa) * (1 - selectedCd.desconto / 100) : Number(selectedCd.inicialCaixa)).toFixed(6);

			let currentProd = this.getCurrentProduct(selectedCd.prodCode);

			this.fillCalcScoreObj(selectedCd, currentProd);
	
			console.log('calcDiscount');
			console.log(this.calcScoreObj);

			this.calcValorTotal(selectedCd);

			this.orderList.forEach(cd => {
				if (cd.id == selectedCd.id) {
					cd.desconto = selectedCd.desconto;
					cd.unitario = selectedCd.unitario;
					cd.caixa	= selectedCd.caixa;
					cd.SequenciaOC = selectedCd.SequenciaOC;

				}
			})
			this.refreshCdScoreCalc();

			this.getScoreCalcApi(selectedCd);

		}
	}

	fillCalcScoreObj(selectedCd, currentProd) {
		this.calcScoreObj = [];
		this.calcScoreObj.push({
			cdId: selectedCd.cnpjCd,
			productBu: (currentProd.categoria == '' || currentProd.categoria == undefined) ? 'SEM BU' : currentProd.categoria,
			productCode: selectedCd.prodCode,
			cost: (selectedCd.custoCx != null && selectedCd.custoCx != undefined) ? selectedCd.custoCx : 10,
			quantity: selectedCd.quantidadeCx,
			unitPrice: Number(Number(selectedCd.caixa).toFixed(6)),
			listPrice: Number(Number(selectedCd.inicialCaixa).toFixed(6)),
			taxPercent: selectedCd.aliquota,
			SequenciaOC: selectedCd.SequenciaOC,
			isContract: selectedCd.valorBloqueado != undefined ? selectedCd.valorBloqueado : false,
			isCampaign: selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? selectedCd.showBadgeCampanhaCD : true,
			isLab: selectedCd.laboratorio == undefined ? false : true
		});
	}

	handleMargin(event){
		let margin = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);
		let productCode = selectedCd.prodCode;
		if (selectedCd.margem != margin) {
			let currentProd;
			selectedCd.margem = margin;

			currentProd = this.getCurrentProduct(productCode);

			this.fillCalcScoreObj(selectedCd, currentProd);

			reverseCalcScreen({ clListString: JSON.stringify(this.calcScoreObj) })
				.then(result => {
					console.log('reverseCalcScreen: entrou certo!');
					console.log(JSON.parse(result));
					let resultObj = JSON.parse(result);
					for (var i = 0; i < resultObj.length; i++) {
						selectedCd.unitario = selectedCd.tipoConversao == 'M' ? (resultObj[i].unitPrice / selectedCd.conversaoUnidadeCx).toFixed(6) : (resultObj[i].unitPrice * selectedCd.conversaoUnidadeCx).toFixed(6);
						selectedCd.caixa	= resultObj[i].unitPrice.toFixed(6);
						selectedCd.desconto = resultObj[i].newDiscount.toFixed(2);
						selectedCd.score	= (resultObj[i].scoreFinal != undefined && resultObj[i].scoreFinal != null) ? resultObj[i].scoreFinal.toFixed(2) : this.cdList.find(cd => cd.id == resultObj[i].cdId).score;

					}
					if (this.isOrderListReturned) {
						this.cdList.forEach(cd => {
							this.orderList.find(cdFromCart => {
								if (cd.id == cdFromCart.id) {
									cdFromCart.quantidade	   = cd.quantidade;
									cdFromCart.quantidadeScreen = Number(cd.quantidade).toFixed(4);
									cdFromCart.quantidadeCx	 = cd.quantidadeCx;
									cdFromCart.desconto		 = cd.desconto;
									cdFromCart.margem		   = cd.margem;
									cdFromCart.verMargem		= cd.verMargem;
									cdFromCart.margemAlvo	   = cd.margemAlvo;
									cdFromCart.caixa			= cd.caixa;
									cdFromCart.unitario		 = cd.unitario;
									cdFromCart.valorTotal	   = cd.valorTotal;
									cdFromCart.valorZerado	  = cd.valorZerado;
									cdFromCart.score			= cd.score;
									cdFromCart.SequenciaOC = cd.SequenciaOC;
									cdFromCart.isCampaign 		= cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ ) ? cd.showBadgeCampanhaCD : true;
									cdFromCart.isLab	 		= cd.laboratorio == undefined ? false : true;
									cdFromCart.observacaoComercial = cd.observacaoComercial;
								}
							});
						});
					}

					this.refreshCdWithCart(false);
					this.calcRefresh(selectedCd);

					this.orderList.forEach(cd => {
						if (cd.id === selectedCd.id) {
							this.refreshCdScoreCalc();
						}
					})
				}).catch(error => {
					console.log('reverseCalcScreen: entrou no erro!');
					console.log(error);
					this.refreshCdWithCart(false);
					this.calcRefresh(selectedCd);
				});
		}

		this.calcValorTotal(selectedCd);
	}

	calcValorTotal(selectedCd){
		let discount = 100-(parseFloat(selectedCd.caixa)*100/parseFloat(selectedCd.inicialCaixa));
		selectedCd.desconto = discount < 0 ? 0 : (Math.round(discount * 100) / 100).toFixed(2);
		selectedCd.valorTotal = selectedCd.tipoConversao == 'M' ? Number(parseFloat(selectedCd.quantidadeCx) * parseFloat(selectedCd.caixa)).toFixed(6) : Number(parseFloat(selectedCd.quantidadeCx) * parseFloat(selectedCd.caixa)).toFixed(6);
	}

	calcTotalOrderPrice() {
		console.log('Calcular valor total');
		let currentTotalPrice = 0;
		for (var i = 0; i < this.orderList.length; i++) {
			currentTotalPrice += Number(this.orderList[i].valorTotal);
		}
		this.totalOrderValue = (Number(currentTotalPrice)).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

		let isCampaignCd = [];
		let cdsToTotalValueRefresh = [];
		this.orderCdList = [];
		this.orderList.forEach(cd => {
			if (cdsToTotalValueRefresh[cd.cds] == undefined) {
				cdsToTotalValueRefresh[cd.cds] = Number(cd.valorTotal);
				if (this.hasOnlyCampaign || this.hasOnlyContract) {
					this.orderCdList.push({
						id: cd.id,
						cdId: cd.cnpjCd,
						prodId: cd.prodId,
						cds: cd.cds,
						valorTotal: cd.valorTotal,
						margem: cd.margem,
						margemAlvo: cd.margemAlvo,
						scoreCd: 100 
					});
				} else {
					this.orderCdList.push({
						id: cd.id,
						cdId: cd.cnpjCd,
						prodId: cd.prodId,
						cds: cd.cds,
						valorTotal: cd.valorTotal,
						margem: cd.margem,
						margemAlvo: cd.margemAlvo,
						scoreCd: ((cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.valorBloqueado)) ? (cd.laboratorio || cd.showBadgeCampanhaCD) ? 100 : cd.score : 100
					});
					if (cd.valorCampanha != 0 || cd.showBadgeShelflifeCNPJ || cd.laboratorio || cd.showBadgeCampanhaCD) {
						isCampaignCd[cd.cds] = true;
					}
				}
			} else {
				if ((isCampaignCd[cd.cds] && (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.valorBloqueado))) {
					if (cd.laboratorio || cd.showBadgeCampanhaCD) {
						this.orderCdList.find(cdFilter => cdFilter.cds == cd.cds).scoreCd = 100;
					} else {
						this.orderCdList.find(cdFilter => cdFilter.cds == cd.cds).scoreCd = cd.score;
					}
				}
				cdsToTotalValueRefresh[cd.cds] += Number(cd.valorTotal);
				this.orderCdList.find(cdFilter => cdFilter.cds == cd.cds).valorTotal = cdsToTotalValueRefresh[cd.cds];
			}
		})
		if(this.filterLst.length > 0){
			this.orderListFiltered = [];
			this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
		}else{
			this.orderListFiltered = this.orderList;
		}				
	}

	handleValidadeMinima(event) {
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);
		let selectedOrderList = this.orderList.find(cd => cd.id === cdId);
		
		selectedCd.validadeMinima = event.detail.value;
		
		if (selectedCd.validadeMinima != "Shelf Life" && !selectedCd.blockShelfLife && selectedCd.showBadgeShelflifeCNPJAux) {
			selectedCd.valorZerado = false;
			selectedCd.showBadgeShelflifeCNPJ = false;
			selectedCd.loteSelecionado = false;
		} else if (selectedCd.validadeMinima == "Shelf Life" && !selectedCd.blockShelfLife && selectedCd.showBadgeShelflifeCNPJAux) {
			selectedCd.valorZerado = true;
			selectedCd.showBadgeShelflifeCNPJ = true;
			selectedCd.loteSelecionado = true;
		}

		if (selectedOrderList) {
			if (selectedOrderList.validadeMinima != "Shelf Life") {
				selectedOrderList.validadeMinima = event.detail.value;
			}
		}
	}

	connectedCallback() {

		this.selected = 'Com saldo';
		window.addEventListener('resize', this.handleResizeHeader.bind(this));
		this.controllerOfButtons(window.innerWidth);
		this.resumo	 = this.isBudget == true ? 'Resumo do orçamento' : 'Resumo do pedido';
		this.desktop = FORM_FACTOR == 'Large';
		this.headerStyle = this.desktop ? 'height: calc(100% - 150px)' : '';
		this.headerClass = this.desktop ? 'main-content slds-scrollable_y' : 'main-content';
		console.log('connectedCallback: Entrou na orderProduct!');
		this.HistoricSection = '';

		console.log('this.goToCheckout');
		console.log(this.goToCheckout);

		if (this.savingStrData) {
			this.savingObjData = JSON.parse(this.savingStrData);
			console.log('this.savingObjData ==> ' + JSON.stringify(this.savingObjData));
		}

		if (this.isBudget && this.dtValidade != undefined) {
			this.dtValidadeFormatada = 'Data de validade: ' +  this.getFormatDate(this.dtValidade);
		} else {
			this.dtValidadeFormatada = undefined;
		}

		if (this.orderListReturned != undefined) {
			this.isOrderListReturned = true;

			this.orderList = JSON.parse(this.orderListReturned);
			this.orderListFiltered = this.orderList;
			this.orderListFiltered.sort((a, b) => (a.indexInsertPosition > b.indexInsertPosition) ? 1 : ((b.indexInsertPosition > a.indexInsertPosition) ? -1 : 0));

			this.orderList.forEach(item => {
				console.log('item.precoCNPJCampanha => '+item.precoCNPJCampanha);
				console.log('item.precoCNPJShelflife => '+item.precoCNPJShelflife);
				this.allValues = [];
				let hasShelflifeCNPJ = false;
				if (item.precoCNPJShelflife) {
					if (item.precoCNPJShelflife.includes(';')) {
						this.allValues = item.precoCNPJShelflife.split(';');
					} else {
						this.allValues.push(item.precoCNPJShelflife);
					}				
				}
				this.allValues.forEach(val => {
					if (val.includes(item.cnpjCd)) {
						hasShelflifeCNPJ = true;
					}
				});
				if (item.precoCNPJCampanha == undefined) {
					if (item.valorCampanha == undefined) {
						item.valorCampanha = item.showBadgeCampanhaCD ? item.valorMalha : 0;
					}
				} else {					
					let campaignPrice = 0;
					let campaignPriceNull = 0;
					if (item.precoCNPJCampanha) {
						if (item.precoCNPJCampanha.includes(";")) {
							item.precoCNPJCampanha.split(";").forEach(cnpjToPrice =>{
								let cnpjToPriceVal = cnpjToPrice.split(",");
								if (cnpjToPrice.includes(item.cnpjCd)) {
									campaignPrice = parseFloat(cnpjToPriceVal[1]);
								} else if (cnpjToPrice.includes('null')) {
									campaignPriceNull = parseFloat(cnpjToPriceVal[1]);
								}
							});
						} else {
							let cnpjToPriceVal = item.precoCNPJCampanha.split(",");
							if (item.precoCNPJCampanha.includes(item.cnpjCd)) {
								campaignPrice = parseFloat(cnpjToPriceVal[1]);
							} else if (item.precoCNPJCampanha.includes('null')) {
								campaignPriceNull = parseFloat(cnpjToPriceVal[1]);
							}
						}
						if (campaignPrice == 0 && campaignPriceNull != 0) {
							campaignPrice = campaignPriceNull;
						}
					}
					if (item.valorCampanha != 0 && item.valorCampanha != undefined && !item.showBadgeCampanhaCD) {
						item.valorCampanha = campaignPrice;
					}
				}
			});
		}
		if (this.goToCheckout) {
			this.navigateToCheckout();
			return;
		}
		getPricebookExternalId({ pricebookId: this.tabelaPreco })
		.then(result => {
			console.log('getPricebookExternalId: entrou certo!');
			console.log(result);
			this.tabelaPrecoExternalId = result;
			if (this.isEdit) {
				this.disableButtons();
				this.getAllCurrentProductPrice();
			} else {
				this.refreshCdScoreCalc();
			}
		}).catch(error => {
			console.log('getPricebookExternalId: entrou no erro!');
			console.log(error);
		});
		this.searchProductCampaign(false);
		this.isLoadingProducts = true;
		if (this.productToSearch) {
			this.onEditProduct(this.productToSearch);
		} else {
			this.searchProducts();
		}
		try{
			this.handleCategoryInitials();
			this.filterLst = [];
			this.filterListMethod();
		} catch(e) {
			console.log(e);
		}

		buscaCodigoLoja({ clienteId: this.clienteEmissorId })
			.then(result => {
				console.log('buscaCodigoLoja: entrou certo!');
				console.log(result);
				if (result != null) {
					this.CodigoLoja = result;
				}
			}).catch(error => {
				console.log(error);
				this.isLoadingProducts = false;
			});
		this.calcTotalOrderPrice();
		if(this.desktop) {
			if(!this.iconPinned) {
				this.showHeader = false;
				this.headerStyle = this.desktop ? 'height: calc(100% - 0px)' : '';
			}
		} else {
			this.showHeader = true;
		}
	}

	keepSavingOrEditing() {
		this.disableButtons();
		console.log('Manter registro salvo.');
		this.automaticSave = true;
		this.fillHeader();
		if ((this.isBudget)) {
			if (!this.isEdit && !this.alreadySaved && this.orderList.length > 0) {
				this.alreadySaved = true;
				console.log('orçamento salvo');
				this.callGenerateBudget();
			} else if (this.orderList.length > 0) {
				console.log('orçamento editado');
				this.callEditBudget();
			}
		} else {
			if (!this.isEdit && !this.alreadySaved && this.orderList.length > 0) {
				this.alreadySaved = true;
				console.log('pedido salvo');
				this.callGenerateOrder();
			} else if (this.orderList.length > 0) {
				console.log('pedido editado');
				this.callEditOrder();
			}
		}
	}

	returnTelaIni() {
		this.automaticSave = false;
		this.fillHeader();
		if(this.pedidoComplementar == null || this.pedidoComplementar == undefined){
			this.pedidoComplementar = false;
		}
		this.handleNavigateMix();
	}

	callGenerateBudget() {
		this.isSaving = true;
		generateBudget({ budget: JSON.stringify(this.orderList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: false, hasComplementOrder: false })
			.then(result => {
				this.isSaving = false;
				console.log(result);
				if (result.length == 18) {
					this.checkInterval(result);
				} else {
					swal("Ops!", "Ocorreu algum problema ao gerar o orçamento! Tente novamente mais tarde!", "Warning");
				}
			}).catch(error => {
				this.isSaving = false;
				this.enableButtons();
				console.log(error);
			});
	}

	callGenerateOrder() {
		this.isSaving = true;
		generateOrder({ jsonOrder: JSON.stringify(this.orderList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: false, keepComplementOrder: this.pedidoComplementar, isAutomaticSave: this.automaticSave })
			.then(result => {
				this.isSaving = false;
				console.log(result);
				if (result.length == 18) {
					this.checkInterval(result);
				} else {
					swal("Ops!", "Ocorreu algum problema ao gerar o pedido! Tente novamente mais tarde!", "Warning");
				}
			}).catch(error => {
				this.isSaving = false;
				swal("Ops!", "Erro ao gerar pedido! Verifique com o administrador!", "error");
				console.log(error);
			});
	}

	callEditBudget() {
		this.isSaving = true;
		editBudget({ budget: JSON.stringify(this.orderList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: false, recordId: this.newRecordId ? this.newRecordId : this.recordId, hasComplementOrder: this.automaticSave ? false : this.pedidoComplementar })
			.then(result => {
				this.isSaving = false;
				console.log(result);
				if (result.length == 18) {
					this.checkInterval(result);
				} else {
					swal("Ops!", "Ocorreu algum problema ao editar o orçamento! Tente novamente mais tarde!", "Warning");
				}
			}).catch(error => {
				this.isSaving = false;
				swal("Ops!", "Erro ao gerar orçamento! Verifique com o administrador!", "error");
				console.log(error);
			});
	}

	callEditOrder() {
		this.isSaving = true;
		editOrder({ jsonOrder: JSON.stringify(this.orderList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: false, recordId: this.newRecordId ? this.newRecordId : this.recordId, keepComplementOrder: this.pedidoComplementar, isAutomaticSave: this.automaticSave })
			.then(result => {
				console.log(result);
				this.isSaving = false;
				if (result.length == 18) {
					this.checkInterval(result);
				} else {
					swal("Ops!", "Ocorreu algum problema ao editar o pedido! Tente novamente mais tarde!", "Warning");
				}
			}).catch(error => {
				this.isSaving = false;
				swal("Ops!", "Erro ao gerar pedido! Verifique com o administrador!", "error");
				console.log(error);
			});
	}

	checkInterval(result) {
		this.enableButtons();
		if (this.automaticSave) {
			console.log(result);
			this.newRecordId = result;
			this.isEdit = true;
			this.savingObjData = {
				registerName: this.newRecordId,
				sobject: this.isBudget ? 'Orçamento' : 'Pedido',
				lastSaveDate: (new Date()).toLocaleTimeString()
			}
			console.log('this.savingObjData ==> ' + JSON.stringify(this.savingObjData));
		} else {
			this.handleNavigateMix();
		}
	}

	fillHeader() {
		if (this.isBudget) {
			console.log('ORÇAMENTO!');
			this.headerInfoData = {
				numOrcamento: this.numOrcamento,
				valorTotal: this.valorTotal,
				clienteEmissorId: this.clienteEmissorId,
				clienteEmissor: this.clienteEmissor,
				clienteEmissorCGC: this.clienteEmissorCGC,
				tabelaPreco: this.tabelaPreco,
				tabelaPrecoNome: this.tabelaPrecoNome,
				canalEntrada: this.canalEntrada,
				condicaoPagamento: this.condicaoPagamento,
				condicaoPagamentoNome: this.condicaoPagamentoNome,
				formaPagamento: this.formaPagamento,
				contatoOrcamento: this.contatoOrcamento,
				prazoValidade: this.prazoValidade,
				dtValidade: this.dtValidade,
				observacaoCliente: this.observacaoCliente,
				observacao: this.observacao,
				hasPermissionERB: this.hasPermissionERB,
				recordId: this.recordId,
				isCoordenador: this.isCoordenador,
				margemAtual: this.margemAtualGeral.replace('%', ''),
				margemAlvo: this.margemAtualAlvo.replace('%', ''),
				score: this.scoreFinalGeral.replace('%', ''),
				Idportalcotacoes: this.Idportalcotacoes, 
				recomendacaoRespondida: this.allRecAnswered,
				dtList: null,
				freteList: null,
				filtroPDF : this.filtroPDF
			}
		} else {
			console.log('PEDIDO!');
			this.headerInfoData = {
				clienteEmissor: this.clienteEmissor,
				clienteEmissorId: this.clienteEmissorId,
				clienteEmissorCGC: this.clienteEmissorCGC,
				medico: this.medico,
				medicoId: this.medicoId,
				medicoCRM: this.medicoCRM,
				tabelaPreco: this.tabelaPreco,
				tabelaPrecoNome: this.tabelaPrecoNome,
				tipoFrete: this.tipoFrete,
				valorFrete: this.valorFrete,
				numeroPedidoCliente: this.numeroPedidoCliente,
				condicaoPagamento: this.condicaoPagamento,
				condicaoPagamentoNome: this.condicaoPagamentoNome,
				contatoOrcamento: this.contatoOrcamento,
				canalVendas: this.canalVendas,
				tipoOrdem: this.tipoOrdem,
				formaPagamento: this.formaPagamento,
				dtPrevistaEntrega: this.dtPrevistaEntrega,
				clienteRecebedor: this.clienteRecebedor,
				clienteRecebedorCGC: this.clienteRecebedorCGC,
				enderecoEntrega: this.enderecoEntrega,
				enderecoEntregaId: this.enderecoEntregaId,
				enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
				observacao: this.observacao,
				observacaoNF: this.observacaoNF,
				observacaoPedido: this.observacaoPedido,
				hasPermissionERB: this.hasPermissionERB,
				margemAtual: this.margemAtualGeral.replace('%', ''),
				margemAlvo: this.margemAtualAlvo.replace('%', ''),
				score: this.scoreFinalGeral.replace('%', ''),
				Idportalcotacoes: this.Idportalcotacoes, 
				recomendacaoRespondida: this.allRecAnswered,
				createOrderDt: this.createOrderDt,
				dtList: null,
				freteList: null
			}
		}
	}

	handleNavigateMix(result) {

		this.recordId = result;
		var compDefinition = {};
		if (this.isBudget) {
			var compDefinition = {
				componentDef: "c:createBudget",
				attributes: {
					isEdit: true,
					recordId: this.recordId,
					newRecordId: this.newRecordId,
					isBudget: this.isBudget,
					numOrcamento: this.numOrcamento,
					valorTotal: this.valorTotal,
					score: this.scoreFinalGeral.replace('%', ''),
					clienteEmissorId: this.clienteEmissorId,
					clienteEmissor: this.clienteEmissor,
					clienteEmissorCGC: this.clienteEmissorCGC,
					tabelaPreco: this.tabelaPreco,
					tabelaPrecoNome: this.tabelaPrecoNome,
					canalEntrada: this.canalEntrada,
					condicaoPagamento: this.condicaoPagamento,
					condicaoPagamentoNome: this.condicaoPagamentoNome,
					formaPagamento: this.formaPagamento,
					contatoOrcamento: this.contatoOrcamento,
					hasPermissionERB: this.hasPermissionERB,
					prazoValidade: this.prazoValidade,
					dtValidade: this.dtValidade,
					observacaoCliente: this.observacaoCliente,
					observacao: this.observacao,
					isCoordenador: this.isCoordenador,
					Idportalcotacoes: this.Idportalcotacoes,
					recomendacaoRespondida: this.allRecAnswered,
					headerInfoData: JSON.stringify(this.headerInfoData),
					orderListReturned: JSON.stringify(this.orderList),
					dtParcelas: this.dtParcelas,
					fretesPorCd: this.fretesPorCd,
					alreadySaved: this.alreadySaved,
					newRecordId: this.newRecordId,
					savingStrData: JSON.stringify(this.savingObjData),
					filtroPDF: this.filtroPDF
				}
			};
		}else{
			console.log('Gerando Pedido!');

			var compDefinition = {
				componentDef: "c:insertOrder",
				attributes: {
					clienteEmissor: this.clienteEmissor,
					clienteEmissorId: this.clienteEmissorId,
					clienteEmissorCGC: this.clienteEmissorCGC,
					recordId: this.recordId,
					medico: this.medico,
					medicoId: this.medicoId,
					medicoCRM: this.medicoCRM,
					tabelaPreco: this.tabelaPreco,
					tabelaPrecoNome: this.tabelaPrecoNome,
					tipoFrete: this.tipoFrete,
					valorFrete: this.valorFrete,
					numeroPedidoCliente: this.numeroPedidoCliente,
					condicaoPagamento: this.condicaoPagamento,
					condicaoPagamentoNome: this.condicaoPagamentoNome,
					contatoOrcamento: this.contatoOrcamento,
					canalVendas: this.canalVendas,
					tipoOrdem: this.tipoOrdem,
					formaPagamento: this.formaPagamento,
					dtPrevistaEntrega: this.dtPrevistaEntrega,
					clienteRecebedor: this.clienteRecebedor,
					clienteRecebedorCGC: this.clienteRecebedorCGC,
					hasPermissionERB: this.hasPermissionERB,
					enderecoEntregaId: this.enderecoEntregaId, 
					enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
					utilizarEnderecoAdicional: this.utilizarEnderecoAdicional,
					observacao: this.observacao,
					observacaoNF: this.observacaoNF,
					observacaoPedido: this.observacaoPedido,
					Idportalcotacoes: this.Idportalcotacoes,
					recomendacaoRespondida: this.allRecAnswered,
					createOrderDt: this.createOrderDt,
					headerInfoData: JSON.stringify(this.headerInfoData),
					isEdit: true,
					isReturn: true,
					alreadySaved: this.alreadySaved,
					newRecordId: this.newRecordId,
					savingStrData: JSON.stringify(this.savingObjData),
					orderListReturned: JSON.stringify(this.orderList)
				}
			};
		}
		try {
		const filterChangeEvent = new CustomEvent('generateorder', {
			detail: { "data": JSON.stringify(compDefinition) }
		});
		this.dispatchEvent(filterChangeEvent);
		} catch (e) {
			debugger;
			console.log(e);
		}
	}

	handleFilterSearchProd() {
		console.log('Buscando produtos filtrados: ');
		this.isLoadingProducts = true;
		this.offSetValue = 0;
		this.prodFilterList = [];
		this.prodList = [];
		this.searchProducts();
	}

	handleGetMoreProducts() {
		this.isLoadingProducts = true;
		this.offSetValue += 20;
		this.searchProducts();
	}

	searchProductCampaign(searchProdCampaign) {
		if (searchProdCampaign) {
			this.isLoadingProducts = true;
			this.offSetValue = 0;
			this.prodFilterList = [];
			this.prodList = [];
		}
		getProductCampaign({ pricebook: this.tabelaPreco, clienteId: this.clienteEmissorId, offSetValue: "", searchGenericValue: this.searchGenericValue, searchFabricanteValue: this.searchFabricanteValue, condPag: this.condicaoPagamento})
			.then(result => {
				console.log('getProductCampaign: entrou certo!');
				if (result != null) {
					if (searchProdCampaign) {
						this.handleProdResult(result);
					} else {
						result.forEach(item => {
							item.show = false;
							this.listProdCampaign.push({
								...item
							});
						});
						this.qtdProductCampaign = 'Total de produtos de campanha: ' + this.listProdCampaign.length;
						this.enableProdCampaignButton = true;
					}
				}
			}).catch(error => {
				this.enableProdCampaignButton = false;
				console.log(error);
			});
	}

	searchProducts() {
		getProduct({ pricebook: this.tabelaPreco, clienteId: this.clienteEmissorId, offSetValue: this.offSetValue.toString(), searchGenericValue: this.searchGenericValue, searchFabricanteValue: this.searchFabricanteValue, condPag: this.condicaoPagamento, isCampaign: false, prodList: null })
			.then(result => {
				console.log('getProduct: entrou certo!');
				console.log(JSON.stringify(result));
				this.handleProdResult(result.productDataList);
				this.mapProductToInventoryList = result.mapProductDataToInventoryList;
				console.log('this.mapProductToInventoryList ==> ' + JSON.stringify(this.mapProductToInventoryList));
			}).catch(error => {
				console.log('getProduct: entrou no erro!');
				console.log(error);
				this.isLoadingProducts = false;
			});
	}

	handleProdResult(result) {		
		if (result != null) {
			this.fillProductList(result);
		}
		if (result.length < 20) {
			this.showMoreProduct = false;
		} else {
			this.showMoreProduct = true;
		}
		this.prodFilterList = this.prodList;
	
		let productCodeList = [];
	
		for (var i = 0; i < this.prodFilterList.length; i++) {
			productCodeList += (this.prodFilterList[i].code + ',');
		}
		
		if(this.prodFilterList.length > 0){
			getFirstMalha({ clienteCGC: this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''), 
							productCode: productCodeList, 
							calcMargem: false, 
							pricebookExternalId: this.tabelaPreco, 
							condPagamento: this.condicaoPagamento, 
							isForaMalha: false})
				.then(result2 => {
					for (var i = 0; i < result2.length; i++) {
						try {
							let t = this.prodFilterList.find(item => item.code == result2[i].productCode);
								t.estoqueSalesForce = (result2[i].foundEstoque == true ? result2[i].estoque : 'Não Encontrado');
							this.prodFilterList.find(item => item.code == result2[i].productCode).unitPriceSalesForce = (result2[i].unitPrice != undefined ? result2[i].unitPrice : 0);
							this.prodFilterList.find(item => item.code == result2[i].productCode).showUnitPriceSalesForce = (result2[i].unitPrice != undefined ? true : false);
							this.prodFilterList.find(item => item.code == result2[i].productCode).showEstoqueSalesForce = (result2[i].estoque != undefined ? '' : 'Não Encontrado');
							this.prodFilterList.find(item => item.code == result2[i].productCode).showPocTemplate = true;
							this.prodFilterList.find(item => item.code == result2[i].productCode).filial = (result2[i].filial != undefined ? result2[i].filial : 'Não Encontrado');
	
						} catch (error2) {
							console.log(error2);
						}
					}
					this.isLoadingProducts = false;
						
				}).catch(error  =>  {
					this.productNotFound();
					this.isLoading  =  false;
					this.isLoadingProducts = false;
				})

		} else {
			this.productNotFound();
			this.isLoadingProducts = false;
		}
	
		this.radioFilter();
	}

	productNotFound(){
		for (var i = 0; i < this.prodFilterList.length; i++) {
			this.prodFilterList[i].estoqueSalesForce = 'Não Encontrado';
			this.prodFilterList[i].unitPriceSalesForce = 0;
			this.prodFilterList[i].showUnitPriceSalesForce = false;
			this.prodFilterList[i].showEstoqueSalesForce = 'Não Encontrado';
			this.prodFilterList[i].filial = 'Não Encontrado';
	
		}
	}

	fillProductList(result) {
		for (var i = 0; i < result.length; i++) {
			this.verMargem = result[i].verMargem;
			let dtParts, dtObject;
			if (result[i].ultimaCompra) {
				dtParts = result[i].ultimaCompra.split('/');
				dtObject = new Date(+dtParts[2], dtParts[1] - 1, +dtParts[0]); 
			}
			let tipoCampanha = result[i].tipoCampanha ? ((result[i].tipoCampanha.includes('Z') && result[i].tipoCampanha.includes('Y')) ? ' | ' + this.condicaoPagamentoNome + ' e Dia D' : result[i].tipoCampanha.includes('Y') ? ' | Dia D' : ' | ' + this.condicaoPagamentoNome) : undefined;
			this.prodList.push({
				...result[i],
				hasSecUnit				  : !result[i].unidadeSec,
				isContractOrCampaign	  : (result[i].showBadgeAcordoComercial || result[i].showBadgeOL) ? true : false,
				precoBadgeCampanhaProduto : result[i].desconto + (tipoCampanha ? ' | ' + tipoCampanha : ''),
				ultimaCompraFilter  	  : dtObject,
				precoBadgeOL			  : this.getCurrencyFormat(result[i].precoBadgeOL),
				precoBadgeConsignado	  : this.getCurrencyFormat(result[i].precoBadgeConsignado),
				precoBadgeAcordoComercial : this.getCurrencyFormat(result[i].precoBadgeAcordoComercial),
				precoBadgeshelflife	   : this.getCurrencyFormat(result[i].precoBadgeshelflife),
				SequenciaOC : result[i].SequenciaOC
			});
			this.prodList.sort((a, b) => (!a.possuiUltimaCompra && b.possuiUltimaCompra) ? 1 : ((!b.possuiUltimaCompra && a.possuiUltimaCompra) ? -1 : 0));
			this.prodList.sort((a, b) => (a.ultimaCompraFilter < b.ultimaCompraFilter) ? 1 : ((b.ultimaCompraFilter < a.ultimaCompraFilter) ? -1 : 0));
			if (result[i].code != undefined) {
				this.mockedProdList[result[i].code] = {
					...result[i],
					hasSecUnit				  : !result[i].unidadeSec,
					isContractOrCampaign	  : (result[i].showBadgeAcordoComercial || result[i].showBadgeOL) ? true : false,
					precoBadgeCampanhaProduto : result[i].desconto + (tipoCampanha ? ' | ' + tipoCampanha : ''),
					ultimaCompraFilter  	  : dtObject,
					precoBadgeOL			  : this.getCurrencyFormat(result[i].precoBadgeOL),
					precoBadgeConsignado	  : this.getCurrencyFormat(result[i].precoBadgeConsignado),
					precoBadgeAcordoComercial : this.getCurrencyFormat(result[i].precoBadgeAcordoComercial),
					precoBadgeshelflife	   : this.getCurrencyFormat(result[i].precoBadgeshelflife),
					SequenciaOC : result[i].SequenciaOC
				};
			}
		}
	}

	getCurrencyFormat(price) {
		return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(price);
	}

	getFormatDate(input) {
		var datePart = input.match(/\d+/g),
			year	 = datePart[0],
			month	= datePart[1], 
			day	  = datePart[2];

		return day + '/' + month + '/' + year;
	}

	radioFilter(){
		if (!this.productFilter) {
			this.productFilter = 'Todos os itens';
		}
		if (this.productFilter == "Com saldo") {
			this.prodFilterList = this.prodFilterList.filter(prod => prod.estoque != 0);
			if (this.selectedSortProduct != undefined || this.selectedSortProduct != '') {
				this.getSortedProduct(this.selectedSortProduct);
			}
		} else {
			this.prodFilterList = this.prodList;
			if (this.selectedSortProduct != undefined || this.selectedSortProduct != '') {
				this.getSortedProduct(this.selectedSortProduct);
			}
		}
	}

	handleRadioFilter(event){
		this.productFilter = event.target.value;
		if (this.productFilter == "Com saldo") {
			this.prodFilterList = this.prodFilterList.filter(prod => prod.estoque != 0);
			if (this.selectedSortProduct != undefined || this.selectedSortProduct != '') {
				this.getSortedProduct(this.selectedSortProduct);
			}
		} else {
			this.prodFilterList = this.prodList;
			if (this.selectedSortProduct != undefined || this.selectedSortProduct != '') {
				this.getSortedProduct(this.selectedSortProduct);
			}
		}
	}

	sortProduct(event){
		this.selectedSortProduct = event.target.value;
		this.getSortedProduct(this.selectedSortProduct);
	}

	getSortedProduct(value) {
		if (value == "Maior Preço") {
			this.sortArrayByParameterDescending(this.prodFilterList, "precoTabelaCx");
		}
		else if (value == "Menor Preço") {
			this.sortArrayByParameterAscending(this.prodFilterList, "precoTabelaCx");
		}
		else if (value == "Maior Saldo") {
			this.sortArrayByParameterDescending(this.prodFilterList, "estoque");
		}
		else if (value == "Menor Saldo") {
			this.sortArrayByParameterAscending(this.prodFilterList, "estoque");
		}
	}

	sortArrayByParameterAscending(array, parameter) {
		array.sort((a, b) => (a[parameter] > b[parameter]) ? 1 : -1);
	}
	
	sortArrayByParameterDescending(array, parameter) {
		array.sort((a, b) => (a[parameter] < b[parameter]) ? 1 : -1);
	}

	handleCategoryInitials(){
		this.prodList.forEach(prod =>{
			if (prod.categoria === 'Genérico'){
				prod.categoryInitials = 'G';
			}
			else if (prod.categoria === 'Materiais'){
				prod.categoryInitials = 'M';
			}
			else if (prod.categoria === 'Referência'){
				prod.categoryInitials = 'R';
			}
		});
	}

	fillValorPrincipal(event) {
		let productId = event.currentTarget.dataset.prodId;
		let currentProd = this.prodFilterList.find(item => item.id == productId);
		this.prodFilterList.find(item => item.id == productId).vlPrincipal = event.detail.value;
		this.prodFilterList.find(item => item.id == productId).vlSecundario = currentProd.tipoConversao == 'M' ? Number(event.detail.value * parseFloat(currentProd.fatorConversao)).toFixed(4) : Number(event.detail.value / parseFloat(currentProd.fatorConversao)).toFixed(4);
	}

	fillObsComercial(event) {
		let cdId = event.currentTarget.dataset.cdId;
		this.cdList.find(cd => cd.id == cdId).observacaoComercial = event.detail.value;
	}

	fillValorSecundario(event) {
		let productId = event.currentTarget.dataset.prodId;
		let currentProd = this.prodFilterList.find(item => item.id == productId);
		this.prodFilterList.find(item => item.id == productId).vlSecundario = event.detail.value;
		this.prodFilterList.find(item => item.id == productId).vlPrincipal = currentProd.tipoConversao == 'M' ? Number(event.detail.value / parseFloat(currentProd.fatorConversao)).toFixed(6) : (event.detail.value * parseFloat(currentProd.fatorConversao));
	}

	distributeValues(productCode, event) {
		let vlPrincipal  = 0;
		let vlSecundario = 0;
		let prodId;
		this.prodFilterList.forEach(item => {
			if (item.code == productCode) {
				prodId = item.id;
				vlPrincipal = item.vlPrincipal == undefined ? vlPrincipal : item.vlPrincipal;
				vlSecundario = item.vlSecundario == undefined ? vlSecundario : item.vlSecundario;
			}
		})

		let maxStock = 0;
		let foraMalha = false;
		
		this.cdList.forEach(item => {
			if (item.prodCode == productCode && !item.valorZerado) {
				maxStock += item.estoque;
			}
			if (item.foraMalhaPesquisado || item.foraMalha) {
				foraMalha = true;
			}
		})


		if (vlPrincipal > 0 || vlSecundario > 0) {
			let currentValue = vlPrincipal;
			for (var i = 0; i < this.cdList.length; i++) {
				if (maxStock < vlPrincipal && !foraMalha) {
					swal({
						title: "Quantidade de estoque total indisponível dentro da malha, deseja tentar distribuir com CD fora malha?",
						buttons: ["Não", "Sim"]
					})
						.then((willSearch) => {
							if (willSearch) {
								event.currentData = {
									productId: prodId,
									productCode: productCode
								}
								this.handleSelectedProduct(event);
								return;
							} else {
								this.fillCdQuantity(vlPrincipal);
							}
						});
				} else if (maxStock < vlPrincipal) {
					this.fillCdQuantity(vlPrincipal);
				} else {
					if (this.cdList[i].estoque > 0 && currentValue != 0 && !this.cdList[i].valorZerado) {
						if (this.cdList[i].estoque > currentValue) {
							this.cdList[i].quantidadeCx = currentValue;
							currentValue = 0;
						} else {
							this.cdList[i].quantidadeCx = this.cdList[i].estoque;
							currentValue -= this.cdList[i].estoque;
						}
					}
				}
				this.cdList[i].quantidade = this.cdList[i].tipoConversao == 'M' ? Number(this.cdList[i].quantidadeCx * parseFloat(this.cdList[i].conversaoUnidadeCx)) : Number(this.cdList[i].quantidadeCx / parseFloat(this.cdList[i].conversaoUnidadeCx));
				this.cdList[i].quantidadeScreen = this.cdList[i].tipoConversao == 'M' ? Number(this.cdList[i].quantidadeCx * parseFloat(this.cdList[i].conversaoUnidadeCx)).toFixed(4) : Number(this.cdList[i].quantidadeCx / parseFloat(this.cdList[i].conversaoUnidadeCx)).toFixed(4);

				this.calcValorTotal(this.cdList[i]);
				this.refreshOrderList(this.cdList[i], this.cdList[i].quantidadeCx);
				this.calcTotalOrderPrice();
			}
		}
	}

	fillCdQuantity(vlPrincipal) {
		let isMainCd = false;
		this.cdList.forEach(cd => {
			if (!cd.valorZerado && !isMainCd) {
				isMainCd = true;
				cd.quantidadeCx = vlPrincipal;
			} else {
				cd.quantidadeCx = 0;
			}
		})
	}
	
	refreshOrderList(selectedCd, qtdcx) {
		if (selectedCd.range && !(selectedCd.valorBloqueado == undefined ? true : selectedCd.valorBloqueado) && !(selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? false : true)) {
			if (selectedCd.range.length > 0) {
				selectedCd.range.forEach(range => {
					if (range.range_min <= qtdcx && (range.range_max >= qtdcx || range.range_max == null)) {
						selectedCd.precoTabelaCx = range.preco_differ.toFixed(6) == undefined ? selectedCd.precoTabelaCx : range.preco_differ.toFixed(6);
						selectedCd.caixa		 = selectedCd.precoTabelaCx;
						selectedCd.inicialCaixa  = range.preco_differ.toFixed(6) == undefined ? selectedCd.inicialCaixa  : range.preco_differ.toFixed(6);
					}
				});
			}
		}

		selectedCd.quantidade = selectedCd.tipoConversao == 'M' ? Number(qtdcx * parseFloat(selectedCd.conversaoUnidadeCx)) : Number(qtdcx / parseFloat(selectedCd.conversaoUnidadeCx));
		selectedCd.quantidadeScreen = selectedCd.tipoConversao == 'M' ? Number(qtdcx * parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(4) : Number(qtdcx / parseFloat(selectedCd.conversaoUnidadeCx)).toFixed(4);
		selectedCd.quantidadeCx = qtdcx;

		this.calcValorTotal(selectedCd);

		this.orderList.forEach(cd => {
			if (cd.id == selectedCd.id) {
				cd.quantidade = selectedCd.quantidade;
				cd.quantidadeScreen = Number(selectedCd.quantidade).toFixed(4);
				cd.quantidadeCx = selectedCd.quantidadeCx;
			}
		})
		let currentProd = this.getCurrentProduct(selectedCd.prodCode);
		this.fillCalcScoreObj(selectedCd, currentProd);
		this.refreshCdScoreCalc();
		this.getScoreCalcApi(selectedCd);

		if(this.filterLst.length > 0){
			this.orderListFiltered = [];
			this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
		}else{
			this.orderListFiltered = this.orderList;
		}
	}
		
	fillBadgeTextoCampanha(listTagByCd, cd) {
		if (listTagByCd.includes(";")) {
			let splitTagByCd = listTagByCd.split(';');
			for (var t = 0; t < splitTagByCd.length; t++) {
				let splitTagText = splitTagByCd[t].split(',');
				let currentTextCamp = splitTagText[1] != undefined ? this.replaceCondType(splitTagText[1]) : this.replaceCondType(splitTagText[0]);
				if (splitTagText[0] == cd || splitTagText[1] == undefined) {
					this.fillBadgeCamp(currentTextCamp);
				}
			}
		} else {
			let splitTagText = listTagByCd.split(',');
			if (splitTagText[0] == cd) {
				let currentTextCamp = splitTagText[1] != undefined ? this.replaceCondType(splitTagText[1]) : undefined;
				this.fillBadgeCamp(currentTextCamp);
			} else {
				let currentTextCamp = listTagByCd.includes(',') ? this.replaceCondType(splitTagText[1]) : this.replaceCondType(listTagByCd);
				this.fillBadgeCamp(currentTextCamp);
			}
		}
	}

	replaceCondType(splitTagText) {
		return splitTagText.replace('Y', 'Dia D').replace('Z', this.condicaoPagamentoNome);
	}

	fillBadgeCamp(currentTextCamp) {
		if (!this.badgeTextoCampanha) {
			this.badgeTextoCampanha = currentTextCamp;
		} else {
			this.badgeTextoCampanha += ' ; ' + currentTextCamp;
		}
	}
	
	handleSelectedProduct(event){
		if (this.isRecommendation && this.isProdReject) {
			return;
		}
		let productId;
		let productCode;
		let getFromMalha;
		let check = true;
		if (event.currentData != null) {
			productId = event.currentData.productId;
			productCode = event.currentData.productCode;
			check = false;
			getFromMalha = true;
			this.distributeQuantity = true;
		} else {
			productId = event.currentTarget.dataset.productId;
			productCode = event.currentTarget.dataset.productCode;
			getFromMalha = event.currentTarget.dataset.productMalha == 'true' ? true : false;
			this.distributeQuantity = event.currentTarget.dataset.productDistribute == 'true' ? true : false;
		}
	
		
		if (!this.lastProduct) {
			this.lastProduct = productId;
		}

		if (this.savedCdData[productCode] == undefined || getFromMalha) {
			check = false;
			this.showHistoric = false;
			this.isForaMalha = false;
			this.isLoading = true;
			this.cdListClone = [];
			getMalha({ clienteCGC: this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''), productCode: productCode, calcMargem: true, pricebookExternalId: this.tabelaPrecoExternalId, condPagamento: this.condicaoPagamento, isForaMalha: getFromMalha})
				.then(result => {
					check = true;

					this.currentSelectedProdCode = productCode;
					this.cdList = [];
					this.savedCdData[productCode] = [];
					let currentProd;
					
					let currentProductHasForaMalha = false;

					currentProd = this.getCurrentProduct(productCode);
					
					let currentMalha = [];
					this.isLoading = false;
					if (result != null) {
						if (JSON.stringify(result[0]) == '{}') {
							this.swalErroMalha();
						} else if (result[0]['code'] != undefined) {
							this.swalErroMalha();
						} else if (result[0]['msgerro'] != undefined) {
							swal('Aviso ERP', `${result[0]['msgerro']}`, 'warning');
						} else if (result[0]['msgErro'] != undefined) {
							swal('Aviso ERP', `${result[0]['msgErro']}`, 'warning');
						} else {
							if (result[0]['cds'] != undefined && currentProd != undefined) {
								this.calcScoreObj = [];
								currentMalha = result[0]['cds'];
								for (var i = 0; i < currentMalha.length; i++) {
									if (!currentProd.showBadgeOL && !currentProd.showBadgeAcordoComercial) {
										this.mockedProdList[productCode].precoTabelaCx  = currentMalha[i].preco;
										currentProd.precoTabelaCx = currentMalha[i].preco;
										if( currentMalha[i].preco == 0){
											this.mockedProdList[productCode].valorZerado = true;
										}
									} 
									this.mockedProdList[productCode].precoMalha = currentMalha[i].preco;
									currentProd.precoMalha = currentMalha[i].preco;
								
									
									if (currentMalha[i].foramalha == false) {
										let obsComer = '';
										let qtd = 0;
										this.calcAllScoreObj.forEach(cd => {
											if(currentMalha[i].cnpj === cd.cdId && productCode === cd.productCode){
												obsComer = cd.observacaoComercial;
												qtd = cd.quantity;
											}
										});
										this.calcScoreObj.push({
											cdId		: currentMalha[i].cnpj,
											productBu   : currentProd.categoria,
											productCode : productCode,
											cost		: (currentMalha[i].custo != null && currentMalha[i].custo != undefined) ? currentMalha[i].custo : 10,
											quantity	: qtd,
											unitPrice   : Number((currentProd.precoTabelaCx).toFixed(6)),
											listPrice   : Number((currentProd.precoTabelaCx).toFixed(6)),
											taxPercent  : currentMalha[i].aliquota,
											valorZerado : currentMalha[i].preco == 0 ? true : false,
											isContract  : currentProd.valorBloqueado != undefined ? currentProd.valorBloqueado : false,
											SequenciaOC: currentProd.SequenciaOC != undefined ? currentProd.SequenciaOC : '',
											pf : currentMalha[i].pf,
											isCampaign  : currentProd.valorCampanha == undefined ? false : (currentProd.valorCampanha == 0 && !currentProd.showBadgeShelflifeCNPJ ) ? currentProd.showBadgeCampanhaCD : true,
											isLab	   : currentMalha[i].laboratorio == undefined ? false : true,
											observacaoComercial : obsComer
										});
									}
									let hasShelflifeCNPJ = false;
									let blockShelfLife = false;
									this.allValues = [];
									if (currentProd.precoCNPJShelflife) {
										if (currentProd.precoCNPJShelflife.includes(';')) {
											this.allValues = currentProd.precoCNPJShelflife.split(';');
										} else {
											this.allValues.push(currentProd.precoCNPJShelflife);
										}				
									} else if (currentProd.precoProdShelfLife) {
										hasShelflifeCNPJ = true;
										blockShelfLife = true;
									}
									this.allValues.forEach(val => {
										if (val.includes(currentMalha[i].cnpj)) {
											hasShelflifeCNPJ = true;
											blockShelfLife = true;
										}
									});
	
									if (currentMalha[i].foramalha) {
										currentProductHasForaMalha = true;
									}

									let allReserveValues = [];

									if (currentProd.dataBadgeReservadoCNPJ) {
										if (currentProd.dataBadgeReservadoCNPJ.includes(';')) {
											allReserveValues = currentProd.dataBadgeReservadoCNPJ.split(';');
										} else {
											allReserveValues.push(currentProd.dataBadgeReservadoCNPJ);
										}		
									}
									let hasReserve = false;
									let resQtd = 0;
									allReserveValues.forEach(val => {
										if (val.includes(currentMalha[i].cnpj)) {
											hasReserve = true;
											resQtd = val.split('_')[1];
										}
									});
									let campaignPrice = 0;
									let campaignPriceNull = 0;
									this.badgeTextoCampanha = undefined;
									let hasPrecoCampaign = false;

									if (currentProd.precoCNPJCampanha) {
										if (currentProd.precoCNPJCampanha.includes(";")) {
											currentProd.precoCNPJCampanha.split(";").forEach(cnpjToPrice =>{
												let cnpjToPriceVal = cnpjToPrice.split(",");
												if (cnpjToPrice.includes(currentMalha[i].cd)) {
													campaignPrice = parseFloat(cnpjToPriceVal[1]);
												} else if (cnpjToPrice.includes('null')) {
													campaignPriceNull = parseFloat(cnpjToPriceVal[1]);
												}
											});
										} else {
											let cnpjToPriceVal = currentProd.precoCNPJCampanha.split(",");
											if (currentProd.precoCNPJCampanha.includes(currentMalha[i].cd)) {
												campaignPrice = parseFloat(cnpjToPriceVal[1]);
											} else if (currentProd.precoCNPJCampanha.includes('null')) {
												campaignPriceNull = parseFloat(cnpjToPriceVal[1]);
											}
										}
										if (campaignPrice == 0 && campaignPriceNull != 0) {
											campaignPrice = campaignPriceNull;
											this.badgeTextoCampanha = campaignPrice;
											hasPrecoCampaign = true;
										}
									}
									if (currentProd.listTagByCd && this.badgeTextoCampanha == undefined) {
										this.fillBadgeTextoCampanha(currentProd.listTagByCd, currentMalha[i].cd);
									}
									let isMult = currentProd.tipoConversao == 'M' ? true : false;
									let hasSaldo = (currentMalha[i].saldo != null && currentMalha[i].saldo != undefined);
									let boolBadgeCampanha = currentProd.showBadgeCampanha != undefined ? currentProd.showBadgeCampanha : false;
									let boolBadgeCampanhaVend = currentProd.showBadgeCampanhaVendedor != undefined ? currentProd.showBadgeCampanhaVendedor : false;
								
									let obsComer = '';
									let qtd = 0;
									let filteredCd;
									let uniConversao = '';
									this.calcAllScoreObj.forEach(cd => {
										if(currentMalha[i].cnpj === cd.cdId && productCode === cd.productCode){
											obsComer = cd.observacaoComercial;
											qtd = cd.quantity;

										}
									});

									this.orderListFiltered.forEach(cd => {
										if(currentMalha[i].cnpj === cd.cnpjCd && productCode === cd.prodCode){
											cd.unidade = isMult ? currentProd.unidadePrincipal: currentProd.unidadeSecundaria;
											filteredCd = cd;
										}
									});
								
									if(currentProd.tipoConversao == 'M'){
										uniConversao = currentProd.unidadePrincipal + ' = '+ currentProd.fatorConversao + ' ('+currentProd.unidadeSecundaria + ')';
									}else if(currentProd.tipoConversao == 'D'){
										uniConversao = currentProd.unidadeSecundaria + ' = '+ currentProd.fatorConversao + ' ('+currentProd.unidadePrincipal + ')';
									}
									
									this.savedCdData[productCode].push({
										id: currentProd.pbEntryId + '_' + currentMalha[i].cnpj,
										cdId: currentMalha[i].cnpj + '_' + productCode,
										pbEntryId: currentProd.pbEntryId,
										prodId: currentProd.id,
										prodCode: productCode,
										nome: currentProd.nome,
										principioAtivo: currentProd.principioAtivo,
										fabricante: currentProd.fabricante,
										anvisa: currentProd.anvisa,
										categoria: currentProd.categoria,
										categoriaCompleta: currentProd.categoriaCompleta,
										tipoConversao: currentProd.tipoConversao,
										unidadePrincipal: currentProd.unidadePrincipal,
										unidadeSecundaria: currentProd.unidadeSecundaria,
										unidadeSec: currentProd.unidadeSec,
										precoFabricaCx: (currentMalha[i].pf).toFixed(6),
										reservationDate: this.getPrevisionDate(this.mapProductToInventoryList[currentMalha[i].cnpj + '_' + productCode]),
										reservationQuantity: this.getPrevisionQuantity(this.mapProductToInventoryList[currentMalha[i].cnpj + '_' + productCode]),

										precoFabricaUn: isMult ? ((currentMalha[i].pf / currentProd.fatorConversao).toFixed(6)) : ((currentMalha[i].pf * currentProd.fatorConversao).toFixed(6)),
										precoTabelaCx: (currentProd.precoTabelaCx).toFixed(6),
										precoMalha: (currentProd.precoMalha).toFixed(6),
										precoTabelaUn: isMult ? ((currentProd.precoTabelaCx / currentProd.fatorConversao).toFixed(6)) : ((currentProd.precoTabelaCx * currentProd.fatorConversao).toFixed(6)),
										temperatura: currentProd.temperatura,
										ean: result[0].ean,
										adicionado: false,
										SequenciaOC: currentProd.SequenciaOC != undefined ? currentProd.SequenciaOC : '',
										loteSelecionado: false,
										possuiLoteSelecionado: false,
										foraMalha: currentMalha[i].foramalha,
										foraMalhaPesquisado: getFromMalha,
										buscaForaMalha: false,
										index: currentMalha[i].prioridade,
										cds: currentMalha[i].filial,
										cnpjCd: currentMalha[i].cnpj,
										lote: "",
										estoque: hasSaldo ? currentMalha[i].saldo : 0,
										estoqueUn: hasSaldo ? isMult ? currentMalha[i].saldo * currentProd.fatorConversao : Number(currentMalha[i].saldo / currentProd.fatorConversao).toFixed(2) : 0 * currentProd.fatorConversao,
										un: "UN",
										quantidade: filteredCd != undefined ? filteredCd.quantidade : 0,
										quantidadeScreen: filteredCd != undefined ? Number(filteredCd.quantidade).toFixed(4) : 0,
										quantidadeCx: filteredCd != undefined ? filteredCd.quantidadeCx : 0,
										quantidadeCxFixo: 0,
										unitario:  filteredCd != undefined ? Number(filteredCd.precoFabricaUn).toFixed(6) : isMult ? (currentProd.precoTabelaCx / currentProd.fatorConversao).toFixed(6) : (currentProd.precoTabelaCx * currentProd.fatorConversao).toFixed(6),
										caixa: filteredCd != undefined ? Number(filteredCd.precoFabricaCx).toFixed(6) : (currentProd.precoTabelaCx).toFixed(6),
										inicialUnitario: isMult ? (currentProd.precoTabelaCx / currentProd.fatorConversao).toFixed(6) : (currentProd.precoTabelaCx * currentProd.fatorConversao).toFixed(6),
										inicialCaixa: (currentProd.precoTabelaCx).toFixed(6),
										precoSugerido: null,
										range: currentMalha[i].range,
										rangeStringify: JSON.stringify(currentMalha[i].range),
										conversaoUnidadeCx: currentProd.fatorConversao != undefined ? (currentProd.fatorConversao > 0 ? currentProd.fatorConversao : 1) : 1,
										desconto: filteredCd != undefined ? filteredCd.desconto : 0,
										valorTotalUnd: 0,
										valorTotalCx: 0,
										valorTotal: filteredCd != undefined ? filteredCd.valorTotalCx : 0,
										custoDif: 0.3,
										aliquota: currentMalha[i].aliquota,
										custoCx: (currentMalha[i].custo != null && currentMalha[i].custo != undefined) ? currentMalha[i].custo : 10,
										margem: currentProd.margem,
										margemAlvo: currentProd.margemAlvo,
										margemTotalCd: 0,
										margemAlvoTotalCd: 0,
										score: currentProd.score,
										scoreBU: 0,
										scoreMix: 0,
										valorCampanha: currentProd.showBadgeCampanhaCD ? currentProd.precoTabelaCx : currentProd.precoCNPJCampanha ? Number(currentMalha[i].preco) : campaignPrice,
										precoCNPJShelflife: currentProd.precoCNPJShelflife,
										precoProdShelfLife: currentProd.precoProdShelfLife,
										precoBadgeCampanhaProduto : this.badgeTextoCampanha ? hasPrecoCampaign ? 'Preço mínimo: ' + this.getCurrencyFormat(this.badgeTextoCampanha) : this.badgeTextoCampanha : null,
										validadeMinima: hasShelflifeCNPJ ? 'Shelf Life' : currentProd.validadeMinima,
										dataBadgeCampanhaVendCNPJ: currentProd.dataBadgeCampanhaVendedor,
										valorBloqueado		   : currentProd.valorBloqueado,
										valorZerado			  : currentMalha[i].preco == 0 ? true : blockShelfLife,
										blockShelfLife		   : currentMalha[i].preco == 0 ? true : false,
										verMargem				: currentProd.verMargem,
										laboratorio			  : currentMalha[i].laboratorio != undefined ? currentMalha[i].laboratorio : null,
										bloqRegionalizacao	   : currentMalha[i].BloqRegionalizacao != undefined ? currentMalha[i].BloqRegionalizacao : false,
										tipoIntegradora		  : currentMalha[i].TipoIntegradora != undefined ? currentMalha[i].TipoIntegradora : null,
										showBadgeOL			  : currentProd.showBadgeOL != undefined ? currentProd.showBadgeOL : false,
										showBadgeReservadoCNPJ   : hasReserve,
										showBadgeReservado   	 : currentProd.showBadgeReservado,
										dataBadgeReservadoCNPJ   : 'Reserva disponível: ' + resQtd,
										showBadgeCampanha		: boolBadgeCampanha,
										showBadgeCampanhaCD	  : (boolBadgeCampanha && (currentProd.dataBadgeCampanha == null || currentProd.dataBadgeCampanha.includes("null") || currentProd.dataBadgeCampanha.includes(currentMalha[i].cd))),
										showBadgeCampanhaVendedor : boolBadgeCampanhaVend,
										showBadgeCampanhaVendedorCD : (boolBadgeCampanhaVend && (currentProd.dataBadgeCampanhaVendCNPJ == null || currentProd.dataBadgeCampanhaVendCNPJ.includes("null") || currentProd.dataBadgeCampanhaVendCNPJ.includes(currentMalha[i].cnpj))),
										showBadgeConsignado	  : currentProd.showBadgeConsignado != undefined ? currentProd.showBadgeConsignado : false,
										showBadgeAcordoComercial : currentProd.showBadgeAcordoComercial != undefined ? currentProd.showBadgeAcordoComercial : false,
										showBadgeshelflife	   : currentProd.showBadgeshelflife != undefined ? currentProd.showBadgeshelflife : false,
										showBadgeShelflifeCNPJ   : hasShelflifeCNPJ,
										showBadgeShelflifeCNPJAux: hasShelflifeCNPJ
										,pf : currentMalha[i].pf,
										uniSecundaria: false,
										observacaoComercial: obsComer,
										unidadeMedida: uniConversao
									});
								}
							}
						}
					} else {
						this.swalErroMalha();
						return;
					}
					if (this.savedCdData[productCode] != undefined) {
						for (var i = 0; i < this.savedCdData[productCode].length ; i++) {
							if (this.savedCdData[productCode][i].foraMalha == false) {
								this.cdList.push(this.savedCdData[productCode][i]);
							}
						}
					}
					if (currentProductHasForaMalha) {
						this.hasMalha = true;
						this.isForaMalha = false;
					} else {
						this.hasMalha = false;
					}
					if (this.lastProduct != productId) {
						this.allCds = true;
					}

					if (getFromMalha) {
						this.getForaMalha(productCode);
					}

					this.calcScoreApi(productCode);

					this.refreshCdWithCart(true);
					this.lastProduct = productId;
					if (this.distributeQuantity) {
						this.distributeValues(productCode, event);
						this.distributeQuantity = false;
					}
					
				}).catch(error  =>  {
					this.isLoading  =  false;
					console.log(error);
					swal('Erro',  `Erro  ao  buscar  a  malha.  Verifique  com  o  administrador!`,  'error');
				})
		} else if (this.currentSelectedProdCode != productCode) {
			check = false;
			this.showHistoric = false;
			let currentProductHasForaMalha = false;
			this.currentSelectedProdCode = productCode;
			this.cdListClone = [];
			this.cdList = [];

			this.isForaMalha = false;

			for (var i = 0; i < this.savedCdData[productCode].length; i++) {				
				if (this.savedCdData[productCode][i].foraMalha) {
					currentProductHasForaMalha = true;
				}
				   
				if (this.savedCdData[productCode][i].buscaForaMalha) {
					this.isForaMalha = true;
				}
			}
			
			if (currentProductHasForaMalha) {
				this.hasMalha = true;
			} else {
				this.hasMalha = false;
			}

			for (var i = 0; i < this.savedCdData[productCode].length; i++) {
				if (this.isForaMalha) {
					this.cdList.push(this.savedCdData[productCode][i]);
				} else {
					if (this.savedCdData[productCode][i].foraMalha == false) {
						this.cdList.push(this.savedCdData[productCode][i]);
					}
				}
			}			

			if (this.lastProduct != productId) {
				this.allCds = true;
			}
			this.refreshCdWithCart(true);
			this.lastProduct = productId;
			
			if (this.distributeQuantity) {
				this.distributeValues(productCode, event);
				this.distributeQuantity = false;
			}
		}

		if (this.distributeQuantity && check) {
			this.distributeValues(productCode, event);
		}
		
		this.prodList.forEach(prod =>{
			prod.show = prod.id == productId ? true : false;
		});
	}

	showSellerRule(event) {
		let prodCode = event.currentTarget.dataset.prodCode;
		let currProd = this.getCurrentProduct(prodCode);
		swal({
			title: "Regra da campanha",
			text: `Regra: ${currProd.regraCampanha}`,
			buttons: ["Ok", "Ir para campanha"]
		})
			.then((willNavigate) => {
				if (willNavigate) {
					this[NavigationMixin.Navigate]({
						type: 'standard__recordPage',
						attributes: {
							recordId: currProd.campanhaId,
							actionName: 'view'
						}
					});
				}
			});
	}

	swalErroMalha() {
		swal('Erro', `Consulta da malha indisponível`, 'error');
	}

	removeForaMalha(event) {		
		let productCode = event.currentTarget.dataset.productCode;
		this.isForaMalha = !this.isForaMalha;

		this.cdList.forEach(cd => {
			if (cd.prodCode == productCode) {
				cd.buscaForaMalha = false;
			}
		})

		this.cdList = this.cdList.filter(cd => cd.foraMalha != true);
		
		this.calcScoreApi(productCode);
		this.refreshCdWithCart(true);
	}

	getForaMalha(productCode) {

		this.isForaMalha = !this.isForaMalha;
		
		this.calcScoreObj = [];
		
		this.cdList.forEach(cd => {
			if (cd.prodCode == productCode) {
				cd.buscaForaMalha = true;
			}
		})
		
		if (this.savedCdData[productCode] != undefined) {
			for (var i = 0; i < this.savedCdData[productCode].length ; i++) {
				if (this.savedCdData[productCode][i].foraMalha) {
					this.cdList.push(this.savedCdData[productCode][i]);
				}

				if (this.savedCdData[productCode][i].quantidadeCx == 0) {
					this.calcScoreObj.push({
						cdId: this.savedCdData[productCode][i].cnpjCd,
						productBu: (this.savedCdData[productCode][i].categoria == '' || this.savedCdData[productCode][i].categoria == undefined) ? 'SEM BU' : this.savedCdData[productCode][i].categoria,
						productCode: productCode,
						cost: (this.savedCdData[productCode][i].custoCx != null && this.savedCdData[productCode][i].custoCx != undefined) ? this.savedCdData[productCode][i].custoCx : 10,
						quantity: this.savedCdData[productCode][i].quantidadeCx,
						unitPrice: Number(this.savedCdData[productCode][i].precoTabelaCx).toFixed(6),
						listPrice: Number(this.savedCdData[productCode][i].precoTabelaCx).toFixed(6),
						taxPercent: this.savedCdData[productCode][i].aliquota,
						isContract: this.savedCdData[productCode][i].valorBloqueado != undefined ? this.savedCdData[productCode][i].valorBloqueado : false,
						SequenciaOC: this.savedCdData[productCode][i].SequenciaOC != undefined ? this.savedCdData[productCode][i].SequenciaOC : '',
						isCampaign: this.savedCdData[productCode][i].valorCampanha == undefined ? false : (this.savedCdData[productCode][i].valorCampanha == 0 && !this.savedCdData[productCode][i].showBadgeShelflifeCNPJ ) ? false : true,
						isLab: this.savedCdData[productCode][i].laboratorio == undefined ? false : true
					});
				}
				
			}
		}

		this.calcScoreApi(productCode);
		this.refreshCdWithCart(true);
	}

	getCurrentProduct(productCode) {
		for (var i = 0; i < this.prodList.length; i++) {
			if (this.mockedProdList[this.prodList[i].code] != undefined) {
				if (this.mockedProdList[this.prodList[i].code].code == productCode) {
					return this.mockedProdList[this.prodList[i].code];
				}
			}
		}
	}

	getPrevisionDate(estoqueList) {
		if(estoqueList != null && estoqueList != undefined) {
			if(estoqueList.size > 1) {
				return estoqueList[0].PrevisaoEntrada__c;
			} else {
				return estoqueList[0].PrevisaoEntrada__c;
			}
		} else {
			return '';
		}
	}

	getPrevisionQuantity(estoqueList) {
		if(estoqueList != null && estoqueList != undefined) {
			if(estoqueList.size > 1) {
				return estoqueList[0].PrevisaoEntrada__c;
			} else {
				let quantity = 0;
				estoqueList.forEach(element => {
					quantity = Number(quantity) + Number(element.QuantidadePrevista__c);
				});
				return quantity;
			}
		} else {
			return '';
		}
	}

	getScoreCalcApi(selectedCd) {
		calcProducts({ clListString: JSON.stringify(this.calcScoreObj) })
			.then(result => {
				let resultObj = JSON.parse(result);
				for (var i = 0; i < resultObj.length; i++) {
					this.cdList.find(cd => cd.cdId == resultObj[i].cdId + '_' + resultObj[i].productCode).margem = resultObj[i].margem.toFixed(2);
					this.cdList.find(cd => cd.cdId == resultObj[i].cdId + '_' + resultObj[i].productCode).margemAlvo = (resultObj[i].margemAlvo).toFixed(2);
					if ((selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ)) {
						if (selectedCd.laboratorio || selectedCd.showBadgeCampanhaCD) {
							this.cdList.find(cd => cd.cdId == resultObj[i].cdId + '_' + resultObj[i].productCode).score = 100.00;
						} else {
							this.cdList.find(cd => cd.cdId == resultObj[i].cdId + '_' + resultObj[i].productCode).score = resultObj[i].scoreFinal.toFixed(2);	
						}
					} else {
						this.cdList.find(cd => cd.cdId == resultObj[i].cdId + '_' + resultObj[i].productCode).score = 100.00;
					}
				}

				this.cdList.forEach(cd => { 
					this.orderList.find(cdFromCart => {
						if (cd.id == cdFromCart.id) {
							cdFromCart.quantidade	   = cd.quantidade;
							cdFromCart.quantidadeScreen = Number(cd.quantidade).toFixed(4);
							cdFromCart.quantidadeCx	 = cd.quantidadeCx;
							cdFromCart.desconto		 = cd.desconto;
							cdFromCart.margem		   = cd.margem;
							cdFromCart.verMargem		= cd.verMargem;
							cdFromCart.margemAlvo	   = cd.margemAlvo;
							cdFromCart.caixa			= cd.caixa;
							cdFromCart.unitario		 = cd.unitario;
							cdFromCart.valorTotal	   = cd.valorTotal;
							cdFromCart.score			= cd.score;
							cdFromCart.validadeMinima   = cd.validadeMinima;
							cdFromCart.observacaoComercial   = cd.observacaoComercial;
						}
					});
					if (cd.id == selectedCd.id) {
						selectedCd.quantidade	   = cd.quantidade;
						selectedCd.quantidadeScreen = Number(cd.quantidade).toFixed(4);
						selectedCd.quantidadeCx	 = cd.quantidadeCx;
						selectedCd.desconto		 = cd.desconto;
						selectedCd.margem		   = cd.margem;
						selectedCd.verMargem		= cd.verMargem;
						selectedCd.margemAlvo	   = cd.margemAlvo;
						selectedCd.caixa			= cd.caixa;
						selectedCd.unitario		 = cd.unitario;
						selectedCd.valorTotal	   = cd.valorTotal;
						selectedCd.score			= cd.score;
						selectedCd.validadeMinima   = cd.validadeMinima;
						selectedCd.observacaoComercial   = cd.observacaoComercial;
					}

				});

				this.refreshCdWithCart(false);  
				this.calcTotalOrderPrice();
				this.calcValorTotal(selectedCd);
		
			}).catch(error => {
				console.log('calcProducts: entrou no erro!');
				console.log(error);
				this.refreshCdWithCart(false);
				this.calcRefresh(selectedCd);
			});
	}

	calcScoreApi(productCode) {

		calcProducts({ clListString: JSON.stringify(this.calcScoreObj) })
			.then(result => {
				this.isLoading = false;
				let resultObj = JSON.parse(result);


				for (var i = 0; i < resultObj.length; i++) {

					let calcCdId = resultObj[i].cdId + '_' + resultObj[i].productCode;

					this.cdList.find(cd => cd.cdId == calcCdId).margem = Number(resultObj[i].margem).toFixed(2);
					this.cdList.find(cd => cd.cdId == calcCdId).margemAlvo = Number(resultObj[i].margemAlvo).toFixed(2);
					if ((this.cdList.find(cd => cd.cdId == calcCdId).valorCampanha == 0 && !this.cdList.find(cd => cd.cdId == calcCdId).showBadgeShelflifeCNPJ)) {
						if (this.cdList.find(cd => cd.cdId == calcCdId).laboratorio) {
							this.cdList.find(cd => cd.cdId == calcCdId).score = 100.00;
						} else {
							this.cdList.find(cd => cd.cdId == calcCdId).score = Number(resultObj[i].scoreFinal).toFixed(2);
						}
					} else {
						this.cdList.find(cd => cd.cdId == calcCdId).score = 100.00;
					}
				}

				this.refreshCdWithCart(true);
			}).catch(error => {
				this.isLoading = false;
				console.log('calcProducts: entrou no erro!');
				console.log(error);
			});
	}

	getAllCurrentProductPrice() {
		this.isLoadingScore = true;
		let prodList = [];

		let cdObj = {};

		let cdObjIndex = {};

		this.orderList.forEach((cd, index) => {
			if (cd.hasNewPaymentCondition || cd.isInCampaign || cd.showBadgeCampanhaCD) {
				if (!prodList.includes(cd.prodCode)) {
					prodList.push(cd.prodCode);
				}
				cdObj[cd.prodCode + '_' + cd.cnpjCd] = {
					cnpjCd: cd.cnpjCd,
					qtd: cd.quantidadeCx,
					nome: cd.nome,
					showBadgeCampanhaCD: cd.showBadgeCampanhaCD
				}
				cdObjIndex[cd.prodCode + '_' + cd.cnpjCd] = index;
			}
		})

		const listProductNotFound = [];
		
		if (prodList.length > 0) {
			this.disableButtons();
			swal('Aviso!', 'Checando preços dos itens do carrinho.', 'warning');
			getMalha({ clienteCGC: this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''), productCode: prodList.join(','), calcMargem: true, pricebookExternalId: this.tabelaPrecoExternalId, condPagamento: this.condicaoPagamento, isForaMalha: true })
				.then(result => {
					this.enableButtons();
					if (result != null) {
						if (JSON.stringify(result[0]) == '{}') {
							this.swalErroMalha();
						} else if (result[0]['code'] != undefined) {
							this.swalErroMalha();
						} else if (result[0]['msgerro'] != undefined) {
							swal('Aviso ERP', `${result[0]['msgerro']}`, 'warning');
						} else if (result[0]['msgErro'] != undefined) {
							swal('Aviso ERP', `${result[0]['msgErro']}`, 'warning');
						} else {
							result.forEach(item => {
								if (item.cds != undefined) {
									item.cds.forEach(cdItem => {
										const product = cdObj[item.codprotheus + '_' + cdItem.cnpj];
										if (product != undefined) {
											const cd = item.cds.find(cd => cd.cnpj == product.cnpjCd);
											let selectedCd = this.orderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]];
											selectedCd.precoMalha = cd.preco;
											selectedCd.inicialCaixa = cd.preco;
											selectedCd.aliquota = cd.aliquota;
											if (product.showBadgeCampanhaCD) {
												selectedCd.valorCampanha = cd.preco;
												selectedCd.caixa = cd.preco;
												if (!selectedCd.hasSecUnit) {
													selectedCd.unitario = cd.preco;
												}
												this.calcValorTotal(selectedCd);
											}
										}
									});
								} else {
									listProductNotFound.push(item.msgerro);
								}
							})
						}
					}
	
					this.orderListFiltered = this.orderList;
					this.isLoadingScore = false;
					this.enableButtons();
					if (listProductNotFound.length > 0) {
						swal('Aviso!', `Erro na busca de preço: ${listProductNotFound.join(' ')}`, 'warning');
						return;
					} else {
						this.refreshCdScoreCalc();
						return;
					}
				}).catch(error => {
					this.isLoadingScore = false;
					swal("Ops!", "Erro ao realizar busca de preços! Verifique com o administrador.", "error");
					this.enableButtons();
				})
		} else {
			this.isLoadingScore = false;
			this.enableButtons();
			this.refreshCdScoreCalc();
		}
	}

	refreshCdScoreCalc() {
		this.calcAllScoreObj = [];

		this.hasOnlyCampaign = true;
		this.hasOnlyLab = true;
		this.hasOnlyContract = true;
		this.orderList.forEach(cd => {
			if (this.hasOnlyLab && !cd.laboratorio) {
				this.hasOnlyLab = false;
			}
			if (this.hasOnlyCampaign && cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.showBadgeCampanhaCD) {
				this.hasOnlyCampaign = false;
			}
			if (this.hasOnlyContract && !cd.valorBloqueado) {
				this.hasOnlyContract = false;
			}
			if (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.valorBloqueado && !cd.laboratorio && !cd.showBadgeCampanhaCD) {
				this.calcAllScoreObj.push({
					cdId: cd.cnpjCd,
					productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
					productCode: cd.prodCode,
					cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
					quantity: cd.quantidadeCx,
					verMargem: cd.verMargem,
					unitPrice: Number(cd.caixa).toFixed(6),
					listPrice: Number(cd.inicialCaixa).toFixed(6),
					taxPercent: cd.aliquota,
					isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
					SequenciaOC: cd.SequenciaOC != undefined ? cd.SequenciaOC : '',
					isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? cd.showBadgeCampanhaCD : true,
					isLab: cd.laboratorio == undefined ? false : true,
					observacaoComercial: cd.observacaoComercial
				});
			}
		});
		if (this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab) {
			this.calcAllScoreObj = [];
			this.orderList.forEach(cd => {
				this.calcAllScoreObj.push({
					cdId: cd.cnpjCd,
					productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
					productCode: cd.prodCode,
					cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
					quantity: cd.quantidadeCx,
					unitPrice: Number(cd.caixa).toFixed(6),
					listPrice: Number(cd.inicialCaixa).toFixed(6),
					taxPercent: cd.aliquota,
					isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
					isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? cd.showBadgeCampanhaCD : true,
					isLab: cd.laboratorio == undefined ? false : true,
					observacaoComercial: cd.observacaoComercial
				});
			});
		}

		calcAllProducts({ clListString: JSON.stringify(this.calcAllScoreObj) })
			.then(result => {
				let resultJson = JSON.parse(result);

				this.calcAllScoreObj.forEach(calcObj => {					
					for (var i = 0; i < resultJson['cdMap'][calcObj.cdId].length; i++) {
						if ((calcObj.cdId + '_' + calcObj.productCode) == (resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode)) {
							let index = this.orderList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
							let indexCdClone = this.orderListFiltered.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
							let indexFilteredList = this.orderCdList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId);

							let maxScore = calcObj.isCampaign || calcObj.isContract || calcObj.isLab ? true : false;
							const scoreBU		   = maxScore ? 100.00 : Number(resultJson['results'][calcObj.productBu]['scoreFinal'].toFixed(2));
							const scoreMix		  = maxScore ? 100.00 : Number(resultJson['results'][calcObj.productBu]['scoreMix'].toFixed(2));
							const scoreItem		 = maxScore ? 100.00 : Number(resultJson['cdProdMap'][calcObj.cdId+'_'+calcObj.productCode]['scoreFinal'].toFixed(2));
							const margemTotalCd	 = Number(resultJson['results'][calcObj.cdId]['scoreDenominator'].toFixed(2));
							const margemAlvoTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreNumerador'].toFixed(2));
							const scoreCd		   = maxScore ? 100.00 : Number(resultJson['results'][calcObj.cdId]['scoreFinal'].toFixed(2));

							calcObj.observacaoComercial = resultJson['cdMap'][calcObj.cdId][i].observacaoComercial;

							this.orderCdList[indexFilteredList] = {
								...this.orderCdList[indexFilteredList],
								margem: margemTotalCd,
								margemAlvo: margemAlvoTotalCd,
								scoreCd: scoreCd
							}
							
							this.orderList[index] = {
								...this.orderList[index],
								score: scoreCd,
								scoreBU,
								scoreMix,
								scoreItem,
								margemTotalCd,
								margemAlvoTotalCd
							}

							this.orderListFiltered[indexCdClone] = {
								...this.orderListFiltered[indexCdClone],
								score: scoreCd,
								scoreBU,
								scoreMix,
								scoreItem,
								margemTotalCd,
								margemAlvoTotalCd
							}
						}
					}
				})
				if (!this.hasOnlyCampaign && !this.hasOnlyContract && !this.hasOnlyLab) {
					this.cdList.forEach(item => {
						if (item.valorCampanha != 0 || item.showBadgeShelflifeCNPJ || item.valorBloqueado || item.showBadgeCampanhaCD) {
							item.scoreBU   = 100;
							item.scoreMix  = 100;
							item.scoreItem = 100;
						}
					})
				}
				
				if (resultJson['results']['Order'] != undefined && !this.hasOnlyCampaign && !this.hasOnlyContract) {
					this.margemAtualGeral = Number(resultJson['results']['Order']['scoreDenominator']).toFixed(2) + '%';
					this.margemAtualAlvo  = Number(resultJson['results']['Order']['scoreNumerador']).toFixed(2) + '%';
					this.scoreFinalGeral  = this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab ? 100.00 + '%' : Number(resultJson['results']['Order']['scoreFinal']).toFixed(2) + '%';
				} else if ((this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab) && this.orderList.length > 0) {
					this.margemAtualGeral = 100.00 + '%';
					this.margemAtualAlvo  = 100.00 + '%';
					this.scoreFinalGeral  = 100.00 + '%';
				} else {
					this.margemAtualGeral = '';
					this.margemAtualAlvo = '';
					this.scoreFinalGeral = '';
				}
			}).catch(error => {
				this.refreshCdWithCart(false);
			});
	}
	removeAllFilters(){

		let divsCds = this.template.querySelectorAll(`[data-div-name="divCd"]`);

		divsCds.forEach(div =>{
			div.classList.remove("cd-card-selected");
			div.classList.add("cd-card-unselected");
		});

		this.filterLst = [];  
		this.filterListClone = []; 
		this.orderListFiltered = this.orderList;
	}
	removeSelectedFilter(event) {
		let cdValue = event.currentTarget.dataset.value; 

		let divCd = this.template.querySelector(`[data-div-cds="${cdValue}"]`); 
		divCd.classList.add("cd-card-unselected"); 
		divCd.classList.remove("cd-card-selected"); 

		this.filterLst = this.filterLst.filter(cd => cd !== cdValue); 

		if (this.filterLst.length == 0) {
			this.removeAllFilters();
		}else{
			this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds)); 
		}
	}

	handleCdFilter(event){
		let dataDivCds = event.currentTarget.dataset.divCds;
		if (this.filterLst.includes(dataDivCds)){
			return;
		}
		this.filterLst.push(dataDivCds);
		let divCd = this.template.querySelector(`[data-div-cds="${dataDivCds}"]`);
		divCd.classList.add("cd-card-selected");
		divCd.classList.remove("cd-card-unselected");
		this.orderListFiltered = this.orderList.filter(prod => this.filterLst.includes(prod.cds));
	}
	
	handleCd(){

		if (!this.allCds) {
			this.selectedRadioCd();
			return;
		}

		this.orderList.forEach(cdFromCart => {
			this.cdList.find(cd => {
				if (cd.id == cdFromCart.id) {
					cd.adicionado = true;
				}
			});
		});

		this.orderList.forEach(cdFromCart => {
			this.cdList.find(cd => {
				if (cdFromCart.id.includes(cd.id) && cdFromCart.loteSelecionado == true) {
					cd.loteSelecionado = true;
					cd.possuiLoteSelecionado = true;
					cd.quantidadeCxShelfLife = cdFromCart.quantidadeCxShelfLife;
				}
			});
		});


		this.current = 0;
		this.cdListClone = [];

		if (this.cdList.length > 0) {
			this.cdList.forEach(cd =>{
				if (this.cdListClone.length < 3){
					this.cdListClone.push(cd);
				}
			});
		}

	}

	handleSelectedRadioCd(event){
		this.current = 0;
		this.selected = event.target.value;

		if (this.selected == 'Com saldo') {
			this.allCds = false;
			this.cdListClone = [];
			this.cdList.forEach(cd =>{
				if (cd.estoque != 0){
					this.cdListClone.push(cd);
				}
			});
		} else {
			this.allCds = true;
			this.handleCd();
		}
	}

	
	selectedRadioCd(){
		this.current = 0;

		if (this.selected == 'Com saldo') {
			this.allCds = false;
			this.cdListClone = [];
			this.cdList.forEach(cd =>{
				if (cd.estoque != 0){
					this.cdListClone.push(cd);
				}
			});
			this.orderList.forEach(cdFromCart => {
				this.cdList.find(cd => {
					if (cd.id == cdFromCart.id) {
						cd.adicionado = true;
					}
				});
			});

			this.orderList.forEach(cdFromCart => {
				this.cdList.find(cd => {
					if (cdFromCart.id.includes(cd.id) && cdFromCart.loteSelecionado == true) {
						cd.loteSelecionado = true;
						cd.possuiLoteSelecionado = true;
						cd.quantidadeCxShelfLife = cdFromCart.quantidadeCxShelfLife;
					}
				});
			});

			let comSaldo = 'Comsaldo';
			this.template.querySelector(`[data-id="${comSaldo}"]`).checked = true;
		} else {
			this.allCds = true;
			this.handleCd();
		}
	}
	
	previousCd(){
		if (this.current <= 0){
			return;
		}
		this.current--;
		this.cdListClone = this.cdList.slice(this.current,this.current+3);
	}

	nextCd(){
		if (this.selected == 'Com saldo'){
			if (this.current +2 >= this.cdList.length - 2){
				return;
			}
		}
		if (this.current +2 >= this.cdList.length - 1){
			return;
		}
		
		this.current++;
		this.cdListClone = this.cdList.slice(this.current,this.current+3);
	}

	previousOrderCd(){
		if (this.currentCd <= 0){
			return;
		}
		this.currentCd--;
		this.cdListClone = this.cdList.slice(this.currentCd,this.currentCd+3);
	}

	nextOrderCd(){
		if (this.currentCd +2 >= this.cdList.length - 1){
				return;
		}
		
		this.currentCd++;
		this.cdListClone = this.cdList.slice(this.currentCd,this.currentCd+3);
	}

	onSearchByActivePrinciple(event) {
		this.searchGenericValue = event.currentTarget.dataset.productAtivo;
		this.valorBusca = event.currentTarget.dataset.productAtivo;
		this.isLoadingProducts = true;
		this.handleFilterSearchProd();
	}

	onChangeSearchProductNome(event) {
		this.searchGenericValue = event.target.value;
		this.valorBusca = event.target.value;
		if (this.searchGenericValue == '') {
			this.isLoadingProducts = true;
			this.handleFilterSearchProd();
		}
	}

	onKeyUpSearchProductNome(event) {
		if (event.key === 'Enter') {
			this.isLoadingProducts = true;
			this.handleFilterSearchProd();
		}
	}

	onChangeSearchProductByFabricator(event) {
		this.searchFabricanteValue = event.target.value;
		if (this.searchFabricanteValue == '') {
			this.isLoadingProducts = true;
			this.handleFilterSearchProd();
		}
	}

	onKeyUpSearchProductByFabricator(event) {
		if (event.key === 'Enter') {
			this.isLoadingProducts = true;
			this.handleFilterSearchProd();
		}
	}

	filterListMethod() {
		this.prodFilterList = [];
		const that = this;
		this.prodList.forEach(item => {
			if (that.convertSpecialCharacters(item.fabricante).includes(that.convertSpecialCharacters(''))){
				if(that.convertSpecialCharacters(item.code).includes(that.productInput) || 
				   that.convertSpecialCharacters(item.nome).includes(that.productInput) || 
				   that.convertSpecialCharacters(item.principioAtivo).includes(that.productInput)){
					
						that.prodFilterList.push(item);
				}
			}
		});
	}

	removeOrderedProduct(event){
		let prodId = event.target.value;
		let productCode = event.currentTarget.dataset.productCode;
		let productCard = event.currentTarget.dataset.productCard;

		this.currentSelectedProdCode = productCode;
		this.cdList = [];
		if (this.savedCdData[productCode] != undefined) {
			for (var i = 0; i < this.savedCdData[productCode].length; i++) {
				this.cdList.push(this.savedCdData[productCode][i]);
			}
		} else {
			for (var i = 0; i < this.orderList.length; i++) {
				if (this.orderList[i].prodCode != undefined) {
					this.cdList.push(this.orderList[i]);
				}
			}
		}

		this.refreshCdWithCart(false);
		if (!productCard) {
			this.prodFilterList.forEach(prod => {
				prod.show = false;
			});
		}
		
		let selectedCd = this.cdList.find(cd => cd.id == prodId);
 
		if (selectedCd == undefined) {
			selectedCd = this.orderList.find(cd => cd.id == prodId);
		}

		swal({
			title: "Remover item do carrinho?",
			text: "Caso remova será recalculado os valores no pré-carrinho!",
			icon: "warning",
			buttons: ["Cancelar", "Remover"],
			dangerMode: true,
		})
			.then((willDelete) => {
				if (willDelete) {
					let removedCd = this.orderList.filter(prod => prod.id === prodId).cnpjCd;
					this.orderListFiltered = this.orderList.filter(prod => prod.id !== prodId);
					this.orderList = this.orderList.filter(prod => prod.id !== prodId);
					let cdsToTotalValueRefresh = [];
					this.orderCdList = [];
					let isCampaignCd = [];

					let splitFreight = [];
					let hasSplitFreight = false;
					let splitFreightHelp = [];
					let i = 0;
					if (this.fretesPorCd) {
						splitFreight = this.fretesPorCd.split(',');
						hasSplitFreight = true;
					}
					let splitHelp = [];

					this.orderList.forEach(cd => {
						if (cdsToTotalValueRefresh[cd.cds] == undefined) { 
							cdsToTotalValueRefresh[cd.cds] = Number(cd.valorTotal);
							if (this.hasOnlyCampaign || this.hasOnlyContract) {
								this.orderCdList.push({
									id: cd.id,
									cdId: cd.cnpjCd,
									prodId: cd.prodId,
									cds: cd.cds,
									valorTotal: cd.valorTotal,
									margem: cd.margem,
									margemAlvo: cd.margemAlvo,
									scoreCd: 100 
								});
							} else {
								this.orderCdList.push({
									id: cd.id,
									cdId: cd.cnpjCd,
									prodId: cd.prodId,
									cds: cd.cds,
									valorTotal: cd.valorTotal,
									margem: cd.margem,
									margemAlvo: cd.margemAlvo,
									scoreCd: (((cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) && !cd.valorBloqueado)) ? (cd.laboratorio || cd.showBadgeCampanhaCD) ? 100 : cd.score : 100
								});
								if (cd.valorCampanha != 0 || cd.showBadgeShelflifeCNPJ || cd.valorBloqueado || cd.laboratorio || cd.showBadgeCampanhaCD) {
									isCampaignCd[cd.cds] = true;
								}
							}
							if (hasSplitFreight) {
								splitFreight.forEach(split => {
									let splitFreightTrim = split.trim();
									if (splitHelp[split.trim()] == undefined) {
										splitHelp[split.trim()] = i;
										let splitCdFreight = splitFreightTrim.split(':');
										if (splitCdFreight[0] == cd.cnpjCd && splitCdFreight[0] != removedCd) {
											splitFreightHelp.push(splitFreight[i].trim());
										}
									}
								});
							}
							i++;
						} else {
							if (isCampaignCd[cd.cds] && cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) {
								if (cd.laboratorio || cd.showBadgeCampanhaCD) {
									this.orderCdList.find(cdFilter => cdFilter.cds == cd.cds).scoreCd = 100;
								} else {
									this.orderCdList.find(cdFilter => cdFilter.cds == cd.cds).scoreCd = cd.score;
								}
							}
							cdsToTotalValueRefresh[cd.cds] += Number(cd.valorTotal);
							this.orderCdList.find(cdFilter => cdFilter.cds == cd.cds).valorTotal = cdsToTotalValueRefresh[cd.cds];
						}
					});
					this.fretesPorCd = splitFreightHelp.length != 0 ? splitFreightHelp.join(',') : null;

					let cdValue =  this.orderList.filter(cd => this.filterLst.includes(cd.cds)); 
					this.filterLst = [];
					cdValue.forEach(cd => {
							this.filterLst.push(
								cd.cds
							);
					})
					if(this.filterLst.length > 0){
						this.orderListFiltered = [];
						this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
					}
					this.calcTotalOrderPrice();
					selectedCd.quantidade = 0;
					selectedCd.quantidadeScreen = 0;
					selectedCd.quantidadeCx = 0;
					selectedCd.desconto = 0;
					selectedCd.unitario = Number(selectedCd.desconto > 0 ? selectedCd.tipoConversao == 'M' ? (selectedCd.inicialUnitario * (1 - selectedCd.desconto / 100)) : (selectedCd.inicialUnitario / (1 - selectedCd.desconto / 100)) : selectedCd.inicialUnitario).toFixed(6);
					selectedCd.caixa = Number(selectedCd.desconto > 0 ? selectedCd.inicialCaixa * (1 - selectedCd.desconto / 100) : selectedCd.inicialCaixa).toFixed(6);
					selectedCd.adicionado = false;
					
					this.calcRefresh(selectedCd);
					
					swal("Poof! Item removido do carrinho!", {
						icon: "success",
					});
					this.refreshCdScoreCalc();
					if (this.orderListFiltered.length > 0) {
						this.keepSavingOrEditing();
					}
				} else {
				}
			});

		this.calcTotalOrderPrice();
	}

	handleSaveCd(event){
		let selectedCd = event.target.value;
		let notSave = event.target.notSave;
		if (selectedCd.quantidadeCx <= 0) {
			swal("Quantidade do produto adicionado deve ser maior que 0!");
			return;
		} else if (selectedCd.quantidadeCx % 1 != 0) {			
			swal("Aviso!", 'Favor verificar quantidade principal do CD, deve ser um valor inteiro!');
			return;
		} else if (selectedCd.valorCampanha != 0 && selectedCd.caixa < selectedCd.valorCampanha) {			
			swal("Aviso!", 'Valor inserido no produto é menor que o valor da campanha!');
			return;
		}
		if(selectedCd.categoria == 'R' || selectedCd.categoria == 'G' ){
			if(selectedCd.pf != undefined && selectedCd.pf != 0){
				if(selectedCd.pf < selectedCd.caixa){
					swal("Aviso!", 'Valor inserido no produto é maior que o preço fixo!');
					return;
				} 
			}else{
				if(selectedCd.pf == 0 ){
					swal("Aviso!",'Preço PF não esta cadastrado, acionar área responsável');
					return;
				}
			}
		}

		if (!this.isProductInserted(selectedCd) && selectedCd.quantidade != 0) {
			let index = 0;
			if (this.orderList.length > 0) {
				this.orderList.forEach(item => {
					if (item.indexInsertPosition >= index) {
						index = item.indexInsertPosition + 1;
					}
				})
			}

			selectedCd = {
				...selectedCd,
				SequenciaOC: ' ',
				indexInsertPosition: index
			}
			this.orderList.push(selectedCd);
			this.orderList.forEach(cdFromCart => {
				this.cdList.forEach(cd => {
					if (cd.id == cdFromCart.id && !notSave) {
						cd.adicionado = true;
					}
				});
			});

			if (!notSave) {
				this.keepSavingOrEditing();
			}

			this.refreshCdScoreCalc();

			if (this.objectProdCdList[selectedCd.prodCode] == undefined) {
				this.objectProdCdList[selectedCd.prodCode] = [];
				this.objectProdCdList[selectedCd.prodCode].push(selectedCd);
			} else {
				this.objectProdCdList[selectedCd.prodCode].push(selectedCd);
			}
		} else {

		}

		for (var i = 0; i < this.orderList.length; i++) {
			if (this.orderList[i].id == selectedCd.id) {
				this.orderList[i].observacaoComercial = selectedCd.observacaoComercial;
				this.orderList.forEach(cdFromCart => {
					this.cdList.forEach(cd => {
						if (cd.id == cdFromCart.id) {
							cdFromCart.uniSecundaria = cd.uniSecundaria;
						}
					});
				});
			}
		}

		this.orderListFiltered = this.orderList;
		this.calcTotalOrderPrice();
	}

	handleListSort(event) {
		if (event.target.value == 'Ordem alfabética') {
			this.orderListFiltered.sort((a, b) => (a.nome > b.nome) ? 1 : ((b.nome > a.nome) ? -1 : 0));
		} else {
			this.orderListFiltered.sort((a, b) => (a.indexInsertPosition > b.indexInsertPosition) ? 1 : ((b.indexInsertPosition > a.indexInsertPosition) ? -1 : 0));
		}
	}
	
	get radioSortOptions() {
		return [
			{ label: "Ordem alfabética", value: "Ordem alfabética" },
			{ label: "Ordem de inserção", value: "Ordem de inserção" }
		];
	}

	isProductInserted(selectedCd) {
		for (var i = 0; i < this.orderList.length; i++) { 
			if (this.orderList[i].id == selectedCd.id) {
				return true;
			}
		}
		return false;
	}

	showCheckout(){
		this.showCheckoutModal = !this.showCheckoutModal;

		this.scrollToTop();

		if (this.showCheckoutModal) {
			let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);
			if (this.desktop) {
				divAllProducts.forEach(div => {
					div.classList.remove('slds-size_3-of-3');
					div.classList.add('slds-size_2-of-3');
				});
			}
		} else {
			let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);

			divAllProducts.forEach(div => {
				div.classList.remove('slds-size_2-of-3');
				div.classList.add('slds-size_3-of-3');
			});
		}
	}

	convertSpecialCharacters (s) {
		if (s.normalize != undefined) {
			s = s.normalize ("NFKD");
		}
		return (s.replace (/[\u0300-\u036F]/g, "")).toUpperCase();
	}
	redirectPedido(event){	
		let pedido = event.currentTarget.dataset.id;

		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: pedido,
				actionName: 'view'
			}
		});			
	}

	openRuleReason(event) {
		swal("Aviso!", `${event.currentTarget.dataset.productMotivo}`);
	}

	openHistoric(event){
		
		var clienteId = this.clienteEmissorId
		let prod = event.target.value;

		if(prod.show){
			if(this.HistoricSection == prod.id){
				this.showHistoric = false;
				this.HistoricSection = '';
			}else{
				this.HistoricSection = prod.id;
				getHistorico({ clienteId: clienteId, prodId: prod.id })
					.then(result => {
						this.HistoricList = [];
						this.HistoricListTotal   = result;
						if(this.HistoricListTotal.length > 0){
							this.tamanho = 0;
							if(this.HistoricListTotal.length > 6){
								this.pageNumber = 6;
								this.isFirstPage = true;
								this.isLastPage = false;
								for (var i = 0; i < 6; i++) {
									this.HistoricList.push(this.HistoricListTotal[i]);
								}
							}else{
								this.pageNumber = this.HistoricListTotal.length;
								this.isLastPage = true;
								this.isFirstPage = true;
								this.HistoricList = this.HistoricListTotal;
							}
						}
						var nome =  prod.id;
						this.showHistoric = true;
					}).catch(error => {
						console.log('getToastInfoData: entrou no erro!');
						console.log(error);
					});
			}
		}

		event.stopPropagation();
	}
	handlePrev(){

		this.isLastPage = false;
		if(this.pageNumber <= 6){
			this.pageNumber = 6;
			this.tamanho = 0;
			this.isFirstPage = true;
		}else{
			this.tamanho = this.pageNumber - 6;
		}
		this.HistoricList = [];


		for (var i = this.tamanho; i < this.pageNumber; i++) {
			this.HistoricList.push(this.HistoricListTotal[i]);
		}
		this.pageNumber = this.tamanho;

		if(this.tamanho = 0){
			this.pageNumber = 6;
		}
	}

	handleNext(){
		this.isFirstPage = false;
		this.tamanho = this.pageNumber + 6;
		if(this.tamanho > this.HistoricListTotal.length){
			this.tamanho = this.HistoricListTotal.length;
			this.isLastPage = true;
		}
		this.HistoricList = [];
		if(this.HistoricList.length = 0){
		}
		for (var i = this.pageNumber ; i < this.tamanho ; i++) {
			this.HistoricList.push(this.HistoricListTotal[i]);
		}
		this.pageNumber = this.tamanho;
	}


	closeSection(event){
		this.showHistoricSection = !this.showHistoricSection;
		event.target.iconName =  this.showHistoricSection ? 'utility:switch' : 'utility:chevronright';
		let prodId = event.target.value;

		let divHist = this.template.querySelector(`[data-target-id="${prodId}"]`);
		divHist.classList.add('slds-hide');
		this.HistoricSection = '';

	}

	openModalProductDescription(event){
		this.showProductDescriptionModal = true;
		this.selectedProductModal = event.target.value;
		this.scrollToTop();
		event.stopPropagation();
	}

	closeModalProductDescription(){
		this.showProductDescriptionModal = false;
	}

	closeCDDescription(){
		this.showCDDescriptionModal = false;
	}

	closeCheckoutModal(){
		this.showCheckoutModal = false;
		let divAllProducts = this.template.querySelectorAll(`[data-name="left_div"]`);
		
		if (this.desktop) {
			divAllProducts.forEach(div =>{
				div.classList.remove('slds-size_2-of-3');
				div.classList.add('slds-size_3-of-3');
			});
		}
	}

	handleNavigate() {

		let qntdError = false;
		let allInvalidItems = [];

		this.orderList.forEach(cd => {
			if (Number(cd.quantidadeCx) % 1 != 0) {
				qntdError = true;
			} else if (cd.valorCampanha != 0 && parseFloat(cd.caixa) < cd.valorCampanha) {
				allInvalidItems.push(cd.prodCode + ' - ' + cd.cds);
			}
		})
		
		if (this.orderList.length == 0) {
			swal("Aviso!", 'Não foi adicionado produto!');
		} else if (qntdError) {
			swal("Aviso!", 'Favor verificar quantidade principal dos produtos inseridos, quantidade principal deve ser um valor inteiro!');
		} else if (allInvalidItems.length > 0) {
			let allInvalidConcat = allInvalidItems.join('; \n');
			swal("Aviso!", `Produto(s) ${allInvalidConcat} possui(em) valor menor que o valor da campanha!`, "warning");
			return;
		} else {
			if ((this.canalVendas == 'Telefone' || this.canalEntrada == 'Telefone' || this.canalVendas == 'Whatsapp' || this.canalEntrada == 'Whatsapp' || this.canalVendas == 'E-mail' || this.canalEntrada == 'E-mail') && !this.allRecAnswered && this.hasPermissionERB) {
				if (this.isRecommendation) {
					this.prodList = this.prodFilterRecommendedList;
					this.prodFilterList = this.prodList;
					if (this.prodFilterRecommendedList.length != 0) {
						swal("Aviso!", "Necessário responder pesquisa de recomendações.", "warning");
						return;
					} else {
						this.allRecAnswered = true;
					}
				} else {
					swal("Aviso!", "Necessário responder pesquisa de recomendações.", "warning");
					this.callGetRecommendation();
					return;
				}
			}
			this.navigateToCheckout();
		}
	}

	navigateToCheckout() {
		if (this.isBudget) {
			var compDefinition = {
				componentDef: "c:orderProductCheckout",
				attributes: {
					isEdit: this.isEdit,
					isBudget: this.isBudget,
					numOrcamento: this.numOrcamento,
					valorTotal: this.valorTotal,
					clienteEmissorId: this.clienteEmissorId,
					clienteEmissor: this.clienteEmissor,
					clienteEmissorCGC: this.clienteEmissorCGC,
					tabelaPreco: this.tabelaPreco,
					tabelaPrecoNome: this.tabelaPrecoNome,
					canalEntrada: this.canalEntrada,
					condicaoPagamento: this.condicaoPagamento,
					condicaoPagamentoNome: this.condicaoPagamentoNome,
					formaPagamento: this.formaPagamento,
					contatoOrcamento: this.contatoOrcamento,
					prazoValidade: this.prazoValidade,
					dtValidade: this.dtValidade,
					observacaoCliente: this.observacaoCliente,
					observacao: this.observacao,
					recordId: this.recordId,
					dtParcelas: this.dtParcelas,
					fretesPorCd: this.fretesPorCd,
					pedidoComplementar: this.pedidoComplementar,
					margemAtualGeral: this.margemAtualGeral.replace('%', ''),
					margemAtualAlvo: this.margemAtualAlvo.replace('%', ''),
					score: this.scoreFinalGeral.replace('%', ''),
					verMargem: this.verMargem,
					Idportalcotacoes: this.Idportalcotacoes,
					createOrderDt: this.createOrderDt,
					orderList: JSON.stringify(this.orderList),
					recomendacaoRespondida: this.allRecAnswered,
					hasPermissionERB: this.hasPermissionERB,
					goToCheckout: this.goToCheckout,
					alreadySaved: this.alreadySaved,
					newRecordId: this.newRecordId,
					savingStrData: JSON.stringify(this.savingObjData),
					filtroPDF : this.filtroPDF
				}
			};

			try {
				const filterChangeEvent = new CustomEvent('displaymyvaluenew', {
					detail: { "data": JSON.stringify(compDefinition) }
				});
				this.dispatchEvent(filterChangeEvent);
			} catch (e) {
				debugger;
				console.log(e);	
			}
		} else {
			var compDefinition = {
				componentDef: "c:orderProductCheckout",
				attributes: {
					isEdit: this.isEdit,
					isBudget: this.isBudget,
					clienteEmissor: this.clienteEmissor,
					clienteEmissorId: this.clienteEmissorId,
					clienteEmissorCGC: this.clienteEmissorCGC,
					medico: this.medico,
					medicoId: this.medicoId,
					medicoCRM: this.medicoCRM,
					tabelaPreco: this.tabelaPreco,
					tabelaPrecoNome: this.tabelaPrecoNome,
					tipoFrete: this.tipoFrete,
					valorFrete: this.valorFrete,
					numeroPedidoCliente: this.numeroPedidoCliente,
					condicaoPagamento: this.condicaoPagamento,
					condicaoPagamentoNome: this.condicaoPagamentoNome,
					contatoOrcamento: this.contatoOrcamento,
					canalVendas: this.canalVendas,
					tipoOrdem: this.tipoOrdem,
					formaPagamento: this.formaPagamento,
					dtPrevistaEntrega: this.dtPrevistaEntrega,
					clienteRecebedor: this.clienteRecebedor,
					clienteRecebedorCGC: this.clienteRecebedorCGC,
					enderecoEntregaId: this.enderecoEntregaId,
					enderecoEntrega: this.enderecoEntrega,
					utilizarEnderecoAdicional: this.utilizarEnderecoAdicional,
					enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
					observacao: this.observacao,
					observacaoNF: this.observacaoNF,
					observacaoPedido: this.observacaoPedido,
					dtParcelas: this.dtParcelas,
					fretesPorCd: this.fretesPorCd,
					pedidoComplementar: this.pedidoComplementar,
					margemAtualGeral: this.margemAtualGeral != undefined ? this.margemAtualGeral.replace('%', ''): undefined,
					margemAtualAlvo: this.margemAtualAlvo != undefined ? this.margemAtualAlvo.replace('%', ''): undefined,
					score: this.scoreFinalGeral != undefined ? this.scoreFinalGeral.replace('%', ''): undefined,
					verMargem: this.verMargem,
					Idportalcotacoes: this.Idportalcotacoes,
					createOrderDt: this.createOrderDt,
					orderList: JSON.stringify(this.orderList),
					recomendacaoRespondida: this.allRecAnswered,
					hasPermissionERB: this.hasPermissionERB,
					goToCheckout: this.goToCheckout,
					alreadySaved: this.alreadySaved,
					newRecordId: this.newRecordId,
					savingStrData: JSON.stringify(this.savingObjData)
				}
			};

			try {
				const filterChangeEvent = new CustomEvent('displaymyvaluenew', {
					detail: { "data": JSON.stringify(compDefinition) }
				});
				this.dispatchEvent(filterChangeEvent);
			} catch (e) {
				debugger;
				console.log(e);
			}
		}
	}

	callGetRecommendation() {		
		let prodList = [];
		this.prodList = [];
		this.prodFilterList = [];
		this.orderList.forEach(item => {
			prodList.push(item.prodId);
		})
		let objRecommendation = {
			"contextRecordId": this.newRecordId ? this.newRecordId : this.recordId,
			"currentProducts": prodList,
			"pricebookId": this.tabelaPreco,
			"accountId": this.clienteEmissorId,
			"condPag": this.condicaoPagamento
		}
		this.isLoadingProducts = true;
		getRecommendations({ contextRecordData: objRecommendation })
			.then(result => {
				this.isLoadingProducts = false;				
				this.prodList = [];
				if (result != undefined) {
					result.forEach(item => {									
						item.isRecommendation = true;
						item.alreadyAnswered = false;
						let tipoCampanha = item.tipoCampanha ? (item.tipoCampanha == 'Z' ? ' | Condição de pagamento' : ' | Dia D') : undefined;
						this.prodList.push({
							...item,
							isContractOrCampaign	 : (item.showBadgeAcordoComercial || item.showBadgeOL) ? true : false,
							precoBadgeCampanhaProduto : this.getCurrencyFormat(item.valorCampanha) + (tipoCampanha ? ' | ' + tipoCampanha : ''),
							precoBadgeOL			  : this.getCurrencyFormat(item.precoBadgeOL),
							precoBadgeConsignado	  : this.getCurrencyFormat(item.precoBadgeConsignado),
							precoBadgeAcordoComercial : this.getCurrencyFormat(item.precoBadgeAcordoComercial),
							precoBadgeshelflife	   : this.getCurrencyFormat(item.precoBadgeshelflife),
							SequenciaOC: item.SequenciaOC
						});
						if(item.code != undefined && this.mockedProdList[item.code] == undefined) {
							this.mockedProdList[item.code] = {
								...item,
								isContractOrCampaign	  : (item.showBadgeAcordoComercial || item.showBadgeOL) ? true : false,
								precoBadgeCampanhaProduto : this.getCurrencyFormat(item.valorCampanha) + (tipoCampanha ? ' | ' + tipoCampanha : ''),
								precoBadgeOL			  : this.getCurrencyFormat(item.precoBadgeOL),
								precoBadgeConsignado	  : this.getCurrencyFormat(item.precoBadgeConsignado),
								precoBadgeAcordoComercial : this.getCurrencyFormat(item.precoBadgeAcordoComercial),
								precoBadgeshelflife	   : this.getCurrencyFormat(item.precoBadgeshelflife),
								SequenciaOC: item.SequenciaOC
							};
						}
					})
				}
				this.prodFilterList = this.prodList;
				this.prodFilterRecommendedList = result;
				this.isRecommendation = true;
			}).catch(error => {
				console.log('getRecommendations: entrou no erro!');
				console.log(error);
				this.isLoadingProducts = false;
			});
		return;
	}

	recommendationApproved(event) {
		this.handleSelectedProduct(event);
		let productId = event.currentTarget.dataset.productId;
		let currentProdInfo;
		this.prodFilterList.forEach(item => {
			if (item.id == productId) {
				item.alreadyAnswered = true;
				currentProdInfo = item;
			}
		})
		this.prodFilterRecommendedList = this.prodFilterRecommendedList.filter(item => item.id != productId);
		let objRecApproved = {
			"contextRecordId": this.newRecordId ? this.newRecordId : this.recordId,
			"externalId" : currentProdInfo.id,
			"targetId" : currentProdInfo.targetId,
			"targetActionId" : currentProdInfo.targetActionId,
			"targetActionName" : currentProdInfo.targetActionName,
			"reactionMessage": "",
			"reaction" : "Accepted"
		}
		setRecommendationReaction({reactionData: objRecApproved});
		return;
	}

	recommendationRefused(event) {
		this.rejectPicklist = '';
		this.isProdReject = true;
		this.currentRejectProduct = event.currentTarget.dataset.productId;		
		this.refusingItem = true;

		return;		
	}

	submitRejectInfo() {
		if (this.rejectPicklist == '') {
			this.rejectReasonPicked = true;
			return;
		}
		let productId = this.currentRejectProduct;
		let currentProdInfo;
		this.prodFilterList.forEach(item => {
			if (item.id == productId) {
				item.alreadyAnswered = true;
				currentProdInfo = item;
				let objRecRefused = {
					"contextRecordId" : this.newRecordId ? this.newRecordId : this.recordId,
					"externalId" : currentProdInfo.id,
					"targetId" : currentProdInfo.targetId,
					"targetActionId" : currentProdInfo.targetActionId,
					"targetActionName" : currentProdInfo.targetActionName,
					"reactionOption": this.rejectPicklist,
					"reactionMessage": this.rejectText,
					"reaction" : "Rejected"
				}
				this.prodFilterRecommendedList = this.prodFilterRecommendedList.filter(item => item.id != productId);
				this.refusingItem = false;
				setRecommendationReaction({reactionData: objRecRefused});
				this.isProdReject = false;
			}			
		})		
	}

	onChangeRejectText(event) {
		this.rejectText = event.target.value;
	}

	onChangeRejectPicklist(event) {
		this.rejectPicklist = event.target.value;
		this.rejectReasonPicked = false;
	}

	closeRejectModal() {
		this.refusingItem = !this.refusingItem;
	}

	onCloseMixClient(event) {
		this.isMixClientOpen = false;
		this.prodFilterList.forEach(item => {
			if (item.isOpenMixAndSearch) {
				item.isOpenMixAndSearch = false;
			}
		});

		if (event.detail.prodCode != null) {
			this.searchGenericValue = event.detail.prodCode;
			this.valorBusca = event.detail.prodCode;
			this.searchFabricanteValue = ""; 
			this.handleFilterSearchProd(); 
		}
	}

	onCloseProductCampaign(event) {
		if (event.detail.prodCode != null) {
			this.searchGenericValue = event.detail.prodCode;
			this.searchProductCampaign(true); 
		}
	}

	onEditProduct(prodCode) {
		if (prodCode != null) {
			this.searchGenericValue = prodCode;
			this.valorBusca = prodCode;
			this.searchFabricanteValue = "";
			this.handleFilterSearchProd();
		}
	}

	openMixClient() {
		this.isMixClientOpen = true;
		this.scrollToTop();
	}

	openMixAndSearch(event) {		
		let productCode = event.currentTarget.dataset.productCode;
		if (this.prodFilterList.find(item => item.code == productCode) != undefined) {
			this.prodFilterList.find(item => item.code == productCode).isOpenMixAndSearch = true;
		}
		this.scrollToTop();
	}

	scrollToTop() {
		if (!this.desktop) {
			const scrollOptions = {
				left: 0,
				top: 0
			}
			parent.scrollTo(scrollOptions);
		}
	}
	
onCloseProductShelfLife(event) {
		let currentCd = {};
		let selectedCd = {};
		if (event.detail.shelfLifeList) {
			let totalQuantity = 0;
			JSON.parse(event.detail.shelfLifeList).forEach(item => {
				currentCd = this.orderList.find(ordItem => ordItem.id == item.idFromCdList + '_' + item.lote);
				totalQuantity += Number(item.quantidade);
				if (!currentCd) {
					currentCd = this.cdList.find(cd => cd.id == item.idFromCdList);
					this.cdList.find(cd => cd.id == item.idFromCdList).loteSelecionado = true;
					this.cdList.find(cd => cd.id == item.idFromCdList).possuiLoteSelecionado = true;
					this.cdList.find(cd => cd.id == item.idFromCdList).valorTotalShelfLife = Number(item.preco) * Number(item.quantidade)
				} else {
					if (this.cdList.find(cd => cd.id == item.idFromCdList) != undefined) {
						currentCd.loteSelecionado = true;
						this.cdList.find(cd => cd.id == item.idFromCdList).loteSelecionado = true;
					}
				}
				if (this.cdList.find(cd => cd.id == item.idFromCdList) != undefined) {
					currentCd.quantidadeCxShelfLife = totalQuantity;
					currentCd.quantidadeShelfLife = totalQuantity;
					this.cdList.find(cd => cd.id == item.idFromCdList).quantidadeCxShelfLife = totalQuantity;
					this.cdList.find(cd => cd.id == item.idFromCdList).quantidadeShelfLife = totalQuantity;
				}
				selectedCd = {
					...currentCd,
					quantidadeCx: item.quantidade,
					quantidade: item.quantidade,
					lote: item.lote,
					estoque: item.saldo,
					caixa: item.preco,
					inicialCaixa: item.preco,
					unitario: item.preco,
					inicialUnitario: item.preco,
					precoTabelaCx: item.preco,
					valorBloqueado: true,
					score: 100.00,
					scoreBU: 100.00,
					scoreMix: 100.00,
					scoreItem: 100.00,
					valorTotal: Number(item.preco) * Number(item.quantidade),
					minimumPrice: item.minimumPrice,
					maximumPrice: item.maximumPrice
				}
				if (this.orderList.find(ordItem => (ordItem.id == selectedCd.id && selectedCd.id.includes(item.lote))) == undefined) {
					let key = selectedCd.id + '_' + item.lote;
					selectedCd.id = key;
					selectedCd.cdId += '_' + item.lote;
				} else {
					let key = selectedCd.id;
					this.orderList = this.orderList.filter(ordItem => (ordItem.id != key));
					selectedCd.id = key;
				}
				this.calcRefresh(selectedCd);
				event.target.value = selectedCd;
				event.target.notSave = true;
				this.handleSaveCd(event);
			});
			this.keepSavingOrEditing();
		}
	}

	enableButtons() {
		this.disableAdvance = false;
	}

	disableButtons() {
		this.disableAdvance = true;
	}

	handleNavigatePular() {
		this.navigateToCheckout();
	}

	handleMouseEnter(event) {
		if(this.desktop) {
			if(!this.iconPinned) {
				this.showHeader = true;
				this.iconName = 'utility:up';
				this.headerStyle = this.desktop ? 'height: calc(100% - 150px)' : '';
			}
		}
	}

	handleMouseLeave(event) {
		if(this.desktop) {
			if(!this.iconPinned) {
				this.showHeader = false;
				this.iconName = 'utility:down';
				this.headerStyle = this.desktop ? 'height: calc(100% - 0px)' : '';
			}
		}
	}

	handleClickIconPin(event) {
		if(this.iconNamePin.includes('pinned')) {
			this.iconPinned = false;
			this.iconNamePin = "utility:pin";
			this.alternativeTextIconPin = "Fixar cabeçalho";
			this.showHeader = false;
			this.headerStyle = this.desktop ? 'height: calc(100% - 0px)' : '';
		} else {
			this.iconPinned = true;
			this.iconNamePin = "utility:pinned";
			this.alternativeTextIconPin = "Desfixar cabeçalho";
			this.showHeader = true;
			this.headerStyle = this.desktop ? 'height: calc(100% - 150px)' : '';
		}
	}

	openModalProductCampaign() {
		this.template.querySelector('c-product-campaign').openModal();
	}

	handleResizeHeader = (event) => {
		
		var w = window.innerWidth;
		var h = window.innerHeight;
		

		this.controllerOfButtons(w);
	}

	controllerOfButtons(width) {

		if(width > '1650') {
			this.productCampaingButtonShow = true;
			this.resumoButtonShow = true;
			this.buttonsGroupShow = false;
			this.backButtonShow = true;
		} else if(width > '1400' && width < '1650') {
			this.productCampaingButtonShow = true;
			this.resumoButtonShow = false;
			this.buttonsGroupShow = true;
			this.backButtonShow = true;
		} else if(width < '500') {
			this.backButtonShow = false;
			this.productCampaingButtonShow = false;
			this.resumoButtonShow = false;
			this.buttonsGroupShow = true;
		} else {
			this.productCampaingButtonShow = false;
			this.resumoButtonShow = false;
			this.buttonsGroupShow = true;
			this.backButtonShow = true;
		}
	}

	handleCheckbox(event){

		let cdId = event.currentTarget.dataset.cdId;
		this.cdList.find(cd => (cd.id === cdId)).uniSecundaria = !this.cdList.find(cd => (cd.id === cdId)).uniSecundaria;  
    }
}