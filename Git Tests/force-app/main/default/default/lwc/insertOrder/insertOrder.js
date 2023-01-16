import { LightningElement, api, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFilteredPaymentConditionData from '@salesforce/apex/OrderScreenController.getFilteredPaymentConditionData';
import getBudgetData from '@salesforce/apex/OrderScreenController.getBudgetData';
import getOrderData from '@salesforce/apex/OrderScreenController.getOrderData';
import getComplementOrderSituation from '@salesforce/apex/OrderScreenController.getComplementOrderSituation';
import getCanEditPrice from '@salesforce/apex/OrderScreenController.getCanEditPrice';
import calcAllProducts from '@salesforce/apex/CalcScore.calcProducts';
import showPicklistValueComponent from '@salesforce/resourceUrl/showPicklistValueComponent';
import getContactData from '@salesforce/apex/OrderScreenController.getContactData';
import getContactRelationData from '@salesforce/apex/OrderScreenController.getContactRelationData';
import getAccountData from '@salesforce/apex/OrderScreenController.getAccountData';
import getToastInfoData from '@salesforce/apex/OrderScreenController.getToastInfoData';
import lockScreen from '@salesforce/apex/OrderScreenController.lockScreen';
import generateBudgetAndOrder from '@salesforce/apex/OrderScreenController.generateBudgetAndOrder';
import updatePaymentConditionAndNotesOrderSonAndSendToAutomaticIntegration from '@salesforce/apex/OrderScreenController.updatePaymentConditionAndNotesOrderSonAndSendToAutomaticIntegration';
import generateComplementOrder from '@salesforce/apex/OrderScreenController.generateComplementOrder';
import generateOrder from '@salesforce/apex/OrderScreenController.generateOrder';
import editLabOrder from '@salesforce/apex/OrderScreenController.editLabOrder';
import editOrder from '@salesforce/apex/OrderScreenController.editOrder';
import { reduceErrors } from 'c/ldsUtils';
import editBudget from '@salesforce/apex/OrderScreenController.editBudget';
import generateBudget from '@salesforce/apex/OrderScreenController.generateBudget';
import getB01Pricebook from '@salesforce/apex/OrderScreenController.getB01Pricebook';
import getEnderecoEntregaData from '@salesforce/apex/OrderScreenController.getEnderecoEntregaData';
import getPricebookExternalId from '@salesforce/apex/OrderScreenController.getPricebookExternalId';
import getApprovedOrder from '@salesforce/apex/OrderScreenController.getApprovedOrder';
import getMalha from '@salesforce/apex/OrderScreenController.getMalha';
import FORM_FACTOR from '@salesforce/client/formFactor';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';
import getTpCondPag from '@salesforce/apex/OrderScreenController.getTpCondPag';
import getConditionExternalId from '@salesforce/apex/OrderScreenController.getConditionExternalId';
import getAddress from '@salesforce/apex/OrderScreenController.getAddress';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import RELATED_CONTACT_OBJECT from '@salesforce/schema/AccountContactRelation';
import RELATED_CONTACT_ACCOUNT_ID from '@salesforce/schema/AccountContactRelation.AccountId';
import RELATED_CONTACT_NAME from '@salesforce/schema/AccountContactRelation.ContactName__c';
import RELATED_CONTACT_ID from '@salesforce/schema/AccountContactRelation.ContactId';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NUM_REGISTER from '@salesforce/schema/Account.NumeroRegistro__c';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_RECORDTYPE from '@salesforce/schema/Account.RecordTypeId';
import ACCOUNT_COUNCIL_TYPE from '@salesforce/schema/Account.TipoConselho__c';
import ACCOUNT_PRESCRIBER_REGISTRY from '@salesforce/schema/Account.UFRegistroMedico__c';

import ENDERECO_OBJECT from '@salesforce/schema/EnderecoEntrega__c';
import ENDERECO_NAME from '@salesforce/schema/EnderecoEntrega__c.Name';
import ENDERECO_COMPLETO from '@salesforce/schema/EnderecoEntrega__c.Address__c';
import ENDERECO_CLIENTE_ID from '@salesforce/schema/EnderecoEntrega__c.Cliente__c';

import mensagemInativo from '@salesforce/label/c.ClienteInativo';

import ClienteRecebedorInativoInsert from '@salesforce/label/c.ClienteRecebedorInativo';
import ClienteInativoInsert from '@salesforce/label/c.ClienteInativoInsert';
import ClienteInativoInsertPositivo from '@salesforce/label/c.ClienteInativoInsertPositivo';
import BuscaCep from '@salesforce/apex/ViaCepBO.BuscaCep';
import { MessageContext, publish } from "lightning/messageService";
import closeConsoleTab from "@salesforce/messageChannel/CloseConsoleTab__c";

export default class InsertOrder  extends NavigationMixin(LightningElement)  {
	// Aura variables
	@api isEdit;
	@api isBudget;
	@api isSonOrder;
	@api isCreateOrderFromBudget;
	@api recordId;
	@api hasPermissionERB;
	@api goToCheckout = false;
	@track canEditPrice = false;
	@api alreadySaved;
	@api savingStrData;
	@api allRecAnswered;
	@api newRecordId;
	
	@api isReturn;
	@api orderListReturned;
	@api clienteEmissorOrderProduct;
	@api clienteEmissorIdOrderProduct;
	@api clienteEmissorCGCOrderProduct;
	@api medicoOrderProduct;
	@api medicoIdOrderProduct;
	@api medicoCRMOrderProduct;
	@api tabelaPrecoOrderProduct;
	@api tabelaPrecoNomeOrderProduct;
	@api tipoFreteOrderProduct;
	@api valorFreteOrderProduct;
	@api numeroPedidoClienteOrderProduct;
	@api condicaoPagamentoOrderProduct;
	@api condicaoPagamentoNomeOrderProduct;
	@api contatoOrcamentoOrderProduct;
	@api canalVendasOrderProduct;
	@api tipoOrdemOrderProduct;
	@api formaPagamentoOrderProduct;
	@api dtPrevistaEntregaOrderProduct;
	@api clienteRecebedorOrderProduct;
	@api clienteRecebedorCGCOrderProduct;
	@api enderecoEntregaIdOrderProduct;
	@api enderecoEntregaContaOrdemOrderProduct;
	@api observacaoOrderProduct;
	@api observacaoNFOrderProduct;
	@api dtParcelasOrderProduct;
	@api fretesPorCdOrderProduct;
	@api pedidoComplementarOrderProduct;
	@api utilizarEnderecoAdicionalOrderProduct;
	@track isVansOrder = false;
	


	@track isSaveDisabled = false;
	@track loading;
	@track disableAdvanceButton = false;
	@track headerInfoDataOrder;
	@track headerInfoDataBudget;
	@track device;
	
	@track Logradouro;
	@track Bairro;
	@track Cidade;
	@track Estado;
	@track Pais;
	@track CEP;
	// Variables from BUDGET SCREEN
	@api isFromBudgetScreen;
	@api fromBudgetisEdit;
	@api fromBudgetisBudget;
	@api fromBudgetrecordId;
	@api fromBudgetheaderId;
	@api fromBudgetnumOrcamento;
	@api fromBudgetvalorTotal;
	@api fromBudgetscore;
	@api fromBudgetclienteEmissorId;
	@api fromBudgetclienteEmissor;
	@api fromBudgetclienteEmissorCGC;
	@api fromBudgettabelaPreco;
	@api fromBudgettabelaPrecoNome;
	@api fromBudgetcanalEntrada;
	@api fromBudgetcondicaoPagamento;
	@api fromBudgetcondicaoPagamentoNome;
	@api fromBudgetformaPagamento;
	@api fromBudgetcontatoOrcamento;
	@api fromBudgetprazoValidade;
	@api fromBudgetdtValidade;
	@api fromBudgetobservacaoCliente;
	@api fromBudgetobservacao;
	@api fromBudgetdtParcelas;
	@api fromBudgetfretesPorCd;
	@api fromBudgetisCoordenador;
	@api fromBudgetorderList;
	@api cnpjCd;
	@api headerInfoData;
	@api fromBudgetIdportalcotacoes;
	@api orderList = [];
	@api orderFreightList = [];
	@api dtList = [];
	@api receivedDtList = [];
	@api freteList = [];
	@api receivedFreightList = [];
	@api dtQuantityAllowed = 4;
	@track freteNecessario = false;
	@track parcelamentoManual = false;
	@track isParcelamentoManual = false;
	@track isInstallmentDisabled = false;
	@track auxOrderList = [];
	@track auxOrderToRemove = [];
	@track orderListComplement = [];
	@track hasComplementOrder = false;
	@track keepComplementOrder = false;
	@track outOfStock = false;
	@track calcAllScoreObj = [];
	@track margemAtualGeral;
	@track margemAtualAlvo;
	@track scoreFinalGeral;
	@track tabelaPrecoExternalId;
	@track createOrderFromBudget;
	@track isLoading;

	@api Idportalcotacoes;
	@api createOrderDt;
	@track IdportalcotacoesAtivo = true;
	// Tipo Ordem (Hide/Show HTML)
	@track tabelaPrecoObject; 
	@track condicaoPagamentoObject;
	@track tipoOrdemContaOrdem = false;
	@track tipoOrdemVendaOuBonificacao = false;
	// @track tipoOrdemBonificacao = false;
	// @track tipoOrdemVenda = false;
	@track salesChannelB01 = ['ACSC - Associação Congregação de Santa Catarina','Portal Apoio','Apoio','Ariba/Amil','Bionexo','Bionexo l Manager','GTPLAN','GT Plan','Portal GTPLAN','Humma','Max Cotações','NEOGRID','Sintese','Smarkets Marketplace','Smart Compras','Movi Tech','TerNet','Tivox','Nimbi','Medical VM','VS Supply','Plani Max','INPART','Portal FAEPA','PORTAL FAEPA','Portal HR','Portal Multicentrais','PORTAL MULTICENTRAIS','MultiCentrais','Portal MV Sistema','PORTAL MV SISTEMA','Portal Sao Martinho','PORTAL SAO MARTINHO','Portal São Martinho','Portal SGHCOT','PORTAL SGHCOT','Portal Sinconecta','PORTAL SINCONECTA','Portal Unifenas','PORTAL UNIFENAS','Portal Unimed Limeira','PORTAL UNIMED LIMEIRA','Portal Wareline','PORTAL WARELINE','Pro Saude','Unifor','Tasy','Paradigma','MVM RS'];

	@api filteredMapAccount;
	@api mapCondIdToCondName;

	// **BEGIN HTML variables**
	// HTML variables (Usadas para a edição de Pedido)
	@api numPedido;
	@api valorTotal;
	@api margem;
	@api score;
	// HTML variables (Usadas para a criação de Pedido)
	@track accountWidth = "width: 100%";
	@track dataObj = new Object();
	@track clienteEmissor;
	@track clienteEmissorId;
	@track condicao;
	@track clienteEmissorCGC;
	@track clienteEmissorCNPJ;
	@track medico;
	@track medicoId;
	@track medicoCRM;
	@track tabelaPreco;
	@track tabelaPrecoNome;
	@track originalTabelaPreco;
	@track originalTabelaPrecoNome;
	@track tipoFrete;
	@track showValorFrete; // mostra o campo "Valor do Frete" caso tipo frete seja "FOB"
	@track valorFrete;
	@track numeroPedidoCliente;
	@track condicaoPagamento;
	@track condicaoPagamentoNome;
	@track currentPaymentCondition;
	@track contatoOrcamento;
	@track accountContactRelationId;
	@track canalVendas;
	@track disabledFormaPag;
	@track disabledDataPrevista;
	@track disabledPrescritor;
	@track disabledRelatedContact;
	@track disabledCanalVendas;
	@track disabledOrderCompraCliente;
	@track disabledOrderType;
	@track oldCanalVendas;
	@track canalVendasErro = false;
	@track ordemCompraClienteErro = false;
	@track obsNotaFiscalErro = false;
	@track obsPedidoErro = false;
	@track tipoOrdem;
	@track formaPagamento;
	@track GeraBoleto;
	@track dtPrevistaEntrega;
	@track clienteRecebedor;
	@track clienteRecebedorName;
	@track clienteRecebedorCGC;
	@track clienteRecebedorCNPJ;
	@track enderecoCobranca;
	@track enderecoEntregaContaOrdem;
	@track enderecoEntregaErro = false;
	@track estadoCliente;
	@track observacao;
	@track observacaoNF;
	@track observacaoPedido;
	@track ordItemList = [];
	@track contaOrdem = [];
	@track contaOrdemShow = false;
	@track dtParcelas;
	@track fretesPorCd;
	@track pedidoComplementar = false;

	@track utilizarEnderecoAdicional = false;
	@track selectedEnderecoEntregaId;
	@track enderecoEntregaId;
	// **END HTML variables**

	@track enderecoCobrancaRecebedor;
	
	@track itensList;

	@track prescriberObjectApi = ACCOUNT_OBJECT;
	@track prescriberRecordType = ACCOUNT_RECORDTYPE;
	@track prescriberSearchFieldsApi = [ACCOUNT_NAME, ACCOUNT_NUM_REGISTER];
	@track prescriberMoreFields = [ACCOUNT_COUNCIL_TYPE, ACCOUNT_PRESCRIBER_REGISTRY];
	@track prescriberListItemOptions = {title: 'Name', description: ['TipoConselho__c','UFRegistroMedico__c','NumeroRegistro__c']};
	@track accountObjectInfo;
	@wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
	accountObjectInfo;

	@track relatedContactAccountFieldApi = RELATED_CONTACT_ACCOUNT_ID;
	@track relatedContactObjectApi = RELATED_CONTACT_OBJECT;
	@track relatedContactSearchFieldsApi = [RELATED_CONTACT_NAME];
	@track relatedContactListItemOptions = {title: 'ContactName__c'};
	@track relatedContactMoreFields = [RELATED_CONTACT_ID];
	@track contatoOrcamento;
	@track showCreateRecordForm = false;

	@track contactObjectInfo;
	//@wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
	@wire(getObjectInfo, { objectApiName: RELATED_CONTACT_OBJECT })
	contactObjectInfo;

	get defaultContactRecordTypeId() {
		if (!this.contactObjectInfo) return null;

		if (this.contactObjectInfo.data) {
			const recordTypeInfos = this.contactObjectInfo.data?.recordTypeInfos;
			
			return Object
				.keys(recordTypeInfos)
				.find(recordType => recordTypeInfos[recordType].name === 'Contato do cliente');
		} else if (this.contactObjectInfo.error) {
			console.log('Erro ao pegar o tipo de registro.');
		} else {
			return null;
		}
	};

	get defaultPrescriberRecordTypeId() {
		if (!this.accountObjectInfo) return null;

		if (this.accountObjectInfo.data) {
			const recordTypeInfos = this.accountObjectInfo.data?.recordTypeInfos;
			
			return Object
				.keys(recordTypeInfos)
				.find(recordType => recordTypeInfos[recordType].name === 'Médico');
		} else if (this.accountObjectInfo.error) {
			console.log('Erro ao pegar o tipo de registro.');
		} else {
			return null;
		}
	};

	get currentLength() {
		return this.observacaoNF ? this.observacaoNF.length : 0;
	}

	@track sizeNote = 0;
	get maxLengthNote() {
		this.getSizeNote();
		var maxSize = 255 - this.sizeNote + (this.observacaoNF ? this.observacaoNF.length : 0);

		console.log('Size get:', this.sizeNote);
		return maxSize;
	}

	get exceededLimit() {
		if (this.currentLength > this.maxLengthNote) {
			return true;
		} else {
			return false;
		}
	}

	@track enderecoObjectApi = ENDERECO_OBJECT;
	@track enderecoSearchFieldApi = [ENDERECO_COMPLETO, ENDERECO_NAME];
	@track enderecoListItemOptions = {title: 'Address__c', description: 'Name'};
	@track enderecoClienteFieldApi = ENDERECO_CLIENTE_ID;

	connectedCallback() {
		this.device = FORM_FACTOR == 'Large';
		console.log(this.device);
		this.getToastData();
		getCanEditPrice({ordId: this.recordId})
			.then(result => {
				this.canEditPrice = result;
			}).catch(error => {
				console.log(error);
			});

		Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => { console.log('Files loaded.'); }).catch(error => { console.log('error: ' + JSON.stringify(error)); });
		console.log('entrou no connectedCallback');
		console.log(this.recordId);
		console.log(this.isCreateOrderFromBudget);
		console.log(this.isFromBudgetScreen);
		console.log('isSonOrder ==> ' + this.isSonOrder);
	}

	connectedCallbackRebase() {

		if(this.isReturn == null || this.isReturn == undefined || !this.isReturn ){
			if (!this.isCreateOrderFromBudget) {
				console.log('isCreateOrderFromBudget:', this.isCreateOrderFromBudget);
				if (this.isFromBudgetScreen) {
					this.createOrderFromBudget = true;
					let emissorCGC = this.fromBudgetclienteEmissorCGC.replaceAll(".","").replace("-", "").replace("/","");
					this.orderList = this.fromBudgetorderList;
					this.orderFreightList = this.fromBudgetorderList;
					this.ordItemList = JSON.parse(this.fromBudgetorderList);
					this.Idportalcotacoes = this.fromBudgetIdportalcotacoes;
					this.clienteEmissor = this.fromBudgetclienteEmissor;
					this.clienteEmissorId = this.fromBudgetclienteEmissorId;
					this.condicao = 'Documento__c != null AND Id != \'' + this.clienteEmissorId + '\'  AND RecordType.Name != \'Médico\'';
					this.clienteEmissorCGC = emissorCGC.length == 11 ? emissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : emissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
					this.clienteEmissorCNPJ = emissorCGC.length == 11 ? false : true;
					this.tabelaPreco = this.fromBudgettabelaPreco;
					this.tabelaPrecoNome = this.fromBudgettabelaPrecoNome;
					this.originalTabelaPreco = this.fromBudgettabelaPreco;
					this.originalTabelaPrecoNome = this.fromBudgettabelaPrecoNome;
					if (this.tabelaPrecoNome == 'B01/BIONEXO') {
						this.IdportalcotacoesAtivo = false;
					}else{
						this.IdportalcotacoesAtivo = true;
					}
					this.condicaoPagamento = this.fromBudgetcondicaoPagamento;
					this.condicaoPagamentoNome = this.fromBudgetcondicaoPagamentoNome;
					this.contatoOrcamento = this.fromBudgetcontatoOrcamento;
					this.canalVendas = this.fromBudgetcanalEntrada;
					this.formaPagamento = this.fromBudgetformaPagamento;
					this.observacao = this.fromBudgetobservacaoCliente;
					this.observacaoNF = this.fromBudgetobservacao;
					this.dtParcelas = this.fromBudgetdtParcelas;
					this.fretesPorCd = this.fromBudgetfretesPorCd;
					this.tipoFrete = this.fromBudgettipoFrete;
					this.prazoValidade             = this.fromBudgetprazoValidade;
					console.log('idportal ' + this.fromBudgetIdportalcotacoes);
					this.Idportalcotacoes          = this.fromBudgetIdportalcotacoes;
					console.log('this.condicaoPagamentoNome ' + this.condicaoPagamentoNome);

					this.hasInstallment();
					this.condicoesBloqueada();
					this.freteNecessario = true;
					if (this.fretesPorCd) {
						console.log(this.fretesPorCd);
						let splitFreight = this.fretesPorCd.split(',');
						splitFreight.forEach(freightCd => {
							//let splittedFreightCd = freightCd.split(':');
							this.freteList.push(freightCd.trim());
						})
						console.log(this.freteList);
						this.receivedFreightList = this.freteList;
					}

					getAccountData({ accId: this.fromBudgetclienteEmissorId })
						.then(result => {
							console.log('É edição');
							console.log('Result: ' + JSON.stringify(result));
							this.enderecoEntregaId = result.EnderecoEntregaId;
							this.estadoCliente = result.EstadoCliente;
							console.log('estadoCliente: ' + result.EstadoCliente);
							this.enderecoCobranca = result.enderecoCobranca;
							this.GeraBoleto = result.GeraBoleto;
							this.hasPermissionERB = result.hasPermissionERB;
							
							if (this.enderecoEntregaId != null) {
								this.utilizarEnderecoAdicional = true;
								this.selectedEnderecoEntregaId = this.enderecoEntregaId;
							}
							console.log('Result.EnderecoEntregaId: ' + result.EnderecoEntregaId);
						}).catch(error => {
							console.log('getAccountData isEdit: entrou no erro!');
							console.log(error);
						})

					getContactRelationData({ accountId: this.fromBudgetclienteEmissorId, contactId: this.fromBudgetcontatoOrcamento })
						.then(result => {
							console.log('Pegando Id do Contato Relacionado no If isFromBudgetScreen.');
							this.accountContactRelationId = result;
						}).catch(error => {
							console.log('getContactRelationData entrou no erro no If isFromBudgetScreen', error);
						})

					this.inputLookupFilter();

					this.getPbExternalId();
				} else {
					console.log('isFromBudgetScreen:', this.isFromBudgetScreen);
					this.showValorFrete = false;


					getFilteredPaymentConditionData()
						.then(result => {
							console.log('getFilteredPaymentConditionData: entrou certo!');
							this.mapCondIdToCondName = result.MapCondIdToCondName;
							console.log(this.mapCondIdToCondName);
						}).catch(error => {
							console.log('getFilteredPaymentConditionData: entrou no erro!');
							console.log(error);
						});

					if (!this.isEdit) {
						this.handleCreateDate();
						getAccountData({ accId: this.recordId })
							.then(result => {
								console.log('Não é edição');
								console.log('result conta: ' + JSON.stringify(result));
								this.clienteEmissor = result.ClienteEmissor;
								if (result.MedicoCRM != undefined) {
									this.medicoId = result.MedicoId;
									this.medicoCRM = result.MedicoCRM;
								} else {
									this.clienteEmissorId = result.ClienteEmissorId;
									this.clienteEmissorCGC = result.ClienteEmissorCGC != undefined ? (result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5")) : '';
									this.clienteEmissorCNPJ = result.ClienteEmissorCGC.length == 11 ? false : true;
								}
								this.condicao = 'Documento__c != null AND Id != \'' + this.clienteEmissorId + '\'  AND RecordType.Name != \'Médico\'';

								this.tabelaPreco = result.TabelaPreco;
								this.tabelaPrecoNome = result.TabelaPrecoNome;
								this.originalTabelaPreco = result.TabelaPreco;
								this.originalTabelaPrecoNome = result.TabelaPrecoNome;
								if (this.tabelaPrecoNome == 'B01/BIONEXO') {
									this.IdportalcotacoesAtivo = false;
								}else{
									this.IdportalcotacoesAtivo = true;
								}
								this.condicaoPagamento = result.CondicaoPagamento;
								this.condicaoPagamentoNome = result.CondicaoPagamentoNome;
								this.contatoOrcamento = result.ContatoOrcamento;
								this.accountContactRelationId = result.AccountContactRelationId;
								this.tipoFrete = result.tipoFrete;
								this.observacao = result.Observacao;
								this.clienteBloqueado = result.ClienteBloqueado;
								this.contemDocAlvaraCrt = result.ContemDocAlvaraCrt;
								this.documentosValidos = result.DocumentosValidos;
								this.estadoCliente = result.EstadoCliente;
								this.enderecoCobranca = result.enderecoCobranca;
								this.GeraBoleto = result.GeraBoleto;
								this.hasPermissionERB = result.hasPermissionERB;
								this.condicoesBloqueada();

								this.fillPaymentCondition('create');

								// this.setFormaPagamentoValue(this.condicaoPagamentoNome);
								this.inputLookupFilter();

								if (!this.clienteBloqueado) {
									// this.showToast(this.toastInfoErrorBlockedAcc);
									this.showToastMsg(mensagemInativo);
								}

								if (result.BloqueioFinanceiro && result.ClienteEmissorCGC.length != 11) {
									this.showToast(this.toastInfoFinancialBlock);
								}

								if (result.ClienteEmissorCGC.length != 11) {
									if (!this.contemDocAlvaraCrt) {
										this.showToast(this.toastInfoErrorDocMissing);
									} else {
										if (this.documentosValidos) {
											this.showToast(this.toastInfoErrorDocExpired);
										}
									}
								}
							}).catch(error => {
								console.log('getAccountData: entrou no erro!');
								console.log(error);
							})
					} else {
						this.alreadySaved = true;
						getComplementOrderSituation({ ordId: this.recordId })
							.then(result => {
								console.log('getComplementOrderSituation: entrou certo!');
								console.log(result);
								if (result) {
									swal('Aviso!', `O pedido original possui pedidos ainda não integrados com o ERP, se desejar prosseguir com esse pedido poderá consumir a reserva que seria destinada ao pedido original`, 'warning');
								}
							}).catch(error => {
								console.log('getComplementOrderSituation: entrou no erro!');
								console.log(error);
							});
						getOrderData({ ordId: this.recordId, condicaoPag: null })
							.then(result => {								
								if (!this.device) {
									if (result.Status != 'Em digitação' && result.Status != 'Reprovado') {
										this.disableAdvanceButton = true;
										swal('Aviso!', 'Não é possível alterar este registro devido seu Status', 'warning');
										return;
									}
								}
								console.log('É Edição');
								console.log('getOrderData: entrou certo!');
								console.log(result);
								console.log(result?.StatusPedido);
								this.ordObj = result;
								if (result?.StatusPedido == 'Integrado') {
									console.log('fechando!');
									this.showToast(result.ToastInfoOrdIntegrated);
								}
								this.clienteEmissor = result.ClienteEmissor;
								this.isVansOrder    = result.isVansOrder;
								this.condicaoPagamento = result.CondicaoPagamento;

								if (this.isVansOrder) {
									this.IdportalcotacoesAtivo = true;
									this.hasInstallment();
								}
								// console.log('result.MedicoCRM: ' + result.MedicoCRM);
								if (result.MedicoCRM != undefined) {
									this.medicoId = result.Medico;
									this.medicoCRM = result.MedicoCRM;
								} else {
									this.clienteEmissorId = result.ClienteEmissorId;
									this.clienteEmissorCGC = result.ClienteEmissorCGC != undefined ? (result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5")) : '';
									this.clienteEmissorCNPJ = result.ClienteEmissorCGC.length == 11 ? false : true;
								}
								this.numPedido = result.NumeroPedido;
								this.valorTotal = (Number(result.ValorTotal)).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
								this.margem = result.Margem + "%";
								this.score = result.Score;
								this.tabelaPreco = result.TabelaPreco;
								this.tabelaPrecoNome = result.TabelaPrecoNome;
								this.originalTabelaPreco = result.TabelaPreco;
								this.originalTabelaPrecoNome = result.TabelaPrecoNome;
								if (this.tabelaPrecoNome == 'B01/BIONEXO') {
									this.IdportalcotacoesAtivo = false;
								}else{
									this.IdportalcotacoesAtivo = true;
								}
								this.canalVendas = result.CanalVendas;
								this.currentPaymentCondition = result.CondicaoPagamento;
								this.accountContactRelationId = result.AccountContactRelationId;
								this.condicaoPagamentoNome = result.CondicaoPagamentoNome;
								this.formaPagamento = result.FormaPagamento;
								
								this.GeraBoleto = result.GeraBoleto;
								this.fillPaymentCondition('');

								if (this.GeraBoleto == undefined) {
									getAccountData({ accId: this.fromBudgetclienteEmissorId })
										.then(result => {
											console.log('É edição');
											this.GeraBoleto = result.GeraBoleto;
										}).catch(error => {
											console.log('getAccountData isEdit: entrou no erro!');
											console.log(error);
										})
								}
								console.log('result.FormaPagamento ' + result.FormaPagamento);
								console.log('result.ContatoOrcamento:', result.ContatoOrcamento);
								this.condicoesBloqueada();
								this.contatoOrcamento = result.ContatoOrcamento;
								this.tipoFrete = result.TipoFrete;
								this.valorFrete = result.ValorFrete;
								this.tipoOrdem = result.TipoOrdem;
								// this.enderecoEntrega       = result.EnderecoEntrega;
								this.numeroPedidoCliente = result.NumeroPedidoCliente;
								this.dtPrevistaEntrega = result.DtPrevistaEntrega;
								this.observacao = result.Observacao;
								this.observacaoNF = result.ObservacaoNotaFiscal;
								this.observacaoPedido = result.ObservacaoPedido;
								this.enderecoEntregaContaOrdem = result.EnderecoEntrega;
								this.estadoCliente = result.EstadoCliente;
								if (result.Itens) {
									let newItens = [];
									result.Itens.forEach(item => {
										if (item.rangeStringify) {
											newItens.push({
												...item,
												range: JSON.parse(item.rangeStringify)
											})
										} else {
											newItens.push({
												...item
											})
										}
									})
									this.ordItemList = newItens;
								}
								this.dtParcelas = result.DtParcelas;
								this.fretesPorCd = result.FretesPorCd;
								this.pedidoComplementar = result.PedidoComplementar;
								this.contemDocAlvaraCrt = result.ContemDocAlvaraCrt;
								this.hasPermissionERB = result.hasPermissionERB;
								this.documentosValidos  = result.DocumentosValidos;
								this.Idportalcotacoes = result.Idportalcotacoes;
								this.allRecAnswered = result.allRecAnswered;
								console.log('this.Idportalcotacoes ' +  this.Idportalcotacoes);
								console.log('ordItemList: ');
								console.log(this.ordItemList);
		
								if (!result.ClienteBloqueado) {
									this.showToastMsg(mensagemInativo);
								}

								if (result.BloqueioFinanceiro && result.ClienteEmissorCGC.length != 11) {
									this.showToast(this.toastInfoFinancialBlock);
								}

								if (result.ClienteEmissorCGC.length != 11) {
									if (!this.contemDocAlvaraCrt) {
										this.showToast(this.toastInfoErrorDocMissing);
									} else {
										if (this.documentosValidos) {
											this.showToast(this.toastInfoErrorDocExpired);
										}
									}
								}
								if (this.numeroPedidoCliente) {
									if (this.numeroPedidoCliente.length > 15) {
										this.ordemCompraClienteErro = true;
									}
								}
								console.log('Condição de pagamento: ' + this.condicaoPagamento);
								console.log('this.mapCondIdToCondName: ' + this.mapCondIdToCondName);
								// this.setFormaPagamentoValue(this.condicaoPagamentoNome);

								// if (this.tipoFrete == "FOB") {
								//     this.showValorFrete = true;
								// } else {
								//     this.showValorFrete = false;
								// }

								this.setTipoOrdemValue(this.tipoOrdem);

								this.inputLookupFilter();

								this.clienteRecebedor = result.ClienteRecebedor;
								this.clienteRecebedorCGC = result.ClienteRecebedorCGC ? result.ClienteRecebedorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5") : '';
								this.enderecoEntregaId = result.EnderecoEntregaId;
								this.enderecoCobrancaRecebedor = result.enderecoCobrancaRecebedor;
								this.enderecoCobranca = result.enderecoCobranca;

								console.log('this.enderecoEntregaId:', this.enderecoEntregaId);
								if (this.enderecoEntregaId != null) {
									this.utilizarEnderecoAdicional = true;
									this.selectedEnderecoEntregaId = this.enderecoEntregaId;
								}
							}).catch(error => {
								console.log('getOrderData: entrou no erro!');
								console.log(error);
							});
					}
				}
			} else {
				console.log('ENTROU NO INSERT ORDER DA OPP');
				this.isFromBudgetScreen = true;
				this.disableButtons();
				getBudgetData({ recordId: this.recordId, condicaoPag: null })
					.then(result => {
						console.log('getBudgetData: entrou certo!');
						console.log(result);
						console.log("Preenchendo dados da tela de edição");

						if (!this.device) {
							if (result.StageName == 'Fechado/Gerado' && result.StageName == 'Fechado/Perdido' && result.StageName == 'Expirado' && result.StageName == 'Aguardando aprovação') {
								this.disabledNext = true;
								swal('Aviso!', 'Não é possível alterar este registro devido seu Status', 'warning');
								return;
							}
						}

						this.clienteEmissor = result.ClienteEmissor;
						this.clienteEmissorId = result.ClienteEmissorId;
						this.clienteEmissorCGC = result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
						this.clienteEmissorCNPJ = result.ClienteEmissorCGC.length == 11 ? false : true;
						this.condicao = 'Documento__c != null AND Id != \'' + this.clienteEmissorId + '\'  AND RecordType.Name != \'Médico\'';
						this.tabelaPreco = result.TabelaPreco;
						this.tabelaPrecoNome = result.TabelaPrecoNome;
						this.originalTabelaPreco = result.TabelaPreco;
						this.originalTabelaPrecoNome = result.TabelaPrecoNome;
						if (this.tabelaPrecoNome == 'B01/BIONEXO') {
							this.IdportalcotacoesAtivo = false;
						}else{
							this.IdportalcotacoesAtivo = true;
						}
						this.canalVendas = result.CanalEntrada;
						this.condicaoPagamento = result.CondicaoPagamento;
						this.condicaoPagamentoNome = result.CondicaoPagamentoNome;
						// this.formaPagamento        = result.CondicaoPagamentoNome == 'RA' ? 'Deposito' : result.CondicaoPagamentoNome != '' ? 'Boleto' : '';

						this.GeraBoleto = result.GeraBoleto;
						this.formaPagamento = result.FormaPagamento;

						console.log('Cheguei Aqui', result.ContatoOrcamento);
						this.contatoOrcamento = result.ContatoOrcamento;
						this.accountContactRelationId = result.AccountContactRelationId;
						this.prazoValidade = result.PrazoValidade;
						this.dtValidade = result.DataValidade;
						this.observacao = result.ObservacaoCliente; // puxar de Account
						this.observacaoNF = result.Observacao;
						this.stageName = result.StageName;
						this.contemDocAlvaraCrt = result.ContemDocAlvaraCrt;
						this.documentosValidos = result.DocumentosValidos;
						this.clienteBloqueado = result.ClienteBloqueado;
						this.hasPermissionERB = result.hasPermissionERB;
						this.isCoordenador = result.IsCoordenador;
						this.dtParcelas = result.DtParcelas;
						this.fretesPorCd = result.FretesPorCd;
						this.ordItemList = result.Itens;
						this.tipoFrete = result.tipoFrete;
						this.enderecoCobranca = result.enderecoCobranca;
						this.allRecAnswered = result.allRecAnswered;

						console.log(this.ordItemList);
						this.orderList = JSON.stringify(this.ordItemList);
						this.orderFreightList = JSON.stringify(this.ordItemList);
						if (!result.ClienteBloqueado) {
							this.showToastMsg(mensagemInativo);
						}

						if (result.BloqueioFinanceiro && result.ClienteEmissorCGC.length != 11) {
							this.showToast(this.toastInfoFinancialBlock);
						}

						this.hasInstallment();
						this.condicoesBloqueada();

						this.freteNecessario = true;

						getAccountData({ accId: this.clienteEmissorId })
							.then(result => {
								console.log('É insertBudgetAndOrder');
								console.log('Result: ' + result);
								this.enderecoEntregaId = result.EnderecoEntregaId;
								this.estadoCliente     = result.EstadoCliente;
								this.enderecoCobranca  = result.enderecoCobranca;
								this.hasPermissionERB = result.hasPermissionERB;
								// if (result.ClienteBloqueado) {
								//     this.showToastMsg(mensagemInativo);
								// }
	
								if (this.enderecoEntregaId != null) {
									this.utilizarEnderecoAdicional = true;
									this.selectedEnderecoEntregaId = this.enderecoEntregaId;
								}
								console.log('Result.EnderecoEntregaId: ' + result.EnderecoEntregaId);
								console.log('Result.enderecoCobranca: ' + result.enderecoCobranca);
							}).catch(error => {
								console.log('getAccountData isEdit: entrou no erro!');
								console.log(error);
							})
		
						this.inputLookupFilter();
						console.log('É coordenador? ' + this.isCoordenador);
	
						if(this.stageName == 'Expirado'){
							this.disabledNext = true;
							if(result.motivoExpirado == null){
								swal({
									text: 'O Orçamento foi expirado!! Por favor informar o motivo de ter sido expirado, mas não se preocupe ainda e possivel clonar ele e criar um novo!!',
									content: "input",
									button: {
									text: "Continuar!",
									closeModal: false,
									},
								})
								.then(name => {
									if (!name) throw null;
									this.inputReason(name);
									swal.stopLoading();
									swal.close();
								})
								.catch(err => {
									swal.stopLoading();
									swal.close();
								
								});
							}
						}else{
							this.disabledNext = false;
						}
						this.inputLookupFilter();

						this.getPbExternalId();
					}).catch(error => {
						console.log('getBudgetData: entrou no erro!');
						console.log(error);
					});
				
			}
	
		}else{
			let utilizarEnderecoAdicional = false;
			this.utilizarEnderecoAdicional = this.utilizarEnderecoAdicionalOrderProduct;
			getAccountData({ accId: this.clienteEmissorIdOrderProduct })
				.then(result => {
					if (this.utilizarEnderecoAdicional){
						utilizarEnderecoAdicional = true;
					}

					this.setTipoOrdemValue(this.tipoOrdemOrderProduct);

					this.enderecoEntregaId = result.EnderecoEntregaId;
					this.estadoCliente     = result.EstadoCliente;
					console.log('estadoCliente: ' + result.EstadoCliente);
					this.enderecoCobranca  = result.enderecoCobranca;
					this.GeraBoleto  = result.GeraBoleto;
					this.hasPermissionERB = result.hasPermissionERB;

					if (this.utilizarEnderecoAdicional) {
						this.enderecoEntregaErro = false;
						this.selectedEnderecoEntregaId = this.enderecoEntregaIdOrderProduct;
						this.enderecoEntregaId = this.enderecoEntregaIdOrderProduct;
					}
					else {
						this.enderecoEntregaErro = false;
					}
				}).catch(error => {
					console.log('getAccountData Return: entrou no erro!');
					console.log(error);
				})
			if (this.tipoOrdemOrderProduct == 'PedidoContaOrdem') {
				getAccountData({ accId: this.clienteRecebedorOrderProduct })
					.then(result => {
						if (this.utilizarEnderecoAdicional){
							utilizarEnderecoAdicional = true;
						}

						this.setTipoOrdemValue(this.tipoOrdemOrderProduct);

						this.clienteRecebedor = this.clienteRecebedorOrderProduct;
						this.clienteRecebedorCGC  = result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
						this.clienteRecebedorCNPJ = result.ClienteEmissorCGC.length == 11 ? false : true;
						this.enderecoCobrancaRecebedor = result.enderecoCobranca;
						this.enderecoEntregaId = this.enderecoEntregaIdOrderProduct;
						this.selectedEnderecoEntregaId = this.enderecoEntregaIdOrderProduct;
						this.hasPermissionERB = result.hasPermissionERB;

						if (!result.ClienteBloqueado) {
							this.showToastMsg(ClienteRecebedorInativoInsert);
						}
						if (utilizarEnderecoAdicional) {
							this.utilizarEnderecoAdicional = true;
						}
						else {
							this.enderecoEntregaErro = false;
						}
					}).catch(error => {
						console.log('getAccountData Return 2: entrou no erro!');
						console.log(error);
					})
			}
			
			this.clienteEmissorCNPJ = this.clienteEmissorOrderProduct.length == 11 ? false : true;
			this.clienteEmissor = this.clienteEmissorOrderProduct;        
			this.clienteEmissorId = this.clienteEmissorIdOrderProduct;
			this.clienteEmissorCGC = this.clienteEmissorCGCOrderProduct;
			this.medico = this.medicoOrderProduct;
			this.medicoId = this.medicoIdOrderProduct;  
			this.medicoCRM = this.medicoCRMOrderProduct; 
			this.tabelaPreco = this.tabelaPrecoOrderProduct;
			this.tabelaPrecoNome = this.tabelaPrecoNomeOrderProduct;
			if (this.tabelaPrecoNome == 'B01/BIONEXO') {
				this.IdportalcotacoesAtivo = false;
			}else{
				this.IdportalcotacoesAtivo = true;
			}
			this.originalTabelaPreco = this.tabelaPrecoOrderProduct;
			this.originalTabelaPrecoNome = this.tabelaPrecoNomeOrderProduct;
			this.tipoFrete = this.tipoFreteOrderProduct; 
			this.valorFrete = this.valorFreteOrderProduct;
			this.numeroPedidoCliente = this.numeroPedidoClienteOrderProduct;     
			this.condicaoPagamento = this.condicaoPagamentoOrderProduct;     
			this.condicaoPagamentoNome = this.condicaoPagamentoNomeOrderProduct;     
			this.contatoOrcamento = this.contatoOrcamentoOrderProduct;      
			this.canalVendas = this.canalVendasOrderProduct;           
			this.tipoOrdem = this.tipoOrdemOrderProduct; 
			this.formaPagamento = this.formaPagamentoOrderProduct;        
			this.dtPrevistaEntrega = this.dtPrevistaEntregaOrderProduct;     
			this.clienteRecebedor = this.clienteRecebedorOrderProduct;      
			this.clienteRecebedorCGC = this.clienteRecebedorCGCOrderProduct;     
			this.enderecoEntregaContaOrdem = this.enderecoEntregaContaOrdemOrderProduct;     
			this.observacao = this.observacaoOrderProduct;
			this.observacaoNF = this.observacaoNFOrderProduct;          
			this.dtParcelas = this.dtParcelasOrderProduct;
			this.fretesPorCd = this.fretesPorCdOrderProduct;           
			this.pedidoComplementar = this.pedidoComplementarOrderProduct;         
			if(this.orderListReturned !=null ){
				this.ordItemList = JSON.parse(this.orderListReturned);
			}

			this.hasInstallment();
			this.condicoesBloqueada();
			this.freteNecessario = false;
			if (this.fretesPorCd) {
				console.log(this.fretesPorCd);
				let splitFreight = this.fretesPorCd.split(',');
				splitFreight.forEach(freightCd => {
					//let splittedFreightCd = freightCd.split(':');
					this.freteList.push(freightCd.trim());
				})
				console.log(this.freteList);
				this.receivedFreightList = this.freteList;
			}

			getContactRelationData({ accountId: this.clienteEmissorId, contactId: this.contatoOrcamento })
				.then(result => {
					console.log('Pegando Id do Contato Relacionado no If isFromBudgetScreen.');
					this.accountContactRelationId = result;
				}).catch(error => {
					console.log('getContactRelationData entrou no erro no If isFromBudgetScreen', error);
				})

			this.inputLookupFilter();
		}
		this.disableFieldsEditOrderSon(this.isSonOrder);

		console.log('this.formaPagamento ==> ' + JSON.stringify(this.formaPagamento));
		//this.clienteEmissorCNPJ = this.clienteEmissorCGC.replace('.-', '').length == 11 ? false : true;
		//console.log('clienteEmissorCNPJ:', this.clienteEmissorCNPJ);
	}

	getPbExternalId() {
		getPricebookExternalId({ pricebookId: this.tabelaPreco })
			.then(result => {
				console.log('getPricebookExternalId: entrou certo!');
				console.log(result);
				this.tabelaPrecoExternalId = result;
				this.getStockFromMalha();
			}).catch(error => {
				console.log('getPricebookExternalId: entrou no erro!');
				console.log(error);
			});
	}

	fillPaymentCondition(moment) {
		if (this.condicaoPagamentoNome != undefined) {
			if (this.condicaoPagamentoNome.includes('RA')) {
				this.disabledFormaPag = true;
				this.formaPagamento = 'Depósito';
			} else {
				if(!this.isSonOrder) {
					this.disabledFormaPag = false;
				}
				this.formaPagamento = (moment == 'create' && (this.GeraBoleto == 'Boleto' || this.GeraBoleto == 'Carteira')) ? null: this.GeraBoleto;
			}
		} else {
			this.disabledFormaPag = false;
			this.formaPagamento = (moment == 'create' && (this.GeraBoleto == 'Boleto' || this.GeraBoleto == 'Carteira')) ? null: this.GeraBoleto;
		}
		console.log('this.formaPagamento ==> ' + JSON.stringify(this.formaPagamento));
		console.log('this.disabledFormaPag ==> ' + JSON.stringify(this.disabledFormaPag));
	}

	getStockFromMalha() {
		swal('Aviso!', 'Checando quantidade de estoque e preço dos itens!', 'warning');
		let prodList = [];

		let hasProdWithourPrice = false;

		let cdObj = {};

		let cdObjIndex = {};

		this.auxOrderList = JSON.parse(this.orderList);

		this.auxOrderList.forEach((cd, index)=> {
			if (cd.precoMalha == undefined || cd.precoMalha == null || cd.precoMalha == '') {
				hasProdWithourPrice = true;
			}
			if (!prodList.includes(cd.prodCode)) {
				prodList.push(cd.prodCode);
			}
			cdObj[cd.prodCode + '_' + cd.cnpjCd] = {
				cnpjCd: cd.cnpjCd,
				qtd: cd.quantidadeCx,
				nome: cd.nome
			}
			cdObjIndex[cd.prodCode + '_' + cd.cnpjCd] = index;
		})

		console.log(this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''));
		console.log(prodList);
		console.log(prodList.join(','));

		const listProductError = [];
		const listProductNotFound = [];

		getMalha({ clienteCGC: this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''), productCode: prodList.join(','), calcMargem: hasProdWithourPrice ? hasProdWithourPrice : false, pricebookExternalId: this.tabelaPrecoExternalId, condPagmento: this.condicaoPagamento, isForaMalha: true })
			.then(result => {
				console.log('getMalha: entrou certo!');
				console.log(result);
				if (result != null) {
					result.forEach(item => {
						if (item.cds != undefined) {
							item.cds.forEach(cdItem => {
								const product = cdObj[item.codprotheus + '_' + cdItem.cnpj];
								if (product != undefined) {
									const cd = item.cds.find(cd => cd.cnpj == product.cnpjCd);
									if (cd.saldo < product.qtd) {
										listProductError.push(product.nome + ' - ' + cd.filial);
										if (hasProdWithourPrice) {
											this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]] = {
												...this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]],
												quantidadePossivel: cd.saldo, 
												quantidadeRestante: product.qtd - cd.saldo, 
												pedidoComplementar: true,
												manterPendente: true,
												precoMalha: cd.preco,
												aliquota: cd.aliquota,
												inicialCaixa: cd.preco
											}
										} else {
											this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]] = {
												...this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]],
												quantidadePossivel: cd.saldo,
												quantidadeRestante: product.qtd - cd.saldo,
												pedidoComplementar: true,
												manterPendente: true
											}
										}
									} else {
										if (hasProdWithourPrice) {
											this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]] = {
												...this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]],
												manterPendente: false,
												precoMalha: cd.preco,
												aliquota: cd.aliquota,
												inicialCaixa: cd.preco
											}
										} else {
											this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]] = {
												...this.auxOrderList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]],
												manterPendente: false
											}
										}
									}
								}
							});                            
						} else {
							listProductNotFound.push(item.msgerro);
						}
					});
				}

				if (listProductNotFound.length > 0) {
					swal('Aviso!', `Erro na busca de estoque: ${listProductNotFound.join(' ')}`, 'warning');
					return;
				} else if (listProductError.length > 0) {
					this.enableButtons();
					this.outOfStock = true;
					return;
				} else {
					swal('Show!', `Estoque verificado e disponível!`, "success");
					this.enableButtons();
				}

			}).catch(error => {
				swal("Ops!", "Erro ao verificar estoque! Verifique com o administrador.", "error");
				console.log('getMalha: entrou no erro!');
				console.log(error);
			});
	}

	async hasInstallment() {
		const conditionPaymentCode = await getConditionExternalId({
			conditionId: this.condicaoPagamento
		});
		if (conditionPaymentCode == '048') {
			this.parcelamentoManual = true;
			if (this.dtParcelas != undefined && this.dtParcelas != "") {
				let splitParcelas = this.dtParcelas.split(',');
				splitParcelas.forEach(parcela => {
					this.dtList.push(parcela.trim());
				})
				console.log(this.dtList);
				this.receivedDtList = this.dtList;
			} else {
				this.receivedDtList = [];
				this.isSaveDisabled = true;
				this.disableAdvanceButton = true;
			}
		} else {
			this.parcelamentoManual = false;
		}
	}

	getToastData() {
		getToastInfoData()
			.then(result => {
				console.log('getToastInfoData: entrou certo!');
				this.toastInfoErrorRequired   = result.ToastInfoErrorRequired;
				this.toastInfoOrdIntegrated   = result.ToastInfoOrdIntegrated;
				this.toastInfoErrorBlockedAcc = result.ToastInfoErrorBlockedAcc;
				this.toastInfoErrorDocMissing = result.ToastInfoErrorDocMissing;
				this.toastInfoErrorDocExpired = result.ToastInfoErrorDocExpired;
				this.toastInfoWarningDeposito = result.ToastInfoWarningDeposito;
				this.toastInfoWarningBoleto   = result.ToastInfoWarningBoleto;
				this.toastInfoFinancialBlock  = result.ToastInfoFinancialBlock;
				if(this.isEdit){
					getApprovedOrder({ ordId: this.recordId })
						.then(result => {
							console.log('getComplementOrderSituation: entrou certo!');
							console.log(result);
							if (result != '') {
								swal('Aviso!', `O pedido não pode ser alterado já esta aprovado`, 'warning');
							}else{
								this.connectedCallbackRebase();
							}
						}).catch(error => {
							console.log('getComplementOrderSituation: entrou no erro!');
							console.log(error);
						});
				}else{
				this.connectedCallbackRebase();
				}
			}).catch(error => {
				console.log('getToastInfoData: entrou no erro!');
				console.log(error);
			});
	}

	fillHeaders() {        
		this.headerInfoDataBudget = {
			numOrcamento          : this.numOrcamento,
			valorTotal            : this.valorTotal,
			score                 : this.score,
			clienteEmissorId      : this.clienteEmissorId,
			clienteEmissor        : this.clienteEmissor,
			clienteEmissorCGC     : this.clienteEmissorCGC,
			tabelaPreco           : this.tabelaPreco,
			tabelaPrecoNome       : this.tabelaPrecoNome,
			canalEntrada          : this.canalVendas,
			condicaoPagamento     : this.condicaoPagamento,
			condicaoPagamentoNome : this.condicaoPagamentoNome,
			formaPagamento        : this.formaPagamento,
			contatoOrcamento      : this.contatoOrcamento,
			prazoValidade         : this.prazoValidade,
			dtValidade            : this.dtValidade,
			observacaoCliente     : this.observacao,
			observacao            : this.observacaoNF,
			observacaoPedido      : this.observacaoPedido,
			dtList                : this.dtParcelas,
			freteList             : this.fretesPorCd,
			recordId              : this.recordId,
			margemAtual           : this.margemAtualGeral,
			margemAlvo            : this.margemAtualAlvo,
			score                 : this.scoreFinalGeral,
			Idportalcotacoes      : this.Idportalcotacoes,
			createOrderDt         : this.createOrderDt,
			isCoordenador         : this.isCoordenador
		}
		
		this.headerInfoDataOrder = {
			clienteEmissor            : this.clienteEmissor,
			clienteEmissorId          : this.clienteEmissorId,
			clienteEmissorCGC         : this.clienteEmissorCGC,
			medico                    : this.medico,
			medicoId                  : this.medicoId,
			medicoCRM                 : this.medicoCRM,
			tabelaPreco               : this.tabelaPreco,
			tabelaPrecoNome           : this.tabelaPrecoNome,
			tipoFrete                 : this.tipoFrete,
			valorFrete                : this.valorFrete,
			numeroPedidoCliente       : this.numeroPedidoCliente,
			condicaoPagamento         : this.condicaoPagamento,
			condicaoPagamentoNome     : this.condicaoPagamentoNome,
			contatoOrcamento          : this.contatoOrcamento,
			canalVendas               : this.canalVendas,
			tipoOrdem                 : this.tipoOrdem,
			formaPagamento            : this.formaPagamento,
			dtPrevistaEntrega         : this.dtPrevistaEntrega,
			clienteRecebedor          : this.clienteRecebedor,
			clienteRecebedorCGC       : this.clienteRecebedorCGC,
			isVansOrder      		  : this.isVansOrder,
			//enderecoEntrega           : this.enderecoEntrega,
			enderecoEntregaId         : this.enderecoEntregaId,
			enderecoEntregaContaOrdem : this.enderecoEntregaContaOrdem,
			observacao                : this.observacao,
			observacaoNF              : this.observacaoNF,
			observacaoPedido          : this.observacaoPedido,
			dtList                    : this.dtParcelas,
			freteList                 : this.fretesPorCd,
			cnpjCd                    : this.cnpjCd,
			margemAtual               : this.margemAtualGeral,
			margemAlvo                : this.margemAtualAlvo,
			score                     : this.scoreFinalGeral,
			Idportalcotacoes          : this.Idportalcotacoes,
			createOrderDt             : this.createOrderDt,
			pedidoComplementar        : this.pedidoComplementar,
			recordId                  : this.isSonOrder ? this.recordId : undefined
		}
	}

	inputLookupFilter() {
		this.contaOrdem  = [];
		this.accountObject = this.clienteEmissorId ? { name: this.clienteEmissor, id: this.clienteEmissorId } : null;
		this.tabelaPrecoObject = this.tabelaPreco ? { name: this.tabelaPrecoNome, id: this.tabelaPreco } : null;
		this.condicaoPagamentoObject = this.condicaoPagamento ? { name: this.condicaoPagamentoNome, id: this.condicaoPagamento } : null;
	}

	selectedRecordId; //store the record id of the selected 
	handleValueSelected(event) {
		console.log(event);
		console.log(event.detail);
		this.selectedRecordId = event.detail;
	}

	// onChangeCondicaoPagamento(event) {
	//     console.log(event);
	//     console.log(event.target);
	//     console.log(event.detail.value);
	//     console.log(event.target.value);
	//     this.condicaoPagamento = event.detail.value;
	//     this.condicaoPagamentoNome = this.mapCondIdToCondName[event.detail.value];
	//     console.log(this.mapCondIdToCondName);
	//     this.setFormaPagamentoValue(this.mapCondIdToCondName[event.detail.value]);
	// }

	setFormaPagamentoValue(value) {
		if (value != null) {
			if (value == 'RA') {
				this.formaPagamento = 'Depósito';
				// this.showToast(this.toastInfoWarningDeposito);
			} else if (value != 'RA' && value != undefined) {
				this.formaPagamento = 'Boleto';
				// this.showToast(this.toastInfoWarningBoleto);
			} else {
				this.formaPagamento = '';
			}
		}
	}

	onChangeAccount(event) {
		console.log("onChangeAccount: entrou!!");
		console.log('target value: ' + event.target.value);
		console.log('detail value: ' + event.detail.value);
		console.log(event.detail.value);
		console.log(event.detail.value.length);

		if (event.detail.value.length != 0) {
			this.clienteEmissorId = this.normalizeData(event.detail.value, true);
			this.recordId = this.clienteEmissorId;
			this.checkContact();
		} else {
			this.clearValues();
		}
		this.connectedCallbackRebase();
	}

	disableFieldsEditOrderSon(isOrderSon) {
		console.log('isOrderSon ==> ' + isOrderSon);
		if(isOrderSon) {
			this.disabledFormaPag = true;
			this.disabledOrderType = true;
			this.disabledCanalVendas = true;
			this.disabledRelatedContact = true;
			this.disabledOrderCompraCliente = true;
			this.disabledPrescritor = true;
			this.disabledDataPrevista = true;
		} else {
			this.disabledOrderType = this.isVansOrder;
			this.disabledCanalVendas = this.isVansOrder;
			this.disabledRelatedContact = this.isVansOrder;
			this.disabledOrderCompraCliente = this.isVansOrder;
			this.disabledPrescritor = this.isVansOrder;
			this.disabledDataPrevista = this.isVansOrder;
		}
		console.log('disabledRelatedContact ==> ' + this.disabledRelatedContact);
	}

	onChangeCliente(event) {
		console.log("onChangeAccount: entrou!!");
		console.log('target value: ' + event.target.value);
		console.log(this.filteredMapAccount);
		console.log(this.clienteEmissor);
		// if (this.filteredMapAccount != undefined) {
		//     if (this.filteredMapAccount[event.detail.value] != undefined) {
		//         console.log('alterar variáveis após mudança de conta');
		//         console.log(this.filteredMapAccount[event.detail.value]);
		//         this.clienteEmissor = this.filteredMapAccount[event.detail.value].Cliente;
		//         this.clienteEmissorId = event.detail.value;
		//         this.clienteEmissorCGC = this.filteredMapAccount[event.detail.value].ClienteCGC != undefined ? this.filteredMapAccount[event.detail.value].ClienteCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5") : "";
		//     } else {
		//         this.clienteEmissorCGC = "";
		//     }
		// }

		if (this.filteredMapAccount != undefined) {
			if (this.filteredMapAccount[event.detail.value] != undefined) {
				this.clienteEmissor = this.filteredMapAccount[event.detail.value].Cliente;
				this.clienteEmissorId = this.normalizeData(event.detail.value, true);

				this.recordId = this.clienteEmissorId;
				this.clienteEmissorCGC = this.filteredMapAccount[event.detail.value].ClienteCGC != undefined ? ( this.filteredMapAccount[event.detail.value].ClienteCGC.length == 11 ? this.filteredMapAccount[event.detail.value].ClienteCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : this.filteredMapAccount[event.detail.value].ClienteCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5") ) : "";
				this.clienteEmissorCNPJ = this.filteredMapAccount[event.detail.value].ClienteCGC.length == 11 ? false : true;
				this.checkContact();
			} else {
				console.log('limpeza');
				this.clearValues();
			}
			if (this.filteredMapAccount[event.detail.value] != undefined) {
				if (this.filteredMapAccount[event.detail.value].Bloqueado == 'Ativo') {
					this.clienteBloqueado = 'Ativo';
					this.showToast(this.toastInfoErrorBlockedAcc);
					this.showToastMsg(mensagemInativo);
				} else {
					this.clienteBloqueado = 'Inativo';
				}
			}
		}
		console.log('belezura');
		this.connectedCallbackRebase();
	}

	onChangeContact(event) {
		const { record } = event.detail;
		this.contatoOrcamento = record.ContactId;
		this.accountContactRelationId = record.Id;
		// this.checkContact();
	}

	onClearContact() {
		this.contatoOrcamento = null;
		this.accountContactRelationId = null;
	}

	handleCreateNewContact() {
		this.showCreateRecordForm = !this.showCreateRecordForm;
	}

	handleSuccessCreateContact(event) {
		const { id: recordId } = event.detail;

		this.contatoOrcamento = recordId;

		getContactRelationData({ accountId: this.clienteEmissorId, contactId: recordId })
			.then(result => {
				console.log('Pegando Id do Contato Relacionado Criado.');
				this.accountContactRelationId = result;
			}).catch(error => {
				console.log('getContactRelationData entrou no erro!', error);
			})

		this.handleCreateNewContact();
	}

	clearValues() {
		this.clienteEmissor            = null;
		this.clienteEmissorId          = null;
		this.clienteEmissorCGC         = null;
		this.medico                    = null;
		this.medicoId                  = null;
		this.medicoCRM                 = null;
		this.tabelaPreco               = null;
		this.tabelaPrecoNome           = null;
		this.originalTabelaPreco       = null;
		this.originalTabelaPrecoNome   = null;
		this.tipoFrete                 = null;
		this.showValorFrete            = null;
		this.valorFrete                = null;
		this.numeroPedidoCliente       = null;
		this.condicaoPagamento         = null;
		this.condicaoPagamentoNome     = null;
		this.contatoOrcamento          = null; 
		this.accountContactRelationId  = null;
		this.canalVendas               = null;
		this.tipoOrdem                 = null;
		this.formaPagamento            = null;
		this.dtPrevistaEntrega         = null;
		this.clienteRecebedor          = null;
		this.clienteRecebedorCGC       = null;
		//this.enderecoEntrega           = null;
		this.enderecoEntregaContaOrdem = null;
		this.observacao                = null;
		this.observacaoNF              = null;
		this.observacaoPedido          = null;
		this.recordId                  = null;
		this.tabelaPrecoObject         = null;
		this.condicaoPagamentoObject   = null;
		this.setTipoOrdemValue('');
		// this.template.querySelector('c-custom-lookup-filter').handleClearSelected();
		for (var i = 0; i < this.template.querySelectorAll('c-custom-lookup-filter').length; i++) {
			this.template.querySelectorAll('c-custom-lookup-filter')[i].handleClearSelected();
		}
		for (var i = 0; i < this.template.querySelectorAll('c-custom-lookup').length; i++) {
			this.template.querySelectorAll('c-custom-lookup')[i].handleClearSelected();
		}
		for(var i=0; i<this.template.querySelectorAll('c-lookup').length; i++){
			this.template.querySelectorAll('c-lookup')[i].clearAll();
		}
		console.log('clearall');
	}
	
	onChangeMedico(event) {
		const {record} = event.detail;
		this.medicoId = record.Id;
		this.medicoCRM = record.NumeroRegistro__c;
	}

	onClearMedico() {
		this.medicoId = null;
		this.medicoCRM = null;
	}

	onChangeClienteRecebedor(event) {
		console.log('onChangeClienteRecebedor');
		this.clienteRecebedor = this.normalizeData(event.detail.value, true);
		console.log('clienteRecebedor:', this.clienteRecebedor);

		if (!this.clienteRecebedor) {
			console.log('Dentro do if');
			this.clienteRecebedorCGC = "";
			this.enderecoCobrancaRecebedor = null;
			this.enderecoEntregaId = null;
			this.selectedEnderecoEntregaId = null;
			this.utilizarEnderecoAdicional = false;
			return;
		}
		getAccountData({ accId: this.clienteRecebedor })
			.then(result => {
				this.clienteRecebedorCGC  = result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
				this.clienteRecebedorCNPJ = result.ClienteEmissorCGC.length == 11 ? false : true;
				//this.enderecoEntregaId = result.EnderecoEntregaId;
				//this.estadoCliente     = result.EstadoCliente;
				//console.log('estadoCliente: ' + result.EstadoCliente);
				this.enderecoCobrancaRecebedor = result.enderecoCobranca;
				if (this.enderecoEntregaId != null) {
					this.utilizarEnderecoAdicional = true;
					this.selectedEnderecoEntregaId = this.enderecoEntregaId;
				}
				if (!result.ClienteBloqueado) {
					this.showToastMsg(ClienteRecebedorInativoInsert);
				}

			}).catch(error => {
				console.log('getAccountData isEdit: entrou no erro!');
				console.log(error);
			})

	}

	// onChangeTabelaPreco(event) {
	//     console.log(event)
	//     this.TabelaPrecoNome = event.target.value;        
	// }

	handleSelectAccountObj(event) {
		const { record } = event.detail;

		this.clienteEmissorId = record ? record.id : null;
		this.clienteEmissor = record ? record.name : null;
		if (record != null) {
			if (this.clienteEmissor.length > 38) {
				this.accountWidth = "width: 100%";
			} else {
				this.accountWidth = "width: 100%";
			}
			this.recordId = this.clienteEmissorId;
			this.checkContact();
		} else {
			this.accountWidth = "width: 100%";
			this.clearValues();
		}
		this.connectedCallbackRebase();
	}

		handleSelectContaOrdem(event) {

		const conta = {
			type: 'icon',
			label: event.detail.value.text,
			name: event.detail.value.value,
			iconName: 'standard:account',
			alternativeText: 'Conta',
		}

		this.contaOrdemShow = true;
		if(this.contaOrdem.filter(function(e) { return e.name === conta.name; }).length > 0) return; 
		this.contaOrdem.push(conta);

		this.clienteRecebedor = event.detail.value.value;
		this.clienteRecebedorName = event.detail.value.text;
		getAccountData({ accId: event.detail.value.value })
			.then(result => {
				console.log('Result: ' + result);
				this.clienteRecebedorCGC  = result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
				this.clienteRecebedorCNPJ = result.ClienteEmissorCGC.length == 11 ? false : true;
				// this.enderecoEntregaId =  result.EnderecoEntregaId;
				// this.enderecoEntrega =  this.clienteRecebedorName;
			}).catch(error => {
				console.log('getAccountData isEdit: entrou no erro!');
				console.log(error);
			})


	}
	handleIdPortal(event) {
		this.Idportalcotacoes = event.target.value;
	}

	handleCreateDate() {
		let current_datetime = new Date()
		let formatted_date = current_datetime.getFullYear() + "-" + (current_datetime.getMonth() + 1) + "-" + current_datetime.getDate() + " " + current_datetime.getHours() + ":" + current_datetime.getMinutes() + ":" + current_datetime.getSeconds() 
		console.log(formatted_date)
		this.createOrderDt = formatted_date;
		console.log('this.createOrderDt => '+this.createOrderDt);
	}

	handlePillItemRemove(event){
		const name = event.detail.item.name;
		const index = event.detail.index;
		console.log('index ' + index);
		this.contaOrdem.splice(index, 1);
		this.contaOrdemShow = false;

	}

	handleChangeFormaPag(event) {
		this.formaPagamento = event.detail.value;
	}

	handleOnFreightValues(event) {
		console.log(event.detail.record);
		let listFreightCd = [];
		let freightList = JSON.parse(this.orderFreightList);
		JSON.parse(event.detail.record).forEach(cd => {
			listFreightCd.push(cd.cnpjCd + ':' + cd.valorFrete + ':' + cd.tipoFrete);
			freightList.forEach(item => {
				if (item.cnpjCd == cd.cnpjCd) {
					item.valorFrete = cd.valorFrete;
					item.tipoFrete = cd.tipoFrete;
				}
			});
		});

		this.orderFreightList = JSON.stringify(freightList);
		this.receivedFreightList = listFreightCd;
		this.fretesPorCd = listFreightCd.join(',');
	}

	handleOnSelectDates(event) {
		console.log(event.detail.record);
		let listDt = [];
		JSON.parse(event.detail.record).forEach(dt => {
			listDt.push(dt);
		});

		this.receivedDtList = listDt;
		this.dtParcelas = listDt.join(',');
		if(this.dtParcelas.length != 0) {
			this.isSaveDisabled = false;
			this.disableAdvanceButton = false;
		}
	}

	handleSelectRecordPrice(event) {
		const { record } = event.detail;

		this.tabelaPreco = record ? record.id : null;
		this.tabelaPrecoNome = record ? record.name : null;
		if(this.tabelaPrecoNome == 'B01/BIONEXO'){
			this.IdportalcotacoesAtivo = false;
		}else{
			this.IdportalcotacoesAtivo = true;
		}

	}

	async condicoesBloqueada() { 
		if((this.disabledFormaPag == null || this.disabledFormaPag == undefined || !this.disabledFormaPag) && 
		   (this.parcelamentoManual ==  null || this.parcelamentoManual == undefined || !this.parcelamentoManual) &&
			this.condicaoPagamento != null && this.condicaoPagamento != undefined ){

			const conditionPaymentCode = await getConditionExternalId({
				conditionId: this.condicaoPagamento
			});

			if (conditionPaymentCode == '050') {
				this.disabledFormaPag = true;
				this.formaPagamento = 'Eletrônico';
			}else if(conditionPaymentCode == '048'){
				this.formaPagamento = '';							
				this.disableAdvanceButton = false;

			}else{
				getTpCondPag({ condicaoPagamento: this.condicaoPagamento })
					.then(result => {
						console.log(result);

						if (result == 'CC') {
							this.disabledFormaPag = true;
							this.formaPagamento = 'Cartão de Credito';
						}else if(result == 'CD'){
							this.disabledFormaPag = true;
							this.formaPagamento = 'Cartão de Debito';                    
						}else if(result == 'CH'){
							this.disabledFormaPag = true;
							this.formaPagamento = 'Cheque';
						}else if(result == 'R$'){
							this.disabledFormaPag = true;
							this.formaPagamento = 'Dinheiro';
						}

					}).catch(error => {
						console.log('getContactData: entrou no erro!');
						console.log(error);
					}); 
			}    
		}
		console.log('disabledFormaPag ==> ' + this.disabledFormaPag);
	}

	async handleSelectRecordCondicaoPagamento(event) {
		console.log(event);
		var condicaoPagamentoData = this.normalizeData(event.detail.record, false);
		this.condicaoPagamento = condicaoPagamentoData?.id;
		this.condicaoPagamentoNome = condicaoPagamentoData?.name;
		this.fillPaymentCondition('');

		console.log(this.isCreateOrderFromBudget);
		console.log(this.isFromBudgetScreen);

		const conditionPaymentCode = await getConditionExternalId({
			conditionId: this.condicaoPagamento
		});

		if (this.isCreateOrderFromBudget || this.isFromBudgetScreen) {
			if (conditionPaymentCode == '048') {
				this.parcelamentoManual = true;
			} else {
				this.parcelamentoManual = false;
				this.receivedDtList = [];
				this.disableAdvanceButton = true;
				this.isSaveDisabled = true;
			}
		} else if (this.isVansOrder) {
			if (conditionPaymentCode == '121') {
				this.isParcelamentoManual = true;
			} else {
				this.isParcelamentoManual = false;
			}
			if (conditionPaymentCode == '048') {
				this.parcelamentoManual = true;
			} else {
				this.parcelamentoManual = false;
				this.receivedDtList = [];
				this.disableAdvanceButton = true;
				this.isSaveDisabled = true;
			}
		}
		this.condicoesBloqueada();

		console.log('this.condicaoPagamento ==> ' + this.condicaoPagamento);
		console.log('conditionPaymentCode ==> ' + conditionPaymentCode);

		if (this.condicaoPagamento && this.condicaoPagamento != undefined) {
			this.disableAdvanceButton = true;
			getOrderData({ ordId: this.recordId, condicaoPag: this.condicaoPagamento })
				.then(result => {
					console.log('getOrderData devido troca da condição de pagamento');
					if (conditionPaymentCode != '048') {
						this.disableAdvanceButton = false;
						this.isSaveDisabled = false;
					}
					if (result != null) {
						if (result.Itens) {
							let newItens = [];
							result.Itens.forEach(item => {
								if (item.rangeStringify) {
									newItens.push({
										...item,
										hasNewPaymentCondition: this.currentPaymentCondition != this.condicaoPagamento,
										range: JSON.parse(item.rangeStringify)
									})
								} else {
									newItens.push({
										...item,
										hasNewPaymentCondition: this.currentPaymentCondition != this.condicaoPagamento
									})
								}
							})
							this.ordItemList = newItens;
						}
					}
					console.log(this.ordItemList);
				}).catch(error => {
					console.log('getOrderData: entrou no erro!');
					console.log(error);
				});
		}
		// this.setFormaPagamentoValue(this.condicaoPagamentoNome);
	}

	onChangeTipoOrdem(event) {
		// console.log(event.detail.value);
		// console.log(event.target.value);
		this.tipoOrdem = event.detail.value;
		this.setTipoOrdemValue(event.detail.value);
	}

	setTipoOrdemValue(value) {
		if (this.enderecoEntregaId != null && value != "PedidoContaOrdem") {
			this.checkEnderecoEntrega(this.enderecoEntregaId);
		}
		if (value == "PedidoVenda") {
			// console.log('Pedido Venda');
			// this.tipoOrdemVenda = true;
			// this.tipoOrdemBonificacao = false;
			this.tipoOrdemVendaOuBonificacao = true;
			this.tipoOrdemContaOrdem = false;
		} else if (value == "PedidoContaOrdem") {
			console.log('Pedido Conta e Ordem');
			// this.tipoOrdemVenda = false;
			// this.tipoOrdemBonificacao = false;
			this.tipoOrdemContaOrdem = true;
			this.tipoOrdemVendaOuBonificacao = false;
			this.enderecoEntregaErro  = false;
			this.utilizarEnderecoAdicional = false;
			this.enderecoEntregaId = null;
			//this.enderecoCobranca = null;
		} else if (value == "PedidoBonificacao"){
			// console.log('Pedido Bonificação');
			// this.tipoOrdemVenda = false;
			// this.tipoOrdemBonificacao = true;
			this.tipoOrdemVendaOuBonificacao = true;
			this.tipoOrdemContaOrdem = false;
		} else {
			// this.tipoOrdemVenda = false;
			// this.tipoOrdemBonificacao = false;
			this.tipoOrdemVendaOuBonificacao = false;
			this.tipoOrdemContaOrdem = false;
		}

		if (this.clienteRecebedor) {
			console.log('if');
			this.enderecoEntregaId = null;
			this.clienteRecebedor  = null;
			this.enderecoCobrancaRecebedor = null;
			this.clienteRecebedorCGC = "";
			this.utilizarEnderecoAdicional = false;
			this.selectedEnderecoEntregaId = null;
		}
	}
	
	onChangeEnderecoEntregaContaOrdem(event) {
		console.log('onChangeEnderecoEntregaContaOrdem');
		const { record } = event.detail;
		this.enderecoEntregaId = record.Id;
	}

	handleUtilizarEnderecoConta() {
		this.utilizarEnderecoAdicional = false;
		this.enderecoEntregaErro = false;
		this.enderecoEntregaId = null;
	}

	handleUtilizarEnderecoAdicional() {
		this.utilizarEnderecoAdicional = true;
		this.enderecoEntregaErro = false;
	}

	onChangeEnderecoEntrega(event) {
		const { record } = event.detail;
		this.checkEnderecoEntrega(record.Id);
	}

	async checkEnderecoEntrega(enderecoEntregaId) {
		console.log('enderecoEntregaId Antes: ' + enderecoEntregaId);
		console.log('estadoCliente Antes: ' + this.estadoCliente);
		try {
			console.log('Try');
			const estadoEndereco = await getEnderecoEntregaData({
				enderecoEntregaId: enderecoEntregaId
			});

			if (estadoEndereco != this.estadoCliente && !this.tipoOrdemContaOrdem) {
				this.enderecoEntregaErro = true;
			} else {
				this.enderecoEntregaId = enderecoEntregaId;
				this.enderecoEntregaErro = false;
			}
		} catch (error) {
			console.log('Catch');
			this.enderecoEntregaId = null;
			this.enderecoEntregaErro = false;
		}
		console.log('enderecoEntregaId Depois: ' + enderecoEntregaId);
		console.log('estadoCliente Depois: ' + this.estadoCliente);
	}

	onClearEnderecoEntrega() {
		this.enderecoEntregaId   = null;
		this.enderecoEntregaErro = false;
		this.selectedEnderecoEntregaId = null;
	}

	onBlurValorFrete(event) {
		console.log('valorFrete: ' + event.target.value);

		if (event.target.value != "") {
			console.log('entrou no if onBlurValorFrete');
			this.valorFrete = event.target.value;
		}
	}

	onChangeNumeroPedidoCliente(event) {
		console.log('numeroPedidoCliente: ' + event.target.value);
		this.numeroPedidoCliente = event.target.value;

		if (this.numeroPedidoCliente.length > 15) {
			this.ordemCompraClienteErro = true;
		}
		else {
			this.ordemCompraClienteErro = false;
		}
	}

	handleObsNF(event) {
		this.observacaoNF = event.target.value;
	}

	handleObsPedido(event) {
		this.observacaoPedido = event.target.value;
	}

	handleCheckSpecialCharacter(event) {
		const fieldValue = event.target.value;
		const fieldName = event.target.name;
		const isValid = !fieldValue.match(/[`´!#$%^&*_+\=\[\]{};'\\|,<>?~àèìòùáéíóúãõñâêîôûäëïöüçÀÈÌÒÙÁÉÍÓÚÃÕÑÂÊÎÔÛÄËÏÖÜÇ]/g);

		if (isValid) {
			if (fieldName == 'ObsNotaFiscal') {
				this.obsNotaFiscalErro = false;	
			} 
			if (fieldName == 'ObsPedido') {
				this.obsPedidoErro = false;
			}
		} else {
			if (fieldName == 'ObsNotaFiscal') {
				this.obsNotaFiscalErro = true;	
			} 
			if (fieldName == 'ObsPedido') {
				this.obsPedidoErro = true;
			}
		}
	}

	handleCEP(event) {
		this.CEP = event.target.value;
	}

	handleBuscaCEP(event) {
		BuscaCep({ cep: this.CEP })
		.then(result => {
			console.log(result);
			this.Logradouro = result.logradouro;
			this.Bairro     = result.bairro;
			this.Cidade     = result.localidade;
			this.Estado     = result.uf;
			this.Pais       = 'Brasil';
		}).catch(error => {
			console.log('BuscaCep: entrou no erro!');
			console.log(error);
		}); 
	}

	handleSelectSalesChannel(event) {
		var record = {};
		record = event?.detail || event?.detail?.value;
		if (this.canalVendas != null) {
			this.oldCanalVendas = this.canalVendas;
		}
		if (this.salesChannelB01.includes(record.record)) {
			this.IdportalcotacoesAtivo = false;
		}else{
			this.IdportalcotacoesAtivo = true;
		}

		if ( (this.salesChannelB01.includes(record.record) && this.salesChannelB01.includes(this.oldCanalVendas)) ||
			 (!this.salesChannelB01.includes(record.record) && !this.salesChannelB01.includes(this.oldCanalVendas)) ||
			 (!this.isEdit && !this.isReturn && !this.isFromBudgetScreen) ) {
			this.canalVendasErro = false;
			this.canalVendas = record.record;
			if (this.salesChannelB01.includes(record.record)) {
				getB01Pricebook()
					.then(result => {
						console.log('getB01Pricebook: entrou certo!');
						this.tabelaPreco = result;
						this.tabelaPrecoNome = 'B01/BIONEXO';
						this.inputLookupFilter();
					}).catch(error => {
						console.log('getB01Pricebook: entrou no erro!');
						console.log(error);
					});
			} else {
				this.tabelaPreco     = this.originalTabelaPreco;
				this.tabelaPrecoNome = this.originalTabelaPrecoNome;
				this.inputLookupFilter();
			}
		} else {
			this.canalVendasErro = true;
			// swal("Aviso!", 'Alteração indisponível pois o novo valor de canal de entrada irá mudar a tabela de preço.');
			// this.canalVendas = this.oldCanalVendas;
		}

	}

	showToast(toastInfo) {
		const evt = new ShowToastEvent({
			title: toastInfo.Title,
			message: toastInfo.Message,
			variant: toastInfo.Type,
		});
		this.dispatchEvent(evt);
	}

	checkContact() {
		if (!this.contatoOrcamento) return;

		getContactData({ contatoOrcamento: this.contatoOrcamento })
			.then(result => {
				if (result != this.recordId && this.contatoOrcamento != null && this.recordId != null) {
					this.showToastMsg('Selecione um Contato vinculado ao Cliente escolhido');
					this.contatoOrcamento = null;
				}
			}).catch(error => {
				console.log('getContactData: entrou no erro!');
				console.log(error);
			});

	}

	handleNavigate(event) {
		if (event.target.value == 'checkout') {
			this.goToCheckout = true;
			this.navigateOrderProduct();
			return;
		} else {
			this.goToCheckout = false;
		}
		var bloqueio = '';
		if(this.recordId != null){
			lockScreen({ servico: 'Pedido', OrcPedId: this.recordId })
				.then(result => {
					bloqueio   = result;
				}).catch(error => {
					console.log('getToastInfoData: entrou no erro!');
					console.log(error);
				});
		}
		if(bloqueio == ''){
			if(this.tipoOrdem == 'PedidoContaOrdem'){
				if(this.clienteRecebedor == undefined || this.clienteRecebedor == ''){
					swal("Aviso!", 'Preencha Cliente Recebedor');
					return;

				}
				if(this.clienteEmissorId == this.clienteRecebedor){
					swal("Aviso!", 'Cliente Recebedor não pode ser igual a Emissor');
					return;
				}
				if(this.clienteRecebedorCGC == undefined || this.clienteRecebedorCGC == '' ){
					swal("Aviso!", 'Cliente Recebedor tem que ser CPF/CNPJ');
					return;
				}

			}

			console.log(this.recordId);
			console.log(this.clienteEmissor);
			console.log(this.clienteEmissorCGC);
			console.log(this.headerId);
			console.log(this.condicaoPagamentoNome);
			console.log(this.tabelaPrecoNome);
			console.log(this.dtPrevistaEntrega);
			
			if (this.observacaoNF) {
				if (this.observacaoNF.length > 0) {
					if (this.currentLength > this.maxLengthNote) {
						swal("Aviso!", 'Campo observação (Nota Fiscal) ultrapassou ' + (this.currentLength - this.maxLengthNote).toString() + ' caracteres do limite!');
						return;
					}
				}
			}
			//console.log('enderecoEntrega: ' + this.enderecoEntrega + ' / ' + this.enderecoEntregaErro);
			var requiredFields = this.checkRequiredFields();
			if(this.tabelaPrecoNome == 'B01/BIONEXO' && (this.Idportalcotacoes == undefined || this.Idportalcotacoes == '')){
					swal("Aviso!", 'Preencher o Id do portal de cotação');
					return;
			}
			
			if (this.observacaoNF) {
				if (this.observacaoNF.length > 0) {
					if (this.currentLength > this.maxLengthNote) {
						swal("Aviso!", 'Campo observação (Nota Fiscal) ultrapassou ' + (this.currentLength - this.maxLengthNote).toString() + ' caracteres do limite!');
						return;
					}
				}
			}
			//console.log('enderecoEntrega: ' + this.enderecoEntrega + ' / ' + this.enderecoEntregaErro);
			var requiredFields = this.checkRequiredFields();

			if (requiredFields.length > 0) {
				var stringField = this.toastInfoErrorRequired.Message.replace('{fields}', requiredFields.join(', '));
				swal("Aviso!", stringField);
				// this.showToastMsg(stringField);
			} 
			else if (this.enderecoEntregaErro == true) {
				swal("Aviso!", 'Selecione um endereço com a UF válida');
			} else if (this.canalVendasErro && (this.isEdit || this.isReturn)) { 
				swal("Aviso!", 'Não é possível trocar o canal de vendas para esse valor.');
			} else if (this.ordemCompraClienteErro) {
				swal("Aviso!", 'Ajuste o campo "Ordem de compra do cliente". Máximo de 15 caracteres.', 'warning');
			} else if (this.obsNotaFiscalErro == true || this.obsPedidoErro == true) {
				swal("Aviso!", 'Não é permitido caracteres especiais nos campos de Observação.', 'warning');
			} else {
				console.log("Calling another component");
				console.log("this.ordItemList: ");
				console.log(this.ordItemList);
				console.log('this.Idportalcotacoes: ' + this.Idportalcotacoes);
				
				var compDefinition = {
					componentDef: "c:orderProduct",
					attributes: {
						isEdit                   : this.isEdit,
						isBudget                 : this.isBudget,
						recordId                 : this.recordId,
						clienteEmissor           : this.clienteEmissor,
						clienteEmissorId         : this.clienteEmissorId,
						clienteEmissorCGC        : this.clienteEmissorCGC,
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
						//enderecoEntrega          : this.enderecoEntrega,
						enderecoEntregaId        : this.enderecoEntregaId, 
						enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
						observacao               : this.observacao,
						observacaoNF             : this.observacaoNF,
						observacaoPedido         : this.observacaoPedido,
						hasPermissionERB         : this.hasPermissionERB,
						dtParcelas               : this.dtParcelas,
						fretesPorCd              : this.fretesPorCd,
						pedidoComplementar       : this.pedidoComplementar,
						utilizarEnderecoAdicional: this.utilizarEnderecoAdicional,
						Idportalcotacoes         : this.Idportalcotacoes,
						createOrderDt            : this.createOrderDt,
						recomendacaoRespondida   : this.allRecAnswered,
						alreadySaved             : this.alreadySaved,
						savingStrData            : this.savingStrData,
						newRecordId              : this.newRecordId,
						orderListReturned        : JSON.stringify(this.ordItemList)
					}
				};
				try {
					const filterChangeEvent = new CustomEvent('displaymyvaluenew', {
						detail: { "data": JSON.stringify(compDefinition) }
					});
					// Fire the custom event
					this.dispatchEvent(filterChangeEvent);
				} catch (e) {
					debugger;
					console.log(e);
				}
			}
		}else{
			this.showToastMsg(bloqueio);
		}
	}

	checkRequiredFields() {
		console.log('contatoOrcamento:', this.contatoOrcamento);
		var mapObjLabel = [];

		if (this.clienteEmissorCNPJ == true) {
			console.log('if this.clienteEmissorCNPJ:', this.clienteEmissorCNPJ);
			mapObjLabel = {
				'clienteEmissorCGC': 'Cliente',
				'tabelaPrecoNome': 'Tabela de preço',
				'canalVendas': 'Canal de vendas',
				'condicaoPagamentoNome': 'Condição de pagamento',
				'contatoOrcamento': 'Contato',
				'tipoOrdem': 'Tipo de ordem',
				'formaPagamento': 'Forma de pagamento'
			}
		}
		else {
			console.log('else this.clienteEmissorCNPJ:', this.clienteEmissorCNPJ);
			mapObjLabel = {
				'clienteEmissorCGC': 'Cliente',
				'tabelaPrecoNome': 'Tabela de preço',
				'canalVendas': 'Canal de vendas',
				'condicaoPagamentoNome': 'Condição de pagamento',
				'tipoOrdem': 'Tipo de ordem',
				'formaPagamento': 'Forma de pagamento'
			}
		}
		
		var emptyFields = [];
		for (var i = 0; i < Object.keys(mapObjLabel).length; i++) {
			var item = Object.keys(mapObjLabel)[i]
			if (this[item] == undefined || this[item] == null) {
				emptyFields.push(mapObjLabel[item]);
			}
		}
		return emptyFields;
	}

	normalizeData(eventData, list) {
		return list ? JSON.parse(JSON.stringify(eventData))[0] : JSON.parse(JSON.stringify(eventData));
	}

	removeSpecialCaracter(value) {
		value = value.replace('á', 'a');
		return value;
	}

	showLoading(show) {
		this.loading = show;
	}

	onClickWindowBack() {
		var close = true;
		const closeclickedevt = new CustomEvent('closeclicked', {
			detail: { close },
		});

		// Fire the custom event
		this.dispatchEvent(closeclickedevt);
	}
    renderedCallback() {
		Promise.all([loadStyle(this, showPicklistValueComponent + '/showPicklistValueComponent/showPicklistValue.css')]).then(() => { console.log('Files loaded showpicklist.'); }).catch(error => { console.log('error: ' + JSON.stringify(error)); });
        // var box1 = document.getElementById('box1');
		var box1 = document.querySelector('#box1');
		if(box1){
			box1.addEventListener('touchmove', function(e) {
				e.stopPropagation();
			}, false); 
		}
 
     }

	navigateOrderProduct() {
		var compDefinition = {
			componentDef: "c:orderProduct",
			attributes: {
				isEdit: this.isEdit,
				isBudget: this.isBudget,
				recordId: this.recordId,
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
				enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
				observacao: this.observacao,
				observacaoNF: this.observacaoNF,
				observacaoPedido: this.observacaoPedido,
				hasPermissionERB: this.hasPermissionERB,
				goToCheckout: this.goToCheckout,
				dtParcelas: this.dtParcelas,
				fretesPorCd: this.fretesPorCd,
				pedidoComplementar: this.pedidoComplementar,
				utilizarEnderecoAdicional: this.utilizarEnderecoAdicional,
				Idportalcotacoes: this.Idportalcotacoes,
				createOrderDt: this.createOrderDt,
				recomendacaoRespondida: this.allRecAnswered,
				alreadySaved: this.alreadySaved,
				savingStrData: this.savingStrData,
				newRecordId: this.newRecordId,
				orderListReturned: JSON.stringify(this.ordItemList)
			}
		};
		try {
			const filterChangeEvent = new CustomEvent('displaymyvaluenew', {
				detail: { "data": JSON.stringify(compDefinition) }
			});
			// Fire the custom event
			this.dispatchEvent(filterChangeEvent);
		} catch (e) {
			debugger;
			console.log(e);
		}
	}
	
	onClickWindowBackBudget() {
		console.log('É do Orçamento?', this.createOrderFromBudget);
		var compDefinition = {
			componentDef: "c:orderProductCheckout",
			attributes: {
				newRecordId              : this.newRecordId,
				isEdit                   : this.isEdit,
				isBudget                 : this.isBudget,
				recordId                 : this.recordId,
				numOrcamento             : this.numOrcamento,
				valorTotal               : this.valorTotal,
				score                    : this.score ? this.score.replace('%', '') : this.score,
				clienteEmissorId         : this.clienteEmissorId,
				clienteEmissor           : this.clienteEmissor,
				clienteEmissorCGC        : this.clienteEmissorCGC,
				tabelaPreco              : this.tabelaPreco,
				tabelaPrecoNome          : this.tabelaPrecoNome,
				canalEntrada             : this.canalVendas,
				condicaoPagamento        : this.condicaoPagamento,
				condicaoPagamentoNome    : this.condicaoPagamentoNome,
				formaPagamento           : this.formaPagamento,
				contatoOrcamento         : this.contatoOrcamento,
				prazoValidade            : this.prazoValidade,
				dtValidade               : this.dtValidade,
				observacaoCliente        : this.observacao,
				observacao               : this.observacaoNF,
				dtParcelas               : this.dtParcelas,
				fretesPorCd              : this.fretesPorCd,
				alreadySaved             : this.alreadySaved,
				savingStrData            : this.savingStrData, // stringify?
				orderList                : this.orderList
			}
		};
		console.log('Criou compDefinition');
		try {
			const filterChangeEvent = new CustomEvent('displaymyvaluenew', {
				detail: { "data": JSON.stringify(compDefinition) }
			});
			this.dispatchEvent(filterChangeEvent);
		} catch (error) {
			debugger;
			console.log(error);
		}
	}

	showToastMsg(toastInfo) {
		const evt = new ShowToastEvent({
			title: 'Erro',
			message: toastInfo,
			variant: 'Error'
		});
		this.dispatchEvent(evt);
	}

	async getSizeNote() {
		try {
			var size = 48 + (this.Idportalcotacoes ? this.Idportalcotacoes.length : 0);
			if (this.enderecoEntregaId != null) {
				var address = await getAddress({
					addressId: this.enderecoEntregaId
				});
				size += (address.length > 32 ? address.length : 32) + (this.observacaoNF ? this.observacaoNF.length : 0);
			} else {
				size += 32 + (this.observacaoNF ? this.observacaoNF.length : 0);
			}
			this.sizeNote = size;
			return size;
		} catch (error) {
			console.log('Erro na função da observacaoNF.');
		}
	}

	callEditOrder() {
        // EDITAR PEDIDO
        this.isSaving = true;
        editLabOrder({ jsonOrder: JSON.stringify(this.ordItemList), headerInfo: JSON.stringify(this.headerInfoDataOrder), sendToApproval: false, recordId: this.recordId, keepComplementOrder: false, isAutomaticSave: false })
        .then(result => {
            console.log(result);
            if (result.length == 18) {
				this.handleNavigateMix(result);
                swal("Show!", "Pedido editado com sucesso!", "success");
			} else {
				swal("Ops!", "Ocorreu algum problema ao editar o pedido! Tente novamente mais tarde!", "Warning");
				this.enableButtons();
			}
        }).catch(error => {
            this.isSaving = false;
            swal("Ops!", "Erro ao gerar pedido! Verifique com o administrador!", "error");
            this.enableButtons();
            console.log(error);
        });
    }

	handleEditOrder() {		
		this.disableButtons();
		this.fillHeaders();
		
		if (this.isParcelamentoManual) {				
			swal("Aviso!", 'Canal de vendas não pode ser de parcelamento manual', 'warning');
			this.enableButtons();
			return;
		}
		
		if (this.canalVendasErro && (this.isEdit || this.isReturn || this.isFromBudgetScreen)) { 
			swal("Aviso!", 'Não é possível trocar o canal de vendas para esse valor.');
			this.enableButtons();
			return;
		}

		console.log(this.headerInfoDataOrder);

		this.callEditOrder();
		return;
	}

	updateOrderSon() {
		this.isLoading = true;
		this.fillHeaders();
		console.log('headerInfoDataOrder ==> ' + JSON.stringify(this.headerInfoDataOrder));

		updatePaymentConditionAndNotesOrderSonAndSendToAutomaticIntegration({orderHeaderInformation: JSON.stringify(this.headerInfoDataOrder)}).then(result => {
			if(result) {
				this.isLoading = false;
				this.onClickWindowBack();
				this.handleNavigateMix(this.recordId);
				// window.location.reload();
			} else {
				this.isLoading = false;
				swal('Erro', 'Erro na atualização deste pedido. \n Entre em contato com o administrador do sistema! \n Classe: OrderService \n Método:updatePaymentConditionAndNotesOrder', 'error');
			}
		}).catch(error => {
			this.isLoading = false;
			swal('Erro', reduceErrors(error), 'error');
		});
	}
	
	handleSaveOrder() {
		console.log('SALVE O PEDIDO.');
		this.disableButtons();
		this.fillHeaders();		
		
		if (this.tipoOrdem == undefined) {
			swal("Aviso!", 'Preencha o tipo de Ordem!');
			this.enableButtons();
			return;
		}
		if(this.tipoOrdem == 'Conta e Ordem'){
			if(this.clienteRecebedor == null || this.clienteRecebedor == ''){
				swal("Aviso!", 'Preencha Cliente Recebedor');
				this.enableButtons();
				return;
			}
			if(this.clienteEmissorId == this.clienteRecebedor){
				swal("Aviso!", 'Cliente Recebedor não pode ser igual a Emissor');
				this.enableButtons();
				return;
			}
			if(this.clienteRecebedorCGC == null || this.clienteRecebedorCGC == '' ){
				swal("Aviso!", 'Cliente Recebedor tem que ser CPF/CNPJ');
				this.enableButtons();
				return;
			}
		}
		if (this.parcelamentoManual) {
			if (this.receivedDtList.length == 0) {
				swal("Aviso!", `Parcelas obrigatórias pelo tipo de condição de pagamento escolhida!`, "warning");
				this.enableButtons();
				return;
			}
		}
		if (this.freteNecessario) {
			if (this.receivedFreightList.length == 0) {
				swal("Aviso!", `Obrigatório registrar valores de frete por CD!`, "warning");
				this.enableButtons();
				return;
			}
		}
		
		if(this.tabelaPrecoNome == 'B01/BIONEXO' && (this.Idportalcotacoes == undefined || this.Idportalcotacoes == '')){
			swal("Aviso!", 'Preencher o Id do portal de cotação');
			this.enableButtons();
			return;
		}
		
		if (this.canalVendasErro && (this.isEdit || this.isReturn || this.isFromBudgetScreen)) { 
			swal("Aviso!", 'Não é possível trocar o canal de vendas para esse valor.');
			this.enableButtons();
			return;
		}
		console.log(this.headerInfoData);
		console.log('formaPagamento: ' + this.formaPagamento);
		console.log('dtPrevistaEntrega: ' + this.dtPrevistaEntrega);
		console.log('clienteRecebedor: ' + this.clienteRecebedor);
		console.log('clienteRecebedorCGC: ' + this.clienteRecebedorCGC);
		//console.log('enderecoEntrega: ' + this.enderecoEntrega);
		console.log('enderecoEntregaContaOrdem: ' + this.enderecoEntregaContaOrdem);
		console.log('observacao: ' + this.observacao);
		console.log('observacaoNF: ' + this.observacaoNF);
		console.log('cnpjCd: ' + this.cnpjCd);        
		console.log('isCreateOrderFromBudget: ' + this.isCreateOrderFromBudget);

		var requiredFields = this.checkRequiredFields();

		//this.itensList = this.isCreateOrderFromBudget ? JSON.stringify(this.ordItemList) : this.fromBudgetorderList;

		this.headerInfoDataBudget = this.isCreateOrderFromBudget ? JSON.stringify(this.headerInfoDataBudget) : this.headerInfoData;

		console.log(this.ordItemList);
		console.log(this.fromBudgetorderList);
		console.log(this.headerInfoData);
		console.log(this.headerInfoDataBudget);
		console.log(this.headerInfoDataOrder);

		if (this.observacaoNF) {
			if (this.observacaoNF.length > 0) {
				if (this.currentLength > this.maxLengthNote) {
					swal("Aviso!", 'Campo observação (Nota Fiscal) ultrapassou ' + (this.currentLength - this.maxLengthNote).toString() + ' caracteres do limite!');
					this.enableButtons();
					return;
				}
			}
		}

		if (requiredFields.length > 0) {
			var stringField = this.toastInfoErrorRequired.Message.replace('{fields}', requiredFields.join(', '));
			console.log('if Erro Campos Obrigatorios');
			swal("Aviso!", stringField);
			this.enableButtons();
		} else if (this.enderecoEntregaErro == true) {
			swal("Aviso!", 'Selecione um endereço com a UF válida.');
			this.enableButtons();
		} else if (this.ordemCompraClienteErro) {
			swal("Aviso!", 'Ajuste o campo "Ordem de compra do cliente".');
			this.enableButtons();
		} else if (this.obsNotaFiscalErro == true || this.obsPedidoErro == true) {
			swal("Aviso!", 'Não é permitido caracteres especiais nos campos de Observação.', 'warning');
			this.enableButtons();
		} else {
				getAccountData({ accId: this.clienteEmissorId })
					.then(result => {        
						if (!result.ClienteBloqueado) {
							swal({
								title: ClienteInativoInsert,
								text: ClienteInativoInsertPositivo,
								icon: "warning",
								buttons: ["Cancelar", "Continuar"],
								dangerMode: true,
							}).then((willSalve) => {
									if (willSalve) {
										if(this.clienteRecebedor != null && this.clienteRecebedor != this.clienteEmissorId ){
											getAccountData({ accId: this.clienteRecebedor })
												.then(result => {
													if (!result.ClienteBloqueado) {
														swal({
															title: ClienteRecebedorInativoInsert,
															text: ClienteInativoInsertPositivo,
															icon: "warning",
															buttons: ["Cancelar", "Continuar"],
															dangerMode: true,
														}).then((willSalve) => {
																if (willSalve) {
																	if (this.outOfStock) {
																		this.dealOutStockGenerateOrder();
																	} else {
																		this.callGenerateBudgetAndOrder();
																	}
																}else{
																	this.enableButtons();
																	return;
																}
														});
													} else {
														if (this.outOfStock) {
															this.dealOutStockGenerateOrder();
														} else {
															this.callGenerateBudgetAndOrder();
														}
													}
												}).catch(error => {
													console.log('getAccountData isEdit: entrou no erro!');
													console.log(error);
												})
										} else {
											if (this.outOfStock) {
												this.dealOutStockGenerateOrder();
											} else {
												this.callGenerateBudgetAndOrder();
											}
										}
									}else{
										this.enableButtons();
										return;
									}
							});
						}else{
							if(this.clienteRecebedor != null && this.clienteRecebedor != this.clienteEmissorId ){
								getAccountData({ accId: this.clienteRecebedor })
									.then(result => {
										if (!result.ClienteBloqueado) {
											swal({
												title: ClienteRecebedorInativoInsert,
												text: ClienteInativoInsertPositivo,
												icon: "warning",
												buttons: ["Cancelar", "Continuar"],
												dangerMode: true,
											}).then((willSalve) => {
												if (willSalve) {
													if (this.outOfStock) {
														this.dealOutStockGenerateOrder();
													} else {
														this.callGenerateBudgetAndOrder();
													}
												} else {
													this.enableButtons();
													return;
												}
											});
										} else {
											if (this.outOfStock) {
												this.dealOutStockGenerateOrder();
											} else {
												this.callGenerateBudgetAndOrder();
											}
										}
									}).catch(error => {
										console.log('getAccountData isEdit: entrou no erro!');
										console.log(error);
									})
							} else {
								if (this.outOfStock) {
									this.dealOutStockGenerateOrder();
								} else {
									this.callGenerateBudgetAndOrder();
								}
							}
						}
					}).catch(error => {
						console.log('getAccountData isEdit: entrou no erro!');
						console.log(error);
					})

		}
	}

	dealOutStockGenerateOrder () {
		swal({
			title: "Aviso!",
			text: "Esse pedido irá gerar um pedido complementar, deseja continuar?",
			icon: "warning",
			buttons: {
				Cancelar: {
					text: "Não",
					value: true
				},
				Aguardar: {
					text: "Manter pendente",
					value: "Aguardar",
				},
				Gerar: {
					text: "Sim",
					value: "Gerar",
				},
			},
			dangerMode: true,
		})
			.then((value) => {
				console.log(value)
				switch (value) {
					case "Gerar":
						console.log('Gerar pedido com pedido complementar');
						console.log(this.auxOrderList);
						this.orderListComplement = [];
						this.auxOrderToRemove = [];
						this.auxOrderList.forEach((cd, index) => {
							if (cd.pedidoComplementar) {
								console.log(cd.quantidadePossivel);
								console.log(cd.quantidadeRestante);
								console.log('cd acima da quantidade possível');
								console.log(cd.itemId);
								this.hasComplementOrder = true;
								this.orderListComplement.push({
									... this.auxOrderList[index],
									itemId: undefined,
									quantidadeCx: cd.quantidadeRestante,
									valorTotal: cd.quantidadeRestante * cd.caixa
								})
								if (cd.quantidadePossivel == 0) {
									this.auxOrderToRemove.push(cd.cdId);
									this.auxOrderList[index] = {
										...this.auxOrderList[index],
										pedidoComplementar: false
									}
								}
							}
						});

						if (this.auxOrderToRemove.length == this.auxOrderList.length) {
							swal({
								title: "Aviso!",
								text: "Não existe estoque para nenhum dos itens adicionados",
								icon: "warning",
								buttons: {
									Cancelar: {
										text: "Cancelar",
										value: true
									},
									Aguardar: {
										text: "Manter pendente",
										value: "Aguardar",
									}
								},
								dangerMode: true,
							})
								.then((value) => {
									console.log(value)
									switch (value) {
										case "Aguardar":
											this.hasComplementOrder = false;
											this.keepComplementOrder = true;
											this.dealOrderWithComplement(false, null);
											break;
										default:
											this.enableButtons();
											return;
									}
								});

							return;
						}

						console.log('tratamentos feitos: ');
						console.log('ordItemList: ');
						console.log(JSON.parse(JSON.stringify(this.auxOrderList)));
						console.log('orderItemComplement: ');
						console.log(JSON.parse(JSON.stringify(this.orderListComplement)));
						this.dealOrderWithComplement(false, null)
						break;
					case "Aguardar":
						this.hasComplementOrder = false;
						this.keepComplementOrder = true;
						this.dealOrderWithComplement(false, null);
						break;
					default:
						this.enableButtons();
						return;
				}
			});
	}

	callGenerateBudgetAndOrder() {
		console.log('this.headerInfoDataBudget: ' + this.headerInfoDataBudget);
		generateBudgetAndOrder({ jsonOrderBudget: JSON.stringify(this.auxOrderList), headerInfoOpp: this.headerInfoDataBudget, headerInfoOrd: JSON.stringify(this.headerInfoDataOrder), oppIdToUpdate: this.newRecordId ? this.newRecordId : this.alreadySaved ? this.recordId : this.recordId ? this.recordId : (this.fromBudgetisEdit ? this.fromBudgetrecordId : null) })
			.then(result => {
				console.log('generateBudgetAndOrder: entrou certo! 33');

				console.log(result);
				if (result.length == 18) {
					this.handleNavigateMix(result);
					swal("Show!", "Orçamento e Pedido gerados com sucesso!", "success");
				} else {
					swal("Ops!", "Ocorreu algum problema ao gerar o orçamento e pedido! Tente novamente mais tarde!", "Warning");
					this.enableButtons();
				}
			}).catch(error => {
				console.log('generateBudgetAndOrder: entrou no erro!');
				console.log(error);
				this.enableButtons();
			});
	}

	dealOrderWithComplement(isComplement, ordId) {
		this.fillHeaders();
		if (!isComplement) {
			this.callHandleBudget(isComplement);
		} else {
			this.buildCalcAllScoreObj(isComplement);
			console.log(this.calcAllScoreObj);
			this.getSpecificMarginCalc(isComplement, ordId, null);
		}
	}

	callHandleBudget(isComplement) {
		this.buildCalcAllScoreObj(false);
		console.log(this.calcAllScoreObj);
		calcAllProducts({ clListString: JSON.stringify(this.calcAllScoreObj) })
			.then(result => {
				let resultJson = JSON.parse(result);
				console.log(resultJson);
				this.calcAllScoreObj.forEach(calcObj => {
					for (var i = 0; i < resultJson['cdMap'][calcObj.cdId].length; i++) {
						if ((calcObj.cdId + '_' + calcObj.productCode) == (resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode)) {
							let index = this.auxOrderList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);

							const scoreBU = Number(resultJson['results'][calcObj.productBu]['scoreFinal'].toFixed(2));
							const scoreMix = Number(resultJson['results'][calcObj.productBu]['scoreMix'].toFixed(2));
							const scoreItem = Number(resultJson['cdProdMap'][calcObj.cdId + '_' + calcObj.productCode]['scoreFinal'].toFixed(2));
							const margemTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreDenominator'].toFixed(2));
							const margemAlvoTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreNumerador'].toFixed(2));
							const scoreCd = Number(resultJson['results'][calcObj.cdId]['scoreFinal'].toFixed(2));

							this.auxOrderList[index] = {
								...this.auxOrderList[index],
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
				if (resultJson['results']['Order'] != undefined) {
					this.margemAtualGeral = Number(Number(resultJson['results']['Order']['scoreDenominator'])).toFixed(2);
					this.margemAtualAlvo = Number(Number(resultJson['results']['Order']['scoreNumerador'])).toFixed(2);
					this.scoreFinalGeral = Number(Number(resultJson['results']['Order']['scoreFinal'])).toFixed(2);
				} else {
					this.margemAtualGeral = '';
					this.margemAtualAlvo = '';
					this.scoreFinalGeral = '';
				}

				this.fillHeaders();
				editBudget({ budget: JSON.stringify(this.auxOrderList), headerInfo: JSON.stringify(this.headerInfoDataBudget), sendToApproval: false, recordId: this.newRecordId ? this.newRecordId : this.recordId ? this.recordId : this.fromBudgetrecordId, hasComplementOrder: true })
				.then(result => {
					console.log(result);
					if (result.length == 18) {
						if (!this.hasComplementOrder && this.keepComplementOrder) {
							this.handleComplementOrder(false, result);
						} else {
							this.handleComplementOrder(isComplement, result);
						}
					} else {
						swal("Ops!", "Ocorreu algum problema ao editar o orçamento! Tente novamente mais tarde!", "Warning");
						this.enableButtons();
					}
				}).catch(error => {
					swal("Ops!", "Erro ao gerar orçamento! Verifique com o administrador!", "error");
					this.enableButtons();
					console.log(error);
				});
			}).catch(error => {
				console.log('calcAllProducts: entrou no erro!');
				console.log(error);
			});
	}

	handleComplementOrder(isComplement, oppId) {
		if (!this.keepComplementOrder) {
			var lstCdId = [];
			this.auxOrderList.forEach(cd => {
				if (cd.pedidoComplementar || cd.quantidadePossivel == 0) {
					console.log(cd.quantidadePossivel);
					console.log(cd.quantidadeRestante);
					if (cd.quantidadePossivel == 0) {
						lstCdId.push(cd.cdId);
					} else {
						cd.quantidade = cd.tipoConversao == 'M' ? (cd.quantidadePossivel * parseFloat(cd.conversaoUnidadeCx)) : Number(cd.quantidadePossivel / parseFloat(cd.conversaoUnidadeCx));
						cd.quantidadeCx = cd.quantidadePossivel;
						cd.valorTotal = cd.quantidadeCx * cd.caixa;
					}
				}
			});
	
			lstCdId.forEach(cdId => {
				this.auxOrderList = this.auxOrderList.filter(cdList => cdList.cdId != cdId);
			})
		}

		this.buildCalcAllScoreObj(isComplement);
		console.log(this.calcAllScoreObj);
		this.getSpecificMarginCalc(isComplement, null, oppId);
	}

	buildCalcAllScoreObj(isComplementOrder) {
		this.calcAllScoreObj = [];

		if (isComplementOrder) {
			this.orderListComplement.forEach(cd => {
				this.calcAllScoreObj.push({
					cdId: cd.cnpjCd,
					productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
					productCode: cd.prodCode,
					cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
					quantity: cd.quantidadeCx,
					unitPrice: Number(cd.caixa).toFixed(6),
					listPrice: Number(cd.inicialCaixa).toFixed(6),// Number((currentProd.precoTabelaCx).toFixed(6)),
					taxPercent: cd.aliquota,
					isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false
				});
			});
		} else {
			this.auxOrderList.forEach(cd => {
				this.calcAllScoreObj.push({
					cdId: cd.cnpjCd,
					productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
					productCode: cd.prodCode,
					cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
					quantity: cd.quantidadeCx,
					unitPrice: Number(cd.caixa).toFixed(6),
					listPrice: Number(cd.inicialCaixa).toFixed(6),// Number((currentProd.precoTabelaCx).toFixed(6)),
					taxPercent: cd.aliquota,
					isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false
				});
			});
		}
	}

	getSpecificMarginCalc(isComplement, ordId, oppId) {
		calcAllProducts({ clListString: JSON.stringify(this.calcAllScoreObj) })
			.then(result => {
				let resultJson = JSON.parse(result);
				console.log(resultJson);
				this.calcAllScoreObj.forEach(calcObj => {
					for (var i = 0; i < resultJson['cdMap'][calcObj.cdId].length; i++) {
						if ((calcObj.cdId + '_' + calcObj.productCode) == (resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode)) {
							let index
							if (isComplement) {
								index = this.orderListComplement.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
							} else {
								index = this.auxOrderList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
							}

							const scoreBU = Number(resultJson['results'][calcObj.productBu]['scoreFinal'].toFixed(2));
							const scoreMix = Number(resultJson['results'][calcObj.productBu]['scoreMix'].toFixed(2));
							const scoreItem = Number(resultJson['cdProdMap'][calcObj.cdId + '_' + calcObj.productCode]['scoreFinal'].toFixed(2));
							const margemTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreDenominator'].toFixed(2));
							const margemAlvoTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreNumerador'].toFixed(2));
							const scoreCd = Number(resultJson['results'][calcObj.cdId]['scoreFinal'].toFixed(2));

							if (isComplement) {
								this.orderListComplement[index] = {
									...this.orderListComplement[index],
									score: scoreCd,
									scoreBU,
									scoreMix,
									scoreItem,
									margemTotalCd,
									margemAlvoTotalCd
								}
							} else {
								this.auxOrderList[index] = {
									...this.auxOrderList[index],
									score: scoreCd,
									scoreBU,
									scoreMix,
									scoreItem,
									margemTotalCd,
									margemAlvoTotalCd
								}
							}
						}
					}
				})
				if (resultJson['results']['Order'] != undefined) {
					this.margemAtualGeral = Number(Number(resultJson['results']['Order']['scoreDenominator'])).toFixed(2);
					this.margemAtualAlvo = Number(Number(resultJson['results']['Order']['scoreNumerador'])).toFixed(2);
					this.scoreFinalGeral = Number(Number(resultJson['results']['Order']['scoreFinal'])).toFixed(2);
				} else {
					this.margemAtualGeral = '';
					this.margemAtualAlvo = '';
					this.scoreFinalGeral = '';
				}

				this.fillHeaders();
				if (isComplement && !this.keepComplementOrder) {
					this.callGenerateComplementOrder(ordId);
				} else {
					if (!this.hasComplementOrder && this.keepComplementOrder) {
						this.callGenerateOrder(false, oppId);
					} else {
						this.callGenerateOrder(true, oppId);
					}
				}
			}).catch(error => {
				console.log('calcAllProducts: entrou no erro!');
				console.log(error);
			});
	}

	callGenerateOrder(sendToApp, oppId) {
		// CRIAR PEDIDO
		generateOrder({ jsonOrder: JSON.stringify(this.auxOrderList), headerInfo: JSON.stringify(this.headerInfoDataOrder), sendToApproval: sendToApp, keepComplementOrder: this.keepComplementOrder, oppId: oppId, isAutomaticSave: false })
			.then(result => {
				console.log(result);
				if (result.length == 18) {
					if (!this.hasComplementOrder && this.keepComplementOrder) {
						this.handleNavigateMix(result);
						swal("Show!", `Pedido gerado e mantido pendente com sucesso!`, "success");
					} else {
						this.dealOrderWithComplement(true, result);
					}
				} else {
					swal("Ops!", "Ocorreu algum problema ao gerar o pedido! Tente novamente mais tarde!", "Warning");
					this.enableButtons();
					return;
				}
			}).catch(error => {
				swal("Ops!", "Erro ao gerar pedido! Verifique com o administrador!", "error");
				this.enableButtons();
				console.log(error);
			});
	}

	callGenerateComplementOrder(ordId) {
		generateComplementOrder({ complementOrder: JSON.stringify(this.orderListComplement), headerInfo: JSON.stringify(this.headerInfoDataOrder), sendToApproval: false, complementOrdId: ordId })
			.then(result => {
				console.log(result);
				if (result.length == 18) {
					this.handleNavigateMix(result);
					swal("Show!", `Pedido complementar gerado com sucesso!`, "success");
				} else {
					swal("Ops!", "Ocorreu algum problema ao gerar o pedido! Tente novamente mais tarde!", "Warning");
					this.enableButtons();
					return;
				}
			}).catch(error => {
				swal("Ops!", "Erro ao gerar pedido! Verifique com o administrador!", "error");
				this.enableButtons();
				console.log(error);
			});
	}

	

	disableButtons() {
		this.isInstallmentDisabled = true;
		this.isSaveDisabled = true;
	}

	enableButtons() {
		this.isInstallmentDisabled = false;
		this.isSaveDisabled = false;
	}

	handleNavigateMix(result) {
		//this.handlePublishCloseTab();
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: result,
				objectApiName: 'order',
				actionName: 'view'
			}
		});
	}

	get optionsTipoFrete() {
		return [
			{ label: 'CIF', value: 'CIF' },
			{ label: 'FOB', value: 'FOB' },
		];
	}

	get optionsTipoOrdem() {
		return [
			{ label: 'Venda',            value: 'PedidoVenda' },
			{ label: 'Bonificação',      value: 'PedidoBonificacao' },
			{ label: 'Conta e Ordem',    value: 'PedidoContaOrdem' }
		]
	}

	get optionsFormaRA() {
			return [{ label: 'Depósito' , value: 'Depósito' },
					{ label: 'Cartão de Credito', value: 'Cartão de Credito'},
					{ label: 'Cartão de Debito', value: 'Cartão de Debito'},
					{ label: 'Cheque', value: 'Cheque'},
					{ label: 'Dinheiro', value: 'Dinheiro'},
					{ label: 'Eletrônico', value: 'Eletrônico'},
					{ label: 'Boleto', value: 'Boleto'}
				   ]
	}
	get optionsForma() {
		return [
			{ label: 'Boleto', value: 'Boleto' },
			{ label: 'Carteira', value: 'Carteira' }
		];
	}

	get optionsCondicao() {
		return [
			{ label: '30/60/90 Dias', value: '306090' },
			{ label: '30 Dias', value: '30' },
		];
	}

	handleSelectRecord(event) {
		const { record } = event.detail;
		console.log(record.Id);
	 }
	@wire(MessageContext)
    messageContext;

    handlePublishCloseTab() {
        publish(this.messageContext, closeConsoleTab);
    }

}