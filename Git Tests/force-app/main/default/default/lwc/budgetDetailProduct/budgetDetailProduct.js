import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getProductData from '@salesforce/apex/OrderScreenController.getProductData';
// import getQuoteItems from '@salesforce/apex/BudgetController.getQuoteItems';
import getHistorico from '@salesforce/apex/OrderScreenController.getHistorico';
import getRecommendations from '@salesforce/apex/OrderScreenController.getRecommendations';
import setRecommendationReaction from '@salesforce/apex/OrderScreenController.setRecommendationReaction';
import getProduct from '@salesforce/apex/OrderScreenController.getProduct';
import getMalha from '@salesforce/apex/OrderScreenController.getMalhaPortal';
import getLotes from '@salesforce/apex/OrderScreenController.getLotes';
//import getFatorProduto from '@salesforce/apex/BudgetController.getFatorProduto';
//import updateProduct from '@salesforce/apex/BudgetController.updateProduct';
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
import { stringToNumber, isEmpty, isNotEmpty } from 'c/utilities';
import { ingestDataConnector } from 'lightning/analyticsWaveApi';
import { doCalloutWithStdResponse } from 'c/calloutService';

export default class BudgetDetailProduct extends NavigationMixin(LightningElement) {
	// variáveis para definição de edição ou inserção de pedido ou orçamento
    @track prod_;
    @api 
    set prod(value){
		this.cdList = [];
        this.prod_ = {...value};
		this.handleSelectedProductAsync();
    }

    get prod(){
        return this.prod_;
    }

    @track budgetData_;
	@track CDsBloqueado;
	@track conversao = '';
	@track fatordeConversao = 1;
	@track quantidade = 0;
	@track comentario = '';
    @api
    set budgetData(value){
        console.log('budgetData >> ', value, JSON.stringify(value));
		if(value){
			this.budgetData_ = {...value};
            let keys = Object.keys(value);
            console.log('keys:::', keys);;
            keys.forEach(key => {

                // if(key == 'AccountContactRelationId'){
                //     this.AccountContactRelationId = value[key]
                // } else 
                if(key == 'allRecAnswered'){
                    this.allRecAnswered = value[key]
                }
                // else if(key == 'BloqueioFinanceiro'){
                //     this.BloqueioFinanceiro = value[key]
                // }
                else if(key == 'CanalEntrada'){
                    this.canalEntrada = value[key]
                }
                // else if(key == 'ClienteBloqueado'){
                //     this.ClienteBloqueado = value[key]
                // }
                else if(key == 'ClienteEmissor'){
                    this.ClienteEmissor = value[key]
                }
                else if(key == 'ClienteEmissorCGC'){
                    this.ClienteEmissorCGC = value[key]
                }
                else if(key == 'ClienteEmissorId'){
                    this.ClienteEmissorId = value[key]
                }
                else if(key == 'ClienteEmissorUF'){
                    this.UF = value[key]
                }               
                else if(key == 'CondicaoPagamento'){
                    this.condicaoPagamento = value[key]
                }
                else if(key == 'CondicaoPagamentoNome'){
                    this.condicaoPagamentoNome = value[key]
                }
                else if(key == 'ContatoOrcamento'){
                    this.contatoOrcamento = value[key]
                }
                // else if(key == 'ContemDocAlvaraCrt'){
                //     this.ContemDocAlvaraCrt = value[key]
                // }
                else if(key == 'DataValidade'){
                    this.dtValidade = value[key]
                }
                // else if(key == 'DocumentosValidos'){
                //     this.DocumentosValidos = value[key]
                // }
                // else if(key == 'enderecoCobranca'){
                //     this.enderecoCobranca = value[key]
                // }
                // else if(key == 'GeraBoleto'){
                //     this.GeraBoleto = value[key]
                // }
                else if(key == 'hasPermissionERB'){
                    this.hasPermissionERB = value[key]
                }
                else if(key == 'Idportalcotacoes'){
                    this.Idportalcotacoes = value[key]
                }
                else if(key == 'IsCoordenador'){
                    this.isCoordenador = value[key]
                }
                // else if(key == 'Itens'){
                //     this.Itens = value[key]
                // }
                else if(key == 'NumOrcamento'){
                    this.NumOrcamento = value[key]
                }
                else if(key == 'oppId'){
                    this.recordId = value[key]
                }
                // else if(key == 'StageName'){
                //     this.StageName = value[key]
                // }
                else if(key == 'TabelaPreco'){
                    this.tabelaPreco = value[key]
                }
                else if(key == 'CDsBloqueado'){
                    this.CDsBloqueado = value[key]
                }
                else if(key == 'TabelaPrecoNome'){
                    this.tabelaPrecoNome = value[key]
                }
                else if(key == 'TabelaPrecoExternalId'){
                    this.tabelaPrecoExternalId = value[key]
                }
                else if(key == 'ValorTotal'){
                    this.valorTotal = value[key]
                }
                else if(key == 'fatorConversao'){
                    this.fatorConversao = value[key]
                }
                else if(key == 'tipoConversao'){
                    this.tipoConversao = value[key]
					 
                }
            });
            console.log('budgetData >> finish');
            // this.loadProdData();

			this.conversao = this.prod_.tipoConversaoProd ? this.prod_.tipoConversaoProd : 'N';
			this.comentario = (this.budgetData_.comentario != undefined) ? this.budgetData_.comentario: '' ;
        }
    }

    get budgetData(){
        return this.budgetData_;
    }

    get cdListItems(){
		let result = [];
        // console.log('this.cdList: get::', JSON.stringify(this.cdList));
        // console.log('this.cdList: get1:',  this.current);fg
        if(this.cdList){
			result = [...this.cdList];
			if((this.selected != undefined && this.selected != '') && this.current!= undefined ){
				console.log('this.selected::', JSON.stringify(this.selected));
				if(this.selected == 'Com saldo'){
					result = result.filter(cd => { 
						if(cd.estoque > 0 ){
							return cd;
						}
					});
				}
				console.log('result ', JSON.stringify(result))
			}
        }
        return result;
    }

	isBudget = true;
	isEdit = true;
    
	@api newRecordId;
	// variáveis cabeçalho (orçamento e pedido)
	@api productToSearch;
	@api recordId;
	@api NumOrcamento;
	@api valorTotal;
	@api score;
	@api ClienteEmissorId;
	@api ClienteEmissor;
	@api ClienteEmissorCGC;
	@api UF;
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
	@api comentarioCliente;
	@api comentario;
	@api comentarioNF;
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

	@track nextCdValue = 0;
	@track headerInfoData = {};
	@api alreadySaved = false;
	@api savingStrData;
	@track isSaving = false;
	@track savingObjData = {};
	@track saveInterval;
	@track automaticSave = true;
	@track hasOnlyCampaign = true;
	@track hasOnlyContract = true;

	@track isLoadingScore = false;
	@track disableAdvance = false;
	@track verMargem = true;
	@track calcScoreObj = [];
	@track calcAllScoreObj = [];
	@track totalOrderValue = 0;
	@track savedCdData = [];
	@track savedCdDataForaMalha = [];
	@track isForaMalha = false;
	@track hasMalha = true;
	@track currentSelectedProdCode;
	@track selectedProduct;
	@track prodMalhaInfo = new Object();
	@track isLoading_ = false;
	@track isLoadingProducts = false;
	@track isLoadingLotes = false;
	@track offSetValue = 0;
	@track searchGenericValue = '';
	@track searchFabricanteValue = '';
	@track showMoreProduct = true;
	@track  tooltip = true;
	@track showHistoric = false;
	@track HistoricSection = '';
	@track showHistoricSection = true;
	@track showProductDescriptionModal = false;
	@track showCDDescriptionModal = false;
	@track showCheckoutModal = false;
	@track activeSection = 'cdaccordion';
	@track manufacturer = '';
	@track productInput = '';
	@track selected = 'Com saldo';
	@track current = 0;
	@track currentCd = 0;
	@track selectedSortProduct;
	@track selectedProductModal;
	@track productListFromSF = new Object();
	@track HistoricListTotal = [];
	@track HistoricList = [];
	@track mockedProdList = [];
	@track prodList = [];
	@track cdList = [];
	@track cdListMock = [];
	@track cdInfoList = [];
	@track showCdInfoList;
	@track allValues = [];
	@track isOrderListReturned = false;
	@track scoreFinalGeral;
	@track margemAtualGeral;
	@track margemAtualAlvo;
	@track mensagem ='Preço não cadastrado para essa tabela, favor entrar em contato com o departamento responsável.';
	// @track prodFilterList = this.prodList;
	@track prodFilterList = [];
	@track prodFilterRecommendedList = [];
	@track filterLst = [];
	@api hasPermissionERB;
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

	//Obs: orderList está puxando a cdList como inicial só por demonstração
	@track objectProdCdList = [];
	@track orderList = this.cdList;
	@track orderListFiltered = this.orderList;
	@track orderCdList = [];

	@track valorBusca;
	@track valorBuscaFabricante;
	@track desktop;
	@track headerStyle = '';
	@track headerClass = '';

	@track productFilter;
	@track allCds = true;
	@track lastProduct;
	@track count = 0;
	@track tamanho = 0;
	@track count = 0;
	@track percentage = 25;
	@track pageNumber = 0; 
	@track isFirstPage = true;
	@track isLastPage = true;
    @api 
    get isLoading(){
        return this.isLoading_;
    }

    set isLoading(value){
		this.isLoading_ = value;
		this.dispatchEvent(new CustomEvent("changespinner", {
			composed: true,
			bubbles: true,
			cancelable: true,
			detail: this.isLoading_
		}));
    }
	
    get optionsRefuse() {
        return [
            { label: 'Sem interesse por ainda ter estoque', value: 'Recusada sem interesse por ainda ter estoque' },
            { label: 'Não trabalha com este produto', value: 'Recusada não trabalha com este produto' },
            { label: 'Sem interesse por ser laboratório/marca não padronizada', value: 'Recusada sem interesse por ser laboratório/marca não padronizada' },
            { label: 'Sem interesse por prazo de entrega', value: 'Recusada sem interesse por prazo de entrega' },
            { label: 'Sem interesse pelo preço', value: 'Recusada sem interesse pelo preço' },
            { label: 'Outros', value: 'Recusada (Outros Justificar)' }
        ];
    }

	get radioOptions(){
		let radioOptions = [
			{ label: "Com saldo", value: "Com saldo", checked: false },
			{ label: "Todos os itens",  value: "Todos os itens", checked: false }
		];
		if(this.selected == '' || this.selected == undefined){
			this.selected = 'Com saldo';
		}
		console.log(' this.selected ' + this.selected);		
		radioOptions.forEach(item => {
			item.checked = (item.value == this.selected ) ? true :false;
	    });
		if(this.selected == 'Com saldo'){
			this.allCds = this.selected != 'Com saldo';
			this.cdList = [...this.cdList];
		}

		return radioOptions;
	}

	get radioOptionsConversao(){

		let radioOptionsConversao = [
				{ label: "Nenhuma", value: "N", checked: false },
				{ label: "Multiplicar",  value: "M", checked: false },
				{ label: "Dividir", value: "D", checked: false },
			];
			radioOptionsConversao.forEach(item => {
				if (item.value == this.conversao ) {
					item.checked = true;
				}else{
					item.checked = false;
				}
			});

		return radioOptionsConversao;
	}

	get orderOptions(){
		return [
			{ label: "Maior Preço", value: "Maior Preço" },
			{ label: "Menor Preço",  value: "Menor Preço" },
			{ label: "Maior Saldo", value: "Maior Saldo" },
			{ label: "Menor Saldo",  value: "Menor Saldo" }
		  ];
	}

	get validityOptions(){
		return [
			{ label: "7 dias", value: "168" },
			{ label: "30 dias", value: "720" },
			{ label: "60 dias",  value: "1440" },
			{ label: "90 dias", value: "2160" },
			{ label: "180 dias",  value: "4320" },
			{ label: "1 ano",  value: "8760" },
			{ label: "18 meses",  value: "13140" },
			{ label: "24 meses",  value: "17520" }
		  ];
	}

