import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import generateBudget from '@salesforce/apex/OrderScreenController.generateBudget';
import generateOrder from '@salesforce/apex/OrderScreenController.generateOrder';
import generateComplementOrder from '@salesforce/apex/OrderScreenController.generateComplementOrder';
import editLabOrder from '@salesforce/apex/OrderScreenController.editLabOrder';
import editOrder from '@salesforce/apex/OrderScreenController.editOrder';
import editBudget from '@salesforce/apex/OrderScreenController.editBudget';
import calcProducts from '@salesforce/apex/CalcScore.calcProductsScreen';
import reverseCalcScreen from '@salesforce/apex/CalcScore.reverseCalcScreen';
import calcAllProducts from '@salesforce/apex/CalcScore.calcProducts';
import getMalha from '@salesforce/apex/OrderScreenController.getMalha';
import getAccountData from '@salesforce/apex/OrderScreenController.getAccountData';
import getComplementOrderSituation from '@salesforce/apex/OrderScreenController.getComplementOrderSituation';
import getConditionExternalId from '@salesforce/apex/OrderScreenController.getConditionExternalId';
import getPricebookExternalId from '@salesforce/apex/OrderScreenController.getPricebookExternalId';
import FORM_FACTOR from '@salesforce/client/formFactor';

import ClienteInativoInsert from '@salesforce/label/c.ClienteInativoInsert';
import ClienteInativoInsertPositivo from '@salesforce/label/c.ClienteInativoInsertPositivo';
import ClienteRecebedorInativoInsert from '@salesforce/label/c.ClienteRecebedorInativoInsert';

import { MessageContext, publish } from "lightning/messageService";
import closeConsoleTab from "@salesforce/messageChannel/CloseConsoleTab__c";
import { CloseActionScreenEvent } from 'lightning/actions';
export default class OrderProductCheckout extends NavigationMixin(LightningElement) {
    // variáveis para definição de edição ou inserção de pedido ou orçamento
    @api isBudget;
    @api isEdit;
    @api alreadySaved;
    @api newRecordId; // recId when creating ord or budget automaticaly

    @api numOrcamento;
    @api valorTotal;
    @api score;
    @api clienteEmissorId;
    @api clienteEmissor;
    @api clienteEmissorCGC;
    @api tabelaPreco;
    @api tabelaPrecoNome;
    @api canalEntrada;
    @api condicaoPagamento;
    @api condicaoPagamentoNome;
    @api formaPagamento;
    @api contatoOrcamento;
    @api prazoValidade;
    @api dtValidade;
    @api observacaoCliente;
    @api observacao;
    @api recordId;
    @api isCoordenador;
    @api orderList;
    @api verMargem;
    @api dtParcelas;
    @api fretesPorCd;
    @api pedidoComplementar;
    @api Idportalcotacoes;
    @api createOrderDt;

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
    @api observacaoNF;
    @api observacaoPedido;
    @api cnpjCd;
    @track isSaving = false;
    @track savingObjData = {};
    @api savingStrData;
    @api hasPermissionERB;
    @api goToCheckout;
    @api allRecAnswered;

    @api dtQuantityAllowed = 4;
    @api dtList = [];
    @api receivedDtList = [];
    @api freteList = [];
    @api receivedFreightList = [];

    @track isInstallmentDisabled = true;

    @track headerInfoData = {};

    @track saveInterval;
    @track automaticSave = false;
    @track totalItens = 0;
    @track tabelaPrecoExternal;
    @track totalOrderValue = 0;
    @track prodToCds = [];
    @track cdListFilter = [];

    @track objectProdCdList = [];
    @track productPerCds = [];

    @track activeSection = '';

    @track isLoading = false;
    @track isLoadingScore = true;
    @track disableLabOrderSave = false;
    @track isSaveDisabled = false;
    @track isAddItemDisabled = false;
    @track isSendToApprovalDisabled = false;
    @track isGenerateOrderByOpp = false;
    @track calcScoreObj = [];
    @track calcAllScoreObj;
    @track margemAtualGeral;
    @track margemAtualAlvo;
    @track scoreFinalGeral;
    @track isCallingMalha = false;
    @track parcelamentoManual = false;
    @track freteNecessario = false;
    @track generateBudgetOrOrder = false;
    @track cdFreightList = [];

    isEditEnabled = false;
    showCDDescriptionModal = false;
    selected;
    totalOrder;
    current = 0;
    showModalDeleteAllSelected = false;
    showModalDelete= false;
    selectedProductToRemove;

    @track invalidProducts = [];
    @track productPerCdsFiltered = [];
    @track cdList = [];
    @track cdListToRemove = [];
    @track cdListClone = [];
    @track cdListCloneSelected = [];
    @track cdListComplement = [];
    @track allProdList = [];
    @track prodList = [];
    @track prodListFiltered = [];
    @track filterList = [];
    @track hasComplementOrder = false;
    @track keepComplementOrder = false;
    @track alphabeticSortType = false;
    @track device = false;
    @track hasOnlyCampaign = true;
    @track hasOnlyContract = true;
    @track hasOnlyLab = true;
    @track prodList = [];
    openUnitMeasurement = false;
    @track prodListMeas = [];
    @api filtroPDF;    

    get validityOptions(){
        return [
            { label: "Shelf Life", value: "Shelf Life" },
            { label: "Maior que 3 Meses", value: "Maior que 3 Meses" },
            { label: "Maior que 6 Meses", value: "Maior que 6 Meses" },
            { label: "Maior que 9 Meses",  value: "Maior que 9 Meses" },
            { label: "Maior que 12 Meses", value: "Maior que 12 Meses" }
          ];
    }

    connectedCallback() {
        this.device = FORM_FACTOR == 'Large';
        console.log(this.device);
        this.disableButtons();
        this.calculateTotalOrder();
        console.log('ENTROU NO CARRINHO!');
        console.log(this.numOrcamento);
        console.log(this.valorTotal);
        console.log(this.score);
        console.log(this.clienteEmissorId);
        console.log(this.clienteEmissor);
        console.log(this.clienteEmissorCGC);
        console.log(this.tabelaPreco);
        console.log(this.tabelaPrecoNome);
        console.log(this.canalEntrada);
        console.log(this.condicaoPagamento);
        console.log(this.condicaoPagamentoNome);
        console.log(this.formaPagamento);
        console.log(this.contatoOrcamento);
        console.log(this.prazoValidade);
        console.log(this.dtValidade);
        console.log(this.observacaoCliente);
        console.log(this.observacao);
        console.log(this.recordId);
        console.log(this.isCoordenador);
		console.log('this.createOrderDt => '+this.createOrderDt);
        console.log(this.orderList);
        console.log(this.pedidoComplementar);
        console.log('verMargem ' + this.verMargem);        
        console.log('dtParcelas: ' + this.dtParcelas);
        console.log('@api filtroPDF: ' + this.filtroPDF);

        if (this.savingStrData) {
            this.savingObjData = JSON.parse(this.savingStrData);
        }
        
        getConditionExternalId({ conditionId: this.condicaoPagamento })
            .then(result => {
                console.log(result);

                if (result == '048') {
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
                    }
                } else {
                    this.receivedDtList = [];
                }

            }).catch(error => {
                console.log('getConditionExternalId: entrou no erro!');
                console.log(error);
            });
        
        if (this.fretesPorCd != undefined && this.fretesPorCd != "") { // !this.freteNecessario && 
            let splitFreight = this.fretesPorCd.split(',');
            splitFreight.forEach(freightCd => {
                //let splittedFreightCd = freightCd.split(':');
                this.freteList.push(freightCd.trim());
            });
            console.log('freteList:');
            console.log(this.freteList);
            this.receivedFreightList = this.freteList;
            this.cdFreightList = this.freteList;
        } else {
            this.receivedFreightList = [];
        }
        this.freteNecessario = this.isBudget ? false : true;

        console.log('this.orderList checkout ==> ' + JSON.stringify(this.orderList));
        this.objectProdCdList = JSON.parse(this.orderList);

        let cdsNameByProdCode = [];
        for (var i = 0; i < this.objectProdCdList.length; i++) {
            if (this.objectProdCdList[i].range && !(this.objectProdCdList[i].valorBloqueado != undefined) && !(this.objectProdCdList[i].valorCampanha == 0)) {
                if (this.objectProdCdList[i].range.length > 0) {
                    this.objectProdCdList[i].range.forEach(range => {
                        if (range.range_min <= this.objectProdCdList[i].quantidadeCx && (range.range_max >= this.objectProdCdList[i].quantidadeCx || range.range_max == null)) {
                            console.log(range.preco_differ.toFixed(6));
                            this.objectProdCdList[i].precoTabelaCx = range.preco_differ.toFixed(6) == undefined ? this.objectProdCdList[i].precoTabelaCx : range.preco_differ.toFixed(6);
                            this.objectProdCdList[i].inicialCaixa  = range.preco_differ.toFixed(6) == undefined ? this.objectProdCdList[i].inicialCaixa  : range.preco_differ.toFixed(6);
                        }
                    });
                }
            }
            console.log(this.objectProdCdList[i].prodCode);
            console.log(cdsNameByProdCode[this.objectProdCdList[i].prodCode]);
            if(this.verMargem == undefined){
                this.verMargem = this.objectProdCdList[i].verMargem;
            }

            if (cdsNameByProdCode[this.objectProdCdList[i].prodCode] == undefined) {
                this.prodToCds[this.objectProdCdList[i].prodId] = [];
                this.prodToCds[this.objectProdCdList[i].prodId].push(this.objectProdCdList[i].cds);
                cdsNameByProdCode[this.objectProdCdList[i].prodCode] = this.objectProdCdList[i].cds;
                console.log('duplicado');
                console.log('this.objectProdCdList[i].valorCampanha => '+this.objectProdCdList[i].valorCampanha);
                this.objectProdCdList[i].valorBloqueado = this.goToCheckout ? this.goToCheckout : this.objectProdCdList[i].valorBloqueado;
                this.prodList.push({
                    id:                       this.objectProdCdList[i].prodId,
                    pbEntryId:                this.objectProdCdList[i].pbEntryId,
                    fatorConversao:           this.objectProdCdList[i].conversaoUnidadeCx,
                    code:                     this.objectProdCdList[i].prodCode,
                    nome:                     this.objectProdCdList[i].nome,
                    principioAtivo:           this.objectProdCdList[i].principioAtivo,
                    fabricante:               this.objectProdCdList[i].fabricante,
                    anvisa:                   this.objectProdCdList[i].anvisa,
                    categoria:                this.objectProdCdList[i].categoria,
                    precoFabricaCx:           this.objectProdCdList[i].precoFabricaCx,
                    precoTabelaCx:            this.objectProdCdList[i].precoTabelaCx,
                    temperatura:              this.objectProdCdList[i].temperatura,
                    cds:                      this.objectProdCdList[i].cds,
                    allCds:                   this.objectProdCdList[i].cds,
                    ean:                      this.objectProdCdList[i].ean,
                    showBadgeOL:              this.objectProdCdList[i].showBadgeOL,
                    showBadgeCampanha:        this.objectProdCdList[i].showBadgeCampanha,
                    showBadgeCampanhaVendedor: this.objectProdCdList[i].showBadgeCampanhaVendedor,
                    showBadgeConsignado:      this.objectProdCdList[i].showBadgeConsignado,
                    showBadgeAcordoComercial: this.objectProdCdList[i].showBadgeAcordoComercial,
                    showBadgeshelflife:       this.objectProdCdList[i].showBadgeshelflife,
                    selected:                 this.objectProdCdList[i].selected,
                    quantidade:               this.objectProdCdList[i].quantidade,
                    margem:                   this.objectProdCdList[i].margem,
                    valorTotal:               this.objectProdCdList[i].valorTotal,
                    valorBloqueado:           this.objectProdCdList[i].valorBloqueado,
                    valorBloqueadoPrice:      this.objectProdCdList[i].showBadgeshelflife ? false : this.objectProdCdList[i].valorBloqueado,
                    SequenciaOC:              this.objectProdCdList[i].SequenciaOC,
                    range:                    this.objectProdCdList[i].range,
                    rangeStringify:           this.objectProdCdList[i].rangeStringify,
                    valorCampanha:            this.objectProdCdList[i].valorCampanha
                });
            } else {
                console.log('pulou o duplicado');
                this.prodToCds[this.objectProdCdList[i].prodId].push(this.objectProdCdList[i].cds);
                cdsNameByProdCode[this.objectProdCdList[i].prodCode] += ', ' + this.objectProdCdList[i].cds;
                this.prodList.find(prod => prod.code == this.objectProdCdList[i].prodCode).allCds = cdsNameByProdCode[this.objectProdCdList[i].prodCode];
            }
            if (this.productPerCds[this.objectProdCdList[i].prodId] == undefined) {
                this.productPerCds[this.objectProdCdList[i].prodId] = [];
                this.productPerCds[this.objectProdCdList[i].prodId].push(this.objectProdCdList[i]);
            } else {
                this.productPerCds[this.objectProdCdList[i].prodId].push(this.objectProdCdList[i]);
            }

            this.productPerCdsFiltered[this.objectProdCdList[i].prodId] = this.productPerCds[this.objectProdCdList[i].prodId];
            
            this.cdList.push(this.objectProdCdList[i]);
        }
        console.log(this.prodList);

