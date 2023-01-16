import { LightningElement, api, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBudgetData from '@salesforce/apex/OrderScreenController.getBudgetData';
import getFilteredPaymentConditionData from '@salesforce/apex/OrderScreenController.getFilteredPaymentConditionData';
import getContactData from '@salesforce/apex/OrderScreenController.getContactData';
import getContactRelationData from '@salesforce/apex/OrderScreenController.getContactRelationData';
import getToastInfoData from '@salesforce/apex/OrderScreenController.getToastInfoData';
import setInputExpiredReason from '@salesforce/apex/OrderScreenController.setInputExpiredReason';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import getSelectedAccountInfo from '@salesforce/apex/OrderScreenController.getSelectedAccountInfo';
import getB01Pricebook from '@salesforce/apex/OrderScreenController.getB01Pricebook';
// import ShowPicklistValue from '../showPicklistValue/showPicklistValue';
import mensagemInativo from '@salesforce/label/c.ClienteInativo';
import getTpCondPag from '@salesforce/apex/OrderScreenController.getTpCondPag';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getConditionExternalId from '@salesforce/apex/OrderScreenController.getConditionExternalId';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import RELATED_CONTACT_OBJECT from '@salesforce/schema/AccountContactRelation';
import RELATED_CONTACT_ACCOUNT_ID from '@salesforce/schema/AccountContactRelation.AccountId';
import RELATED_CONTACT_NAME from '@salesforce/schema/AccountContactRelation.ContactName__c';
import RELATED_CONTACT_ID from '@salesforce/schema/AccountContactRelation.ContactId';
/*
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import CONTACT_ACCOUNT_ID from '@salesforce/schema/Contact.AccountId';
import CONTACT_NAME from '@salesforce/schema/Contact.Name';
*/

export default class CreateBudget extends NavigationMixin(LightningElement)  {
    // from Aura component
    @api recordId;
    @api isEdit;
    @api isBudget;
    @api accountList;
    @api hasPermissionERB;
    @api alreadySaved;
    @api savingStrData;
    @api allRecAnswered;
    @api newRecordId;

    @api isReturn;
    @api orderListReturned;
    @api numOrcamentoOrderProduct;          
    @api valorTotalOrderProduct;            
    @api scoreOrderProduct;                 
    @api clienteEmissorIdOrderProduct;      
    @api clienteEmissorOrderProduct;        
    @api clienteEmissorCGCOrderProduct;     
    @api tabelaPrecoOrderProduct;           
    @api tabelaPrecoNomeOrderProduct ;      
    @api canalEntradaOrderProduct;          
    @api condicaoPagamentoOrderProduct;     
    @api condicaoPagamentoNomeOrderProduct ;
    @api formaPagamentoOrderProduct;        
    @api contatoOrcamentoOrderProduct;      
    @api prazoValidadeOrderProduct;         
    @api dtValidadeOrderProduct;            
    @api observacaoClienteOrderProduct;     
    @api observacaoOrderProduct;            
    @api isCoordenadorOrderProduct;         
    @api dtParcelasOrderProduct;            
    @api fretesPorCdOrderProduct;           
    @api pedidoComplementarOrderProduct;
    @api Idportalcotacoes;
    // **BEGIN Class variables**
    // is Edit only
    @api ObservacoesCliente;
    @api Observacoes;
    @api Margem;
    @api NumOrcamento;
    @api ValorTotal;
    // is Edit and Create info 
    @api Cliente;
    @api AccountId;
    @api PbId;
    @api ContactId;
    @api TipoCliente;
    @api MapIdToCGC;
    @api ClienteCGC;
    @api DateToday;
    @api MapAllFilteredAccounts;
    @api MapCondIdToCondName;
    // **END Class variables**

    // toast info variables
    @api toastInfoErrorRequired;
    @api toastInfoOrdIntegrated;
    @api toastInfoErrorBlockedAcc;
    @api toastInfoErrorDocMissing;
    @api toastInfoWarningDeposito;
    @api toastInfoWarningBoleto;
    @api toastInfoFinancialBlock;

    // variable for HTML
    @track accountWidth = this.isEdit ? "width: 308px" : "width: 270px";
    @track cliente;
    @track accountId;
    @track clienteCGC;
    @track clienteTipo;
    @track pricebookId;
    @track mapCondIdToCondName;
    @track margem;
    @api filteredMapAccount;
    @track disabledFormaPag;

    @track accountObject;
    @track tabelaPrecoObject;
    @track condicaoPagamentoObject;
    @track salesChannelB01 = [
        'ACSC - Associação Congregação de Santa Catarina',
        'Portal Apoio',
        'Apoio',
        'Ariba/Amil',
        'Bionexo',
        'Bionexo l Manager',
        'GTPLAN',
        'GT Plan',
        'Portal GTPLAN',
        'Humma',
        'Max Cotações',
        'NEOGRID',
        'Sintese',
        'Smarkets Marketplace',
        'Smart Compras',
        'Movi Tech',
        'TerNet',
        'Tivox',
        'Nimbi',
        'Medical VM',
        'VS Supply',
        'Plani Max',
        'INPART',
        'Portal Sintese',
        'Portal SINTESE',
        'Portal FAEPA',
        'PORTAL FAEPA',
        'Portal HR',
        'Portal Multicentrais',
        'PORTAL MULTICENTRAIS',
        'MultiCentrais',
        'Multicentrais',
        'Portal MV Sistema',
        'PORTAL MV SISTEMA',
        'Portal Sao Martinho',
        'PORTAL SAO MARTINHO',
        'Portal São Martinho',
        'Portal SGHCOT',
        'PORTAL SGHCOT',
        'Portal Sinconecta',
        'PORTAL SINCONECTA',
        'Portal Unifenas',
        'PORTAL UNIFENAS',
        'Portal Unimed Limeira',
        'PORTAL UNIMED LIMEIRA',
        'Portal Wareline',
        'PORTAL WARELINE',
        'Pro Saude',
        'Unifor',
        'Tasy',
        'Paradigma',
        'MVM RS'
    ];

    // variable for HTML
    @track numOrcamento;
    @track valorTotalScreen;
    @track valorTotal;
    @track score;
    @track clienteEmissorId;
    @track clienteEmissor;
    @track clienteEmissorCGC;
    @track clienteEmissorCNPJ;
    @track tabelaPreco;
    @track tabelaPrecoNome;
    @track originalTabelaPreco;
    @track originalTabelaPrecoNome;
    @track canalEntrada;
    @track oldcanalEntrada;
    @track canalEntradaErro = false;
	@track obsNotaFiscalErro = false;
    @track condicaoPagamento;
    @track condicaoPagamentoNome;
    @track currentPaymentCondition;
    @track formaPagamento;
    @track GeraBoleto;
    @track prazoValidade;
    @track dtValidadePadrao; // data padrão para criação de Orçamento
    @track dtValidade;
    @track observacaoCliente;
    @track stageName;
    @track disabledNext = false;
    @track observacao;
    @track contemDocAlvaraCrt;
    @track documentosValidos;
    @track clienteBloqueado;
    @track isCoordenador;
    @track ordItemList;
    @track dtParcelas;
    @track fretesPorCd;
    @track IdportalcotacoesAtivo = false;

    /*
    @track contactAccountFieldApi = CONTACT_ACCOUNT_ID;
    @track contactObjectApi = CONTACT_OBJECT;
    @track contactSearchFieldsApi = [CONTACT_NAME];
    */
    @track relatedContactAccountFieldApi = RELATED_CONTACT_ACCOUNT_ID;
    @track relatedContactObjectApi = RELATED_CONTACT_OBJECT;
    @track relatedContactSearchFieldsApi = [RELATED_CONTACT_NAME];
    @track relatedContactListItemOptions = {title: 'ContactName__c'};
    @track relatedContactMoreFields = [RELATED_CONTACT_ID];
    @track contatoOrcamento;
    @track accountContactRelationId;
    @track showCreateRecordForm = false;
    @track device;
    @api filtroPDF;

    @track contactObjectInfo;
    @wire(getObjectInfo, { objectApiName: RELATED_CONTACT_OBJECT }) // CONTACT_OBJECT
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

    handleChangeFormaPag(event) {
        this.formaPagamento = event.detail.value;
    }

    connectedCallback() {
        this.device = FORM_FACTOR == 'Large';
        console.log(this.device);
        getToastInfoData()
            .then(result => {
                console.log('getToastInfoData: entrou certo!');
                this.toastInfoErrorRequired      = result.ToastInfoErrorRequired;
                this.toastInfoOrdIntegrated      = result.ToastInfoOrdIntegrated;
                this.toastInfoErrorBlockedAcc    = result.ToastInfoErrorBlockedAcc;
                this.toastInfoErrorDocMissing    = result.ToastInfoErrorDocMissing;
                this.toastInfoErrorDocExpired    = result.ToastInfoErrorDocExpired;
                this.toastInfoWarningDeposito    = result.ToastInfoWarningDeposito;
                this.toastInfoWarningBoleto      = result.ToastInfoWarningBoleto;
                this.toastInfoFinancialBlock     = result.ToastInfoFinancialBlock;
                this.connectedCallbackRebase();
            }).catch(error => {
                console.log('getToastInfoData: entrou no erro!');
                console.log(error);
            });
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {console.log('Files loaded.');}).catch(error => {console.log('error: ' + JSON.stringify(error));});
    }
    connectedCallbackRebase() {
        console.log('CREATE BUDGET: Entrou no connectedCallback');
        console.log(this.recordId);
        console.log(this.isEdit);
        console.log(this.filtroPDF);

        var data = new Date();
        var formattedDate = this.getPatternDate(data);

        console.log('Data padrão formatada: ' + formattedDate);

        this.dtValidadePadrao = formattedDate;
        this.dtValidade = formattedDate;
        
        getFilteredPaymentConditionData() 
            .then(result => {
                console.log('getFilteredPaymentConditionData: entrou certo!');
                this.mapCondIdToCondName = result.MapCondIdToCondName;
            }).catch(error => {
                console.log('getFilteredPaymentConditionData: entrou no erro!');
                console.log(error);
            });
        
        console.log('getBudgetData: '+this.recordId);
        if(!this.isReturn || this.isReturn == null || this.isReturn == undefined ){
            if (this.recordId != undefined) { 
                console.log('getBudgetData: '+this.recordId);
                getBudgetData({ recordId : this.recordId, condicaoPag: null })
                    .then(result => {
                        console.log('getBudgetData: entrou certo!');
                        console.log(result);
                        if (this.isEdit) {
                            this.alreadySaved = true;
                            if (!this.device) {
                                if (result.StageName != 'Em digitação' && result.StageName != 'Aprovado' && result.StageName != 'Reprovado') {
                                    this.disabledNext = true;
                                    swal('Aviso!', 'Não é possível alterar este registro devido seu Status', 'warning');
                                    return;
                                }
                            }
                            console.log("Preenchendo dados da tela de edição");
                            console.log("result.filtroPDF "+ result.filtroPDF);
                            this.numOrcamento          = result.NumOrcamento;
                            this.valorTotalScreen      = (Number(result.ValorTotal)).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
                            this.valorTotal            = (Number(result.ValorTotal));
                            this.score                 = result.Score;
                            this.clienteEmissor        = result.ClienteEmissor;
                            this.clienteEmissorId      = result.ClienteEmissorId;
                            this.clienteEmissorCGC     = result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
                            this.clienteEmissorCNPJ    = result.ClienteEmissorCGC.length == 11 ? false : true;
                            this.tabelaPreco           = result.TabelaPreco;
                            this.tabelaPrecoNome       = result.TabelaPrecoNome;
                            if (this.tabelaPrecoNome == 'B01/BIONEXO') {
                                this.IdportalcotacoesAtivo = false;
                            }else{
                                this.IdportalcotacoesAtivo = true;
                            }
                            this.originalTabelaPreco   = result.TabelaPreco;
                            this.originalTabelaPrecoNome = result.TabelaPrecoNome;
                            this.canalEntrada          = result.CanalEntrada;
                            this.condicaoPagamento     = result.CondicaoPagamento;
                            this.condicaoPagamentoNome = result.CondicaoPagamentoNome;
                            this.currentPaymentCondition = result.CondicaoPagamento;
                            this.GeraBoleto            = result.GeraBoleto;
                            this.hasPermissionERB      = result.hasPermissionERB;
                            this.Idportalcotacoes            = result.Idportalcotacoes;
                            console.log('this.GeraBoleto: ' + this.GeraBoleto);
                            console.log('result.FormaPagamento: ' + result.FormaPagamento);
                            this.formaPagamento        = result.FormaPagamento;
                            this.allRecAnswered        = result.allRecAnswered;
                            this.filtroPDF             = result.filtroPDF;

                            // this.formaPagamento        = result.CondicaoPagamentoNome == 'RA' ? 'Deposito' : result.CondicaoPagamentoNome != '' ? 'Boleto' : '';
                            if(this.condicaoPagamentoNome != undefined){
                                if(this.condicaoPagamentoNome.includes('RA')){
                                    this.disabledFormaPag = true;
                                    this.formaPagamento   = 'Depósito';
                                }else{
                                    this.disabledFormaPag = false;
                                }
                            }else{
                                this.disabledFormaPag  = false;
                            //     this.formaPagamento    = result.FormaPagamento;
                            }
                            if((this.disabledFormaPag == null || this.disabledFormaPag == undefined || !this.disabledFormaPag) && 
                                (this.parcelamentoManual ==  null || this.parcelamentoManual == undefined || !this.parcelamentoManual) &&
                                this.condicaoPagamento != null && this.condicaoPagamento != undefined ){

                                getConditionExternalId({ conditionId: this.condicaoPagamento })
                                    .then(result => {
                                        console.log(result);
                        
                                        if (result == '050') {
                                            this.disabledFormaPag = true;
                                            this.formaPagamento = 'Eletrônico';
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
                        
                                    }).catch(error => {
                                        console.log('getConditionExternalId: entrou no erro!');
                                        console.log(error);
                                    });
                            }

                            this.contatoOrcamento      = result.ContatoOrcamento;
                            this.accountContactRelationId = result.AccountContactRelationId;
                            this.prazoValidade         = result.PrazoValidade;
                            this.dtValidade            = result.DataValidade;
                            this.observacaoCliente     = result.ObservacaoCliente; // puxar de Account
                            this.observacao            = result.Observacao;
                            this.stageName             = result.StageName;
                            this.contemDocAlvaraCrt    = result.ContemDocAlvaraCrt;
                            this.documentosValidos     = result.DocumentosValidos;
                            this.clienteBloqueado      = result.ClienteBloqueado;
                            this.isCoordenador         = result.IsCoordenador;
                            this.dtParcelas            = result.DtParcelas;
                            this.fretesPorCd           = result.FretesPorCd;
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
                            console.log('É coordenador? ' + this.isCoordenador);
                            console.log('contatoOrcamento:', this.contatoOrcamento);
                            console.log('accountContactRelationId:', this.accountContactRelationId);

                            if (!this.clienteBloqueado) {
                                this.showToast(this.toastInfoErrorBlockedAcc);
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
                        } else {
                            console.log("Preenchendo dados da tela de inserção");
                            this.clienteEmissor        = result.ClienteEmissor;
                            this.clienteEmissorId      = result.ClienteEmissorId;
                            this.clienteEmissorCGC     = result.ClienteEmissorCGC.length == 11 ? result.ClienteEmissorCGC.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4") : result.ClienteEmissorCGC.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, "$1.$2.$3/$4-$5");
                            this.clienteEmissorCNPJ    = result.ClienteEmissorCGC.length == 11 ? false : true;
                            this.tabelaPreco           = result.TabelaPreco;
                            this.tabelaPrecoNome       = result.TabelaPrecoNome;
                            this.originalTabelaPreco   = result.TabelaPreco;
                            this.originalTabelaPrecoNome = result.TabelaPrecoNome;
                            this.condicaoPagamento     = result.CondicaoPagamento;
                            this.condicaoPagamentoNome = result.CondicaoPagamentoNome;
                            this.GeraBoleto            = result.GeraBoleto;
                            this.Idportalcotacoes            = result.Idportalcotacoes;
                            this.hasPermissionERB      = result.hasPermissionERB;
                            // this.formaPagamento        = result.CondicaoPagamentoNome == 'RA' ? 'Deposito' : result.CondicaoPagamentoNome != '' ? 'Boleto' : '';
                            if(this.condicaoPagamentoNome != undefined){
                                if(this.condicaoPagamentoNome.includes('RA')){
                                    this.disabledFormaPag = true;
                                    this.formaPagamento   = 'Depósito';
                                }else{
                                    this.disabledFormaPag = false;
                                    this.formaPagamento    = (result.GeraBoleto == 'Boleto' || result.GeraBoleto == 'Carteira') ? null : result.GeraBoleto;
                                }
                            }else{
                                this.disabledFormaPag  = false;
                                this.formaPagamento    = (result.GeraBoleto == 'Boleto' || result.GeraBoleto == 'Carteira') ? null : result.GeraBoleto;
                            }
                            if((this.disabledFormaPag == null || this.disabledFormaPag == undefined || !this.disabledFormaPag) && 
                                (this.parcelamentoManual ==  null || this.parcelamentoManual == undefined || !this.parcelamentoManual) &&
                                this.condicaoPagamento != null && this.condicaoPagamento != undefined ){
                                if (this.condicaoPagamentoNome == '050/VINDI') {
                                    this.disabledFormaPag = true;
                                    this.formaPagamento = 'Eletrônico';
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

                            this.contatoOrcamento      = result.ContatoOrcamento;
                            this.accountContactRelationId = result.AccountContactRelationId;
                            this.observacaoCliente     = result.ObservacaoCliente;
                            this.prazoValidade         = 3; // valor padrão
                            this.contemDocAlvaraCrt    = result.ContemDocAlvaraCrt;
                            this.documentosValidos     = result.DocumentosValidos;
                            this.clienteBloqueado      = result.ClienteBloqueado;
                            this.isCoordenador         = result.IsCoordenador;
                            this.dtParcelas            = result.DtParcelas;
                            this.fretesPorCd           = result.FretesPorCd;
                            console.log('É coordenador? ' + this.isCoordenador);
                            console.log('contatoOrcamento:', this.contatoOrcamento);
                            console.log('accountContactRelationId:', this.accountContactRelationId);

                            if (!this.clienteBloqueado) {
                                this.showToast(this.toastInfoErrorBlockedAcc);
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
                        }
                        this.inputLookupFilter();
                    }).catch(error => {
                        console.log('getBudgetData: entrou no erro!');
                        console.log(error);
                    });
            }
        }else{
            this.numOrcamento = this.numOrcamentoOrderProduct;          
            this.valorTotal = this.valorTotalOrderProduct;            
            this.score = this.scoreOrderProduct;                 
            this.clienteEmissorId = this.clienteEmissorIdOrderProduct;      
            this.clienteEmissor = this.clienteEmissorOrderProduct;        
            this.clienteEmissorCGC = this.clienteEmissorCGCOrderProduct;     
            this.tabelaPreco = this.tabelaPrecoOrderProduct;           
            this.tabelaPrecoNome = this.tabelaPrecoNomeOrderProduct ;      
            if (this.tabelaPrecoNome == 'B01/BIONEXO') {
                this.IdportalcotacoesAtivo = false;
            }else{
                this.IdportalcotacoesAtivo = true;
            }
            this.originalTabelaPreco   = this.tabelaPrecoOrderProduct;
            this.originalTabelaPrecoNome = this.tabelaPrecoNomeOrderProduct;
            this.canalEntrada = this.canalEntradaOrderProduct;          
            this.condicaoPagamento = this.condicaoPagamentoOrderProduct;     
            this.condicaoPagamentoNome = this.condicaoPagamentoNomeOrderProduct ;
            console.log('this.formaPagamento ==> ' + JSON.stringify(this.formaPagamento));
            this.formaPagamento = this.formaPagamentoOrderProduct; 
            if((this.disabledFormaPag == null || this.disabledFormaPag == undefined || !this.disabledFormaPag) && 
                (this.parcelamentoManual ==  null || this.parcelamentoManual == undefined || !this.parcelamentoManual) &&
                this.condicaoPagamento != null && this.condicaoPagamento != undefined ){
                if (this.condicaoPagamentoNome == '050/VINDI') {
                    this.disabledFormaPag = true;
                    this.formaPagamento = 'Eletrônico';
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

            this.contatoOrcamento = this.contatoOrcamentoOrderProduct;      
            this.prazoValidade = this.prazoValidadeOrderProduct;         
            this.dtValidade = this.dtValidadeOrderProduct;            
            this.observacaoCliente = this.observacaoClienteOrderProduct;     
            this.observacao = this.observacaoOrderProduct;            
            this.isCoordenador = this.isCoordenadorOrderProduct;         
            this.dtParcelas = this.dtParcelasOrderProduct;            
            this.fretesPorCd = this.fretesPorCdOrderProduct;           
            this.pedidoComplementar = this.pedidoComplementarOrderProduct;
            if(this.orderListReturned !=null ){
                this.ordItemList = JSON.parse(this.orderListReturned);
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
    }
    handleIdPortal(event) {
        this.Idportalcotacoes = event.target.value;
    }

    inputReason(reason){
        setInputExpiredReason({recordId : this.recordId, reason : reason.substring(0,255)})
        .then(result => {
            console.log(result);
        })
        .catch(error => {
            console.log("setInputExpiredReason: entrou no erro!");
            console.log(error);
        });

    }

    inputLookupFilter(){
        this.accountObject = this.clienteEmissorId ? {name: this.clienteEmissor, id: this.clienteEmissorId} : null;
        this.tabelaPrecoObject = this.tabelaPreco ? {name: this.tabelaPrecoNome, id: this.tabelaPreco} : null;
        this.condicaoPagamentoObject = this.condicaoPagamento ? {name: this.condicaoPagamentoNome, id: this.condicaoPagamento} : null;
    }

    selectedRecordId; //store the record id of the selected 
    handleValueSelected(event) {
        console.log(event);
        console.log(event.detail);
        this.selectedRecordId = event.detail;
    }

    handleSelectAccountObj(event) {
        const { record } = event.detail;

        this.clienteEmissorId = record ? record.id : null;
        this.clienteEmissorNome = record ? record.name : null;

        if (record != null) {
            if (this.clienteEmissorNome.length > 32) {
                this.accountWidth = "width: 270px";
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
    
    handleSelectRecordPrice(event) {
        const { record } = event.detail;    

        this.tabelaPreco = record ? record.id: null;
        this.tabelaPrecoNome = record ? record.name: null;
        if(this.tabelaPrecoNome == 'B01/BIONEXO'){
            this.IdportalcotacoesAtivo = false;
        }else{
            this.IdportalcotacoesAtivo = true;
        }

    }
    
    checkRequiredFields(){
        var mapObjLabel = [];
        if (this.clienteEmissorCNPJ == true) {
            mapObjLabel = {
                'clienteEmissorCGC' : 'Cliente',
                'tabelaPrecoNome' : 'Tabela de Preço',
                'canalEntrada' : 'Canal de Entrada',
                'condicaoPagamentoNome' : 'Condição de Pagamento',
                'contatoOrcamento' : 'Contato',
                'formaPagamento' : 'Forma de pagamento'
            }
        }
        else {
            mapObjLabel = {
                'clienteEmissorCGC' : 'Cliente',
                'tabelaPrecoNome' : 'Tabela de Preço',
                'canalEntrada' : 'Canal de Entrada',
                'condicaoPagamentoNome' : 'Condição de Pagamento',
                'formaPagamento' : 'Forma de pagamento'
            }
        }
        
        var emptyFields = [];
        for(var i=0; i<Object.keys(mapObjLabel).length; i++){
            var item = Object.keys(mapObjLabel)[i]
            if(this[item] == undefined || this[item] == null){
                emptyFields.push(mapObjLabel[item]);
            }
        }
        return emptyFields;
    }

    @track cnpj= '';
	handleNavigate() {
        console.log(this.recordId);
        console.log(this.clienteEmissor);
        console.log(this.clienteEmissorCGC);
        console.log(this.condicaoPagamentoNome);
        console.log(this.tabelaPrecoNome);

        console.log('isBudget: ' + this.isBudget);
        console.log('isEdit: ' + this.isEdit);

        var requiredFields = this.checkRequiredFields(); 

        if(this.tabelaPrecoNome == 'B01/BIONEXO' && (this.Idportalcotacoes == undefined || this.Idportalcotacoes == '')){
                swal("Aviso!", 'Preencher o Id do portal de cotação');
                return;
        }

        if(requiredFields.length > 0){
            var stringField = this.toastInfoErrorRequired.Message.replace('{fields}', requiredFields.join(', '));
            swal("Aviso!", stringField);
            // this.showToastMsg(stringField);
        } else if (this.canalEntradaErro && (this.isEdit || this.isReturn)) {
            swal("Aviso!", 'Não é possível trocar o canal de vendas para esse valor.');
        } else if (this.obsNotaFiscalErro == true) {
            swal("Aviso!", 'Não é permitido caracteres especiais no campo Observação.', 'warning');
        } else {
            
            console.log("Calling another component");
            console.log("filtroPDF createbudget "+ this.filtroPDF);
            var compDefinition = {
                componentDef: "c:orderProduct",
                title: "Adicionar produtos",
                attributes: {
                    isEdit                : this.isEdit,
                    isBudget              : this.isBudget,
                    numOrcamento          : this.numOrcamento,
                    valorTotal            : this.valorTotal,
                    score                 : this.score,
                    clienteEmissorId      : this.clienteEmissorId,
                    clienteEmissor        : this.clienteEmissor,
                    clienteEmissorCGC     : this.clienteEmissorCGC,
                    tabelaPreco           : this.tabelaPreco,
                    tabelaPrecoNome       : this.tabelaPrecoNome,
                    canalEntrada          : this.canalEntrada,
                    condicaoPagamento     : this.condicaoPagamento,
                    condicaoPagamentoNome : this.condicaoPagamentoNome,
                    formaPagamento        : this.formaPagamento,
                    contatoOrcamento      : this.contatoOrcamento,
                    prazoValidade         : this.prazoValidade,
                    dtValidadePadrao      : this.dtValidadePadrao,
                    dtValidade            : this.dtValidade,
                    observacaoCliente     : this.observacaoCliente,
                    observacao            : this.observacao,
                    recordId              : this.recordId,
                    hasPermissionERB      : this.hasPermissionERB,
                    isCoordenador         : this.isCoordenador,
                    dtParcelas            : this.dtParcelas,
                    fretesPorCd           : this.fretesPorCd,
                    Idportalcotacoes      : this.Idportalcotacoes,
                    recomendacaoRespondida: this.allRecAnswered,
                    alreadySaved          : this.alreadySaved,
                    newRecordId           : this.newRecordId,
                    savingStrData         : this.savingStrData,
                    orderListReturned     : JSON.stringify(this.ordItemList),
                    filtroPDF             : this.filtroPDF
                }
            };
            
            try{
                const filterChangeEvent = new CustomEvent('displaymyvaluenew', {
                    detail: { "data" : JSON.stringify(compDefinition) }
                });
                // Fire the custom event
                this.dispatchEvent(filterChangeEvent);
            }catch(e){
                debugger;
                console.log(e);

            }
            /*
            // Base64 encode the compDefinition JS object
            var encodedCompDef = btoa(JSON.stringify(compDefinition));
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                title: 'Adicionar produtos',
                attributes: {
                    url: '/one/one.app#' + encodedCompDef,
                    title: 'Adicionar produtos'
                }
            });*/
        }
    }

    handleCheckSpecialCharacter(event) {
		const fieldValue = event.target.value;
		const fieldName = event.target.name;
		const isValid = !fieldValue.match(/[`´!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~àèìòùáéíóúãõñâêîôûäëïöüçÀÈÌÒÙÁÉÍÓÚÃÕÑÂÊÎÔÛÄËÏÖÜÇ]/g);

		if (isValid) {
			if (fieldName == 'ObsNotaFiscal') {
				this.obsNotaFiscalErro = false;	
			} 
		} else {
			if (fieldName == 'ObsNotaFiscal') {
				this.obsNotaFiscalErro = true;	
			} 
		}		
	}

    handleSelectSalesChannel(event) {
        var record = {};
        record     = event?.detail || event?.detail?.value;
        if (this.canalEntrada != null) {
            this.oldcanalEntrada = this.canalEntrada;
        }
        if (this.salesChannelB01.includes(record.record)) {
            this.IdportalcotacoesAtivo = false;
        }else{
            this.IdportalcotacoesAtivo = true;
        }

        if ( (this.salesChannelB01.includes(record.record) && this.salesChannelB01.includes(this.oldcanalEntrada)) ||
             (!this.salesChannelB01.includes(record.record) && !this.salesChannelB01.includes(this.oldcanalEntrada)) ||
             (!this.isEdit && !this.isReturn) ) {
            this.canalEntradaErro = false;
            this.canalEntrada = record.record;
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
            this.canalEntradaErro = true;
            // swal("Aviso!", 'Alteração indisponível pois o novo valor de canal de entrada irá mudar a tabela de preço.');
            // this.canalEntrada = this.oldcanalEntrada;
        }
    }

	// handleSelectAccountObj(event) {
	// 	const { record } = event.detail;
	// 	console.log(record.Id);
    //     this.cnpj = record.Description;
	// }
	handleSelectRecord(event) {
		const { record } = event.detail;
		console.log(record.Id);
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
        console.log('contatoOrcamento:', this.contatoOrcamento);
    }

    handleCreateNewContact() {
        this.showCreateRecordForm = !this.showCreateRecordForm;
        this.scrollToTop();
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

    checkContact() {
        if(!this.contatoOrcamento) return;

        getContactData({ contatoOrcamento : this.contatoOrcamento })
            .then(result => {
                if(result != this.recordId && this.contatoOrcamento != null && this.recordId !=null){
                    this.showToastMsg('Selecione um Contato vinculado ao Cliente escolhido');
                    this.contatoOrcamento = null;
                }
            }).catch(error => {
                console.log('getContactData: entrou no erro!');
                console.log(error);
            });

    }
    onChangeAccount(event) {
        console.log("onChangeAccount: entrou!!");
        console.log('detail value: ' + event.detail.value);
        console.log(event.detail.value);
        console.log(event.detail.value.length);
        console.log(this.clienteEmissorId);

        if (event.detail.value.length != 0) {
            this.clienteEmissorId = this.normalizeData(event.detail.value, true);
            this.recordId = this.clienteEmissorId;
            this.checkContact();
        } else {                
            this.clearValues();
        }
        this.connectedCallbackRebase();
    }
    
    normalizeData(eventData, list){
        return list ? JSON.parse(JSON.stringify(eventData))[0] : JSON.parse(JSON.stringify(eventData));
    }

    clearValues(){
        this.clienteEmissor = undefined;
        this.clienteEmissorId = undefined;
        this.clienteEmissorCGC = undefined;
        this.tabelaPreco = undefined;
        this.tabelaPrecoNome = undefined;
        this.condicaoPagamento = undefined;
        this.condicaoPagamentoNome = undefined;
        this.formaPagamento = undefined;
        this.contatoOrcamento = null;
        this.accountContactRelationId = null;
        this.observacaoCliente = undefined;
        this.stageName = undefined;
        this.recordId = undefined;
        // this.template.querySelector('c-custom-lookup-filter').handleClearSelected();
        for(var i=0; i<this.template.querySelectorAll('c-custom-lookup-filter').length; i++){
            this.template.querySelectorAll('c-custom-lookup-filter')[i].handleClearSelected();
        }
        for(var i=0; i<this.template.querySelectorAll('c-custom-lookup').length; i++){
            this.template.querySelectorAll('c-custom-lookup')[i].handleClearSelected();
        }
        for(var i=0; i<this.template.querySelectorAll('c-lookup').length; i++){
            this.template.querySelectorAll('c-lookup')[i].clearAll();
        }
        console.log('clearall');
    }

    onChangePricebook(event) {
        this.pbId = event.detail.value;
    }

    /*onChangeTabelaPreco(event) {
        console.log(event.detail);
        this.tabelaPreco = event.detail.value;
        this.tabelaPrecoNome = 'Tabela';
    }*/

    async handleSelectRecordCondicaoPagamento(event) {
        console.log(event);

        if (!this.GeraBoleto) {
            const result = await getBudgetData({
                recordId: this.recordId
            });
            this.GeraBoleto = result.GeraBoleto;
        }

        console.log('GeraBoleto ' + this.GeraBoleto);
        var condicaoPagamentoData = this.normalizeData(event.detail.record, false);
        this.condicaoPagamento = condicaoPagamentoData?.id;
        this.condicaoPagamentoNome = condicaoPagamentoData?.name;

        if(this.condicaoPagamentoNome != undefined){
            if(this.condicaoPagamentoNome.includes('RA')){
                this.disabledFormaPag = true;
                this.formaPagamento   = 'Depósito';
            }else{
                this.disabledFormaPag = false;
                this.formaPagamento   = this.GeraBoleto;
            }
        }else{
            this.disabledFormaPag  = false;
            this.formaPagamento    = this.GeraBoleto;
        }

        if((this.disabledFormaPag == null || this.disabledFormaPag == undefined || !this.disabledFormaPag) && 
           (this.parcelamentoManual ==  null || this.parcelamentoManual == undefined || !this.parcelamentoManual) &&
            this.condicaoPagamento != null && this.condicaoPagamento != undefined ){
            if (this.condicaoPagamentoNome == '050/VINDI') {
                this.disabledFormaPag = true;
                this.formaPagamento = 'Eletrônico';
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

		if (this.condicaoPagamento) {
            this.disabledNext = true;
			getBudgetData({ recordId : this.recordId, condicaoPag: this.condicaoPagamento })
				.then(result => {
                    this.disabledNext = false;
					console.log('getOrderData devido troca da condição de pagamento');
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

    onBlurObservacaoCliente(event) {
        this.observacaoCliente = event.target.value;
    }
    onBlurObservacao(event) {
        this.observacao = event.target.value;
    }

    onChangeFormaPagamento(event) {
        console.log(event.detail.value);
        this.formaPagamento = event.detail.value;
    }

    onChangeDataValidade(event) {
        console.log(event.detail.value);
        console.log(this.dtValidadePadrao);
        this.dtValidade = event.detail.value;   
        
        var splittedDate = this.dtValidade.split('-');
        var data = new Date();
        this.getDaysMinusWeekend(data.getDate(), data.getMonth(), data.getFullYear(), Number(splittedDate[2]), Number(splittedDate[1]) - 1, Number(splittedDate[0]));
    }

    getDaysMinusWeekend(startDay, startMonth, startYear, endDay, endMonth, endYear) {
        console.log('calculando prazo!');
        var sdate = new Date();
        var edate = new Date();

        sdate.setFullYear(startYear, startMonth, startDay);
        edate.setFullYear(endYear, endMonth, endDay);

        const _MS_PER_DAY = 1000 * 60 * 60 * 24;

        // Discard the time and time-zone information.
        const utc1 = Date.UTC(startYear, startMonth, startDay);
        const utc2 = Date.UTC(endYear, endMonth, endDay);

        var weekendDayCount = 0;

        console.log('sdate: ' + sdate);
        console.log('edate: ' + edate);

        while (sdate < edate) {
            sdate.setDate(sdate.getDate() + 1);
            if (sdate.getDay() === 0 || sdate.getDay() == 6) {
                ++weekendDayCount;
            }
        }

        console.log('weekend days: ' + weekendDayCount);

        var prazoValidadeComFds = Math.floor((utc2 - utc1) / _MS_PER_DAY);

        console.log('days between 2 dates: ' + prazoValidadeComFds);

        this.prazoValidade = prazoValidadeComFds - weekendDayCount;

        console.log('Prazo calculado: ' + this.prazoValidade);
    }

    onBlurPrazoValidade(event) {
        console.log(event.target.value);
        console.log(this.prazoValidade);
        var data = new Date();
        this.prazoValidade = event.target.value;
        this.getDateMinusWeekend(data.getDate(), data.getMonth(), data.getFullYear(), Number(this.prazoValidade));
        console.log("Prazo de validade: " + this.prazoValidade);
    }

    getDateMinusWeekend(startDay, startMonth, startYear, prazo) {
        console.log('calculando data pelo prazo');

        var sdate = new Date();
        var edate = new Date();

        sdate.setFullYear(startYear, startMonth, startDay);
        edate.setFullYear(startYear, startMonth, startDay);

        console.log(sdate);
        
        for (var i = 0; i < prazo; i++) {
            edate.setDate(edate.getDate() + 1);
            if (edate.getDay() == 0) {
                edate.setDate(edate.getDate() + 1);
            } else if (edate.getDay() == 6) {
                edate.setDate(edate.getDate() + 2);
            }
        }

        console.log(edate);

        var day   = edate.getDate() > 9 ? edate.getDate() : '0' + edate.getDate();
        var month = edate.getMonth() + 1 > 9 ? edate.getMonth() + 1 : '0' + (edate.getMonth() + 1);
        var year  = edate.getFullYear();

        var formattedDate = year + '-' + month + '-' + day;

        this.prazoValidade = prazo;
        this.dtValidade  = formattedDate;

        console.log('data calculada: ' + this.dtValidade);        
    }

    getPatternDate(dateValue) {
        var weekdays = new Array(7);
        weekdays[0] = "Sunday";
        weekdays[1] = "Monday";
        weekdays[2] = "Tuesday";
        weekdays[3] = "Wednesday";
        weekdays[4] = "Thursday";
        weekdays[5] = "Friday";
        weekdays[6] = "Saturday";

        if (dateValue.getDay() == 0 || dateValue.getDay() == 1 || dateValue.getDay() == 2) {
            dateValue.setDate(dateValue.getDate() + 3);
        } else if (dateValue.getDay() == 6) {
            dateValue.setDate(dateValue.getDate() + 4);
        } else if (dateValue.getDay() == 3 || dateValue.getDay() == 4 || dateValue.getDay() == 5) {
            dateValue.setDate(dateValue.getDate() + 5);
        }

        console.log(weekdays[dateValue.getDay()]);
        console.log(dateValue);

        var day = dateValue.getDate() > 9 ? dateValue.getDate() : '0' + dateValue.getDate();
        var month = dateValue.getMonth() + 1 > 9 ? dateValue.getMonth() + 1 : '0' + (dateValue.getMonth() + 1);
        var year = dateValue.getFullYear();

        this.prazoValidade = 3; // valor padrão

        return year + '-' + month + '-' + day;
    }


    handleChange(event) {
        this.value = event.detail.value;
    }

    onClickWindowBack(event) {
        var close = true;
        const closeclickedevt = new CustomEvent('closeclicked', {
            detail: { close },
        });

        // Fire the custom event
        this.dispatchEvent(closeclickedevt);
    }
    
    showToastMsg(toastInfo) {
        const evt = new ShowToastEvent({
            title: 'Erro',
            message: toastInfo,
            variant: 'Error'
        });
        this.dispatchEvent(evt);
    }

    renderedCallback() {
        // var box1 = document.getElementById('box1');
		var box1 = document.querySelector('#box1');
		if(box1){
			box1.addEventListener('touchmove', function(e) {
				e.stopPropagation();
			}, false); 
		}
 
     }
 
    scrollToTop() {
        if (!this.device) {
            const scrollOptions = {
				left: 0,
				top: 0
			}
			parent.scrollTo(scrollOptions);
        }
    }
    
    showToast(toastInfo) {
        const evt = new ShowToastEvent({
            title: toastInfo.Title,
            message: toastInfo.Message,
            variant: toastInfo.Type
        });
        this.dispatchEvent(evt);
    }
    get optionsFormaRA() {
            return [{ label: 'Depósito' , value: 'Depósito' },
                    { label: 'Cartão de Credito', value: 'Cartão de Credito'},
                    { label: 'Cartão de Debito', value: 'Cartão de Debito'},
                    { label: 'Cheque', value: 'Cheque'},
                    { label: 'Dinheiro', value: 'Dinheiro'},
                    { label: 'Eletrônico', value: 'Eletrônico'}
                   ]
    }
    get optionsForma() {
        return [
            { label: 'Boleto', value: 'Boleto' },
            { label: 'Carteira', value: 'Carteira' }
        ];
    }

    // get optionsForma() {
    //     return [
    //         { label: '', value: '' },
    //         { label: 'Boleto', value: 'Boleto' },
    //         { label: 'Depósito', value: 'Deposito' },
    //         { label: 'Carteira', value: 'Carteira' }
    //     ];
    // }

}