    connectedCallback() {
		this.desktop = FORM_FACTOR == 'Large';
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {console.log('Files loaded.');}).catch(error => {console.log('error: ' + JSON.stringify(error));});
    }

	disconnectedCallback(){
		if(this.handleSelectedProductTimeout){
			clearTimeout(this.handleSelectedProductTimeout);
		}
	}

	isRendered = false;
    renderedCallback() {
		if(!this.isRendered){
			this.isRendered = true;
			
			var box1 = document.querySelector('#box1');
			if(box1){
				box1.addEventListener('touchmove', function(e) {
					e.stopPropagation();
				}, false); 
			}
 
            this.enforceStyles();
        }
    }

    enforceStyles(){
        let style = document.createElement('style');
		//document.querySelector("c-budget-detail-product > div.slds-section.slds-is-open.slds-card > button > lightning-icon > lightning-primitive-icon > svg")
        style.innerText = `
			c-budget-detail-product button.close-button {
				position: absolute;
				right: .3rem;
				top: .3rem;
			}
			c-budget-detail-product button.close-button:hover {
				border-color: lightgray;
			}
        	c-budget-detail-product button.close-button svg {
    			fill: darkgray;
            }
        `;
        this.template.querySelector('.style-element-container').appendChild(style);
    }

	calcRefresh(selectedCd) {

		// if (this.isOrderListReturned) {   // tirei este if pois so funcionava quando voltava do carrinho (checkout final)
			this.orderList.find(cdCart => {
				if (cdCart.id == selectedCd.id) {
					cdCart.quantidadeCx = selectedCd.quantidadeCx;
					cdCart.quantidade = selectedCd.quantidade;
					cdCart.quantidadeScreen = stringToNumber(selectedCd.quantidade, 4);
					cdCart.margem = selectedCd.margem;
					cdCart.verMargem = selectedCd.verMargem,
					cdCart.margemAlvo = selectedCd.margemAlvo;
					cdCart.desconto = selectedCd.desconto;
					cdCart.valorTotal = selectedCd.valorTotal;
					cdCart.SequenciaOC = selectedCd.SequenciaOC;
					cdCart.isCampaign = selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? false : true;
				}
			});

		// }

		// this.calcValorTotalAllCds(selectedCd);
		// this.calcValorTotalAllCds(selectedCd);
		if(this.filterLst.length > 0){
			this.orderListFiltered = [];
			this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
		}else{
			this.orderListFiltered = this.orderList;
		}                

	}

	calcPriceUnit(event){

		console.log('entrou calcpriceunit');
		let unit = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);

		if (unit && unit != selectedCd.quantidadeScreen) {
			selectedCd.quantidade = stringToNumber(unit);
			selectedCd.quantidadeScreen = stringToNumber(unit, 4);
			selectedCd.quantidadeCx = stringToNumber(selectedCd.tipoConversaoProd == 'M' ? unit / parseFloat(selectedCd.conversaoUnidadeCx) : (unit * parseFloat(selectedCd.conversaoUnidadeCx)), 6);
			if (selectedCd.range && !(selectedCd.valorBloqueado == undefined ? true : selectedCd.valorBloqueado) && !(selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? false : true)) {
				if (selectedCd.range.length > 0) {
					selectedCd.range.forEach(range => {
						if (range.range_min <= selectedCd.quantidadeCx && (range.range_max >= selectedCd.quantidadeCx || range.range_max == null)) {
							selectedCd.precoTabelaCx = stringToNumber(!range.preco_differ ? selectedCd.precoTabelaCx : range.preco_differ, 6);
							selectedCd.caixa         = selectedCd.precoTabelaCx;
							selectedCd.inicialCaixa  = stringToNumber(!range.preco_differ ? selectedCd.inicialCaixa  : range.preco_differ, 6);
						}
					});
				}
			}
			selectedCd.precoTabelaCx = novoPrecoTabela == null ? selectedCd.precoTabelaCx : novoPrecoTabela;

			if (stringToNumber(selectedCd.quantidadeCx) % 1 != 0) {
				swal("Aviso!", 'Quantidade principal do produto não pode ser fracionada!');
			}

			// this.calcValorTotalAllCds(selectedCd);

			let currentProd = this.getCurrentProduct(selectedCd.prodCode);
			this.fillCalcScoreObj(selectedCd, currentProd);
			this.refreshCdScoreCalc();

			this.getScoreCalcApi(selectedCd);
		}
		this.calcRefresh(selectedCd);

	}

	calcPriceUnitCx(event){
		console.log('calcPriceUnitCx');
		let qtdcx = event.target.value && parseFloat(event.target.value) || 1;
		this.prod_.quantidadeCx = qtdcx;
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.cdId === cdId);
		
		if (selectedCd.range && !(selectedCd.valorBloqueado == undefined ? true : selectedCd.valorBloqueado) && !(selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? false : true)) {
			if (selectedCd.range.length > 0) {
				selectedCd.range.forEach(range => {
					if (range.range_min <= qtdcx && (range.range_max >= qtdcx || range.range_max == null)) {
						selectedCd.precoTabelaCx = stringToNumber(!range.preco_differ ? selectedCd.precoTabelaCx : range.preco_differ, 6);
						selectedCd.caixa         = selectedCd.precoTabelaCx;
						selectedCd.inicialCaixa  = stringToNumber(!range.preco_differ ? selectedCd.inicialCaixa  : range.preco_differ, 6);
					}
				});
			}
		}

		selectedCd.quantidade = stringToNumber(selectedCd.tipoConversaoProd == 'M' ? qtdcx * parseFloat(selectedCd.conversaoUnidadeCx) : qtdcx / parseFloat(selectedCd.conversaoUnidadeCx), 4);
		selectedCd.quantidadeScreen = stringToNumber(selectedCd.tipoConversaoProd == 'M' ? qtdcx * parseFloat(selectedCd.conversaoUnidadeCx) : qtdcx / parseFloat(selectedCd.conversaoUnidadeCx), 4);
		selectedCd.quantidadeCx = qtdcx;
		
		this.cdList.forEach(cd => {
			if (cd.cdId == selectedCd.cdId) {
				cd.quantidade = selectedCd.quantidade;
				cd.quantidadeScreen = stringToNumber(selectedCd.quantidade, 4);
				cd.quantidadeCx = selectedCd.quantidadeCx;
				cd.quantidadePortal = selectedCd.quantidadeCx;
				// cd.unitario = selectedCd.unitario;
			}
		});
		this.calcValorTotalAllCds(selectedCd)
		this.atualizandoFatores(false);

		console.log('this.cdList::33:', JSON.stringify(this.cdList));
	}

	// calcUnitValue(event){
	// 	let unitValue = parseFloat(event.target.value);
	// 	let cdId = event.currentTarget.dataset.cdId;
	// 	let selectedCd = this.cdList.find(cd => cd.cdId === cdId);

	// 	if (selectedCd.unitario != unitValue) {
	// 		selectedCd.unitario = stringToNumber(unitValue, 6);
	// 		selectedCd.caixa = selectedCd.tipoConversao == 'M' ? stringToNumber(parseFloat(unitValue) * parseFloat(selectedCd.conversaoUnidadeCx) : parseFloat(unitValue) / parseFloat(selectedCd.conversaoUnidadeCx), 6);

	// 		let currentProd = this.getCurrentProduct(selectedCd.prodCode);

	// 		this.fillCalcScoreObj(selectedCd, currentProd);

	// 		// console.log(this.calcScoreObj);

	// 		this.getScoreCalcApi(selectedCd);

	// 		this.orderList.forEach(cd => {
	// 			if (cd.id === selectedCd.id) {
	// 				this.refreshCdScoreCalc();
	// 			}
	// 		})
	// 		// this.orderListFiltered = this.orderList;      // ATUALIZAR OS FILTROS TESTE
	// 		if(this.filterLst.length > 0){
	// 			this.orderListFiltered = [];
	// 			this.orderListFiltered = this.orderList.filter(cd => this.filterLst.includes(cd.cds));
	// 		}else{
	// 			this.orderListFiltered = this.orderList;
	// 		}                
	// 	}
	// }

	calcCxValue(event){
		let cxValue = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.cdId === cdId);
		if (selectedCd.caixa != cxValue) {
			selectedCd.caixa = stringToNumber(cxValue, 6);
			selectedCd.unitario = stringToNumber(selectedCd.tipoConversaoProd == 'M' ? cxValue / parseFloat(selectedCd.conversaoUnidadeCx) : cxValue * parseFloat(selectedCd.conversaoUnidadeCx), 6);
	
			// let currentProd = this.getCurrentProduct(selectedCd.prodCode);
			// this.fillCalcScoreObj(selectedCd, currentProd);

			this.cdList.forEach(cd => {
				if (cd.cdId == selectedCd.cdId) {
					cd.quantidade       = selectedCd.quantidade;
					cd.quantidadeScreen = stringToNumber(selectedCd.quantidade, 4);
					cd.quantidadeCx     = selectedCd.quantidadeCx;
					cd.unitarioPortal   = selectedCd.unitario;
					cd.desconto         = selectedCd.desconto;
					cd.margem           = selectedCd.margem;
					cd.verMargem        = selectedCd.verMargem;
					cd.margemAlvo       = selectedCd.margemAlvo;
					cd.caixa            = selectedCd.caixa;
					cd.unitario         = selectedCd.unitario;
					cd.valorTotal       = selectedCd.valorTotal;
					cd.score            = selectedCd.score;
					cd.validadeMinima   = selectedCd.validadeMinima;
					cd.SequenciaOC 		= selectedCd.SequenciaOC;
					cd.quantidadeCx = selectedCd.quantidadeCx;
					cd.isCampaign 		= selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? false : true;
				}
			})
			this.refreshCdScoreCalc();

			this.getScoreCalcApi(selectedCd);

			console.log('calcCxValue');
			// console.log(this.calcScoreObj);

			console.log('orderList xxxxx ' + JSON.stringify(this.cdList)  );

			this.calcValorTotalAllCds(selectedCd);
			this.atualizandoFatores(false);

		}

	}

	calcDiscount(event){
		let discount = parseFloat(event.target.value);
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.cdId === cdId);

		if (selectedCd.desconto != discount) {

			selectedCd.desconto = discount;
			selectedCd.unitario = stringToNumber(selectedCd.desconto > 0 ? stringToNumber(selectedCd.inicialUnitario) * (1 - selectedCd.desconto / 100) : stringToNumber(selectedCd.inicialUnitario), 6);
			selectedCd.caixa = stringToNumber(selectedCd.desconto > 0 ? stringToNumber(selectedCd.inicialCaixa) * (1 - selectedCd.desconto / 100) : stringToNumber(selectedCd.inicialCaixa), 6);

			let currentProd = this.getCurrentProduct(selectedCd.prodCode);

			this.fillCalcScoreObj(selectedCd, currentProd);
	
			console.log('calcDiscount');
			console.log(this.calcScoreObj);

			// this.calcValorTotalAllCds(selectedCd);

			this.cdList.forEach(cd => {
				if (cd.cdId == selectedCd.cdId) {
					cd.desconto = selectedCd.desconto;
					cd.unitario = selectedCd.unitario;
					cd.caixa    = selectedCd.caixa;
					cd.unitarioPortal   = selectedCd.unitario;
				}
			})
			this.refreshCdScoreCalc();

			this.getScoreCalcApi(selectedCd);
			this.atualizandoFatores(false);

		}
	}

	fillCalcScoreObj(selectedCd, currentProd) {
		this.calcScoreObj = [];
		this.calcScoreObj.push({
			cdId: selectedCd.cnpjCd,
			productBu: selectedCd.categoria,//(currentProd.categoria == '' || currentProd.categoria == undefined) ? 'SEM BU' : currentProd.categoria,
			productCode: selectedCd.prodCode,
			cost: (selectedCd.custoCx != null && selectedCd.custoCx != undefined) ? selectedCd.custoCx : 10,
			quantity: selectedCd.quantidadeCx,
			unitPrice: stringToNumber(selectedCd.caixa, 6),
			listPrice: stringToNumber(selectedCd.inicialCaixa, 6), // stringToNumber(currentProd.precoTabelaCx, 6),
			taxPercent: selectedCd.aliquota,
			SequenciaOC: selectedCd.SequenciaOC,
			isContract: selectedCd.valorBloqueado != undefined ? selectedCd.valorBloqueado : false,
			isCampaign: selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ ) ? false : true
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

			for (var i = 0; i < this.prodList.length; i++) {
				if (this.mockedProdList[this.prodList[i].code] != undefined) {
					if (this.mockedProdList[this.prodList[i].code].code == productCode) {
						currentProd = this.mockedProdList[this.prodList[i].code];
						break;
					}
				}
			}

			this.fillCalcScoreObj(selectedCd, currentProd);

			console.log('handleMargin');
			console.log(this.calcScoreObj);

			reverseCalcScreen({ clListString: JSON.stringify(this.calcScoreObj) })
				.then(result => {
					console.log('reverseCalcScreen: entrou certo!');
					console.log(JSON.parse(result));
					let resultObj = JSON.parse(result);
					for (var i = 0; i < resultObj.length; i++) {
                        
		                let selectedCd = this.cdList.find(cd => cd.id === resultObj[i].cdId);

						selectedCd.unitario = stringToNumber(selectedCd.tipoConversaoProd == 'M' ? resultObj[i].unitPrice / selectedCd.conversaoUnidadeCx : resultObj[i].unitPrice * selectedCd.conversaoUnidadeCx, 6);
						selectedCd.caixa    = stringToNumber(resultObj[i].unitPrice, 6);
						selectedCd.desconto = stringToNumber(resultObj[i].newDiscount, 2);
						selectedCd.score    = stringToNumber(resultObj[i].scoreFinal || (selectedCd && selectedCd.score), 2);

					}
					if (this.isOrderListReturned) {
						this.cdList.forEach(cd => {
							this.orderList.find(cdFromCart => {
								if (cd.cdId == cdFromCart.cdId) {
									cdFromCart.quantidade       = cd.quantidade;
									cdFromCart.quantidadeScreen = stringToNumber(cd.quantidade, 4);
									cdFromCart.quantidadeCx     = cd.quantidadeCx;
									cdFromCart.desconto         = cd.desconto;
									cdFromCart.margem           = cd.margem;
									cdFromCart.verMargem        = cd.verMargem;
									cdFromCart.margemAlvo       = cd.margemAlvo;
									cdFromCart.caixa            = cd.caixa;
									cdFromCart.unitario         = cd.unitario;
									cdFromCart.valorTotal       = cd.valorTotal;
									cdFromCart.valorZerado      = cd.valorZerado;
									cdFromCart.score            = cd.score;
									cdFromCart.SequenciaOC = cd.SequenciaOC;
									cdFromCart.isCampaign 		= cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ ) ? false : true;
								}
							});
						});
					}

					this.calcRefresh(selectedCd);

					this.orderList.forEach(cd => {
						if (cd.id === selectedCd.id) {
							this.refreshCdScoreCalc();
						}
					})
				}).catch(error => {
					console.log('reverseCalcScreen: entrou no erro!');
					console.log(error);
					this.calcRefresh(selectedCd);
				});
		}

		// this.calcValorTotalAllCds(selectedCd);
	}

	calcMargem(selectedCd){
		//let margem = 100*(parseFloat(selectedCd.caixa)-parseFloat(selectedCd.custoCx))/parseFloat(selectedCd.caixa);
		//apenas 3 números depois da virgula
		//selectedCd.margem = stringToNumber(Math.round(margem * 100) / 100, 2);
	}
	
	calcValorTotalAllCds(selectedCd){
		this.cdList = this.cdList.map(cd => {
			let discount = 100-(parseFloat(cd.caixa)*100/parseFloat(cd.inicialCaixa));
			cd.desconto = stringToNumber(discount < 0 ? 0 : (Math.round(discount * 100) / 100), 2);
			cd.valorTotal = stringToNumber(
				(cd.unitarioPortal && cd.quantidadePortal ? cd.unitarioPortal * cd.quantidadePortal :
					(
						cd.quantidadeCx * 
						(	cd.unitario ? (cd.tipoConversaoProd == 'M' ? (cd.unitario * cd.conversaoUnidadeCx) : (cd.unitario / cd.conversaoUnidadeCx)) : 
							(cd.precoTabelaCx)
						), 6
					)
				)
			) 
			|| 0;
			return cd;
		});
	}
	
	calcValorTotalCd(cd){
		let discount = 100-(parseFloat(cd.caixa)*100/parseFloat(cd.inicialCaixa));
		cd.desconto = stringToNumber(discount < 0 ? 0 : (Math.round(discount * 100) / 100), 2);
		// cd.valorTotal = stringToNumber(cd.tipoConversaoProd == 'M' ? parseFloat(cd.quantidadeCx) * parseFloat(cd.caixa) : parseFloat(cd.quantidadeCx) / parseFloat(cd.caixa), 6);
		cd.valorTotal = stringToNumber(
			(cd.unitarioPortal && cd.quantidadePortal ? cd.unitarioPortal * cd.quantidadePortal :
				(
					cd.quantidadeCx * 
					(	cd.unitario ? (cd.tipoConversaoProd == 'M' ? (cd.unitario * cd.conversaoUnidadeCx) : (cd.unitario / cd.conversaoUnidadeCx)) : 
						(cd.precoTabelaCx)
					), 6
				)
			)
		) 
		|| 0;
		return cd;
	}

	handleValidadeMinima(event) {
		let cdId = event.currentTarget.dataset.cdId;
		let selectedCd = this.cdList.find(cd => cd.id === cdId);
		selectedCd.validadeMinima = event.detail.value;
		this.cdList.forEach(cd => {
			if (cd.cdId == selectedCd.cdId) {
				cd.validadeMinima = selectedCd.validadeMinima;
			}
		});
		console.log('selectedCd', selectedCd);
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

	// returnTelaIni() {
	// 	this.automaticSave = false;
	// 	// if(this.recordId == null && this.recordId == '' ){
	// 	this.fillHeader();
	// 	if(this.pedidoComplementar == null || this.pedidoComplementar == undefined){
	// 		this.pedidoComplementar = false;
	// 	}
	// 	this.handleNavigateMix();
	// }

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
				// swal("Ops!", "Erro ao gerar orçamento! Verifique com o administrador!", "error");
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
					// this.enableButtons();
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
		} else {
			//clearInterval(this.saveInterval);
			// this.handleNavigateMix();
		}
	}

	fillHeader() {
		if (this.isBudget) {
			console.log('ORÇAMENTO!');
			this.headerInfoData = {
				NumOrcamento          : this.NumOrcamento,
				valorTotal            : this.valorTotal,
				ClienteEmissorId      : this.ClienteEmissorId,
				ClienteEmissor        : this.ClienteEmissor,
				ClienteEmissorCGC     : this.ClienteEmissorCGC,
				tabelaPreco           : this.tabelaPreco,
				tabelaPrecoNome       : this.tabelaPrecoNome,
				canalEntrada          : this.canalEntrada,
				condicaoPagamento     : this.condicaoPagamento,
				condicaoPagamentoNome : this.condicaoPagamentoNome,
				formaPagamento        : this.formaPagamento,
				contatoOrcamento      : this.contatoOrcamento,
				prazoValidade         : this.prazoValidade,
				dtValidade            : this.dtValidade,
				comentarioCliente     : this.comentarioCliente,
				comentario            : this.comentario,
				hasPermissionERB      : this.hasPermissionERB,
				recordId              : this.recordId,
				isCoordenador         : this.isCoordenador,
				margemAtual           : this.margemAtualGeral.replace('%', ''),
				margemAlvo            : this.margemAtualAlvo.replace('%', ''),
				score                 : this.scoreFinalGeral.replace('%', ''),
				Idportalcotacoes      : this.Idportalcotacoes, 
				recomendacaoRespondida: this.allRecAnswered,
				dtList                : null,
				freteList             : null
			}
			console.log('this.Idportalcotacoes ' + this.Idportalcotacoes);
		} else {
			console.log('PEDIDO!');
			this.headerInfoData = {
				ClienteEmissor           : this.ClienteEmissor,
				ClienteEmissorId         : this.ClienteEmissorId,
				ClienteEmissorCGC        : this.ClienteEmissorCGC,
				medico                   : this.medico,
				medicoId                 : this.medicoId,
				medicoCRM                : this.medicoCRM,
				tabelaPreco              : this.tabelaPreco,
				tabelaPrecoNome          : this.tabelaPrecoNome,
				tipoFrete                : this.tipoFrete,
				valorFrete               : this.valorFrete,
				numeroPedidoCliente      : this.numeroPedidoCliente,
				condicaoPagamento        : this.condicaoPagamento,
				condicaoPagamentoNome    : this.condicaoPagamentoNome,
				contatoOrcamento         : this.contatoOrcamento,
				canalVendas              : this.canalVendas,
				tipoOrdem                : this.tipoOrdem,
				formaPagamento           : this.formaPagamento,
				dtPrevistaEntrega        : this.dtPrevistaEntrega,
				clienteRecebedor         : this.clienteRecebedor,
				clienteRecebedorCGC      : this.clienteRecebedorCGC,
				enderecoEntrega          : this.enderecoEntrega,
				enderecoEntregaId        : this.enderecoEntregaId,
				enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
				comentario               : this.comentario,
				comentarioNF             : this.comentarioNF,
				hasPermissionERB         : this.hasPermissionERB,
				margemAtual              : this.margemAtualGeral.replace('%', ''),
				margemAlvo               : this.margemAtualAlvo.replace('%', ''),
				score                    : this.scoreFinalGeral.replace('%', ''),
				Idportalcotacoes         : this.Idportalcotacoes, 
				recomendacaoRespondida   : this.allRecAnswered,
				createOrderDt            : this.createOrderDt,
				dtList                   : null,
				freteList                : null
			}
			console.log('this.Idportalcotacoes ' + this.Idportalcotacoes);
		}
	}

	// handleNavigateMix() {
	// 	var compDefinition = {};
	// 	if (this.isBudget) {
	// 		var compDefinition = {
	// 			componentDef: "c:createBudget",
	// 			attributes: {
	// 				isEdit: true,
	// 				recordId: this.recordId,
	// 				newRecordId: this.newRecordId,
	// 				isBudget: this.isBudget,
	// 				NumOrcamento          : this.NumOrcamento,
	// 				valorTotal            : this.valorTotal,
	// 				score                 : this.scoreFinalGeral.replace('%', ''),
	// 				ClienteEmissorId      : this.ClienteEmissorId,
	// 				ClienteEmissor        : this.ClienteEmissor,
	// 				ClienteEmissorCGC     : this.ClienteEmissorCGC,
	// 				tabelaPreco           : this.tabelaPreco,
	// 				tabelaPrecoNome       : this.tabelaPrecoNome,
	// 				canalEntrada          : this.canalEntrada,
	// 				condicaoPagamento     : this.condicaoPagamento,
	// 				condicaoPagamentoNome : this.condicaoPagamentoNome,
	// 				formaPagamento        : this.formaPagamento,
	// 				contatoOrcamento      : this.contatoOrcamento,
	// 				hasPermissionERB      : this.hasPermissionERB,
	// 				prazoValidade         : this.prazoValidade,
	// 				dtValidade            : this.dtValidade,
	// 				comentarioCliente     : this.comentarioCliente,
	// 				comentario            : this.comentario,
	// 				isCoordenador         : this.isCoordenador,
	// 				Idportalcotacoes      : this.Idportalcotacoes,
	// 				recomendacaoRespondida: this.allRecAnswered,
	// 				headerInfoData        : JSON.stringify(this.headerInfoData),
	// 				orderListReturned     : JSON.stringify(this.orderList),
	// 				dtParcelas            : this.dtParcelas,
	// 				fretesPorCd           : this.fretesPorCd,
	// 				alreadySaved          : this.alreadySaved,
	// 				newRecordId           : this.newRecordId,
	// 				savingStrData         : JSON.stringify(this.savingObjData)
				
	// 			}
	// 		};
	// 	}else{
	// 		console.log('Gerando Pedido!');

	// 		var compDefinition = {
	// 			componentDef: "c:insertOrder",
	// 			attributes: {
	// 				ClienteEmissor           : this.ClienteEmissor,
	// 				ClienteEmissorId         : this.ClienteEmissorId,
	// 				ClienteEmissorCGC        : this.ClienteEmissorCGC,
	// 				recordId                 : this.recordId,
	// 				medico                   : this.medico,
	// 				medicoId                 : this.medicoId,
	// 				medicoCRM                : this.medicoCRM,
	// 				tabelaPreco              : this.tabelaPreco,
	// 				tabelaPrecoNome          : this.tabelaPrecoNome,
	// 				tipoFrete                : this.tipoFrete,
	// 				valorFrete               : this.valorFrete,
	// 				numeroPedidoCliente      : this.numeroPedidoCliente,
	// 				condicaoPagamento        : this.condicaoPagamento,
	// 				condicaoPagamentoNome    : this.condicaoPagamentoNome,
	// 				contatoOrcamento         : this.contatoOrcamento,
	// 				canalVendas              : this.canalVendas,
	// 				tipoOrdem                : this.tipoOrdem,
	// 				formaPagamento           : this.formaPagamento,
	// 				dtPrevistaEntrega        : this.dtPrevistaEntrega,
	// 				clienteRecebedor         : this.clienteRecebedor,
	// 				clienteRecebedorCGC      : this.clienteRecebedorCGC,
	// 				hasPermissionERB         : this.hasPermissionERB,
	// 				//enderecoEntrega        : this.enderecoEntrega,
	// 				enderecoEntregaId        : this.enderecoEntregaId, 
	// 				enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
	// 				utilizarEnderecoAdicional: this.utilizarEnderecoAdicional,
	// 				comentario               : this.comentario,
	// 				comentarioNF             : this.comentarioNF,
	// 				Idportalcotacoes         : this.Idportalcotacoes,
	// 				recomendacaoRespondida   : this.allRecAnswered,
	// 				createOrderDt            : this.createOrderDt,
	// 				headerInfoData           : JSON.stringify(this.headerInfoData),
	// 				isEdit                   : true,
	// 				isReturn                 : true,
	// 				alreadySaved             : this.alreadySaved,
	// 				newRecordId              : this.newRecordId,
	// 				savingStrData            : JSON.stringify(this.savingObjData),
	// 				orderListReturned        : JSON.stringify(this.orderList)
	// 			}
	// 		};
	// 	}
	// 	try {
	// 	let filterChangeEvent = new CustomEvent('generateorder', {
	// 		detail: { "data": JSON.stringify(compDefinition) }
	// 	});
	// 	// Fire the custom event
	// 	this.dispatchEvent(filterChangeEvent);
	// 	} catch (e) {
	// 		debugger;
	// 		console.log(e);
	// 	}
	// }

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

	searchProducts() {
		getProduct({ pricebook: this.tabelaPreco, clienteId: this.ClienteEmissorId, offSetValue: this.offSetValue.toString(), searchGenericValue: this.searchGenericValue, searchFabricanteValue: this.searchFabricanteValue })
			.then(result => {
				console.log('getProduct: entrou certo!');
				console.log(result);
				this.isLoadingProducts = false;
				if (result != null) {
					for (var i = 0; i < result.length; i++) {
					// this.verMargem = result[i].verMargem;
						this.prodList.push({
							...result[i],
							isContractOrCampaign     : (result[i].showBadgeAcordoComercial || result[i].showBadgeOL) ? true : false,
							precoBadgeCampanhaProduto : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].valorCampanha),
							precoBadgeOL              : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeOL),
							precoBadgeConsignado      : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeConsignado),
							precoBadgeAcordoComercial : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeAcordoComercial),
							precoBadgeshelflife       : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeshelflife)
						});
						if (result[i].code != undefined) {
							this.mockedProdList[result[i].code] = {
								...result[i],
								isContractOrCampaign     : (result[i].showBadgeAcordoComercial || result[i].showBadgeOL) ? true : false,
								precoBadgeCampanhaProduto : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].valorCampanha),
								precoBadgeOL              : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeOL),
								precoBadgeConsignado      : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeConsignado),
								precoBadgeAcordoComercial : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeAcordoComercial),
								precoBadgeshelflife       : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(result[i].precoBadgeshelflife)
							};
						}
					}
				}
				if (result.length < 20) {
					this.showMoreProduct = false;
				} else {
					this.showMoreProduct = true;
				}
				this.prodFilterList = this.prodList;

				this.radioFilter();
			}).catch(error => {
				console.log('getProduct: entrou no erro!');
				console.log(error);
				this.isLoadingProducts = false;
			});
	}

	getFormatDate(input) {
		var datePart = input.match(/\d+/g),
			year     = datePart[0],
			month    = datePart[1], 
			day      = datePart[2];

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

	//sort array by parameters
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

	@track handleCloseCdInfoListModal;

	handleSelectedInfo(event){
		this.openCDDescription();
		// this.scrollToTop();
		let productCode = event.currentTarget.dataset.productCode;
		this.showCdInfoList = event.currentTarget.dataset.cdCnpj;
		event.stopPropagation();
		this.isLoadingLotes = true;
		if(isEmpty(this.cdInfoList)){
			this.cdInfoList = {};
		}
		this.allValues = [];
		this.cdList.forEach(cd => {
			if (cd.prodCode == productCode && cd.precoCNPJShelflife) {
				if (cd.precoCNPJShelflife.includes(';')) {
					this.allValues = cd.precoCNPJShelflife.split(';');
				} else {
					this.allValues.push(cd.precoCNPJShelflife);
				}				
			}
		});

		getLotes({ clienteCGC: this.showCdInfoList, productCode: productCode })
			.then(result => {
				this.isLoadingLotes = false;
				if (isNotEmpty(result)) {
					let currentInfo = [...result];
					this.cdInfoList[this.showCdInfoList] = [];
					for (var i = 0; i < currentInfo.length; i++) {
						let shelfPrice = 0;
						this.allValues.forEach(val => {
							if (val.includes(currentInfo[i].lote) && val.includes(this.showCdInfoList)) {
								shelfPrice = val.split('_')[2];
							}
						});
						this.cdInfoList[this.showCdInfoList].push({
							id: i+1,
							lote: currentInfo[i].lote,
							validade: this.getFormatDate(currentInfo[i].validade),
							saldo: parseInt(currentInfo[i].estoque).toString(),
							preco: new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(shelfPrice)
						});
					}
					this.cdInfoList = {...this.cdInfoList};
				}
			}).catch(error => {
				this.isLoadingLotes = false;
				this.showCdInfoList = false;
			})
	}

	get infoList(){
		return this.showCdInfoList && this.cdInfoList ?this.cdInfoList[this.showCdInfoList] : false ;
	}

	handleSelectedProduct2 (event) {
		let event2 = {
			currentTarget : {
				dataset : {
					productId : event.target.dataset.productId,
					productCode : event.target.dataset.productCode,
					productMalha : event.target.dataset.productMalha
				}
			}
		}
		console.warn(this.prod_);
		this.handleSelectedProduct(event2);
	}
	
	// impede que a malha seja chamada muitas vezes
	handleSelectedProductTimeout;
	@api handleSelectedProductAsync(event){
		console.log('handleSelectedProductAsync handleSelectedProductTimeout:::', this.handleSelectedProductTimeout);
		let scope = this;
		if(scope.handleSelectedProductTimeout){
			clearTimeout(scope.handleSelectedProductTimeout);
		}
		scope.handleSelectedProductTimeout = setTimeout(() => {
			scope.handleSelectedProduct(event);
		}, 1000);
	}
	
	@api handleSelectedProduct(event){
		if (this.isRecommendation && this.isProdReject) {
			return;
		}
		this.selected = '';
		this.activeSection = 'cdaccordion';

        console.log('event:::', event, this.currentSelectedProdCode);
		let productId;
		let productCode;
		let getFromMalha;
		console.log('EVENTO:',event);
        if(event){
			console.log('aqui', this.currentSelectedProdCode);
            productId = event.currentTarget.dataset.productId;
            productCode = (event.currentTarget.dataset.productCode == undefined) ? this.currentSelectedProdCode:event.currentTarget.dataset.productCode;
            getFromMalha = event.currentTarget.dataset.productMalha == 'true' ? true : false;
        } else {
			// console.log('aqui ooo', this.currentSelectedProdCode);
			// console.log('aqui ooo2 ', JSON.stringify(this.prod_));
            productId = this.prod_.prodId; 
            productCode = (this.prod_.prodCode ) ;
            getFromMalha = false;
        }

		console.log('productId', productId);
		console.log('productCode', productCode);
		console.log('getFromMalha', getFromMalha);
        
			this.cdList = [];
			this.showHistoric = false;
			this.isForaMalha = false;
			this.isLoading = true;
			this.tabelaPrecoExternalId = 'B01';        // tirar isso 
			                   
			let DadosProd;
			this.budgetData_.Itens.forEach(obj => {
				if(obj.prodCode == productCode){
					DadosProd = obj;
				}
			});
			getFatorProduto({ prodId: productId, quoteitemId: this.prod_.id })
			.then(response => {
				console.log('Entrou no RESP::',response.data);
				let resp = JSON.parse(response.data);
				this.isLoadingLotes = false;
				if (isNotEmpty(resp)) {
					
					this.verMargem = resp.verMargem || false;
					this.conversao = resp.tipoConversaoProd;
					this.fatordeConversao = stringToNumber(resp.fatorConversaoProd) || 1;
					console.log('this.verMargem ', this.verMargem);
					console.log('this.conversao ', this.conversao);
					console.log('this.fatorConversao ', this.fatordeConversao);
		
					this.atualizandoFatores(false);
					console.log('quantidadeSolicitada ', this.prod_.quantidadeSolicitada);

					let params = {
						clienteCGC: this.ClienteEmissorCGC.replace(/[^\w\s]/gi, ''),
						UF: this.UF,
						productCode: productCode,
						calcMargem: true,
						pricebookExternalId: this.tabelaPrecoExternalId,
						condPagamento: this.budgetData_.CondicaoPagamento,
						isForaMalha: getFromMalha};
					console.log('getMalha >> params:::', params);
					getMalha(params)
					.then(result => {
						console.log('getMalha: entrou certo!', result);
						this.currentSelectedProdCode = productCode;
						this.cdList = [];
						this.current = 0;
						this.savedCdData[productCode] = [];
						
						let currentProductHasForaMalha = false;
		
						//currentProd = this.prodList.find(prod => prod.code == productCode);
						
						console.log(this.prod);
						let currentMalha = [];
						this.isLoading = false;
		
						if (this.handleSelectedProductTimeout && result != null) {
							if (isEmpty(result[0])) {
								console.error("A malha retornou um valor vazio!");
								this.swalErroMalha(); // ERRO QND A MALHA ESTÁ FORA (Protheus retonando obj vazio)
							} else if (result[0]['code'] != undefined) {
								this.swalErroMalha(); // ERRO QND A MALHA ESTÁ FORA (Informática fora)
							} else if (result[0]['msgerro'] != undefined) {
								swal('Aviso ERP', `${result[0]['msgerro']}`, 'warning'); // ERRO QND N TEM O PRODUTO PRO CLIENTE
							} else if (result[0]['msgErro'] != undefined) {
								swal('Aviso ERP', `${result[0]['msgErro']}`, 'warning'); // ERRO QND N TEM O CLIENTE 
							} else {
								if (isNotEmpty(result[0]['cds'])) {
									this.calcScoreObj = [];
									currentMalha = [...result[0]['cds']];
									for (var i = 0; i < currentMalha.length; i++) {
										currentMalha[i] = {...currentMalha[i]};
										currentMalha[i].cnpj = currentMalha[i].cnpj || (currentMalha[i].cdId.length == 14 && currentMalha[i].cdId);
										console.log('currentMalha[i]: ', JSON.stringify(currentMalha[i]));
										var precoTabelaCx = this.prod_.precoTabelaCx != undefined ? this.prod_.precoTabelaCx : 0 ;
										if (!this.prod_.showBadgeOL && !this.prod_.showBadgeAcordoComercial) {
											this.prod_.precoTabelaCx = currentMalha[i].preco;
											if( isEmpty(currentMalha[i].preco)){
												this.prod_.valorZerado = false; //true;
											}
										} 
										this.prod_.precoMalha = currentMalha[i].preco;
										
										console.log('ean: ' + result[0].ean);
										if (currentMalha[i].foramalha == false) {
											this.calcScoreObj.push({
												cdId        : currentMalha[i].cnpj,
												productBu   : this.prod_.categoria,
												productCode : productCode,
												cost        : isNotEmpty(currentMalha[i].custo) ? currentMalha[i].custo : 10,
												quantity    : 0,
												unitPrice   : stringToNumber(this.prod_.precoTabelaCx, 6),
												listPrice   : stringToNumber(this.prod_.precoTabelaCx, 6), // stringToNumber(this.prod_.precoTabelaCx, 6),
												taxPercent  : currentMalha[i].aliquota,
												valorZerado : false,//currentMalha[i].preco == 0 ? true : false,
												isContract  : isNotEmpty(this.prod_.valorBloqueado) ? this.prod_.valorBloqueado : false,
												SequenciaOC: isNotEmpty(this.prod_.SequenciaOC) ? this.prod_.SequenciaOC : '',
												isCampaign  : isNotEmpty(this.prod_.valorCampanha) ? false : isEmpty(this.prod_.showBadgeShelflifeCNPJ) ? false : true
											});
										}
										let hasShelflifeCNPJ = false;
										this.allValues = [];
										if (this.prod_.precoCNPJShelflife) {
											if (this.prod_.precoCNPJShelflife.includes(';')) {
												this.allValues = this.prod_.precoCNPJShelflife.split(';');
											} else {
												this.allValues.push(this.prod_.precoCNPJShelflife);
											}				
										}
										this.allValues.forEach(val => {
											if (val.includes(currentMalha[i].cnpj)) {
												hasShelflifeCNPJ = true;
											}
										});
		
										if (currentMalha[i].foramalha) {
											currentProductHasForaMalha = true;
										}
										//this.conversao = (this.conversao == null) ? this.budgetData_.conversao: this.conversao;
										//this.fatordeConversao = (this.fatordeConversao == null) ? this.budgetData_.fatordeConversao: this.fatordeConversao;
										let campaignPrice = 0;
										let campaignPriceNull = 0;
		
										if (this.prod_.precoCNPJCampanha) {
											if (this.prod_.precoCNPJCampanha.includes(";")) {
												this.prod_.precoCNPJCampanha.split(";").forEach(cnpjToPrice =>{
													let cnpjToPriceVal = cnpjToPrice.split(",");
													if (cnpjToPrice.includes(currentMalha[i].cnpj)) {
														campaignPrice = parseFloat(cnpjToPriceVal[1]);
													} else if (cnpjToPrice.includes('null')) {
														campaignPriceNull = parseFloat(cnpjToPriceVal[1]);
													}
												});
											} else {
												let cnpjToPriceVal = this.prod_.precoCNPJCampanha.split(",");
												if (this.prod_.precoCNPJCampanha.includes(currentMalha[i].cnpj)) {
													campaignPrice = parseFloat(cnpjToPriceVal[1]);
												} else if (this.prod_.precoCNPJCampanha.includes('null')) {
													campaignPriceNull = parseFloat(cnpjToPriceVal[1]);
												}
											}
											if (campaignPrice == 0 && campaignPriceNull != 0) {
												campaignPrice = campaignPriceNull;
											}
										}
										console.log(campaignPrice);
		
										let precoSugerido;
										if (currentMalha[i].range && !this.prod_.showBadgeOL && !this.prod_.showBadgeAcordoComercial && campaignPrice == 0 && !this.prod_.showBadgeshelflife) {
											if (currentMalha[i].range.length > 0) {
												currentMalha[i].range.forEach(range => {
													if (range.range_min <= 0 && (isEmpty(range.range_max) || range.range_max >= 0)) {
														precoSugerido = this.prod_.precoTabelaCx = !!range.preco_differ ? stringToNumber(range.preco_differ, 6) : this.prod_.precoTabelaCx;
													}
												});
											}
										}
		
										let boolBadgeCampanha = isNotEmpty(this.prod_.showBadgeCampanha) ? this.prod_.showBadgeCampanha : false;
										let boolBadgeCampanhaVend = isNotEmpty(this.prod_.showBadgeCampanhaVendedor) ? this.prod_.showBadgeCampanhaVendedor : false;
										console.log(this.prod_.dataBadgeCampanha);
										//this.fatordeConversao = this.prod_.fatorConversaoProd ? this.prod_.fatorConversaoProd : '1';
										//this.conversao = this.prod_.tipoConversaoProd ? this.prod_.tipoConversaoProd : 'N';	
										this.prod_.precoTabelaCx = stringToNumber(this.prod_.precoTabelaCx, 6);
										this.prod_.precoFabricaCx = stringToNumber(this.prod_.precoFabricaCx, 6);
										this.prod_.conversaoUnidadeCx = stringToNumber(this.prod_.conversaoUnidadeCx, 6);
										this.prod_.precoMalha = stringToNumber(this.prod_.precoMalha, 6);
		
										// CDS bloqueados foi definido incorretamente, na verdade são os CDs aptos a receberem cotações
										let cdbloqueado = !this.CDsBloqueado || !this.CDsBloqueado.includes(currentMalha[i].cnpj);
										let cdIdAtual = currentMalha[i].cnpj + '_' + productCode;
										this.comentario = (this.prod_.comentario != undefined) ? this.prod_.comentario: '';
										let trueFator = this.conversao != 'D' ? this.fatordeConversao : 1/this.fatordeConversao;
										let unitarioPortal = this.conversao != 'N' ? trueFator * this.prod_.precoTabelaCx : this.prod_.precoTabelaCx;
										// let quantidadeSolicitada = Math.round(this.prod_.quantidadeSolicitada * trueFator);
										
										let newCd = Object.assign({}, {...this.prod_}, {
											cdId: cdIdAtual,
											prodCode: productCode,
											precoFabricaCx: this.prod_.precoFabricaCx,
											precoFabricaUn: stringToNumber(this.prod_.tipoConversaoProd == 'M' ? this.prod_.precoFabricaCx / this.prod_.conversaoUnidadeCx : this.prod_.precoFabricaCx * this.prod_.conversaoUnidadeCx, 6),
											precoTabelaCx: this.prod_.precoTabelaCx,
											precoMalha: this.prod_.precoMalha,
											precoTabelaUn: stringToNumber(this.prod_.tipoConversaoProd == 'M' ? this.prod_.precoTabelaCx / this.prod_.conversaoUnidadeCx : this.prod_.precoTabelaCx * this.prod_.conversaoUnidadeCx, 6),
											ean: result[0].ean,
											adicionado: false,
											SequenciaOC: this.prod_.SequenciaOC || '',
											foraMalha: currentMalha[i].foramalha,
											buscaForaMalha: false,
											comentario: this.prod_.comentario || '',
											tipoConversao: this.prod_.tipoConversao,
											fatordeConversao : this.prod_.fatorConversao || 1,
											index: currentMalha[i].prioridade,
											cds: currentMalha[i].filial,
											cnpjCd: currentMalha[i].cnpj || currentMalha[i].cdId,
											lote: "",
											estoque: (currentMalha[i].saldo != null && currentMalha[i].saldo != undefined) ? currentMalha[i].saldo : 0,
											estoqueUn: stringToNumber(isNotEmpty(currentMalha[i].saldo) ? this.prod_.tipoConversaoProd == 'M' ? currentMalha[i].saldo * this.prod_.conversaoUnidadeCx : currentMalha[i].saldo / this.prod_.conversaoUnidadeCx : 0 * this.prod_.conversaoUnidadeCx, 2),
											un: "UN",
											// quantidade: cdIdAtual == this.prod_.cdId && this.prod_.quantidade ? Math.round(this.prod_.quantidade * trueFator) : quantidadeSolicitada,
											// quantidadeScreen: cdIdAtual == this.prod_.cdId && this.prod_.quantidadeScreen ? Math.round(this.prod_.quantidadeScreen * trueFator) : quantidadeSolicitada,
											quantidadeCx: cdIdAtual == this.prod_.cdId && this.prod_.quantidadeCx || undefined,
											// quantidadeCxFixo: cdIdAtual == this.prod_.cdId && this.prod_.quantidadeCxFixo ? Math.round(this.prod_.quantidadeCxFixo * trueFator) : quantidadeSolicitada,
											quantidadePortal: (cdIdAtual == this.prod_.cdId && this.prod_.quantidadePortal) || undefined,
											unitario: stringToNumber((cdIdAtual == this.prod_.cdId && this.prod_.unitario)),// || this.prod_.tipoConversaoProd == 'M' ? this.prod_.precoTabelaCx / this.prod_.conversaoUnidadeCx : (this.prod_.precoTabelaCx * this.prod_.conversaoUnidadeCx), 6),
											// caixa:  (currentMalha[i].cnpj + '_' + productCode == this.prod_.cdId ) ? this.prod_.unitario != undefined && this.prod_.unitario != 0 ? this.prod_.unitario:(precoTabelaCx > 0 ? precoTabelaCx: this.prod_.precoTabelaCx): this.prod_.precoTabelaCx ,
											caixa: stringToNumber((cdIdAtual == this.prod_.cdId && this.prod_.caixa)),
											//  || 
											// 						this.prod_.unitario ? 
											// 						(this.prod_.tipoConversaoProd == 'M' ? (this.prod_.unitario * this.prod_.conversaoUnidadeCx) : (this.prod_.unitario / this.prod_.conversaoUnidadeCx)) : 
											// 						this.prod_.precoTabelaCx, 6) ,
											unitarioPortal: (cdIdAtual == this.prod_.cdId && this.prod_.unitarioPortal) || unitarioPortal,
											inicialUnitario: stringToNumber(this.prod_.tipoConversaoProd == 'M' ? (currentMalha[i].preco / this.prod_.conversaoUnidadeCx) : (currentMalha[i].preco * this.prod_.conversaoUnidadeCx), 6),
											inicialCaixa: currentMalha[i].preco,
											precoSugerido: precoSugerido,
											range: currentMalha[i].range,
											rangeStringify: JSON.stringify(currentMalha[i].range),
											conversaoUnidadeCx: this.prod_.conversaoUnidadeCx != undefined ? (this.prod_.conversaoUnidadeCx > 0 ? this.prod_.conversaoUnidadeCx : 1) : 1,
											desconto: 0,
											valorTotalUnd: this.prod_.valorTotalUnd || 0,
											valorTotalCx: this.prod_.valorTotalCx || 0,
											custoDif: 0.3,
											aliquota: currentMalha[i].aliquota,
											custoCx: isNotEmpty(currentMalha[i].custo) ? currentMalha[i].custo : 10,
											margem: 0,
											margemAlvo: 0,
											margemTotalCd: 0,
											margemAlvoTotalCd: 0,
											score: 0,
											scoreBU: 0,
											scoreMix: 0,
											valorCampanha: campaignPrice,
											precoBadgeCampanhaProduto : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(campaignPrice),
											validadeMinima: this.prod_.validadeMinima,
											dataBadgeCampanhaVendCNPJ: this.prod_.dataBadgeCampanhaVendedor,
											valorBloqueado           : this.prod_.valorBloqueado,
											valorZerado              : false, //isEmpty(currentMalha[i].preco),
											verMargem                : this.verMargem,
											bloqRegionalizacao       : currentMalha[i].BloqRegionalizacao ? currentMalha[i].BloqRegionalizacao : false,
											laboratorio              : currentMalha[i].laboratorio ? currentMalha[i].laboratorio : null,
											showBadgeOL              : isNotEmpty(this.prod_.showBadgeOL) ? this.prod_.showBadgeOL : false,
											showBadgeCampanha        : boolBadgeCampanha,
											showBadgeCampanhaCD      : isNotEmpty(boolBadgeCampanha) && (isEmpty(this.prod_.dataBadgeCampanha) || this.prod_.dataBadgeCampanha.includes("null") || this.prod_.dataBadgeCampanha.includes(currentMalha[i].cnpj)),
											showBadgeCampanhaVendedor : boolBadgeCampanhaVend,
											showBadgeCampanhaVendedorCD : isNotEmpty(boolBadgeCampanhaVend) && (isEmpty(this.prod_.dataBadgeCampanhaVendCNPJ) || this.prod_.dataBadgeCampanhaVendCNPJ.includes("null") || this.prod_.dataBadgeCampanhaVendCNPJ.includes(currentMalha[i].cnpj)),
											showBadgeShelflifeCNPJ   : hasShelflifeCNPJ,
											cbBloqueado: cdbloqueado,
											// oppPerdida : (!!DataPedidoPerdido) ? DataPedidoPerdido.substring(8, 10) +  '/' +  DataPedidoPerdido.substring(5, 7) + '/' +  DataPedidoPerdido.substring(0, 4)  + ' Perdido ' + (ValorPedidoPerdido ? stringToNumber(ValorPedidoPerdido, 2): ''): '',
											// oppGanha : (!!DataPedidoGanho) ?  DataPedidoGanho.substring(8, 10) +  '/' +  DataPedidoGanho.substring(5, 7) + '/' +  DataPedidoGanho.substring(0, 4)  + ' Ganho ' + (ValorPedidoGanho ? stringToNumber(ValorPedidoGanho, 2): ''): ''
										});
										newCd  = this.calcValorTotalCd(newCd);
										this.cdList.push(newCd);
									}
								}
							}
						} else {
							this.swalErroMalha(); // ERRO QND A MALHA ESTA FORA (Status Code 500)
							return;
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
						this.atualizandoFatores(false);
						this.calcScoreApi(productCode);
		
						this.lastProduct = productId;
		
					}).catch(error => {
		
						swal('Erro', `Erro ao buscar a malha. Verifique com o administrador!`, 'error');
						console.log('getMalha: entrou no erro!');
						console.log(error);
					}).finally(() => {
						this.isLoading = false;
						console.log('cdList:::', this.cdList);
						this.cdList = [...this.cdList];
					});
				}
			}).catch(error => {
				this.isLoadingLotes = false;
				this.showCdInfoList = false;
			})
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

		// this.cdList.find(cd => cd.prodCode == productCode).buscaForaMalha = false;
		// var cdbloqueado = 

		this.cdList = this.cdList.filter(cd => cd.foraMalha != true);
		this.cdList.forEach(cd =>{
			cd.cdbloqueado = ( this.CDsBloqueado == undefined ) ? true  : this.CDsBloqueado.includes(currentMalha[i].cnpj) ? false: true;
		});

		this.calcScoreApi(productCode);
	}
 
	getForaMalha(productCode) {

		this.isForaMalha = !this.isForaMalha;
		
		this.calcScoreObj = [];
		
		this.cdList.forEach(cd => {
			if (cd.prodCode == productCode) {
				cd.buscaForaMalha = true;
			}
		})
		// this.cdList.find(cd => cd.prodCode == productCode).buscaForaMalha = true;
		
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
						unitPrice: stringToNumber(this.savedCdData[productCode][i].precoTabelaCx, 6),
						listPrice: stringToNumber(this.savedCdData[productCode][i].precoTabelaCx, 6),
						taxPercent: this.savedCdData[productCode][i].aliquota,
						isContract: this.savedCdData[productCode][i].valorBloqueado != undefined ? this.savedCdData[productCode][i].valorBloqueado : false,
						SequenciaOC: this.savedCdData[productCode][i].SequenciaOC != undefined ? this.savedCdData[productCode][i].SequenciaOC : '',
						isCampaign: this.savedCdData[productCode][i].valorCampanha == undefined ? false : (this.savedCdData[productCode][i].valorCampanha == 0 && !this.savedCdData[productCode][i].showBadgeShelflifeCNPJ ) ? false : true
					});
				}
				
			}
		}

		console.log(this.calcScoreObj);
		this.calcScoreApi(productCode);
	}

	getCurrentProduct(productCode) {
		for (var i = 0; i < this.cdList.length; i++) {
			if (this.mockedProdList[this.cdList[i].code] != undefined) {
				if (this.mockedProdList[this.cdList[i].code].code == productCode) {
					return this.mockedProdList[this.cdList[i].code];
				}
			}
		}
	}

	getScoreCalcApi(selectedCd) {
		console.log('getScoreCalcApi', this.calcScoreObj);
		calcProducts({ clListString: JSON.stringify(this.calcScoreObj) })
			.then(result => {
				console.log('calcProducts: entrou certo!');
				console.log(JSON.parse(result));
				let resultObj = JSON.parse(result);
				for (var i = 0; i < resultObj.length; i++) {
                    let selectedCd1 = this.cdList.find(cd => cd.cdId == (resultObj[i].cdId + '_' + resultObj[i].productCode));
					selectedCd1.margem = stringToNumber(resultObj[i].margem, 2);
					selectedCd1.margemAlvo = stringToNumber(resultObj[i].margemAlvo, 2);
					if (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ) {
						selectedCd1.score = stringToNumber(resultObj[i].scoreFinal, 2);
					} else {
						selectedCd1.score = 100.00;
					}
				}

				this.cdList.forEach(cd => { 
					if (cd.cdId == selectedCd.cdId) {
						cd.margem           = selectedCd.margem;
						cd.margemAlvo       = selectedCd.margemAlvo;
						cd.score            = selectedCd.score;
					}

				});

				// this.calcValorTotalAllCds(selectedCd);
		
			}).catch(error => {
				console.log('calcProducts: entrou no erro!');
				console.log(error);
				this.calcRefresh(selectedCd);
			});
	}

	calcScoreApi(productCode) {

        // if(!this.calcScoreObj){
        //     this.fillCalcScoreObj(selectedItem, selectedItem);
        // }
		console.log(productCode);
		console.log(this.calcScoreObj);

		calcProducts({ clListString: JSON.stringify(this.calcScoreObj) })
			.then(result => {
				this.isLoading = false;
				console.log('calcProducts: entrou certo!',result,JSON.parse(result));
				let resultObj = JSON.parse(result);

				console.log(resultObj);
				for (var i = 0; i < resultObj.length; i++) {
					console.log(resultObj[i]);

					let calcCdId = resultObj[i].cdId + '_' + resultObj[i].productCode;
                    let selectedItem = this.cdList.find(cd => cd.cdId == calcCdId);
                    console.log('calcCdId:::', calcCdId);
                    if(selectedItem){
                        selectedItem.margem = stringToNumber(resultObj[i].margem, 2);
                        selectedItem.margemAlvo = stringToNumber(resultObj[i].margemAlvo, 2);
                        if (selectedItem.valorCampanha == 0 && !selectedItem.showBadgeShelflifeCNPJ) {
                            selectedItem.score = stringToNumber(resultObj[i].scoreFinal, 2);
                        } else {
                            selectedItem.score = 100.00;
                        }
                    }
				}

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
			if (cd.precoMalha == undefined || cd.precoMalha == null || cd.precoMalha == '') {
				if (!prodList.includes(cd.prodCode)) {
					prodList.push(cd.prodCode);
				}
				cdObj[cd.prodCode + '_' + cd.cnpjCd] = {
					cnpjCd: cd.cnpjCd,
					qtd: cd.quantidadeCx,
					nome: cd.nome
				}
				cdObjIndex[cd.prodCode + '_' + cd.cnpjCd] = index;
			}
		})

		let listProductNotFound = [];
		
		if (prodList.length > 0) {
			swal('Aviso!', 'Checando preços dos itens do carrinho.', 'warning');
			// this.ClienteEmissorCGC = '28806545000109';// tirar isso 
			// this.tabelaPrecoExternalId = 'B01';        // tirar isso 
			getMalha({ clienteCGC: this.ClienteEmissorCGC.replace(/[^\w\s]/gi, ''),UF: this.UF, productCode: prodList.join(','), calcMargem: true, pricebookExternalId: this.tabelaPrecoExternalId, condPagamento: this.CondicaoPagamento, isForaMalha: true })
				.then(result => {
					console.log('getMalha: entrou certo!');
					console.log(result);
					if (this.handleSelectedProductTimeout && result != null) {
						if (JSON.stringify(result[0]) == '{}') {
							this.swalErroMalha(); // ERRO QND A MALHA ESTÁ FORA (Protheus retonando obj vazio)
						} else if (result[0]['code'] != undefined) {
							this.swalErroMalha(); // ERRO QND A MALHA ESTÁ FORA (Informática fora)
						} else if (result[0]['msgerro'] != undefined) {
							swal('Aviso ERP', `${result[0]['msgerro']}`, 'warning'); // ERRO QND N TEM O PRODUTO PRO CLIENTE
						} else if (result[0]['msgErro'] != undefined) {
							swal('Aviso ERP', `${result[0]['msgErro']}`, 'warning'); // ERRO QND N TEM O CLIENTE 
						} else {
							result.forEach(item => {
								if (item.cds != undefined) {
									item.cds.forEach(cdItem => {
										let product = cdObj[item.codprotheus + '_' + cdItem.cnpj];
										if (product != undefined) {
											let cd = item.cds.find(cd => cd.cnpj == product.cnpjCd);
											console.log(item);
											console.log(product);
											console.log(cd);
											this.orderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].precoMalha = cd.preco;
											this.orderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].inicialCaixa = cd.preco;
											this.orderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].aliquota = cd.aliquota;
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
					console.log('getMalha: entrou no erro!');
					console.log(error);
				})
		} else {
			this.isLoadingScore = false;
			this.enableButtons();
			this.refreshCdScoreCalc();
		}
	}

	refreshCdScoreCalc() {
		this.calcAllScoreObj = [];

		this.hasOnlyCampaign = true; // se só tem campanha, calcula normal, SE tem mais itens sem ser campanha, desconsidera os itens de campanha
		this.hasOnlyContract = true;
		this.cdList.forEach(cd => {
			if (this.hasOnlyCampaign && cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) {
				this.hasOnlyCampaign = false;
			}
			if (this.hasOnlyContract && !cd.valorBloqueado) {
				this.hasOnlyContract = false;
			}
			if (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.valorBloqueado) {
				this.calcAllScoreObj.push({
					cdId: cd.cnpjCd,
					productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
					productCode: cd.prodCode,
					cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
					quantity: cd.quantidadeCx,
					verMargem: cd.verMargem,
					unitPrice: stringToNumber(cd.caixa, 6),
					listPrice: stringToNumber(cd.inicialCaixa, 6),// stringToNumber(currentProd.precoTabelaCx, 6),
					taxPercent: cd.aliquota,
					isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
					SequenciaOC: cd.SequenciaOC != undefined ? cd.SequenciaOC : '',
					isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? false : true
				});
			}
		});
		if (this.hasOnlyCampaign || this.hasOnlyContract) {
            this.calcAllScoreObj = [];
            this.cdList.forEach(cd => {
				this.calcAllScoreObj.push({
					cdId: cd.cnpjCd,
					productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
					productCode: cd.prodCode,
					cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
					quantity: cd.quantidadeCx,
					unitPrice: stringToNumber(cd.caixa, 6),
					listPrice: stringToNumber(cd.inicialCaixa, 6),
					taxPercent: cd.aliquota,
					isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
					isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? false : true
				});
            });
        }
		console.log(this.calcAllScoreObj);

		calcAllProducts({ clListString: JSON.stringify(this.calcAllScoreObj) })
			.then(result => {
				console.log('calcAllProducts: entrou certo!');
				console.log('result: ' + result);
				let resultJson = JSON.parse(result);
				console.log(resultJson);

				this.calcAllScoreObj.forEach(calcObj => {                    
					for (var i = 0; i < resultJson['cdMap'][calcObj.cdId].length; i++) {
						if ((calcObj.cdId + '_' + calcObj.productCode) == (resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode)) {
							// let index = this.orderList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
							let index = this.cdList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);

							let scoreBU           = calcObj.isCampaign || calcObj.isContract ? 100.00 : stringToNumber(resultJson['results'][calcObj.productBu]['scoreFinal'], 2);
							let scoreMix          = calcObj.isCampaign || calcObj.isContract ? 100.00 : stringToNumber(resultJson['results'][calcObj.productBu]['scoreMix'], 2);
							let scoreItem         = calcObj.isCampaign || calcObj.isContract ? 100.00 : stringToNumber(resultJson['cdProdMap'][calcObj.cdId+'_'+calcObj.productCode]['scoreFinal'], 2);
							let margemTotalCd     = stringToNumber(resultJson['results'][calcObj.cdId]['scoreDenominator'], 2);
							let margemAlvoTotalCd = stringToNumber(resultJson['results'][calcObj.cdId]['scoreNumerador'], 2);
							let scoreCd           = calcObj.isCampaign || calcObj.isContract ? 100.00 : stringToNumber(resultJson['results'][calcObj.cdId]['scoreFinal'], 2);

							this.cdList[index] = {
								...this.cdList[index],
								score: scoreCd,
								scoreBU,
								scoreMix,
								scoreItem,
								margemTotalCd,
								margemAlvoTotalCd
							}

							// this.orderCdList[indexFilteredList] = {
							// 	...this.orderCdList[indexFilteredList],
							// 	margem: margemTotalCd,
							// 	margemAlvo: margemAlvoTotalCd,
							// 	scoreCd: scoreCd
							// }
							
							// this.orderList[index] = {
							// 	...this.orderList[index],
							// 	score: scoreCd,
							// 	scoreBU,
							// 	scoreMix,
							// 	scoreItem,
							// 	margemTotalCd,
							// 	margemAlvoTotalCd
							// }

							// this.orderListFiltered[indexCdClone] = {
							// 	...this.orderListFiltered[indexCdClone],
							// 	score: scoreCd,
							// 	scoreBU,
							// 	scoreMix,
							// 	scoreItem,
							// 	margemTotalCd,
							// 	margemAlvoTotalCd
							// }
						}
					}
				})
				if (!this.hasOnlyCampaign && !this.hasOnlyContract) {
                    this.cdList.forEach(item => {
                        if (item.valorCampanha != 0 || item.showBadgeShelflifeCNPJ || item.valorBloqueado) {
                            item.scoreBU   = 100;
                            item.scoreMix  = 100;
                            item.scoreItem = 100;
                        }
                    })
                }
				
				if (resultJson['results']['Order'] != undefined && !this.hasOnlyCampaign && !this.hasOnlyContract) {
					this.margemAtualGeral = stringToNumber(resultJson['results']['Order']['scoreDenominator'], 2) + '%';
					this.margemAtualAlvo  = stringToNumber(resultJson['results']['Order']['scoreNumerador'], 2) + '%';
					this.scoreFinalGeral  = this.hasOnlyCampaign || this.hasOnlyContract ? 100.00 : stringToNumber(resultJson['results']['Order']['scoreFinal'], 2) + '%';

					console.log('eNTRADA ' + JSON.stringify(this.calcAllScoreObj)  );
					console.log('margemAtualGeral xxxxxxx ' + this.margemAtualGeral  );
					console.log('margemAtualAlvo xxxxxxx ' + this.margemAtualAlvo   );
					console.log('scoreFinalGeral xxxxxxx ' + this.scoreFinalGeral );
				} else if ((this.hasOnlyCampaign || this.hasOnlyContract) && this.orderList.length > 0) {
                    this.margemAtualGeral = 100.00 + '%';
                    this.margemAtualAlvo  = 100.00 + '%';
                    this.scoreFinalGeral  = 100.00 + '%';
				} else {
					this.margemAtualGeral = '';
					this.margemAtualAlvo = '';
					this.scoreFinalGeral = '';
				}
				console.log('SHOW DE BOLA');
			}).catch(error => {
				console.log('calcAllProducts: entrou no erro!');
				console.log(error);
			});
	}
	
	handleCdFilter(event){
		console.log('entrou em handleCdFilter');
		console.log(event.currentTarget.dataset.divCds);
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
	
	//Screen must show only 3 cards, also theres a button to show more cards
	handleCd(){
		// console.log('handleCd');

		// if (!this.allCds) {
		// 	console.log('handleCd if');
		// 	this.selectedRadioCd();
		// 	return;
		// }

		// this.orderList.forEach(cdFromCart => {
		// 	this.cdList.find(cd => {
		// 		if (cd.id == cdFromCart.id) {
		// 			cd.adicionado = true;
		// 		}
		// 	});
		// });
		// this.current = 0;
	}
	handleSelectedRadioCd(event){

		this.current = 0;
		this.selected = event.target.value;
		this.allCds = this.selected != 'Com saldo';
		this.cdList = [...this.cdList];
	}

	handleSelectedRadioConversao(event){

		console.log('dataset:::',  JSON.stringify(event.target.value));
		// this.conversao = event.target.value;
		this.conversao = event.target.dataset.id;
		
		if(this.conversao == 'N'){
			this.fatordeConversao = 1;
		}
		console.log('this.conversao ' + this.conversao);
		// this.cdList = this.cdList.map(cdCart => {
		// 	cdCart.quantidadeCx = this.conversao == 'M' ? quantidadeCx * this.fatordeConversao : quantidadeCx / this.fatordeConversao;
		// });
		console.log('this.fatordeConversao ' + this.fatordeConversao);
		this.atualizandoFatores(true, true);
	
	}
	
	handleFatorConversao(event){
		if(event.target.value){
			if(event.target.value.includes('.') || event.target.value.includes(',')){
				let fatorInseridoList = event.target.value.split(/[.|,]+/);
				let decimalFraction = fatorInseridoList[fatorInseridoList.length-1];
				let result = Number.parseFloat(fatorInseridoList.slice(0, -1).join('')+'.'+decimalFraction) || 1;
				this.fatordeConversao = result || 1;
	
			}else{
				this.fatordeConversao = event.target.value ? stringToNumber(event.target.value): 1;
			}
			// this.cdList = this.cdList.map(cdCart => {
			// 	cdCart.quantidadeCx = this.conversao == 'M' ? quantidadeCx * this.fatordeConversao : quantidadeCx / this.fatordeConversao;
			// });
			this.atualizandoFatores(false, true);
		}
	}

	atualizandoFatores(updateProduct, refreshQuantidadeCx){
		if(this.fatordeConversao && this.conversao){
			console.log('this.fatordeConversao::: ', this.fatordeConversao);
			let trueFator = (this.conversao != 'D' ? this.fatordeConversao : (1/this.fatordeConversao)) || 1;
			// let unitarioPortal = this.conversao != 'N' ? trueFator * this.prod_.precoTabelaCx : this.prod_.precoTabelaCx;
			console.log('trueFator:::', trueFator);
			console.log('this.prod_.quantidadeCx:::', this.prod_.quantidadeCx);
			console.log('refreshQuantidadeCx:::', refreshQuantidadeCx);
			console.log('this.prod_.quantidadeSolicitada:::', this.prod_.quantidadeSolicitada);
			console.log('this.fatordeConversao:::', this.fatordeConversao);
			let quantidadeCx;
			if(!this.prod_.quantidadeCx){
				refreshQuantidadeCx = true;
				console.log('atualizandoFatores... A');
				this.prod_.quantidadeCx = Math.trunc(this.conversao == 'D' ? this.prod_.quantidadeSolicitada / this.fatordeConversao : this.prod_.quantidadeSolicitada * this.fatordeConversao);
				quantidadeCx = Math.trunc(this.prod_.quantidadeCx);
			} else if(refreshQuantidadeCx) {
				console.log('atualizandoFatores... B');
				this.prod_.quantidadeCx = Math.trunc(this.conversao == 'D' ? this.prod_.quantidadeSolicitada * this.fatordeConversao : this.prod_.quantidadeSolicitada / this.fatordeConversao);
				quantidadeCx = Math.trunc(this.prod_.quantidadeCx);
			} else {
				console.log('atualizandoFatores... C');
				quantidadeCx = this.prod_.quantidadeCx;//Math.trunc(this.prod_.quantidadeCx || (this.prod_.quantidadeSolicitada * this.fatordeConversao));
			}
			console.log('quantidadeCx:::', quantidadeCx);
			console.log('this.cdList:::', this.cdList, JSON.stringify(this.cdList));
			this.cdList = this.cdList.map(cdCart => {
				let cdIdAtual = cdCart.cnpj + '_' + this.prod_.prodCode;
				cdCart.quantidadeCx = (cdIdAtual == this.prod_.cdId && !refreshQuantidadeCx && cdCart.quantidadeCx) || quantidadeCx || this.prod_.quantidadeCx || this.prod_.quantidadeSolicitada;
				console.log('cdCart.quantidadeCx:::', cdCart.quantidadeCx);
				console.log('cdCart.caixa:::', cdCart.caixa, this.fatordeConversao);
				console.log('this.fatordeConversao * stringToNumber(cdCart.caixa):::', this.fatordeConversao * stringToNumber(cdCart.caixa));
				// cdCart.quantidade = (cdIdAtual == this.prod_.cdId && this.prod_.quantidade) ? Math.round(this.prod_.quantidade * trueFator) : quantidadeCx;
				// cdCart.quantidadeScreen = (cdIdAtual == this.prod_.cdId && this.prod_.quantidadeScreen) ? Math.round(this.prod_.quantidadeScreen * trueFator) : quantidadeCx;
				// cdCart.quantidadeCxFixo = (cdIdAtual == this.prod_.cdId && this.prod_.quantidadeCxFixo) ? Math.round(this.prod_.quantidadeCxFixo * trueFator) : quantidadeCx;
				cdCart.quantidade = cdCart.quantidadeCx;
				cdCart.quantidadeScreen = cdCart.quantidadeCx;
				cdCart.quantidadeCxFixo = cdCart.quantidadeCx;
				cdCart.quantidadePortal = Math.trunc(cdCart.quantidadeCx * trueFator);
				cdCart.unitarioPortal =  stringToNumber(this.conversao == 'D' ? (this.fatordeConversao * stringToNumber(cdCart.caixa)) : (cdCart.caixa / this.fatordeConversao));//cdCart.unitario || cdCart.caixa || 
				cdCart.valorTotal = stringToNumber(cdCart.quantidadePortal) * stringToNumber(cdCart.unitarioPortal);
				return cdCart;
			});
			// this.calcValorTotalAllCds();
			if(updateProduct){
				this.atualizarProduto();
			}
		}
	}

	updateTimer;
	atualizarProduto(){
		if(this.updateTimer != null){
			clearTimeout(this.updateTimer);
		}
		let params = {
			prod: JSON.stringify({
				Id: this.prod_.prodId,
				FatorConversaoPortal__c: this.fatordeConversao ? this.fatordeConversao.toString() : 1,
				TipoConversaoPortal__c: this.conversao,
			})
		};
		console.log('chegou', params);
		this.updateTimer = setTimeout(function() {
			doCalloutWithStdResponse(this, updateProduct, params).then(response =>{
				console.log('ProdutoSalvo: ',JSON.stringify(response));
	
			}).catch(error =>{
				console.log('erro ao atualizar produto: ',error);
			});
		}, 1200);
	}

	handlecomentario(event){

		console.log('comentario ;;; ',  JSON.stringify(event.target.value));
		// this.conversao = event.target.value;
		this.comentario = event.target.value;
		this.prod_.comentario = event.target.value;
	}

	selectedRadioCd(){
		this.current = 0;

		if (this.selected == 'Com saldo') {
			console.log('selectedRadioCd if');
			this.allCds = false;
			this.cdList = [];
		} else {
			console.log('selectedRadioCd else');
			this.allCds = true;
			this.handleCd();
		}
	}
	
	previousCd(){
		if (this.current <= 0){
			return;
		}
		this.current--;
		this.cdListItems = this.cdList.slice(this.current,this.current+3);

	}

	nextCd(){
		if (this.current +2 >= this.cdList.length - 1){
			return;
		}
		
		this.current++;
		this.cdListItems = this.cdList.slice(this.current,this.current+3);
	}

	get showPreviousCdButton() {
		return this.cdListItems && this.current > 0;
	}

	get showNextCdButton() {
		return this.cdListItems && this.current < this.cdListItems.length - 3;
	}

	// previousOrderCd(){
	// 	if (this.currentCd <= 0){
	// 		return;
	// 	}
	// 	this.currentCd--;
	// 	this.cdList = this.cdList.slice(this.currentCd,this.currentCd+3);
	// }

	// nextOrderCd(){
	// 	if (this.currentCd +2 >= this.cdList.length - 1){
	// 			return;
	// 	}
		
	// 	this.currentCd++;
	// 	this.cdList = this.cdList.slice(this.currentCd,this.currentCd+3);
	// }

	handleChangeValue(event){
		if (event.target.name === 'manufacturer'){
			this.manufacturer = this.convertSpecialCharacters(event.target.value);
			console.log(this.manufacturer);
		}
		else if (event.target.name === 'searchProduct'){
			this.productInput = this.convertSpecialCharacters(event.target.value);
			console.log(this.productInput);
		}
		this.filterListMethod();
	}

	onSearchByActivePrinciple(event) {
		this.searchGenericValue = event.currentTarget.dataset.productAtivo;
		console.log(event.target.value);
		this.valorBusca = event.currentTarget.dataset.productAtivo;
		this.isLoadingProducts = true;
		this.handleFilterSearchProd();
	}

	onChangeSearchProductNome(event) {
		this.searchGenericValue = event.target.value;
		console.log(event.target.value);
		this.valorBusca = event.target.value;
		if (event.key === 'Enter') {
			this.isLoadingProducts = true;
			this.handleFilterSearchProd();
		}
	}

	onChangeSearchProductByFabricator(event) {
		console.log(event.target.value);
		this.valorBuscaFabricante = event.target.value;
		this.searchFabricanteValue = event.target.value;
		if (event.key === 'Enter') {
			this.isLoadingProducts = true;
			this.handleFilterSearchProd();
		}
	}

	filterSearchProductFabricatorList(value) {
		//var regex = new RegExp(value, 'gi');
		this.prodFilterList = this.prodList.filter(
			prod => prod.campoBuscaFabricante.toLowerCase().includes(value.toLowerCase()) // row => regex.test(row.campoBuscaFabricante)
		);

		if (this.valorBusca != null){
			//regex = new RegExp(this.valorBuscaNome, 'gi');
			this.prodFilterList = this.prodFilterList.filter(
				prod => prod.campoBusca.toLowerCase().includes(this.valorBusca.toLowerCase()) //row => regex.test(row.campoBusca)
			);
		}
	}

	filterListMethod() {
		this.prodFilterList = [];
		let that = this;
		this.prodList.forEach(item => {
			if (that.convertSpecialCharacters(item.fabricante).includes(that.convertSpecialCharacters(that.manufacturer))){
				if(that.convertSpecialCharacters(item.code).includes(that.productInput) || 
				   that.convertSpecialCharacters(item.nome).includes(that.productInput) || 
				   that.convertSpecialCharacters(item.principioAtivo).includes(that.productInput)){
					
						that.prodFilterList.push(item);
				}
			}
		});
	}

	removeOrderedProduct(event){
	}

	handleSaveCd(event){
		console.log('handleSaveCd - Adicionar');
		let selectedCd = event.target.value;
		// console.log('dataset:::',  JSON.stringify(event.target.dataset));
		console.log('selectedCd:::',  JSON.stringify(selectedCd));

		let caixa = parseFloat(selectedCd.caixa);

		if (selectedCd.quantidadeCx <= 0) {
			swal("Quantidade do produto adicionado deve ser maior que 0!");
			return;
		} else if (selectedCd.quantidadeCx % 1 != 0) {            
			swal("Aviso!", 'Favor verificar quantidade principal do CD, deve ser um valor inteiro!');
			return;
		} else if (selectedCd.valorCampanha != 0 && caixa < selectedCd.valorCampanha && selectedCd.showBadgeCampanhaCD) {            
			swal("Aviso!", 'Valor inserido no produto é menor que o valor da campanha!');
			return;
		}
		this.cdList.forEach(cd => { 
			if (cd.cdId == selectedCd.cdId) {
				cd.adicionado = true;
				cd.quantidadeCx = selectedCd.quantidadeCx;
				cd.unitario = stringToNumber(cd.tipoConversaoProd == 'M' ? selectedCd.caixa / cd.conversaoUnidadeCx : selectedCd.caixa * cd.conversaoUnidadeCx, 6);
				cd.caixa = selectedCd.caixa;
				cd.tipoConversao = this.conversao;
				cd.fatordeConversao = this.fatordeConversao || 1;
				cd.comentario = this.comentario;
			}
		});
		let selectedCdEnvia = this.cdList.find(cd => cd.cdId === selectedCd.cdId);
		if(selectedCdEnvia.unitario <= 0){
			swal("Valor do produto adicionado deve ser maior que 0!");
			return;
		}
		if(selectedCdEnvia.estoque < selectedCdEnvia.quantidadeCx){
			swal({
				title: "Aviso!",
				text: "O CD selecionado esta com estoque menor que quantidade solicitada, deseja continuar?", 
				icon: "warning",
				buttons: {
					Cancelar: {
						text: "Não",
						value: true
					},
					Gerar: {
						text: "Sim",
						value: "Gerar",
					},
				},
				dangerMode: true,
			}).then((value) => {
					console.log(value)
					switch (value) {
						case "Gerar":
							console.log('selectedCdEnvia:::',  JSON.stringify(selectedCdEnvia));
							this.dispatchEvent(new CustomEvent("cdselected", {
								detail: {
									cds: selectedCd.cds,
									cnpjCd: selectedCd.cnpjCd,
									quantidade: selectedCd.quantidadeCx,
									valor: selectedCdEnvia.unitario,
									selectedCd: selectedCdEnvia
									// validadeMinima: selectedCd.validadeMinima
								}
							}));
							this.dispatchEvent(new CustomEvent('closeclick'));
							break;
						default:
							this.cdList.forEach(cd => { 
								if (cd.cdId == selectedCd.cdId) {
									cd.adicionado = false; 
								}
							});
							return;
					}
			});
		}else{
			console.log('selectedCdEnvia:::',  JSON.stringify(selectedCdEnvia));
			this.dispatchEvent(new CustomEvent("cdselected", {
				detail: {
					cds: selectedCd.cds,
					cnpjCd: selectedCd.cnpjCd,
					quantidade: selectedCd.quantidadeCx,
					valor: selectedCdEnvia.unitario,
					selectedCd: selectedCdEnvia
					// validadeMinima: selectedCd.validadeMinima
				}
			}));
			this.dispatchEvent(new CustomEvent('closeclick'));
		}


		// if (!this.isProductInserted(selectedCd) && selectedCd.quantidade != 0) {
		// 	let index = 0;
		// 	if (this.orderList.length > 0) {
		// 		this.orderList.forEach(item => {
		// 			if (item.indexInsertPosition >= index) {
		// 				index = item.indexInsertPosition + 1;
		// 			}
		// 		})
		// 	}
		// 	selectedCd = {
		// 		...selectedCd,
		// 		SequenciaOC: ' ',
		// 		indexInsertPosition: index
		// 	}
		// 	this.keepSavingOrEditing();
		// 	this.refreshCdScoreCalc();
		// 	if (this.objectProdCdList[selectedCd.prodCode] == undefined) {
		// 		this.objectProdCdList[selectedCd.prodCode] = [];
		// 		this.objectProdCdList[selectedCd.prodCode].push(selectedCd);
		// 	} else {
		// 		this.objectProdCdList[selectedCd.prodCode].push(selectedCd);
		// 	}
		// }

		// if (this.objectProdCdList[selectedCd.prodCode] != undefined) {
		// 	for (var i = 0; i < this.objectProdCdList[selectedCd.prodCode].length; i++) {
		// 		console.log(this.objectProdCdList[selectedCd.prodCode][i].prodId);
		// 		console.log(this.objectProdCdList[selectedCd.prodCode][i]);
		// 	}
		// }
		// console.log(this.objectProdCdList);
		// console.log(this.orderList);
		// this.orderListFiltered = this.orderList;
		// handleCdFilter

	}

	handleListSort(event) {
	}
	
	get radioSortOptions() {
		return [
			{ label: "Ordem alfabética", value: "Ordem alfabética" },
			{ label: "Ordem de inserção", value: "Ordem de inserção" }
		];
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
		//á à ã => a
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

	openHistoric(event){
		
		var clienteId = this.ClienteEmissorId
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
						console.log('result getHistorico ');
						console.log(result);
						console.log('teste ' + this.HistoricListTotal.length);
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

		console.log('valida ' + this.tamanho );
		console.log('valida1 ' + this.pageNumber );

		for (var i = this.tamanho; i < this.pageNumber; i++) {
			this.HistoricList.push(this.HistoricListTotal[i]);
		}
		this.pageNumber = this.tamanho;

		if(this.tamanho = 0){
			this.pageNumber = 6;
		}
		console.log('Prev tamanho ' + this.tamanho );
		console.log('Prev ' + this.pageNumber );
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
			console.log('this.HistoricList ');
		}
		for (var i = this.pageNumber ; i < this.tamanho ; i++) {
			this.HistoricList.push(this.HistoricListTotal[i]);
		}
		this.pageNumber = this.tamanho;
		console.log('Next ' + this.pageNumber );
	}


	closeSection(event){
		this.showHistoricSection = !this.showHistoricSection;
		event.target.iconName =  this.showHistoricSection ? 'utility:switch' : 'utility:chevronright';
		let prodId = event.target.value;

		let divHist = this.template.querySelector(`[data-target-id="${prodId}"]`);
		divHist.classList.add('slds-hide');
		this.HistoricSection = '';

	}

	buttonCloseClick(event) {
		this.dispatchEvent(new CustomEvent('closeclick'));
	}

	openModalProductDescription(event){
		this.showProductDescriptionModal = true;
		this.selectedProductModal = event.target.value;
		console.log('this.selectedProductModal ' + this.selectedProductModal);
		// this.scrollToTop();
		event.stopPropagation();
	}

	closeModalProductDescription(){
		this.showProductDescriptionModal = false;
	}

	openCDDescription(){
		this.showCDDescriptionModal = true;
	}

	closeCDDescription(){
		this.showCDDescriptionModal = false;
	}

	openCheckoutModal(){
		this.showCheckoutModal = !this.showCheckoutModal;
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
		console.log(this.orderList);
		console.log('isBudget: ' + this.isBudget);
		console.log('isEdit: ' + this.isEdit);

		let qntdError = false;
		let valorCampanhaError = false;

		this.orderList.forEach(cd => {
			if (stringToNumber(cd.quantidadeCx) % 1 != 0) {
				qntdError = true;
			} else if (cd.valorCampanha != 0 && parseFloat(cd.caixa) < cd.valorCampanha) {            
				valorCampanhaError = true;
			}
		})
		
		if (this.orderList.length == 0) {
			console.log(this.orderList);
			swal("Aviso!", 'Não foi adicionado produto!');
		} else if (qntdError) {
			swal("Aviso!", 'Favor verificar quantidade principal dos produtos inseridos, quantidade principal deve ser um valor inteiro!');
		} else if (valorCampanhaError) {
			swal("Aviso!", 'Favor verificar os valores dos produtos de campanha inseridos, valor do produto não pode ser menor que o valor da campanha!');
		} else {
			if ((this.canalVendas == 'Telefone' || this.canalEntrada == 'Telefone' || this.canalVendas == 'Whatsapp' || this.canalEntrada == 'Whatsapp') && !this.allRecAnswered && this.hasPermissionERB) {
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
			console.log("Calling another component");
			clearInterval(this.saveInterval);
			if (this.isBudget) {
				var compDefinition = {
					componentDef: "c:orderProductCheckout",
					attributes: {
						isEdit:                this.isEdit,
						isBudget:              this.isBudget,
						NumOrcamento:          this.NumOrcamento,
						valorTotal:            this.valorTotal,
						ClienteEmissorId:      this.ClienteEmissorId,
						ClienteEmissor:        this.ClienteEmissor,
						ClienteEmissorCGC:     this.ClienteEmissorCGC,
						tabelaPreco:           this.tabelaPreco,
						tabelaPrecoNome:       this.tabelaPrecoNome,
						canalEntrada:          this.canalEntrada,
						condicaoPagamento:     this.condicaoPagamento,
						condicaoPagamentoNome: this.condicaoPagamentoNome,
						formaPagamento:        this.formaPagamento,
						contatoOrcamento:      this.contatoOrcamento,
						prazoValidade:         this.prazoValidade,
						dtValidade:            this.dtValidade,
						comentarioCliente:     this.comentarioCliente,
						comentario:            this.comentario,
						recordId:              this.recordId,
						dtParcelas:            this.dtParcelas,
						fretesPorCd:           this.fretesPorCd,
						pedidoComplementar:    this.pedidoComplementar,
						margemAtualGeral:      this.margemAtualGeral.replace('%', ''),
						margemAtualAlvo:       this.margemAtualAlvo.replace('%', ''),
						score:                 this.scoreFinalGeral.replace('%', ''),
						verMargem:             this.verMargem,
						Idportalcotacoes:      this.Idportalcotacoes,
						createOrderDt:         this.createOrderDt,
						orderList:             JSON.stringify(this.orderList),
						recomendacaoRespondida:this.allRecAnswered,
						hasPermissionERB:      this.hasPermissionERB,
						alreadySaved:          this.alreadySaved,
						newRecordId:           this.newRecordId,
						savingStrData:         JSON.stringify(this.savingObjData)
					}
				};
	
				try {
					let filterChangeEvent = new CustomEvent('displaymyvaluenew', {
						detail: { "data": JSON.stringify(compDefinition) }
					});
					// Fire the custom event
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
						ClienteEmissor: this.ClienteEmissor,
						ClienteEmissorId: this.ClienteEmissorId,
						ClienteEmissorCGC: this.ClienteEmissorCGC,
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
						comentario: this.comentario,
						comentarioNF: this.comentarioNF,
						dtParcelas: this.dtParcelas,
						fretesPorCd: this.fretesPorCd,
						pedidoComplementar: this.pedidoComplementar,
						margemAtualGeral: this.margemAtualGeral.replace('%', ''),
						margemAtualAlvo: this.margemAtualAlvo.replace('%', ''),
						score: this.scoreFinalGeral.replace('%', ''),
						verMargem:             this.verMargem,
						Idportalcotacoes: this.Idportalcotacoes,
						createOrderDt: this.createOrderDt,
						orderList: JSON.stringify(this.orderList),
						recomendacaoRespondida: this.allRecAnswered,
						hasPermissionERB: this.hasPermissionERB,
						alreadySaved: this.alreadySaved,
						newRecordId: this.newRecordId,
						savingStrData: JSON.stringify(this.savingObjData)
					}
				};

				try {
					let filterChangeEvent = new CustomEvent('displaymyvaluenew', {
						detail: { "data": JSON.stringify(compDefinition) }
					});
					// Fire the custom event
					this.dispatchEvent(filterChangeEvent);
				} catch (e) {
					debugger;
					console.log(e);
				}
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
			"accountId": this.ClienteEmissorId
		}
		this.isLoadingProducts = true;
		getRecommendations({ contextRecordData: objRecommendation })
			.then(result => {
				console.log('getRecommendations: entrou certo!');
				console.log(result);
				this.isLoadingProducts = false;				
				this.prodList = [];
				if (result != undefined) {
					result.forEach(item => {									
						item.isRecommendation = true;
						item.alreadyAnswered = false;
						this.prodList.push({
							...item,
							isContractOrCampaign     : (item.showBadgeAcordoComercial || item.showBadgeOL) ? true : false,
							precoBadgeCampanhaProduto : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.valorCampanha),
							precoBadgeOL              : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeOL),
							precoBadgeConsignado      : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeConsignado),
							precoBadgeAcordoComercial : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeAcordoComercial),
							precoBadgeshelflife       : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeshelflife),
							SequenciaOC: item.SequenciaOC
						});
						if(item.code != undefined && this.mockedProdList[item.code] == undefined) {
							this.mockedProdList[item.code] = {
								...item,
								isContractOrCampaign      : (item.showBadgeAcordoComercial || item.showBadgeOL) ? true : false,
								precoBadgeCampanhaProduto : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.valorCampanha),
								precoBadgeOL              : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeOL),
								precoBadgeConsignado      : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeConsignado),
								precoBadgeAcordoComercial : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeAcordoComercial),
								precoBadgeshelflife       : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.precoBadgeshelflife),
								SequenciaOC: item.SequenciaOC
							};
						}
					})
				}
				console.log(result);
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
		console.log('recommendationApproved');
		this.handleSelectedProduct(event);
		let productId = event.currentTarget.dataset.productId;
		let currentProdInfo;
		this.prodFilterList.forEach(item => {
			if (item.id == productId) {
				console.log(productId);
				item.alreadyAnswered = true;
				currentProdInfo = item;
			}
		})
		this.prodFilterRecommendedList = this.prodFilterRecommendedList.filter(item => item.id != productId);
		console.log(currentProdInfo);
		let objRecApproved = {
			"contextRecordId": this.newRecordId ? this.newRecordId : this.recordId,
			"externalId" : currentProdInfo.id,
			"targetId" : currentProdInfo.targetId,
			"targetActionId" : currentProdInfo.targetActionId,
			"targetActionName" : currentProdInfo.targetActionName,
			"reactionMessage": "",
			"reaction" : "Accepted"
		}
		console.log(objRecApproved);
		setRecommendationReaction({reactionData: objRecApproved});
		return;
	}

	recommendationRefused(event) {
		console.log('recommendationRefused');
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
		console.log(productId);
		let currentProdInfo;
		this.prodFilterList.forEach(item => {
			if (item.id == productId) {
				item.alreadyAnswered = true;
				console.log(productId);
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
				console.log(objRecRefused);						
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
		console.log(event.detail.record);
		console.log(event.detail.prodCode);
		this.isMixClientOpen = false;

		if (event.detail.prodCode != null) {
			this.searchGenericValue = event.detail.prodCode;
			this.valorBusca = event.detail.prodCode;
			this.searchFabricanteValue = "";
			this.handleFilterSearchProd();
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
		// to open modal set isMixClientOpen tarck value as true
		this.isMixClientOpen = true;
		this.scrollToTop();
	}

    scrollToTop() {
        if (!this.desktop) {
            let scrollOptions = {
				left: 0,
				top: 0
			}
			parent.scrollTo(scrollOptions);
        }
    }

	enableButtons() {
		this.disableAdvance = false;
	}

	disableButtons() {
		this.disableAdvance = true;
	}
}