        this.refreshCdFilter();

        this.prodListFiltered = this.prodList;
        this.cdList.forEach(cd => {
            if (cd.selected == undefined) {
                cd.selected = true;
            }
        })
        this.cdListCloneSelected = this.cdList;
        this.prodListMeas = JSON.stringify(this.cdList);
        this.cdListCloneSelected.sort((a, b) => (a.indexInsertPosition > b.indexInsertPosition) ? 1 : ((b.indexInsertPosition > a.indexInsertPosition) ? -1 : 0));
        
        this.activeSection = '';

        
        if (this.goToCheckout) {
            this.disableButtons();
            this.isLoadingScore = false;
            return;
        }

        // this.handleCd(this.prodListFiltered[0].Id);

        // this.removeAllFilters();

        // calcular valor total de acordo com a lista de Cds
        this.calcTotalOrderPrice();
        this.refreshCdScoreCalc();
        this.getStockFromMalha(null);
        console.log('this.cdListCloneReserved checkout ==> ' + JSON.stringify(this.cdListCloneReserved));
    }

    handleSelectedItens() {
        this.cdListCloneSelected = [];
        this.cdListClone = [];
        this.cdList.forEach(cd => {
            if (cd.selected) {
                this.cdListCloneSelected.push(cd);
            } else {
                this.cdListClone.push(cd);
            }
            if (this.invalidProducts.includes(cd.prodId)) {   
                cd.selected = false;
                cd.disableCheckbox = true;
            }
        });
        if (this.cdListCloneSelected.length == 0) {
            this.disableButtons();
            this.isAddItemDisabled = false;
        } else if (!this.isCallingMalha && !this.generateBudgetOrOrder) {            
            this.enableButtons();
        }
        this.remakeFreightList(JSON.stringify(this.cdListCloneSelected));
        
    }

    handleListSort(event) {
        if (event.target.value == 'Ordem alfabética') {
            this.cdListClone.sort((a, b) => (a.nome > b.nome) ? 1 : ((b.nome > a.nome) ? -1 : 0));
            this.cdListCloneSelected.sort((a, b) => (a.nome > b.nome) ? 1 : ((b.nome > a.nome) ? -1 : 0));
        } else if (event.target.value == 'Agrupar por CD') {
          
            this.cdListClone.sort((a, b) => (a.cds > b.cds) ? 1 : ((b.cds > a.cds) ? -1 : 0));
            this.cdListCloneSelected.sort((a, b) => (a.cds > b.cds) ? 1 : ((b.cds > a.cds) ? -1 : 0));
            
        } else {
            this.cdListClone.sort((a, b) => (a.indexInsertPosition > b.indexInsertPosition) ? 1 : ((b.indexInsertPosition > a.indexInsertPosition) ? -1 : 0));
            this.cdListCloneSelected.sort((a, b) => (a.indexInsertPosition > b.indexInsertPosition) ? 1 : ((b.indexInsertPosition > a.indexInsertPosition) ? -1 : 0));
        }

        this.filtroPDF = event.target.value;
    }

    handleIndexOrder() {
        let indexOrder = 0;
        this.cdList.forEach(cd => {
            cd.indexPosition = indexOrder;
            indexOrder++;
        })
    }

    get radioSortOptions() {
        return [
            { label: "Ordem alfabética", value: "Ordem alfabética" },
            { label: "Ordem de inserção", value: "Ordem de inserção" },
            { label: "Agrupar por CD", value: "Agrupar por CD" }
        ];
    }

    getStockFromMalha(event) {
        if(event != null) {
            var eventValue = JSON.parse(JSON.stringify(event.target.value));
            console.log('event ======> ' + event);
            console.log('event.target.value ======> ' + event.target.value);
        }
        this.disableButtons();
        this.isCallingMalha = true;
        this.isLoadingScore = true;
        this.isGenerateOrderByOpp = true;
        if (event == null) {
            swal('Aviso!', 'Checando quantidade de estoque dos produtos!')
        }
        let prodList = [];

        let cdObj = {};

        let cdObjIndex = {};

        this.cdList.forEach((cd, index)=> {   
            if (!prodList.includes(cd.prodCode) && !cd.showBadgeShelflifeCNPJ) {
                prodList.push(cd.prodCode);
            }
            cdObj[cd.prodCode + '_' + cd.cnpjCd] = {
                cnpjCd: cd.cnpjCd,
                qtd: cd.quantidadeCx,
                nome: cd.nome
            }
            cdObjIndex[cd.prodCode + '_' + cd.cnpjCd] = index;
        });

        console.log(this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''));
        console.log(prodList);
        console.log(prodList.join(','));

        const listProductError = [];
        const listProductNotFound = []
        var hasValidProduct = false;

        if(prodList.length == 0) return;

        getPricebookExternalId({ pricebookId: this.tabelaPreco })
            .then(result => {
                console.log('getPricebookExternalId: entrou certo!');
                console.log(result);
                this.tabelaPrecoExternal = result;
                this.isLoadingScore = true;
                this.disableButtons();
                getMalha({ clienteCGC: this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''), productCode: prodList.join(','), calcMargem: false, pricebookExternalId: this.tabelaPrecoExternal, condPagamento: this.condicaoPagamento, isForaMalha: true  })
                    .then(result => {
                        console.log('getMalha: entrou certo!');
                        console.log(result);
                        if (result != null) {
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
                                            const product = cdObj[item.codprotheus + '_' + cdItem.cnpj];
                                            if (product != undefined) {
                                                const cd = item.cds.find(cd => cd.cnpj == product.cnpjCd);
                                                console.log(item);
                                                console.log(product);
                                                console.log(product.qtd);
                                                console.log(cd.saldo);
                                                if (cd.preco == 0) {
                                                    this.invalidProducts.push(item.codprotheus);
                                                    this.checkInvalidProducts();
                                                    listProductNotFound.push(item.msgerro);
                                                } else {
                                                    if (cd.saldo < product.qtd) {
                                                        listProductError.push(product.nome + ' - ' + cd.filial);
                                                        this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].quantidadePossivel = cd.saldo;
                                                        this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].quantidadeRestante = product.qtd - cd.saldo;
                                                        this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].pedidoComplementar = true;
                                                        this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].manterPendente     = true;
                                                    } else {
                                                        this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].manterPendente = false;
                                                        hasValidProduct = true;
                                                    }
                                                    this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].estoque = cd.saldo;
                                                    this.cdList[cdObjIndex[item.codprotheus + '_' + cdItem.cnpj]].laboratorio = cd.laboratorio;
                                                }
                                            }
                                        });
                                    } else {
                                        let invalidProd = item.msgerro.split(' ')[1];
                                        this.invalidProducts.push(invalidProd);
                                        this.checkInvalidProducts();
                                        listProductNotFound.push(item.msgerro);
                                    }
                                })
                            }
                            this.calcTotalOrderPrice();
                            this.refreshCdScoreCalc();
                            this.refreshCdFilter();
                            this.removeAllFilters();
                        }                    

                        this.cdListClone = this.cdList;
                        this.cdListCloneSelected = this.cdList;
                        this.handleSelectedItens();
                        this.isCallingMalha = false;
                        this.isInstallmentDisabled = false;
                        this.isLoadingScore = false;
                        if (listProductNotFound.length > 0 && !hasValidProduct && event) {
                            swal('Aviso!', `Erro na busca de estoque: ${listProductNotFound.join(' ')}`, 'warning');
                            this.enableButtons();
                            return;
                        } else if (listProductError.length > 0 && event) {
                            //swal('Aviso!', `Produtos com quantidade acima do estoque disponível: ${listProductError.join(', ')}`);
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
                                            console.log(this.cdList);
                                            this.cdListComplement = [];
                                            this.cdListToRemove = [];
                                            this.cdList.forEach((cd, index) => {
                                                if (cd.pedidoComplementar) {
                                                    console.log(cd.quantidadePossivel);
                                                    console.log(cd.quantidadeRestante);
                                                    console.log('cd acima da quantidade possível');
                                                    console.log(cd.itemId);
                                                    this.hasComplementOrder = true;
                                                    this.cdListComplement.push({
                                                        ...this.cdList[index],
                                                        itemId: undefined,
                                                        quantidadeCx: cd.quantidadeRestante
                                                    })
                                                    if (cd.quantidadePossivel == 0) {
                                                        this.cdListToRemove.push(cd.cdId);
                                                        this.cdList[index] = {
                                                            ...this.cdList[index],
                                                            pedidoComplementar: false
                                                        }
                                                    }
                                                }
                                            });

                                            if (this.cdListToRemove.length == this.cdList.length) {
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
                                                    dangerMode: true,})
                                                    .then((value) => {
                                                        console.log(value)
                                                        switch (value) {
                                                            case "Aguardar":
                                                                this.keepComplementOrder = true;
                                                                this.handleSaveOrderOrOpp(event);
                                                                break;
                                                            default:
                                                                this.enableButtons();
                                                                return;
                                                        }
                                                    });
                                                        
                                                return;
                                            }

                                            console.log('tratamentos feitos: ');
                                            console.log('cdList: ');
                                            console.log(JSON.parse(JSON.stringify(this.cdList)));
                                            console.log('cdListComplement: ');
                                            console.log(JSON.parse(JSON.stringify(this.cdListComplement)));
                                            event.target.value = "true";
                                            this.handleSaveOrderOrOpp(event);
                                            break;
                                        case "Aguardar":
                                            this.keepComplementOrder = true;
                                            this.handleSaveOrderOrOpp(event);
                                            break;
                                        default:
                                            this.enableButtons();
                                            return;
                                    }
                                });
                        } else if (event){
                            if(event.target.value == undefined) {
                                event.target.value = eventValue;
                            }
                            this.handleSaveOrderOrOpp(event);
                        } else {
                            this.enableButtons();
                        }

                    }).catch(error => {
                        swal("Ops!", "Erro ao verificar estoque!", "error");
                        this.enableButtons();
                        this.isInstallmentDisabled = false;
                        this.isLoadingScore = false;
                        console.log('getMalha: entrou no erro!');
                        console.log(error);
                    })
                }).catch(error => {
                    console.log('getPricebookExternalId: entrou no erro!');
                    console.log(error);
                });
    }

    handleSelectedProduct(event) {
        this.activeSection = 'cdaccordion';
        this.isLoading = true;
        let productId = event.currentTarget.dataset.productId;
        this.prodList.forEach(prod => {
            prod.show = prod.id === productId ? true : false;
        });
        this.handleCd(productId);
    }

    calcRefresh(selectedCd) {
        console.log(selectedCd.quantidade);
        this.calcValorTotal(selectedCd);
        console.log('calcPriceUnit');
        this.calcTotalOrderPrice();
    }

    calcPriceUnit(event) {
        let unit = parseFloat(event.target.value);
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);

        const previousUnitValue = selectedCd.quantidade;
        //obs: eu não sei se os calculos estão seguindo as regras de negócio certinhas
        //coloquei preço de und e etc só por questão de demonstração do protótipo
        console.log(event.currentTarget.dataset);
        console.log(this.mockedProdList);

        console.log(event.target);
        console.log(event.detail);

        if (unit == 0) {
            swal({
                title: "Remover item do carrinho?",
                text: "Caso remova será recalculado os valores no carrinho!",
                icon: "warning",
                buttons: ["Cancelar", "Remover"],
                dangerMode: true,
            })
                .then((willDelete) => {
                    if (willDelete) {
                        console.log('Removendo!');
                        this.cdListClone = this.cdList.filter(cd => cd.id !== cdId);
                        this.cdListCloneSelected = this.cdList.filter(cd => cd.id !== cdId);

                        this.cdList = this.cdList.filter(cd => cd.id !== cdId);

                        this.calcRefresh(selectedCd);
                        this.handleCd(selectedCd.prodId);

                        this.refreshCdFilter();
                    } else {
                        console.log('remoção cancelada');
                        console.log(selectedCd.quantidade);
                        unit = selectedCd.quantidade;
                        console.log(unit);
                        console.log(event.detail.value);
                        event.target.value = unit;
                        event.detail.value = unit;
                        console.log('previousUnitValue: ' + previousUnitValue);
                        console.log(event.detail.value);
                        selectedCd.quantidade = unit;
                        selectedCd.quantidadeCx = (unit / parseFloat(selectedCd.conversaoUnidadeCx));

                        this.calcRefresh(selectedCd);
                    }
                    this.prodListMeas = JSON.stringify(this.cdList);
                });
        } else {
            if (selectedCd.valorCampanha != 0 && selectedCd.caixa < selectedCd.valorCampanha) {            
                swal("Aviso!", 'Valor inserido no produto é menor que o valor da campanha!');
                return;
            }
            selectedCd.quantidade = unit;
            selectedCd.quantidadeCx = (unit / parseFloat(selectedCd.conversaoUnidadeCx));
            if (selectedCd.range && !(selectedCd.valorBloqueado != undefined) && !(selectedCd.valorCampanha == 0)) {
				if (selectedCd.range.length > 0) {
					selectedCd.range.forEach(range => {
						if (range.range_min <= selectedCd.quantidadeCx && (range.range_max >= selectedCd.quantidadeCx || range.range_max == null)) {
							console.log(range.preco_differ.toFixed(6));
							selectedCd.precoTabelaCx = range.preco_differ.toFixed(6) == undefined ? selectedCd.precoTabelaCx : range.preco_differ.toFixed(6);
							selectedCd.caixa         = selectedCd.precoTabelaCx;
							selectedCd.inicialCaixa  = range.preco_differ.toFixed(6) == undefined ? selectedCd.inicialCaixa  : range.preco_differ.toFixed(6);
						}
					});
				}
			}
            let currentProd = this.prodList.find(prod => prod.id == selectedCd.prodId);
            this.fillCalcScoreObj(selectedCd, currentProd);
            this.prodListMeas = JSON.stringify(this.cdList);
            this.calcRefresh(selectedCd);
			this.refreshCdScoreCalc();
        }

    }

    calcPriceUnitCx(event) {
        let qtdcx = parseFloat(event.target.value);
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);

        if (qtdcx == 0) {
            swal({
                title: "Remover item do carrinho?",
                text: "Caso remova será recalculado os valores no carrinho!",
                icon: "warning",
                buttons: ["Cancelar", "Remover"],
                dangerMode: true,
            })
                .then((willDelete) => {
                    if (willDelete) {
                        console.log('Removendo!');
                        this.cdListClone = this.cdList.filter(cd => cd.id !== cdId);
                        this.cdListCloneSelected = this.cdList.filter(cd => cd.id !== cdId);

                        this.cdList = this.cdList.filter(cd => cd.id !== cdId);
                        
                        this.refreshCdFilter();

                        this.calcRefresh(selectedCd);

                        this.refreshCdScoreCalc();
                    } else {
                        console.log('remoção cancelada');
                        this.refreshCdFilter();
                        qtdcx = selectedCd.quantidadeCx;
                        selectedCd.quantidade = (qtdcx * parseFloat(selectedCd.conversaoUnidadeCx));
                        selectedCd.quantidadeCx = qtdcx;
                        this.calcRefresh(selectedCd);
                        this.refreshCdFilter();
                    }
                    this.prodListMeas = JSON.stringify(this.cdList);
                });
        } else {
            selectedCd.quantidade = selectedCd.tipoConversao == 'M' ? (qtdcx * parseFloat(selectedCd.conversaoUnidadeCx)) : Number(qtdcx / parseFloat(selectedCd.conversaoUnidadeCx));
            selectedCd.quantidadeCx = qtdcx;
            console.log(selectedCd);
			if (selectedCd.range && !(selectedCd.valorBloqueado != undefined) && !(selectedCd.valorCampanha == 0)) {
				if (selectedCd.range.length > 0) {
					selectedCd.range.forEach(range => {
						if (range.range_min <= qtdcx && (range.range_max >= qtdcx || range.range_max == null)) {
							console.log(range.preco_differ.toFixed(6));
							selectedCd.precoTabelaCx = range.preco_differ.toFixed(6) == undefined ? selectedCd.precoTabelaCx : range.preco_differ.toFixed(6);
							selectedCd.caixa         = selectedCd.precoTabelaCx;
							selectedCd.inicialCaixa  = range.preco_differ.toFixed(6) == undefined ? selectedCd.inicialCaixa  : range.preco_differ.toFixed(6);
						}
					});
				}
			}
            let currentProd = this.prodList.find(prod => prod.id == selectedCd.prodId);
			this.fillCalcScoreObj(selectedCd, currentProd);
            this.prodListMeas = JSON.stringify(this.cdList);
            this.calcRefresh(selectedCd);
            this.getScoreCalcApi(selectedCd);
            this.refreshCdScoreCalc();
        }
    }

    calcUnitValue(event) {
        let unitValue = parseFloat(event.target.value);
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);

        selectedCd.unitario = unitValue;
        selectedCd.caixa = parseFloat(unitValue) * parseFloat(selectedCd.conversaoUnidadeCx);
        console.log(selectedCd.caixa);

        this.calcValorTotal(selectedCd);

        console.log('calcUnitValue');

        this.calcTotalOrderPrice();
    }

    
    async calcCxValue(event) {
        let cxValue = parseFloat(event.target.value);
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);
        let selectedCdCaixaLastValue = selectedCd.caixa;

        console.log('selectedCd ====> ' + JSON.stringify(selectedCd));


        if (selectedCd.caixa != cxValue) {

            if(selectedCd.showBadgeShelflifeCNPJ) {
                if(parseFloat(cxValue) >= selectedCd.minimumPrice) {
                    this.callMethodsValor(selectedCd, cxValue);
                } else {
                    selectedCd.caixa = undefined;

                    await swal({
                        title: 'Aviso!', 
                        text: 'Só é possível inserir valores acima do preço mínimo. \nPreço mínimo: ' + selectedCd.minimumPrice.toString(),
                        closeOnClickOutside: false,
                        closeOnEsc: false,
                        icon: 'info'}).then(ok => {
                        if(ok) {
                            selectedCd.caixa = selectedCdCaixaLastValue;
                        }
                    });
                }
            } else {
                this.callMethodsValor(selectedCd, cxValue);
            }
        }
    }
    
    callMethodsValor(selectedCd, cxValue) {
        selectedCd.caixa = cxValue;
        selectedCd.unitario = selectedCd.tipoConversao == 'M' ? cxValue / parseFloat(selectedCd.conversaoUnidadeCx) : cxValue * parseFloat(selectedCd.conversaoUnidadeCx);
        let currentProd = this.prodList.find(prod => prod.id == selectedCd.prodId);
        this.fillCalcScoreObj(selectedCd, currentProd);
        this.getScoreCalcApi(selectedCd)
        this.calcValorTotal(selectedCd);
        this.calcTotalOrderPrice();
        this.refreshCdScoreCalc();
    }

    SequenciaOC(event) {
        let SequenciaOC = parseFloat(event.target.value);
        console.log('inicio ' + JSON.stringify(this.prodList));
        console.log('inicio2  ' + JSON.stringify(this.cdList));
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);
        selectedCd.SequenciaOC = SequenciaOC;
        let currentProd = this.prodList.find(prod => prod.id == selectedCd.prodId);
        this.prodList.find(prod => prod.id == selectedCd.prodId).SequenciaOC = selectedCd.SequenciaOC;
        this.fillCalcScoreObj(selectedCd, currentProd);

        console.log('inicio3  ' + JSON.stringify(this.cdList));
        console.log('okkk ' + JSON.stringify(this.prodList));
        this.getScoreCalcApi(selectedCd)

        this.calcValorTotal(selectedCd);
        this.calcTotalOrderPrice();
        this.refreshCdScoreCalc();

    }

    calcDiscount(event) {
        let discount = parseFloat(event.target.value);
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);

        if (selectedCd.desconto != discount) {

            selectedCd.desconto = discount;
            //Calculo do valores levando em consideração o desconto, só leva em consideração se ele for > 0
            selectedCd.unitario = selectedCd.desconto > 0 ? selectedCd.inicialUnitario * (1 - selectedCd.desconto / 100) : selectedCd.inicialUnitario;
            selectedCd.caixa = selectedCd.desconto > 0 ? selectedCd.inicialCaixa * (1 - selectedCd.desconto / 100) : selectedCd.inicialCaixa;

            selectedCd.unitario = Number(selectedCd.unitario).toFixed(6);
            selectedCd.caixa = Number(selectedCd.caixa).toFixed(6);

            let currentProd = this.prodList.find(prod => prod.id == selectedCd.prodId);
            this.fillCalcScoreObj(selectedCd, currentProd);

            this.getScoreCalcApi(selectedCd)

            this.calcValorTotal(selectedCd);
            this.calcTotalOrderPrice();
            this.refreshCdScoreCalc();
        }
    }

    handleMargin(event) {
        let margin = parseFloat(event.target.value);
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);
        if (selectedCd.margem != margin) {
            selectedCd.margem = margin;

            let currentProd = this.prodList.find(prod => prod.id == selectedCd.prodId);

            this.calcScoreObj = [];
            this.calcScoreObj.push({
                cdId: selectedCd.cnpjCd,
                productBu: (currentProd.categoria == '' || currentProd.categoria == undefined) ? 'SEM BU' : currentProd.categoria,
                productCode: selectedCd.prodCode,
                cost: (selectedCd.custoCx != null && selectedCd.custoCx != undefined) ? selectedCd.custoCx : 10,
                quantity: selectedCd.quantidadeCx,
                unitPrice: Number(selectedCd.precoTabelaCx).toFixed(6),
                listPrice: Number(selectedCd.precoTabelaCx).toFixed(6),
                taxPercent: selectedCd.aliquota,
                SequenciaOC: selectedCd.SequenciaOC,
                margem: margin,
                isContract: selectedCd.valorBloqueado != undefined ? selectedCd.valorBloqueado : false
            });

            reverseCalcScreen({ clListString: JSON.stringify(this.calcScoreObj) })
                .then(result => {
                    console.log('reverseCalcScreen: entrou certo!');
                    console.log(JSON.parse(result));
                    let resultObj = JSON.parse(result);
                    for (var i = 0; i < resultObj.length; i++) {
                        selectedCd.unitario = selectedCd.tipoConversao == 'M' ? (resultObj[i].unitPrice / selectedCd.conversaoUnidadeCx).toFixed(6) : (resultObj[i].unitPrice * selectedCd.conversaoUnidadeCx).toFixed(6);
                        selectedCd.caixa    = resultObj[i].unitPrice.toFixed(6);
                        selectedCd.desconto = resultObj[i].newDiscount.toFixed(2);
                        selectedCd.score    = (resultObj[i].scoreFinal != undefined && resultObj[i].scoreFinal != null) ? resultObj[i].scoreFinal.toFixed(2) : selectedCd.score;
                    }

                    this.calcRefresh(selectedCd);
                    this.refreshCdScoreCalc();
                }).catch(error => {
                    console.log('reverseCalcScreen: entrou no erro!');
                    console.log(error);
                    this.calcRefresh(selectedCd);
                });
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
			listPrice: Number(Number(selectedCd.inicialCaixa).toFixed(6)), // Number((currentProd.precoTabelaCx).toFixed(6)),
			taxPercent: selectedCd.aliquota,
			SequenciaOC: selectedCd.SequenciaOC,
			isContract: selectedCd.valorBloqueado != undefined ? selectedCd.valorBloqueado : false,
			isCampaign: selectedCd.valorCampanha == undefined ? false : (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ) ? selectedCd.showBadgeCampanhaCD : true,
			isLab: selectedCd.laboratorio == undefined ? false : true
		});
	}

    calcValorTotal(selectedCd) {
        let discount = 100 - (parseFloat(selectedCd.caixa) * 100 / parseFloat(selectedCd.inicialCaixa));
        selectedCd.desconto = discount < 0 ? 0 : (Math.round(discount * 100) / 100).toFixed(2);
        // selectedCd.desconto = discount;
        // selectedCd.unitario = selectedCd.desconto > 0 ? selectedCd.inicialUnitario * (1 - selectedCd.desconto / 100) : selectedCd.inicialUnitario;
        // selectedCd.caixa = selectedCd.desconto > 0 ? selectedCd.inicialCaixa * (1 - selectedCd.desconto / 100) : selectedCd.inicialCaixa;
        selectedCd.valorTotal = Number(parseFloat(selectedCd.quantidadeCx) * parseFloat(selectedCd.caixa)).toFixed(6);
    }

    calcTotalOrderPrice() {
        console.log('Calcular valor total');
        this.handleSelectedItens();
        let currentTotalPrice = 0;
        this.totalItens = 0;
        for (var i = 0; i < this.cdList.length; i++) {
            console.log('Entrou aqui');
            if (this.cdList[i].selected) {
                console.log(this.cdList[i].quantidade);
                console.log(this.cdList[i].precoFabricaUn);
                currentTotalPrice += Number(this.cdList[i].valorTotal);
                this.totalItens += 1;
            }
        }
        this.totalOrderValue = (Number(currentTotalPrice)).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
        this.refreshCdFilter();
    }

    getScoreCalcApi(selectedCd) {
        if (!this.goToCheckout) {
            calcProducts({ clListString: JSON.stringify(this.calcScoreObj) })
                .then(result => {
                    console.log('calcProducts: entrou certo!');
                    console.log(JSON.parse(result));
                    let resultObj = JSON.parse(result);
                    for (var i = 0; i < resultObj.length; i++) {
                        let cdCode = resultObj[i].cdId + '_' + resultObj[i].productCode;
                        this.cdList.find(cd => cd.cdId == cdCode).margem = resultObj[i].margem.toFixed(2);
                        this.cdList.find(cd => cd.cdId == cdCode).margemAlvo = (resultObj[i].margemAlvo).toFixed(2);
                        if (selectedCd.valorCampanha == 0 && !selectedCd.showBadgeShelflifeCNPJ) {
                            if (selectedCd.laboratorio || selectedCd.showBadgeCampanhaCD) {
                                this.cdList.find(cd => cd.cdId == cdCode).score = 100.00;
                            } else {
                                this.cdList.find(cd => cd.cdId == cdCode).score = resultObj[i].scoreFinal.toFixed(2);
                            }
                        } else {
                            this.cdList.find(cd => cd.cdId == cdCode).score = 100.00;
                        }
                        // this.cdList.find(cd => cd.id == resultObj[i].cdId).scoreBU = resultObj[i].scoreBU.toFixed(2);
                        // this.cdList.find(cd => cd.id == resultObj[i].cdId).scoreMix = resultObj[i].scoreMix.toFixed(2);
                        // this.cdList.find(cd => cd.id == resultObj[i].cdId).scoreItem = resultObj[i].scoreItem.toFixed(2);
                    }
                    this.calcRefresh(selectedCd);
                }).catch(error => {
                    console.log('calcProducts: entrou no erro!');
                    console.log(error);
                    this.calcRefresh(selectedCd);
                });
        }
    }

    buildCalcAllScoreObj(isComplementOrder) {
        this.calcAllScoreObj = [];

        if (isComplementOrder) {
            this.cdListComplement.forEach(cd => {
                this.calcAllScoreObj.push({
                    cdId: cd.cnpjCd,
                    productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
                    productCode: cd.prodCode,
                    cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
                    quantity: cd.quantidadeCx,
                    unitPrice: Number(cd.caixa).toFixed(6),
                    listPrice: Number(cd.inicialCaixa).toFixed(6),// Number((currentProd.precoTabelaCx).toFixed(6)),
                    taxPercent: cd.aliquota,
                    isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
                    isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? cd.showBadgeCampanhaCD : true,
                    isLab: cd.laboratorio == undefined ? false : true
                });
            });
        } else {
            this.cdList.forEach(cd => {
                this.calcAllScoreObj.push({
                    cdId: cd.cnpjCd,
                    productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
                    productCode: cd.prodCode,
                    cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
                    quantity: cd.quantidadeCx,
                    unitPrice: Number(cd.caixa).toFixed(6),
                    listPrice: Number(cd.inicialCaixa).toFixed(6),// Number((currentProd.precoTabelaCx).toFixed(6)),
                    taxPercent: cd.aliquota,
                    isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
                    isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? cd.showBadgeCampanhaCD : true,
                    isLab: cd.laboratorio == undefined ? false : true
                });
            });
        }
    }

    refreshCdScoreCalc() {
        this.calcAllScoreObj = [];

        this.hasOnlyLab = true;
        this.hasOnlyCampaign = true; // se só tem campanha, calcula normal, SE tem mais itens sem ser campanha, desconsidera os itens de campanha
        this.hasOnlyContract = true;
        this.cdList.forEach(cd => {
            if (cd.selected) {

                console.log('this.hasOnlyLab '+this.hasOnlyLab);
                console.log(' !cd.laboratorio '+ !cd.laboratorio);

                console.log('this.hasOnlyCampaign '+this.hasOnlyCampaign);
                console.log(' cd.valorCampanha '+ !cd.valorCampanha);
                console.log(' !cd.showBadgeShelflifeCNPJ '+ !cd.showBadgeShelflifeCNPJ);
                console.log(' !cd.showBadgeCampanhaCD '+ !cd.showBadgeCampanhaCD);


                console.log(' this.hasOnlyContract '+ this.hasOnlyContract);
                console.log(' !cd.valorBloqueado '+ !cd.valorBloqueado);

                if (this.hasOnlyLab && !cd.laboratorio) {
                    this.hasOnlyLab = false;
                }
                if (this.hasOnlyCampaign && cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.showBadgeCampanhaCD) {
                    this.hasOnlyCampaign = false;
                }
                if (this.hasOnlyContract && !cd.valorBloqueado) {
                    this.hasOnlyContract = false;
                }

                console.log(this.hasOnlyCampaign);
                console.log(this.hasOnlyContract);
                if (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.valorBloqueado && !cd.laboratorio && !cd.showBadgeCampanhaCD) {
                    this.calcAllScoreObj.push({
                        cdId: cd.cnpjCd,
                        productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
                        productCode: cd.prodCode,
                        cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
                        quantity: cd.quantidadeCx,
                        unitPrice: Number(cd.caixa).toFixed(6),
                        listPrice: Number(cd.inicialCaixa).toFixed(6),// Number((currentProd.precoTabelaCx).toFixed(6)),
                        taxPercent: cd.aliquota,
                        isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
                        isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? cd.showBadgeCampanhaCD : true,
                        isLab: cd.laboratorio == undefined ? false : true
                    });
                }
            }
        });

        if (this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab) {
            this.calcAllScoreObj = [];
            this.cdList.forEach(cd => {
                if (cd.selected) {
                    this.calcAllScoreObj.push({
                        cdId: cd.cnpjCd,
                        productBu: (cd.categoria == '' || cd.categoria == undefined) ? 'SEM BU' : cd.categoria,
                        productCode: cd.prodCode,
                        cost: (cd.custoCx != null && cd.custoCx != undefined) ? cd.custoCx : 10,
                        quantity: cd.quantidadeCx,
                        unitPrice: Number(cd.caixa).toFixed(6),
                        listPrice: Number(cd.inicialCaixa).toFixed(6),// Number((currentProd.precoTabelaCx).toFixed(6)),
                        taxPercent: cd.aliquota,
                        isContract: cd.valorBloqueado != undefined ? cd.valorBloqueado : false,
                        isCampaign: cd.valorCampanha == undefined ? false : (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ) ? cd.showBadgeCampanhaCD : true,
                        isLab: cd.laboratorio == undefined ? false : true
                    });
                }
            });
        }
        console.log('this.hasOnlyCampaign => '+this.hasOnlyCampaign);
        console.log(this.calcAllScoreObj);

        this.handleSelectedItens();
        if (!this.goToCheckout) {
        calcAllProducts({ clListString: JSON.stringify(this.calcAllScoreObj) })
            .then(result => {
                console.log('calcAllProducts: entrou certo!');
                // this.isLoadingScore = false;

                console.log('result: ' + result);
                let resultJson = JSON.parse(result);
                console.log(resultJson);                
                this.calcAllScoreObj.forEach(calcObj => {                    
                    for (var i = 0; i < resultJson['cdMap'][calcObj.cdId].length; i++) {
                        let currentKey = resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode;
                        if ((calcObj.cdId + '_' + calcObj.productCode) == (currentKey)) {
                            let index = this.cdList.findIndex(item => (item.cdId == currentKey));
                            let indexCdClone = this.cdListClone.findIndex(item => (item.cdId == currentKey));
                            let indexCdCloneSelected = this.cdListCloneSelected.findIndex(item => (item.cdId == currentKey));
                            let indexFilteredList = this.cdListFilter.findIndex(item => (item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId));
    
                            const scoreBU           = calcObj.isCampaign || calcObj.isContract || calcObj.isLab ? 100.00 : Number(resultJson['results'][calcObj.productBu]['scoreFinal'].toFixed(2));
                            const scoreMix          = calcObj.isCampaign || calcObj.isContract || calcObj.isLab ? 100.00 : Number(resultJson['results'][calcObj.productBu]['scoreMix'].toFixed(2));
                            const scoreItem         = calcObj.isCampaign || calcObj.isContract || calcObj.isLab ? 100.00 : Number(resultJson['cdProdMap'][calcObj.cdId+'_'+calcObj.productCode]['scoreFinal'].toFixed(2));
                            const margemTotalCd     = Number(resultJson['results'][calcObj.cdId]['scoreDenominator'].toFixed(2));
                            const margemAlvoTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreNumerador'].toFixed(2));
                            const scoreCd           = calcObj.isCampaign || calcObj.isContract || calcObj.isLab ? 100.00 : Number(resultJson['results'][calcObj.cdId]['scoreFinal'].toFixed(2));
                            console.log('scoreCd');
                            console.log(scoreCd);
                            if (indexFilteredList != -1) {
                                this.cdListFilter[indexFilteredList] = {
                                    ...this.cdListFilter[indexFilteredList],
                                    margem: margemTotalCd,
                                    margemAlvo: margemAlvoTotalCd,
                                    scoreCd: scoreCd
                                }
                            }
                            
                            if (index != -1) {
                                this.cdList[index] = {
                                    ...this.cdList[index],
                                    score: scoreCd,
                                    scoreBU,
                                    scoreMix,
                                    scoreItem,
                                    margemTotalCd,
                                    margemAlvoTotalCd
                                }
                            }

                            if (indexCdClone != -1) {
                                this.cdListClone[indexCdClone] = {
                                    ...this.cdListClone[indexCdClone],
                                    score: scoreCd,
                                    scoreBU,
                                    scoreMix,
                                    scoreItem,
                                    margemTotalCd,
                                    margemAlvoTotalCd
                                }
                            }

                            if (indexCdCloneSelected != -1) {
                                this.cdListCloneSelected[indexCdCloneSelected] = {
                                    ...this.cdListCloneSelected[indexCdCloneSelected],
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
                if (!this.hasOnlyCampaign && !this.hasOnlyContract && !this.hasOnlyLab) {
                    this.cdList.forEach(item => {
                        if (item.valorCampanha != 0 || item.showBadgeShelflifeCNPJ || item.valorBloqueado || item.laboratorio || item.showBadgeCampanhaCD) {
                            item.scoreBU   = 100;
                            item.scoreMix  = 100;
                            item.scoreItem = 100;
                        }
                    })
                }

                // console.log('====== If');
                // console.log('resultJson[results][Order] != undefined '+ resultJson['results']['Order'] != undefined);
                // console.log('!this.hasOnlyCampaign '+ !this.hasOnlyCampaign);
                // console.log('!this.hasOnlyLab '+ !this.hasOnlyLab);
                // console.log('====== fim If');

                // console.log('====== Else If');
                // console.log('!this.hasOnlyCampaign '+ !this.hasOnlyCampaign);
                // console.log('!this.hasOnlyContract '+ !this.hasOnlyContract);
                // console.log('!this.hasOnlyLab '+ !this.hasOnlyLab);
                // console.log('!this.cdListCloneSelected.length '+ !this.cdListCloneSelected.length);
                // console.log('====== fim Else If');

                if (resultJson['results']['Order'] != undefined && !this.hasOnlyCampaign && !this.hasOnlyContract && !this.hasOnlyLab) {
                    console.log(resultJson['results']['Order'] != undefined );
                    this.margemAtualGeral = Number(Number(resultJson['results']['Order']['scoreDenominator'])).toFixed(2) + '%';
                    this.margemAtualAlvo  = Number(Number(resultJson['results']['Order']['scoreNumerador'])).toFixed(2) + '%';                    
                    this.scoreFinalGeral  = this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab ? 100.00 + '%' : Number(Number(resultJson['results']['Order']['scoreFinal'])).toFixed(2) + '%';

                } else if ((this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab) && this.cdListCloneSelected.length > 0) {
                    
                    console.log('else if');
                    this.margemAtualGeral = 100.00 + '%';
                    this.margemAtualAlvo  = 100.00 + '%';
                    this.scoreFinalGeral  = 100.00 + '%';

                } else if((this.margemAtualGeral != '' || this.margemAtualAlvo  != '' || this.scoreFinalGeral != '' ) && this.cdListCloneSelected.length > 0){
                    
                    this.margemAtualGeral = 100.00 + '%';
                    this.margemAtualAlvo  = 100.00 + '%';
                    this.scoreFinalGeral  = 100.00 + '%';
                    
                }else {

                    console.log('else');
                    this.margemAtualGeral = '';
                    this.margemAtualAlvo  = '';
                    this.scoreFinalGeral  = '';
                }
                console.log('SHOW DE BOLA');
                console.log('margemAtualAlvo' +this.margemAtualAlvo);
                console.log('margemAtualGeral' +this.margemAtualGeral);
                this.calcTotalOrderPrice();
            }).catch(error => {
                console.log('calcAllProducts: entrou no erro!');
                console.log(error);
                this.calcTotalOrderPrice();
            });
        }
    }

    handleRemoveCd(event) {
        let cdId = event.currentTarget.dataset.cdId;
        let selectedCd = this.cdList.find(cd => cd.id === cdId);
        swal({
            title: "Remover item do carrinho?",
            text: "Caso remova será recalculado os valores no carrinho!",
            icon: "warning",
            buttons: ["Cancelar", "Remover"],
            dangerMode: true,
        })
            .then((willDelete) => {
                if (willDelete) {
                    console.log('Removendo!');
                    this.cdListClone = this.cdList.filter(cd => cd.id !== cdId);
                    this.cdListCloneSelected = this.cdList.filter(cd => cd.id !== cdId);
                    this.cdList = this.cdList.filter(cd => cd.id !== cdId);
                    
                    this.remakeFreightList(JSON.stringify(this.cdList));

                    this.refreshCdFilter();

                    this.calcRefresh(selectedCd);
                    this.refreshCdScoreCalc();
                    
                    if (this.cdList.length > 0) {
                        this.keepSavingOrEditing();
                    }
                } else {
                    console.log('remoção cancelada');
                    this.calcRefresh(selectedCd);                    
                }
            });
    }

    handleRemoveProduct(event) {
        console.log(event.target.value);
        let currentProdId = event.target.value;
        swal({
            title: "Remover item do carrinho?",
            text: "Caso remova será recalculado os valores no carrinho!",
            icon: "warning",
            buttons: ["Cancelar", "Remover"],
            dangerMode: true,
        })
            .then((willDelete) => {
                if (willDelete) {
                    console.log('Removendo!');

                    this.cdListClone = this.cdList.filter(prod => prod.prodId !== currentProdId);
                    this.cdList = this.cdList.filter(prod => prod.prodId !== currentProdId);
                    
                    this.remakeFreightList(JSON.stringify(this.cdList));

                    this.refreshCdFilter();

                    this.productPerCds[currentProdId] = undefined;
                    this.productPerCdsFiltered[currentProdId] = this.productPerCds[currentProdId];
                    this.prodList = this.prodList.filter(prod => prod.id !== currentProdId);
                    this.prodListFiltered = this.prodListFiltered.filter(prod => prod.id !== currentProdId);
                    swal('Item removido!');

                    this.calcTotalOrderPrice();
                    this.refreshCdScoreCalc();
                } else {
                    console.log('remoção cancelada');
                }
            });
    }

    handleRemoveAllSelectedProducts(event) {
        let selectedCdList = [];
        this.cdList.forEach(cd => {
            if (cd.selected) {
                selectedCdList.push(cd.id);
            }
        });

        if (selectedCdList.length > 0) {
            swal({
                title: "Remover itens selecionados do carrinho?",
                text: "Caso remova será recalculado os valores no carrinho!",
                icon: "warning",
                buttons: ["Cancelar", "Remover"],
                dangerMode: true,
            })
                .then((willDelete) => {
                    if (willDelete) {
                        console.log('Removendo!');

                        selectedCdList.forEach(cdId => {
                            this.cdList      = this.cdList.filter(cd => cd.id !== cdId);
                            this.cdListClone = this.cdList;
                        });
                        this.prodListMeas = JSON.stringify(this.cdList);
                        swal('Item(s) removido(s)!');

                        this.calcTotalOrderPrice();
                        this.refreshCdScoreCalc();
                        this.remakeFreightList(JSON.stringify(this.cdList));
                        if (this.cdList.length > 0) {
                            this.keepSavingOrEditing();
                        }
                    } else {
                        console.log('remoção cancelada');
                    }
                });
        } else {
            swal('Nenhum produto selecionado!');
        }        
    }

    calculateTotalOrder(){
        let sum = 0;
        this.prodList.forEach(prod=>{
            if(prod.selected){
                sum = sum + prod.valorTotal;
            }
        });
        this.totalOrder = sum;
    }

    setProdShowFalse() {
        this.prodList.forEach(prod => {
            prod.show = false;
        });
    }

    removeAllFilters(){
        let divsCds = this.template.querySelectorAll(`[data-div-name="divCd"]`);

        divsCds.forEach(div =>{
            div.classList.remove("cd-card-selected");
            div.classList.add("cd-card-unselected");
        });

        this.filterList = [];
        this.cdListClone = this.cdList;
        this.handleSelectedItens();
    }

    refreshCdFilter() {
        let cdsToTotalValueRefresh = [];
        let isCampaignCd = [];
        this.cdListFilter = [];
        this.cdList.filter(cd => cd.selected != false).forEach(cd => {
            if (cdsToTotalValueRefresh[cd.cds] == undefined) {
                cdsToTotalValueRefresh[cd.cds] = Number(cd.valorTotal);
                console.log('refreshCdFilter');
                console.log('valorFrete:', cd.valorFrete);
                console.log('tipoFrete:', cd.tipoFrete);
                console.log('===cd.cds:', cd.cds);
                console.log('===cd.score:', cd.score);
                if (this.hasOnlyCampaign || this.hasOnlyContract || this.hasOnlyLab) {
                    this.cdListFilter.push({
                        id: cd.id,
                        cdId: cd.cnpjCd,
                        prodId: cd.prodId,
                        cds: cd.cds,
                        valorTotal: cd.valorTotal,
                        margem: cd.margem,
                        margemAlvo: cd.margemAlvo,
                        observacaoComercial: cd.observacaoComercial,
                        scoreCd: 100 //this.hasOnlyCampaign ? 100 : cd.valorCampanha == 0 ? cd.scoreCd : 100
                    });
                } else {
                    this.cdListFilter.push({
                        id: cd.id,
                        cdId: cd.cnpjCd,
                        prodId: cd.prodId,
                        cds: cd.cds,
                        valorTotal: cd.valorTotal,
                        margem: cd.margem,
                        margemAlvo: cd.margemAlvo,
                        observacaoComercial: cd.observacaoComercial,
                        scoreCd: (cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ && !cd.valorBloqueado /*|| (cd.valorCampanha > 0 && !cd.showBadgeCampanhaCD)*/) ? (cd.laboratorio || cd.showBadgeCampanhaCD) ? 100 : cd.score : 100
                    });
                    if (cd.valorCampanha != 0 || cd.showBadgeShelflifeCNPJ || cd.valorBloqueado || cd.laboratorio || cd.showBadgeCampanhaCD) {
                        isCampaignCd[cd.cds] = true;
                    }
                }
            } else {
                if (isCampaignCd[cd.cds] && cd.valorCampanha == 0 && !cd.showBadgeShelflifeCNPJ /*|| cd.showBadgeCampanhaCD*/) {
                    if (cd.laboratorio /*|| cd.showBadgeCampanhaCD*/) {
                        this.cdListFilter.find(cdFilter => cdFilter.cds == cd.cds).scoreCd = 100;
                    } else {
                        this.cdListFilter.find(cdFilter => cdFilter.cds == cd.cds).scoreCd = cd.score;
                    }
                }
                cdsToTotalValueRefresh[cd.cds] += Number(cd.valorTotal);
                this.cdListFilter.find(cdFilter => cdFilter.cds == cd.cds).valorTotal = cdsToTotalValueRefresh[cd.cds];
            }
        });

    }

    handleCdFilter(event){
        console.log(event.currentTarget.dataset.divCds);
        console.log(event.currentTarget.dataset.divProdid);
        let dataDivCds = event.currentTarget.dataset.divCds;
        let prodId = event.currentTarget.dataset.divProdid;

        if (this.filterList.includes(dataDivCds)){
            return;
        }

        this.filterList.push(dataDivCds);
        let divCd = this.template.querySelector(`[data-div-cds="${dataDivCds}"]`);
        divCd.classList.add("cd-card-selected");
        divCd.classList.remove("cd-card-unselected");

        this.productPerCdsFiltered[prodId] = this.productPerCds[prodId].filter(cd => this.filterList.includes(cd.cds));
        this.cdListClone = this.cdList.filter(prod => (this.filterList.includes(prod.cds) && !prod.selected));
        this.cdListCloneSelected = this.cdList.filter(prod => (this.filterList.includes(prod.cds) && prod.selected));
    }
    removeCdFilter(event) {
        console.log(event.currentTarget.dataset.value);
        let cdValue = event.currentTarget.dataset.value;

        let divCd = this.template.querySelector(`[data-div-cds="${cdValue}"]`);
        divCd.classList.add("cd-card-unselected");
        divCd.classList.remove("cd-card-selected");

        this.filterList = this.filterList.filter(cd => cd !== cdValue);

        this.cdListClone = this.cdList.filter(cd => this.filterList.includes(cd.cds));
        this.cdListCloneSelected = this.cdList.filter(cd => this.filterList.includes(cd.cds));

        console.log(this.filterList);
        console.log(this.filterList.length);

        if (this.filterList.length == 0) {
            this.removeAllFilters();
        }
    }


    handleChange(event){
        console.log(event.currentTarget.dataset);
        let selectedProductId = event.currentTarget.dataset.prodId;
        let selectedProduct = this.prodList.find(prod => prod.id === selectedProductId);
        if (event.target.name === 'quantityInput'){
            selectedProduct.quantidade = event.target.value;
        }
        else if (event.target.name === 'valueInput'){
            selectedProduct.precoTabelaCx = event.target.value;
        }
        selectedProduct.valorTotal = selectedProduct.quantidade*selectedProduct.precoTabelaCx;
        
        this.calculateTotalOrder();
    }

    removeProduct(){
        this.prodList = this.prodList.filter(prod => prod.id !== this.selectedProductToRemove.id);
        this.prodListFiltered = this.prodListFiltered.filter(prod => prod.id !== this.selectedProductToRemove.id);
        this.calculateTotalOrder();
        this.closeModalDelete();
    }

    handleCheckbox(event){
        let selectedCdId = event.currentTarget.dataset.cdId;

        let prodId = this.cdList.find(cd => (cd.id === selectedCdId)).cdId.split('_')[1];
        console.log(prodId);
        console.log(this.invalidProducts);
        if (this.invalidProducts.includes(prodId)) {   
            this.cdList.find(cd => (cd.id === selectedCdId)).selected = false;
            this.cdList.find(cd => (cd.id === selectedCdId)).disableCheckbox = true;
            this.orderList = this.cdList.filter(cd => cd.selected != false);       
            // swal("Ops!", "Item não disponível!", "warning");
        } else {
            this.cdList.find(cd => (cd.id === selectedCdId)).selected = event.target.checked;

            this.orderList = this.cdList.filter(cd => cd.selected != false);

            this.calcTotalOrderPrice();
            this.refreshCdScoreCalc();
            this.refreshCdFilter();
            this.removeAllFilters();
        }

        this.prodListMeas = JSON.stringify(this.cdList);
        console.log('CCCCCCCCCCCCCC', this.prodListMeas);
    }

    checkInvalidProducts() {
        this.cdList.forEach(cd => {
            let prodId = cd.cdId.split('_')[1];
            if (this.invalidProducts.includes(prodId)) {
                cd.selected = false;
                cd.disableCheckbox = true;
            }
        })
    }

    handleCdShow(prod) {
        prod.show = !prod.show;
    }

    handleEdit(event) {
        // this.activeSection = this.activeSection == 'cdaccordion' ? '' : 'cdaccordion';
        let selectedProductId = event.target.value;

        // this.prodList.forEach(prod => {
        //     prod.showCd = prod.id === selectedProductId ? prod.showCd == 'cdaccordion' ? '' : 'cdaccordion' : '';
        // });

        this.handleCd(selectedProductId);
    }

    handleCd(productId){
        this.isLoading = false;
        this.current = 0;
        this.cdListClone = [];

        console.log('productId: ' + productId);

        console.log(this.productPerCdsFiltered);

        if (this.productPerCdsFiltered[productId] != undefined) {
            for (var i = 0; i < this.productPerCdsFiltered[productId].length; i++) {
                if (this.cdListClone.length < 3) {
                    this.cdListClone.push(this.productPerCdsFiltered[productId][i]);
                }
            }
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
        if (this.current +2 >= this.cdList.length - 1){
            return;
        }
        
        this.current++;
        this.cdListClone = this.cdList.slice(this.current,this.current+3);
    }

    handleAllCheckbox(event){
        let checked = event.target.checked;
        this.cdList.forEach(cd =>{
            cd.selected = checked;
        });

        this.orderList = this.cdList.filter(cd => cd.selected != false);

        if (!checked) {
            this.removeAllFilters();
        }
        this.calcTotalOrderPrice();
        this.refreshCdScoreCalc();
        this.refreshCdFilter();
    }

    openModalDeleteAllSelected(){
        this.showModalDeleteAllSelected = true;
    }
    closeModalDeleteAllSelected(){
        this.showModalDeleteAllSelected = false;
    }

    openModalDelete(event){
        let selectedProductId = event.target.value;
        this.selectedProductToRemove = this.prodList.find(prod => prod.id === selectedProductId);
        this.showModalDelete = true;
    }
    closeModalDelete(){
        this.showModalDelete = false;
    }

    openCDDescription(){
        this.showCDDescriptionModal = true;
    }

    closeCDDescription(){
        this.showCDDescriptionModal = false;
    }

    fillHeader() {
        if (this.isBudget) {
            console.log('ORÇAMENTO!');
            this.headerInfoData = {
                numOrcamento          : this.numOrcamento,
                valorTotal            : this.valorTotal,
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
                dtValidade            : this.dtValidade,
                observacaoCliente     : this.observacaoCliente,
                observacao            : this.observacao,
                recordId              : this.recordId,
                isCoordenador         : this.isCoordenador,
                Idportalcotacoes      : this.Idportalcotacoes,
				hasPermissionERB      : this.hasPermissionERB,
				recomendacaoRespondida: this.allRecAnswered,
                margemAtual           : this.margemAtualGeral.replace('%', ''),
                margemAlvo            : this.margemAtualAlvo.replace('%', ''),
                score                 : this.scoreFinalGeral.replace('%', ''),
                dtList                : this.receivedDtList.length > 0 ? JSON.stringify(this.receivedDtList) : null,
                freteList             : this.receivedFreightList.length > 0 ? JSON.stringify(this.receivedFreightList) : null,
                filtroPDF             : this.filtroPDF
            }
        } else {
            console.log('PEDIDO!');
            console.log('freteList:');
            console.log(JSON.parse(JSON.stringify(this.receivedFreightList)));
            this.headerInfoData = {
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
                enderecoEntrega          : this.enderecoEntrega,
                enderecoEntregaId        : this.enderecoEntregaId,
                enderecoEntregaContaOrdem: this.enderecoEntregaContaOrdem,
                observacao               : this.observacao,
                observacaoNF             : this.observacaoNF,
                observacaoPedido         : this.observacaoPedido,
                margemAtual              : this.margemAtualGeral != undefined ? this.margemAtualGeral.replace('%', '') : this.margemAtualGeral,
                margemAlvo               : this.margemAtualAlvo != undefined ? this.margemAtualAlvo.replace('%', '') : this.margemAtualAlvo,
                score                    : this.scoreFinalGeral != undefined ? this.scoreFinalGeral.replace('%', '') : this.scoreFinalGeral,
                Idportalcotacoes         : this.Idportalcotacoes,
				hasPermissionERB         : this.hasPermissionERB,
				recomendacaoRespondida   : this.allRecAnswered,
                createOrderDt            : this.createOrderDt,
                dtList                   : this.receivedDtList.length > 0 ? JSON.stringify(this.receivedDtList) : null,
                freteList                : this.receivedFreightList.length > 0 ? JSON.stringify(this.receivedFreightList) : null
            }
        }
    }

    handleNavigateInsertOrder() {
        this.fillHeader();
        this.handleIndexOrder();
        console.log("going back to insertOrder comp");
        var compDefinition = {
            componentDef: "c:insertOrder",
            attributes: {
                isEdit                : this.isEdit,
                numOrcamento          : this.numOrcamento,
                valorTotal            : this.valorTotal,
                score                 : this.scoreFinalGeral,
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
                dtValidade            : this.dtValidade,
                observacaoCliente     : this.observacaoCliente,
                observacao            : this.observacao,
                recordId              : this.recordId,
                newRecordId           : this.newRecordId,
                isCoordenador         : this.isCoordenador,
                Idportalcotacoes      : this.Idportalcotacoes,
                createOrderDt         : this.createOrderDt,
                headerInfoData        : JSON.stringify(this.headerInfoData),
                isFromBudgetScreen    : true,
                orderListReturned     : JSON.stringify(this.cdList.filter(cd => cd.selected != false)),
                hasPermissionERB      : this.hasPermissionERB,
                allRecAnswered        : this.allRecAnswered,
                dtParcelas            : this.dtParcelas,
                fretesPorCd           : this.receivedFreightList.length > 0 ? JSON.stringify(this.receivedFreightList) : null
            }
        };
        
        try {
            const filterChangeEvent = new CustomEvent('generateorder', {
                detail: { "data": JSON.stringify(compDefinition) }
            });
            // Fire the custom event
            this.dispatchEvent(filterChangeEvent);
        } catch (e) {
            debugger;
            console.log(e);
        }

    }

    handleOnFreightValues(event) {
        console.log(event.detail.record);
        const eventFreight = event.detail.record;
        this.remakeFreightList(eventFreight);

        console.log('receivedFreightList:');
        console.log(this.receivedFreightList);
    }

    remakeFreightList(newFreight) {
        this.cdFreightList = [];
        console.log('Entrou remake');
        let listFreightCd = [];
        let cdFreightHelp = [];
        JSON.parse(newFreight).forEach(cd => {
            this.cdList.find(item => item.id == cd.id).valorFrete = cd.valorFrete;
            this.cdList.find(item => item.id == cd.id).tipoFrete = cd.tipoFrete;
            if (cdFreightHelp[cd.cnpjCd] == undefined && cd.tipoFrete != undefined && cd.tipoFrete != '') {
                cdFreightHelp[cd.cnpjCd] = Number(cd.cnpjCd);
                console.log('entrou if');
                listFreightCd.push(cd.cnpjCd + ':' + cd.valorFrete + ':' + cd.tipoFrete);
                this.cdFreightList.push(this.cdList.find(item => item.id == cd.id));
            }
        });

        this.orderList = this.cdList.filter(cd => cd.selected != false);
        console.log(listFreightCd);
        console.log(JSON.parse(JSON.stringify(this.cdFreightList)));

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
    }

    handleNavigateOrderProduct(event) {
        let prodCode = event.currentTarget.dataset.prodCode;
        let getRecommendation = event.currentTarget.dataset.recommendation == "true" ? true : false;
        console.log("going back to orderProduct comp");
        var compDefinition = {};

        if (this.isBudget) {
            compDefinition = {
                componentDef: "c:orderProduct",
                attributes: {
                    isEdit                : this.isEdit,
                    selectedProd          : prodCode,
                    getRecommendation     : getRecommendation,
                    numOrcamento          : this.numOrcamento,
                    valorTotal            : this.valorTotal,
                    score                 : this.scoreFinalGeral,
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
                    dtValidade            : this.dtValidade,
                    observacaoCliente     : this.observacaoCliente,
                    observacao            : this.observacao,
                    dtParcelas            : this.dtParcelas,
                    fretesPorCd           : this.fretesPorCd,
                    Idportalcotacoes      : this.Idportalcotacoes,
                    alreadySaved          : true,
                    savingStrData         : JSON.stringify(this.savingObjData),
                    recomendacaoRespondida: this.allRecAnswered,
                    hasPermissionERB      : this.hasPermissionERB,
                    pedidoComplementar    : this.pedidoComplementar,
                    recordId              : this.recordId,
                    newRecordId           : this.newRecordId,
                    isCoordenador         : this.isCoordenador,
                    orderListReturned     : JSON.stringify(this.cdList)
                }
            };    
        } else {
            compDefinition = {
                componentDef: "c:orderProduct",
                attributes: {
                    selectedProd              : prodCode,
                    getRecommendation         : getRecommendation,
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
                    enderecoEntregaId         : this.enderecoEntregaId,
                    enderecoEntrega           : this.enderecoEntrega,
                    enderecoEntregaContaOrdem : this.enderecoEntregaContaOrdem,
                    utilizarEnderecoAdicional : this.utilizarEnderecoAdicional,
                    observacao                : this.observacao,
                    observacaoNF              : this.observacaoNF,
                    observacaoPedido          : this.observacaoPedido,
                    dtParcelas                : this.dtParcelas,
                    fretesPorCd               : this.fretesPorCd,
                    Idportalcotacoes          : this.Idportalcotacoes,
                    createOrderDt             : this.createOrderDt,
                    recomendacaoRespondida    : this.allRecAnswered,
                    hasPermissionERB          : this.hasPermissionERB,
                    alreadySaved              : true,
                    savingStrData             : JSON.stringify(this.savingObjData),
                    newRecordId               : this.newRecordId,
                    pedidoComplementar        : this.pedidoComplementar,
                    cnpjCd                    : this.cnpjCd,
                    score                     : this.scoreFinalGeral,
                    orderListReturned         : JSON.stringify(this.cdList)
                }
            };
        }

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

    handleSendToApprovalOrderOrOpp() {
        this.fillHeader();
        if (this.isBudget && !this.isEdit) {
            swal("Ops!", "Em desenvolvimento!", "warning");
        } else if (!this.isBudget && !this.isEdit) {
            swal("Ops!", "Em desenvolvimento!", "warning");
        } else if (this.isBudget && this.isEdit) {
            swal("Ops!", "Em desenvolvimento!", "warning");
        } else {
            swal("Ops!", "Em desenvolvimento!", "warning");
        }
    }

    checkDuplicateDates() {
        let hasError = false;
        var today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate(), 0);
        console.log(this.receivedDtList);
        this.receivedDtList.forEach(item => {
            let currentDate = new Date(new Date(item).getFullYear(), new Date(item).getMonth(), new Date(item).getDate() + 1, 0);
            if (currentDate < today){
                hasError = true;
            }
        })

        return hasError;
    }

    handleSaveOrderOrOpp(event) {
        this.fillHeader();
        this.disableButtons();
        let sendToApp = event.target.value == "true" ? true : false;
        this.generateBudgetOrOrder = sendToApp;
        console.log(this.cdList);
        console.log(this.headerInfoData);
        console.log(this.recordId);

        console.log(JSON.stringify(this.cdList));
        console.log(JSON.stringify(this.headerInfoData));

        console.log('isEdit? ' + this.isEdit);
        console.log('isBudget? ' + this.isBudget);

        if (this.goToCheckout) {
            console.log('Salvar pedido integradora');
            this.checkOperationType(false);
            this.goToCheckout = false;
            return;
        }

        if (this.checkDuplicateDates()) {
            console.log('funfou');
            swal("Aviso!", "Verificar datas de parcelas!", "warning");
            this.enableButtons();
            return;
        }

        if (this.parcelamentoManual) {
            if (this.receivedDtList.length == 0) {
                swal("Aviso!", `Parcelas obrigatórias pelo tipo de condição de pagamento escolhida!`, "warning");
                this.enableButtons();
                return;
            }
        }
        if (sendToApp && this.isBudget || !this.isBudget) {
            if (this.cdList.length == 0) {
                swal("Aviso!", `Obrigatório adicionar produtos para realizar está ação!`, "warning");
                this.enableButtons();
                return;
            }
        }
        if (this.freteNecessario) {
            let error = false;
            this.receivedFreightList.forEach(cd => {
                if (!cd) {
                    error = true;
                }
            });
            if (this.receivedFreightList.length == 0 || this.cdListFilter.length != this.cdFreightList.length || error) {
                swal("Aviso!", `Obrigatório registrar valores de frete por CD!`, "warning");
                this.enableButtons();
                return;
            }
        }
        let allInvalidItems = [];
        let allInvalidSeqOCItems = [];
        this.cdList.forEach(selectedCd => {
            if (selectedCd.valorCampanha != 0 && selectedCd.caixa < selectedCd.valorCampanha) {   
                allInvalidItems.push(selectedCd.prodCode + ' - ' + selectedCd.cds);
            }
            if (selectedCd.SequenciaOC) {
                var sequenciaOCLength = selectedCd.SequenciaOC.toString().length;
                if (sequenciaOCLength > 6) {
                    allInvalidSeqOCItems.push(selectedCd.prodCode + ' - ' + selectedCd.SequenciaOC);                    
                }
            }
        });
        if (allInvalidItems.length > 0) {
            let allInvalidConcat = allInvalidItems.join('; \n');
            swal("Aviso!", `Produto(s) ${allInvalidConcat} possui(em) valor menor que o valor da campanha!`, "warning");
            this.enableButtons();
            return;
        }
        if (allInvalidSeqOCItems.length > 0) {
            let allInvalidConcat = allInvalidSeqOCItems.join(', ');
            swal("Aviso!", `Sequência OC do(s) produto(s) ${allInvalidConcat} possui(em) mais de 6 caracteres!`, "warning");
            this.enableButtons();
            return;
        }
        if (this.pedidoComplementar) {
            getComplementOrderSituation({ ordId: this.recordId })
                .then(result => {
                    console.log('getComplementOrderSituation: entrou certo!');
                    console.log(result);
                    if (result) {
                        swal({
                            title: "Aviso!",
                            text: "O pedido original possui pedidos ainda não integrados com o ERP, se desejar prosseguir com esse pedido poderá consumir a reserva que seria destinada ao pedido original. Continuar mesmo assim?",
                            icon: "warning",
                            buttons: {
                                Cancelar: {
                                    text: "Não",
                                    value: true
                                },
                                Sim: {
                                    value: "Sim",
                                },
                            },
                            dangerMode: true,
                        })
                            .then((value) => {
                                console.log(value)
                                switch (value) {
                                    case "Sim":
                                        this.checkOperationType(sendToApp);
                                        break;
                                    default:
                                        this.enableButtons();
                                        return;
                                }
                            });
                    } else {
                        this.checkOperationType(sendToApp);
                    }
                }).catch(error => {
                    console.log('getComplementOrderSituation: entrou no erro!');
                    console.log(error);
                });
        } else if (this.isBudget || !sendToApp) {
            this.checkOperationType(sendToApp);
        } else {
            getAccountData({ accId: this.clienteEmissorId })
                .then(result => {
                    console.log('result ' + JSON.stringify(result));
                    if (!result.ClienteBloqueado) {
                        console.log('bloqueado');
                        swal({
                            title: ClienteInativoInsert,
                            text: ClienteInativoInsertPositivo,
                            icon: "warning",
                            buttons: ["Cancelar", "Continuar"],
                            dangerMode: true,
                        }).then((willSalve) => {
                                console.log('willSalve ' + willSalve);
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
                                                            this.checkOperationType(sendToApp);
                                                        } else {
                                                            this.enableButtons();
                                                            return;
                                                        }
                                                    });
                                                } else {
                                                    this.checkOperationType(sendToApp);
                                                }
                                            }).catch(error => {
                                                console.log('getAccountData isEdit: entrou no erro!');
                                                console.log(error);
                                            })
                                    } else {
                                        this.checkOperationType(sendToApp);
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
                                                this.checkOperationType(sendToApp);
                                            } else {
                                                this.enableButtons();
                                                return;
                                            }
                                        });
                                    } else {
                                        this.checkOperationType(sendToApp);
                                    }
                                }).catch(error => {
                                    console.log('getAccountData isEdit: entrou no erro!');
                                    console.log(error);
                                })
                        }else{
                            this.checkOperationType(sendToApp);
                        }
                    }
                }).catch(error => {
                    console.log('getAccountData isEdit: entrou no erro!');
                    console.log(error);
                })
        }
    }

    keepSavingOrEditing() {
        this.disableButtons();
        console.log('Manter registro salvo.');
        this.automaticSave = true;
        this.fillHeader();
        if ((this.isBudget)) {
            if (this.cdList.filter(cd => cd.selected != false).length > 0) {
                console.log('orçamento editado');
                this.callEditBudget();
            }
        } else {
            if (this.cdList.filter(cd => cd.selected != false).length > 0) {
                console.log('pedido editado');
                this.callEditOrder();
            }
        }
    }

    checkInterval(result) {
        if (this.automaticSave) {
            console.log(result);
            this.newRecordId = result;
            this.savingObjData = {
                registerName: this.newRecordId,
                sobject: this.isBudget ? 'Orçamento' : 'Pedido',
                lastSaveDate: (new Date()).toLocaleTimeString()
            }
            this.enableButtons();
        } else {
            //clearInterval(this.saveInterval);
            this.handleNavigateMix(result);
        }
    }

    checkOperationType(sendToApp) {
        this.cdList = this.cdList.filter(cd => cd.selected != false);
        this.handleIndexOrder();
        this.automaticSave = false;
        if (this.isBudget) {
            // EDITAR ORÇAMENTO
            this.callEditBudget(sendToApp);
        } else {
            // EDITAR PEDIDO
            if (this.hasComplementOrder && !this.keepComplementOrder) {
                this.dealOrderWithComplement(sendToApp, false);
            } else {
                this.callEditOrder(sendToApp);
            }
        }
    }

    callEditBudget(sendToApp) {
        this.isSaving = true;
        // EDITAR ORÇAMENTO
        editBudget({ budget: JSON.stringify(this.cdList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: this.automaticSave ? false : sendToApp, recordId: this.newRecordId ? this.newRecordId : this.recordId, hasComplementOrder: false })
            .then(result => {
                this.isSaving = false;
                console.log(result);
                if (result.length == 18) {
                    this.checkInterval(result);
                    if (!this.automaticSave) {
                        clearInterval(this.saveInterval);
                        swal("Show!", "Orçamento editado com sucesso!", "success");
                    } else {
                        console.log('edição de orçamento automática realizada');
                    }
                } else {
                    swal("Ops!", "Ocorreu algum problema ao editar o orçamento! Tente novamente mais tarde!", "Warning");
                    this.enableButtons();
                }
            }).catch(error => {
                this.isSaving = false;
                swal("Ops!", "Erro ao gerar orçamento! Verifique com o administrador!", "error");
                this.enableButtons();
                console.log(error);
            });
    }

    handleEditOrder() {
		this.disableButtons();
		this.fillHeader();

		this.callEditLabOrder();
		return;
	}

    callEditLabOrder() {
        // EDITAR PEDIDO
        this.isSaving = true;
        this.disableLabOrderSave = true;
        editLabOrder({ jsonOrder: JSON.stringify(this.cdList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: false, recordId: this.newRecordId ? this.newRecordId : this.recordId, keepComplementOrder: false, isAutomaticSave: false })
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

    callEditOrder(sendToApp) {
        // EDITAR PEDIDO
        this.isSaving = true;
        editOrder({ jsonOrder: JSON.stringify(this.cdList), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: this.automaticSave ? false : sendToApp, recordId: this.newRecordId ? this.newRecordId : this.recordId, keepComplementOrder: this.keepComplementOrder, isAutomaticSave: this.automaticSave })
        .then(result => {
            console.log(result);
            if (result.length == 18) {
                this.isSaving = false;
                    if (this.hasComplementOrder && !this.keepComplementOrder && !this.automaticSave) {
                        this.callGenerateComplementOrder(result);
                    } else {
                        this.checkInterval(result);
                        if (!this.automaticSave) {
                            clearInterval(this.saveInterval);
                            swal("Show!", "Pedido editado com sucesso!", "success");
                        } else {
                            console.log('edição de pedido automática realizada');
                        }
                    }
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

    callGenerateComplementOrder(ordId) {
        this.cdListComplement.forEach(cd => {
            cd.quantidade = cd.tipoConversao == 'M' ? (cd.quantidadeCx * parseFloat(cd.conversaoUnidadeCx)) : Number(cd.quantidadeCx / parseFloat(cd.conversaoUnidadeCx));
            cd.valorTotal = Number(cd.quantidadeCx) * Number(cd.caixa);
        })

        console.log('CD LIST PEDIDO PRA GERAR');
        console.log(JSON.parse(JSON.stringify(this.cdList)));
        console.log('CD LIST PEDIDO COMPLEMENTAR');
        console.log(JSON.parse(JSON.stringify(this.cdListComplement)));

        this.buildCalcAllScoreObj(true);
        console.log(JSON.parse(JSON.stringify(this.calcAllScoreObj)));

        this.getSpecificMarginCalc(false, true, ordId);
    }

    dealOrderWithComplement(sendToApp, isComplement) {
        var lstCdId = [];
        this.cdList.forEach(cd => {
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
            this.cdList = this.cdList.filter(cdList => cdList.cdId != cdId);
        })

        this.buildCalcAllScoreObj(isComplement);
        console.log(this.calcAllScoreObj);
        this.getSpecificMarginCalc(sendToApp, isComplement, null);
    }

    getSpecificMarginCalc(sendToApp, isComplement, ordId) {
        calcAllProducts({ clListString: JSON.stringify(this.calcAllScoreObj) })
            .then(result => {
                let resultJson = JSON.parse(result);
                console.log('result json '+resultJson);
                this.calcAllScoreObj.forEach(calcObj => {
                    for (var i = 0; i < resultJson['cdMap'][calcObj.cdId].length; i++) {
                        if ((calcObj.cdId + '_' + calcObj.productCode) == (resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode)) {
                            let index
                            if (isComplement) {
                                index = this.cdListComplement.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
                            } else {
                                index = this.cdList.findIndex(item => item.cdId == resultJson['cdMap'][calcObj.cdId][i].cdId + '_' + resultJson['cdMap'][calcObj.cdId][i].productCode);
                            }

                            const scoreBU = Number(resultJson['results'][calcObj.productBu]['scoreFinal'].toFixed(2));
                            const scoreMix = Number(resultJson['results'][calcObj.productBu]['scoreMix'].toFixed(2));
                            const scoreItem = Number(resultJson['cdProdMap'][calcObj.cdId + '_' + calcObj.productCode]['scoreFinal'].toFixed(2));
                            const margemTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreDenominator'].toFixed(2));
                            const margemAlvoTotalCd = Number(resultJson['results'][calcObj.cdId]['scoreNumerador'].toFixed(2));
                            const scoreCd = Number(resultJson['results'][calcObj.cdId]['scoreFinal'].toFixed(2));

                            if (isComplement) {
                                this.cdListComplement[index] = {
                                    ...this.cdListComplement[index],
                                    score: scoreCd,
                                    scoreBU,
                                    scoreMix,
                                    scoreItem,
                                    margemTotalCd,
                                    margemAlvoTotalCd
                                }
                            } else {
                                this.cdList[index] = {
                                    ...this.cdList[index],
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
                    this.margemAtualGeral = Number(Number(resultJson['results']['Order']['scoreDenominator'])).toFixed(2) + '%';
                    this.margemAtualAlvo = Number(Number(resultJson['results']['Order']['scoreNumerador'])).toFixed(2) + '%';
                    this.scoreFinalGeral = Number(Number(resultJson['results']['Order']['scoreFinal'])).toFixed(2) + '%';
                } else {
                    this.margemAtualGeral = '';
                    this.margemAtualAlvo = '';
                    this.scoreFinalGeral = '';
                }

                this.fillHeader();
                if (isComplement) {
                    generateComplementOrder({ complementOrder: JSON.stringify(this.cdListComplement), headerInfo: JSON.stringify(this.headerInfoData), sendToApproval: false, complementOrdId: ordId })
                        .then(result => {
                            console.log(result);
                            if (result.length == 18) {
                                clearInterval(this.saveInterval);
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
                } else {
                    this.callEditOrder(sendToApp);
                }
            }).catch(error => {
                console.log('calcAllProducts: entrou no erro!');
                console.log(error);
            });
    }

    handleGenerateOrderByOpp() {
        this.disableButtons();
        this.isLoadingScore = true;

        let prodList = [];

        let cdObj = {};

        let cdObjIndex = {};

        this.cdList.forEach((cd, index)=> {
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

        let allInvalidSeqOCItems = [];
        for (var i = 0; i < this.cdList.length; i++) {
            if (this.cdList[i].estoque != null && this.cdList[i].estoque != undefined) {
                if (this.cdList[i].quantidadeCx > this.cdList[i].estoque) {
                    listProductError.push(this.cdList[i].nome + ' - ' + this.cdList[i].cds); 
                }
            }
            if (this.cdList[i].SequenciaOC) {
                var sequenciaOCLength = this.cdList[i].SequenciaOC.toString().length;
                if (sequenciaOCLength > 6) {
                    allInvalidSeqOCItems.push(this.cdList[i].prodCode + ' - ' + this.cdList[i].SequenciaOC);
                }
            }
        }
        if (allInvalidSeqOCItems.length > 0) {
            let allInvalidConcat = allInvalidSeqOCItems.join(', ');
            swal("Aviso!", `Sequência OC do(s) produto(s) ${allInvalidConcat} possui(em) mais de 6 caracteres!`, "warning");
            this.enableButtons();
            this.isLoadingScore = false;
            return;
        }

        getMalha({ clienteCGC: this.clienteEmissorCGC.replace(/[^\w\s]/gi, ''), productCode: prodList.join(','), calcMargem: false, pricebookExternalId: null, condPagamento: this.condicaoPagamento, isForaMalha: true  })
            .then(result => {
                console.log('getMalha: entrou certo!');
                console.log(result);
                if (result != null) {
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
                                    const product = cdObj[item.codprotheus + '_' + cdItem.cnpj];
                                    if (product != undefined) {
                                        const cd = item.cds.find(cd => cd.cnpj == product.cnpjCd);
                                        if (cd.saldo < product.qtd) {
                                            listProductError.push(product.nome + ' - ' + cd.filial);
                                        }
                                    }
                                });
                            } else {
                                listProductNotFound.push(item.msgerro);
                            }
                        })
                    }
                }
                this.isLoadingScore = false;
                if (listProductNotFound.length > 0) {
                    swal('Aviso!', `Erro na busca de estoque: ${listProductNotFound.join(' ')}`, 'warning');
                    this.enableButtons();
                    return;
                } else {
                    this.enableButtons();
                    this.handleNavigateInsertOrder();
                    return;
                }

            }).catch(error => {
                swal("Ops!", "Erro ao verificar estoque! Verifique com o administrador.", "error");
                this.enableButtons();
                this.isLoadingScore = false;
                console.log('getMalha: entrou no erro!');
                console.log(error);
            })
    }
    
    swalErroMalha() {
        swal('Erro', `Consulta da malha indisponível`, 'error');
    }

    disableButtons() {
        this.isInstallmentDisabled = true;
        this.isSaveDisabled = true;
        this.isAddItemDisabled = true;
        this.isSendToApprovalDisabled = true;
        this.isGenerateOrderByOpp = true;
    }

    enableButtons() {
        if (!this.goToCheckout) {
            this.isInstallmentDisabled = false;
            this.isSaveDisabled = false;
            this.isAddItemDisabled = false;
            this.isSendToApprovalDisabled = false;
            this.isGenerateOrderByOpp = false;
        }
    }

    handleNavigateMix(result) {
        this.cdList.forEach(item => {
            item.disableCheckbox = true;
        });
        this.handlePublishCloseTab(); // close window after navigate
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: result,
                objectApiName: this.isBudget ? 'opportunity' : 'order',
                actionName: 'view'
            }
        });
    }

    closeCurrentTab() {
        var close = true;
        const closeclickedevt = new CustomEvent('closeclicked', {
            detail: { close },
        });
        // Fire the custom event
        this.dispatchEvent(closeclickedevt);
    }
    @wire(MessageContext)
    messageContext;

    handlePublishCloseTab() {
        publish(this.messageContext, closeConsoleTab);
    }

    handleProductSelected(event){
        console.log('Capturou o evento do componente filho', event.detail);
        if (event.detail.action != "close") {
            try{
                let selected = JSON.parse(event.detail);
                for (let i = 0; i < this.cdListCloneSelected.length; i++) {
                    if (this.cdListCloneSelected[i].id === selected.prodId) {
                        this.cdListCloneSelected[i].unidadeMedida = selected.value;
                    }
                }
                for (let i = 0; i < this.cdList.length; i++) {
                    if (this.cdList[i].id === selected.prodId) {
                        this.cdList[i].unidadeMedida = selected.value;
                    }
                }
                this.prodListMeas = JSON.stringify(this.cdList);
            }catch(error){
                console.log('handleProductSelected error', error);
            }
        }

        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}