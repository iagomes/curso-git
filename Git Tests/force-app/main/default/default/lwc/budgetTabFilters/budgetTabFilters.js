import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { doCalloutWithStdResponse } from 'c/calloutService';
import getUsersPicklist from '@salesforce/apex/BudgetTabController.getUsersPicklist';
import getMesa from '@salesforce/apex/BudgetTabController.getMesa';
import getCategoria from '@salesforce/apex/BudgetTabController.getCategoria';
import getVendedor from '@salesforce/apex/BudgetTabController.getVendedor';
import { formatarData, stringToDate } from 'c/utilities';
import Id from '@salesforce/user/Id';
import EstadosJson from '@salesforce/resourceUrl/EstadosJson';

export default class BudgetTabFilters extends LightningElement {

    showFilters = false;
    statusSearch = [];
    vendedorSelected = [];
    teamMember = [];
    mesaSelected = null;
    mesaOptions = [];
    categoriaSelected = null;
    categoriaOptions = [];
    quoteIntegratorId = null;
    quoteType = null;
    cnpjCliente = null;
    nomeCliente = null;
    produto = null;
    ufCliente = [];
    cidadeCliente = null;
    vencimentoCotacao = {};
    vencimentoCotacaoText = null;
    showModalDataVencimento = false;
    @api expiredValue = false;
    statesCities = [];
    states = [];
    cities = [];
    
    vdiPickList = [];
    vdePickList = [];
    
    
    @api orderBy = 'CreatedDate';
    lastRecord;
    @api itemsPerPage;
    @api queryLimit;

    @track canalEntradaSelected = [];

    getSetor(){
        let scope = this;
        doCalloutWithStdResponse(scope, getUsersPicklist, {}).then(response => {
            let vdi2List = JSON.parse(response.data.vdi);
            scope.vdiPickList = vdi2List.map(opt => {
                return {value: opt.value, label: opt.data, isSelected: opt.selected};
            });
            scope.teamMember = [{...scope.vdiPickList[0]}];
            let vde2List = JSON.parse(response.data.vde);
            scope.vdePickList = vde2List.map(opt => {
                return {value: opt.value, label: opt.data, isSelected: opt.selected};
            });
        }).catch(error => {
            console.error('Error to get Users', JSON.stringify(error));
        });
    }

    executeGetMesa(){
        let scope = this;
        doCalloutWithStdResponse(scope, getMesa, {}).then(response => {
            let mesa2List = JSON.parse(response.data);
            scope.mesaOptions = mesa2List.map(opt => {
                return {value: opt.value, label: opt.data, isSelected: opt.selected};
            });
        }).catch(error => {
            console.error('Error to get Users', JSON.stringify(error));
        });
    }

    executeGetCategoria(){
        let scope = this;
        doCalloutWithStdResponse(scope, getCategoria, {}).then(response => {
            let categoria2List = JSON.parse(response.data);
            scope.categoriaOptions = categoria2List.map(opt => {
                return {value: opt.value, label: opt.data, isSelected: opt.selected};
            });
            
        }).catch(error => {
            console.error('Error to get category', JSON.stringify(error));
        });
    }

    value = 'inProgress';

    get options() {
        return [
            { label: 'New', value: 'new' },
            { label: 'In Progress', value: 'inProgress' },
            { label: 'Finished', value: 'finished' },
        ];
    }

    get canalEntradaSelectedLabel(){
        let result;
        if(this.canalEntradaSelected){
            let filteredItems = this.canalEntradaSelected.filter(item => {return item.value != ""});
            result = filteredItems.length > 0 ? "Canal de vendas: " + filteredItems.map(item => {return item.label}).join(", ") : false;
        }
        return result;
    }

    get mesaSelectedLabel(){
        let result;
        if(this.mesaSelected){
            let filteredItems = this.mesaSelected.filter(item => {return item.value != ""});
            result = filteredItems.length > 0 ? "Mesa: " + filteredItems.map(item => {return item.label}).join(", ") : false;
        }
        return result;
    }

    get categoriaSelectedLabel(){
        let result;
        if(this.categoriaSelected){
            let filteredItems = this.categoriaSelected.filter(item => {return item.value != ""});
            result = filteredItems.length > 0 ? "Categoria: " + filteredItems.map(item => {return item.label}).join(", ") : false;
        }
        return result;
    }

    get quoteIntegratorIdLabel(){
        return this.quoteIntegratorId ? "ID da cotação na Integradora: " + this.quoteIntegratorId: false;
    }

    get vendedorSelectedLabel(){
        let result;
        if(this.vendedorSelected){
            let filteredItems = this.vendedorSelected.filter(item => {return item.value != ""});
            result = filteredItems.length > 0 ? "Representante (VDE): " + filteredItems.map(item => {return item.label}).join(", ") : false;
        }
        return result;
    }

    get teamMemberLabel(){
        let result;
        if(this.teamMember){
            let filteredItems = this.teamMember.filter(item => {return item.value != ""});
            result = filteredItems.length > 0 ? "Vendedor (VDI): " + filteredItems.map(item => {return item.label}).join(", ") : false;
        }
        return result;
    }


    get quoteTypeLabel(){
        return this.quoteType ? "Tipo cotação: " + this.quoteType : false;
    }

    get userLabel(){
        return this.teamMember ? "Vendedor: " + this.teamMember.label : false;
    }

    get cnpjClienteLabel(){
        return this.cnpjCliente ? "CNPJ do cliente: " + this.cnpjCliente : false;
    }

    get nomeClienteLabel(){
        return this.nomeCliente ? "Nome do cliente: " + this.nomeCliente : false;
    }

    get produtoLabel(){
        return this.produto ? "Produto: " + this.produto : false;
    }

    get ufClienteLabel(){
        return this.ufCliente && this.ufCliente.length > 0 ? "UF do Cliente: " + this.ufCliente.join(", ") : null;
    }

    get cidadeClienteLabel(){
        return this.cidadeCliente && this.cidadeCliente.length > 0 ? "Cidade do Cliente: " + this.cidadeCliente.join(", ") : null;
    }

    get statusSearchLabel(){
        return this.statusSearch && this.statusSearch.length > 0 ? "Status: " + this.statusSearch.join(", ") : null;
    }

    get vencimentoCotacaoLabel(){
        return this.vencimentoCotacaoText ? "Data de Vencimento: " + this.vencimentoCotacaoText : null;
    }

    isRendered = false;
    renderedCallback() {
        if(!this.isRendered){
            this.isRendered = true;
            this.enforceStyles();
        }
    }

    connectedCallback(){
        this.getStatesCitiesJson();
        this.getSetor();
        this.executeGetMesa();
        this.executeGetCategoria();
    }

    getStatesCitiesJson(){
        let request = new XMLHttpRequest();
        request.open("GET", EstadosJson, false);
        request.send(null);

        this.statesCities = JSON.parse(request.responseText);
        this.states = this.statesCities.map(st => {
            return {value: st.sigla, label: st.nome, isSelected: false};
        });
    }

    enforceStyles(){
        let style = document.createElement('style');
        style.innerText = `
            c-budget-tab-filters .modal-data-vencimento .slds-modal__content {
                display: inline-grid;
            }
            
            c-budget-tab-filters .modal-data-vencimento .slds-modal__content .btn-fixed-date {
                margin: 5px auto;
            }
            
            c-budget-tab-filters .modal-data-vencimento .slds-modal__content .btn-fixed-date button {
                width: 200px;
            }
            
            c-budget-tab-filters .modal-data-vencimento .slds-modal__content .btn-delete {
                margin: 0 5px;
            }
            
            c-budget-tab-filters .modal-data-vencimento .slds-modal__content lightning-input {
                margin: 5px 30px;
            }
            
            c-budget-tab-filters .modal-data-vencimento .slds-modal__container {
                min-width: 450px !important;
                max-width: 450px !important;
                width: 450px !important;
            }
        `;
        this.template.querySelector('.style-element').appendChild(style);
    }

    vencimentoCotacaoRemove(event){
        this.vencimentoCotacao = {};
        this.vencimentoCotacaoText = null;
        this.doSearch();
    }

    canalVendasRemove(event){
        this.canalEntradaSelected = [];
        this.template.querySelector('c-dropdown-input[name="canalEntrada"]').clearSelections(true);
        this.doSearch();
    }

    quoteIntegratorIdRemove(event){
        this.quoteIntegratorId = null;
        this.doSearch();
    }

    vendedorSelectedRemove(event){
        this.vendedorSelected = [];
        this.template.querySelector('c-dropdown-input[name="vdePickList"]').clearSelections(true);
        this.doSearch();
    }

    teamMemberRemove(event){
        this.teamMember = [];
        this.template.querySelector('c-dropdown-input[name="vdiPickList"]').clearSelections(true);
        this.doSearch();
    }

    quoteTypeRemove(event){
        this.quoteType = null;
        this.doSearch();
    }

    cnpjClienteRemove(event){
        this.cnpjCliente = null;
        this.doSearch();
    }

    mesaRemove(event){
        this.mesaSelected = null;
        this.template.querySelector('c-dropdown-input[name="mesa"]').clearSelections(true);
        this.doSearch();
    }

    categoriaRemove(event){
        this.categoriaSelected = null;
        this.template.querySelector('c-dropdown-input[name="categoria"]').clearSelections(true);
        this.doSearch();
    }

    nomeClienteRemove(event){
        this.nomeCliente = null;
        this.doSearch();
    }

    produtoRemove(event){
        this.produto = null;
        this.doSearch();
    }
    ufClienteRemove(event){
        this.ufCliente = [];
        this.template.querySelector('c-dropdown-input[name="uf"]').clearSelections(true);
        this.doSearch();
    }

    cidadeClienteRemove(event){
        this.cidadeCliente = null;
        this.template.querySelector('c-dropdown-input[name="city"]').clearSelections(true);
        this.doSearch();
    }

    statusSearchRemove(event){
        this.statusSearch = [];
        if(this.statusOpts){
            this.statusOpts.forEach(opt => {opt.selected = false});
        }
        this.doSearch();
    }


    // getSearchStatus(){
    //     return this.statusSearch && this.statusSearch.length > 0 ? this.statusSearch.join(';') : null;
    // }

    handleChange(event) {
        this.value = event.detail.value;
    }

    // setUser(event){
    //     this.teamMember = event.target.value;
    // }

    setQuoteIntegratorId(event) {
        this.quoteIntegratorId = event.target.value ? event.target.value : '';
    }

    setQuoteType(event) {
        this.quoteType = event.target.value ? event.target.value : '';
    }

    setCNPJCliente(event) {
        this.cnpjCliente = event.target.value ? event.target.value : '';
    }

    setNomeCliente(event) {
        this.nomeCliente = event.target.value ? event.target.value : '';
    }

    setProduto(event) {
        this.produto = event.target.value ? event.target.value : '';
    }

    get hasFilters(){
        return (
            this.canalEntradaSelectedLabel ||
            this.quoteIntegratorIdLabel ||
            this.vendedorSelectedLabel || 
            this.teamMemberLabel ||
            this.quoteTypeLabel ||
            this.cnpjClienteLabel ||
            this.mesaSelectedLabel ||
            this.categoriaSelectedLabel ||
            this.nomeClienteLabel ||
            this.produtoLabel ||
            this.ufClienteLabel ||
            this.cidadeClienteLabel ||
            this.statusSearchLabel ||
            this.vencimentoCotacaoLabel
        );
    }

    statusOpts = [
        { label: 'Novo', value: 'Novo', selected: true },
        { label: 'Em digitação', value: 'Em digitação', selected: true },
        { label: 'Aguardando Integração', value: 'Aguardando Integração', selected: false },
        { label:'Falha na integração', value: 'Falha na integração', selected: false },
        { label: 'Respondida', value: 'Respondida', selected: false },
        { label: 'Sem Retorno', value: 'Sem Retorno', selected: false },
        { label: 'Gerar Pedido', value: 'Gerar Pedido', selected: false },
        { label: 'Encerrado', value: 'Encerrado', selected: false },
        { label: 'Não Respondida', value: 'Não Respondida', selected: false },
        { label: 'Cancelada', value: 'Cancelada', selected: false },
        // { label: 'Aprovado', value: 'Aprovado', selected: false },
        // { label: 'Reprovado', value: 'Reprovado', selected: false },
    ];

    get statusOptions(){
        for(let i = 0; i < this.statusOpts.length; i++){
            this.statusOpts[i].index = i;
            this.statusOpts[i].isFirstElement = false;
            this.statusOpts[i].isLastElement = false;
            this.statusOpts[i].class = 'slds-button slds-button_neutral '+this.statusOpts[i].value.replaceAll(' ','')+' '+this.statusOpts[i].selected; 
        }
        this.statusOpts[0].isFirstElement = true;
        this.statusOpts[this.statusOpts.length - 1].isLastElement = true;
        return this.statusOpts;
    }

    get vencimentoCotacaoDate1(){
        return this.vencimentoCotacaoText ? this.vencimentoCotacao.date1 : null;
    }

    get vencimentoCotacaoDate2(){
        return this.vencimentoCotacaoText ? this.vencimentoCotacao.date2 : null;
    }

    handleStatusSelectedClick(event) {
        if(event.target && event.target.innerHTML){
            this.statusSearch = [];
            this.statusOpts.forEach(opt => {
                if(opt.value == event.target.innerHTML){
                    opt.selected = true;
                }
                if(opt.selected){
                    this.statusSearch = [...this.statusSearch, opt.value];
                }
            });
            this.statusOpts = [...this.statusOpts];
        }
    }

    handleStatusUnselectedClick(event) {
        if(event.target && event.target.innerHTML){
            this.statusSearch = [];
            this.statusOpts.forEach(opt => {
                if(opt.value == event.target.innerHTML){
                    opt.selected = false;
                }
                if(opt.selected){
                    this.statusSearch = [...this.statusSearch, opt.value];
                }
            });
            this.statusOpts = [...this.statusOpts];
        }
    }

    @api toggleFiltersVisibility(value) {
        if(value === undefined || typeof value === 'object'){
            this.showFilters = !this.showFilters;
        } else {
            this.showFilters = value;
        }
        if(this.showFilters){
            this.template.querySelector('div.content > div.filters').classList.remove('slds-hide');
        } else {
            this.template.querySelector('div.content > div.filters').classList.add('slds-hide');
        }
        this.dispatchEvent(new CustomEvent('filtervisibilitychange'));
    }

    @api setSearchCritereas(value, clearOldFilters){
        let scope = this;
        
        if(value && typeof value === 'object'){
            if(clearOldFilters){
                let canalEntrada = scope.template.querySelector('c-dropdown-input[name="canalEntrada"]')
                canalEntrada.clearSelections(true);
                let vdiPickList = scope.template.querySelector('c-dropdown-input[name="vdiPickList"]')
                vdiPickList.clearSelections(true);
                let vdePickList = scope.template.querySelector('c-dropdown-input[name="vdePickList"]')
                vdePickList.clearSelections(true);
                let mesa = scope.template.querySelector('c-dropdown-input[name="mesa"]')
                mesa.clearSelections(true);
                let categoria = scope.template.querySelector('c-dropdown-input[name="categoria"]')
                categoria.clearSelections(true);
                let uf = scope.template.querySelector('c-dropdown-input[name="uf"]')
                uf.clearSelections(true);
                let city = scope.template.querySelector('c-dropdown-input[name="city"]')
                city.clearSelections(true);
                if(value.hasOwnProperty('canalEntradaSelected') && !!value.canalEntradaSelected && value.canalEntradaSelected.length > 0){
                    scope.canalEntradaSelected = [];
                    scope.canalEntradaSelected = value.canalEntradaSelected.map(ce =>{return {value: ce, label: ce, isSelected: true}});
                    canalEntrada.setSelectedOptions(value.canalEntradaSelected);
                } else {
                    scope.canalEntradaSelected = [];
                }

                if(value.hasOwnProperty('vendedorSelected') && !!value.vendedorSelected && value.vendedorSelected.length > 0){
                    scope.vendedorSelected = [];
                    scope.vendedorSelected = [...scope.vdePickList.filter(tm =>{return value.vendedorSelected.includes(tm.value)})];
                    vdePickList.setSelectedOptions(value.vendedorSelected);
                } else {
                    scope.vendedorSelected = [];
                }
                    
                if(value.hasOwnProperty('categoriaSelected') && !!value.categoriaSelected && value.categoriaSelected.length > 0){
                    scope.categoriaSelected = [];
                    scope.categoriaSelected = [...scope.categoriaOptions.filter(tm =>{return value.categoriaSelected.includes(tm.value)})];
                    categoria.setSelectedOptions(value.categoriaSelected);
                } else {
                    scope.categoriaSelected = [];
                }

                if(value.hasOwnProperty('mesaSelected') && !!value.mesaSelected && value.mesaSelected.length > 0){
                    scope.mesaSelected = [];
                    scope.mesaSelected = [...scope.mesaOptions.filter(tm =>{return value.mesaSelected.includes(tm.value)})];
                    mesa.setSelectedOptions(value.mesaSelected);
                } else {
                    scope.mesaSelected = [];
                }

                if(value.hasOwnProperty('teamMember') && !!value.teamMember && value.teamMember.length > 0){
                    scope.teamMember = [];
                    let tMemberList = value.teamMember.filter(tm =>{return tm != 'userId'});
                    if(value.teamMember.includes('userId')){
                        tMemberList.push(Id);
                    }
                    
                    scope.teamMember = scope.vdiPickList.filter(tm =>{return tMemberList.includes(tm.value)});
                    vdiPickList.setSelectedOptions(tMemberList);

                } else {
                    scope.teamMember = [];
                }

                if(value.hasOwnProperty('ufCliente')){
                    scope.ufCliente = value.ufCliente;
                    let estados = this.statesCities.filter(st =>{return this.ufCliente.includes(st.sigla)});
                    scope.cities = estados.map(est =>{return est.cidades}).flat(1).map(ct =>{return {value: ct, label: ct, isSelected: !!(value.cidadeCliente?.includes(ct))};});
                    uf.setSelectedOptions(value.ufCliente);
                }else{
                    scope.ufCliente = [];
                    scope.cities = [];
                }

                if(value.hasOwnProperty('cidadeCliente')){
                    scope.cidadeCliente = value.cidadeCliente;
                }else{
                    scope.cidadeCliente = [];
                }

                if(value.hasOwnProperty('statusSearch')){
                    scope.statusSearch = value.statusSearch;

                }else{
                    scope.statusSearch = [];
                }
                
                scope.statusOpts = scope.statusOpts.map(opt => {
                    
                    if(value.statusSearch?.includes(opt.value)){
                        opt.selected = true;
                    }else{
                        opt.selected = false;
                    }
                    return opt;
                });

                scope.quoteIntegratorId = value.hasOwnProperty('quoteIntegratorId') ? value.quoteIntegratorId : null;
                scope.quoteType = value.hasOwnProperty('quoteType') ? value.quoteType : null;
                scope.cnpjCliente = value.hasOwnProperty('cnpjCliente') ? value.cnpjCliente : null;
                scope.nomeCliente = value.hasOwnProperty('nomeCliente') ? value.nomeCliente : null;
                scope.produto = value.hasOwnProperty('produto') ? value.produto : null;
                scope.queryLimit = value.hasOwnProperty('queryLimit') ? value.queryLimit : null;
                scope.vencimentoCotacao = value.hasOwnProperty('vencimentoCotacao') ? value.vencimentoCotacao : {};
                scope.setVencimentoFilter();
            }
        }
    }

    doSearch() {

        let detail = this.constructParams();
        this.dispatchEvent(new CustomEvent('btnfiltrarclick', {
            bubbles: true,
            detail: detail
        }));
    }

    sendFilters(){

        let detail = this.constructParams();
        this.dispatchEvent(new CustomEvent('btnsalvarclick', {
            bubbles: true,
            detail: detail
        }));
    }

    constructParams(){
        this.lastRecord = null;
         
        let detail = {
            statusSearch: this.statusSearch,
            canalEntradaSelected: this.canalEntradaSelected,
            vendedorSelected: this.vendedorSelected,
            teamMember: this.teamMember,
            quoteIntegratorId: this.quoteIntegratorId,
            quoteType: this.quoteType,
            cnpjCliente: this.cnpjCliente,
            mesaSelected: this.mesaSelected,
            categoriaSelected: this.categoriaSelected,
            nomeCliente: this.nomeCliente,
            produto: this.produto,
            ufCliente: this.ufCliente,
            cidadeCliente: this.cidadeCliente,
            vencimentoCotacao: this.vencimentoCotacao,
            orderBy: this.orderBy,
            lastRecord: this.lastRecord,
            itemsPerPage: this.itemsPerPage,
            queryLimit: this.queryLimit,
            vencimentoCotacaoText: this.vencimentoCotacaoText
        };
        return detail;
    }

    handleOptionSelection(customEvent) {
        let data = JSON.parse(customEvent.detail);
        if (data.field == 'canalEntrada') {
            this.canalEntradaSelected = data.selectedOptions;
        }
        else if (data.field == 'vdiPickList'){
            this.teamMember = data.selectedOptions.filter(item => {return item.value != "" && item.value !='%todos%'});
        }
        else if (data.field == 'vdePickList'){
            this.vendedorSelected = data.selectedOptions.filter(item => {return item.value != "" && item.value !='%todos%'});
        }
        else if (data.field == 'uf'){
            let ufResult = data.selectedOptions.filter(item => {return item.value != null && item.value != "" && item.value !='%todos%'});
            this.ufCliente = ufResult.map(uf => {return uf.value;});
            let estados = this.statesCities.filter(st =>{return this.ufCliente.includes(st.sigla)});
            this.cities = estados.map(est =>{return est.cidades}).flat(1).map(ct =>{return {value: ct, label: ct, isSelected: false};});
        }
        else if(data.field == 'city'){
            let ctResult = data.selectedOptions.filter(item => {return item.value != null && item.value != "" && item.value !='%todos%'});
            this.cidadeCliente = ctResult.map(ct => {return ct.value;});
        }
        else if (data.field == 'mesa'){
            this.mesaSelected = data.selectedOptions.filter(item => {return item.value != null && item.value != "" && item.value !='%todos%'});
        }
        else if (data.field == 'categoria'){
            this.categoriaSelected = data.selectedOptions.filter(item => {return item.value != null && item.value != "" && item.value !='%todos%'});
        }
    }

    setvencimentoCotacaoDe(event){
        
        if(!this.vencimentoCotacao){
            this.vencimentoCotacao = {};
        }
        this.vencimentoCotacao.last_n_days = undefined;
        this.vencimentoCotacao.yesterday = undefined;
        let enteredValue = event.target.value;
        if(this.vencimentoCotacao.date2){
            if(stringToDate(this.vencimentoCotacao.date2).getTime() <= stringToDate(enteredValue).getTime()){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Data inválida',
                    message: 'Por favor selecione uma data menor que a data final do filtro ("Até").',
                    variant: 'error',
                }));
            } else {
                this.vencimentoCotacao.date1 = enteredValue;
            }
        } else {
            this.vencimentoCotacao.date1 = enteredValue;
        }

        this.setVencimentoFilter();
    }

    setVencimentoCotacaoAte(event){
        
        if(!this.vencimentoCotacao){
            this.vencimentoCotacao = {};
        }
        this.vencimentoCotacao.last_n_days = undefined;
        this.vencimentoCotacao.yesterday = undefined;
        let enteredValue = event.target.value;

        
            if(this.vencimentoCotacao.date1){
                
                if(stringToDate(this.vencimentoCotacao.date1).getTime() >= stringToDate(enteredValue).getTime()){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Data inválida',
                        message: 'Por favor selecione uma data maior que a data inicial do filtro ("De").',
                        variant: 'error',
                    }));
                } else {
                    this.vencimentoCotacao.date2 = enteredValue;
                }
            } else {
                this.vencimentoCotacao.date2 = enteredValue;
            }
        
        this.setVencimentoFilter();
    }

    setVencimentoToday(){
        this.vencimentoCotacao = {last_n_days:0};
        this.vencimentoCotacaoText = 'Hoje';
    }

    setVencimentoYesterday(){
        this.vencimentoCotacao = {yesterday:true};
        this.vencimentoCotacaoText = 'Ontem';
    }

    setVencimentoUltimos7Dias(){
        this.vencimentoCotacao = {last_n_days:7};
        this.vencimentoCotacaoText = 'Últimos 7 dias';
    }

    setVencimentoUltimos30Dias(){
        this.vencimentoCotacao = {last_n_days:30};
        this.vencimentoCotacaoText = 'Últimos 30 dias';
    }

    setVencimentoFilter(){
        if(!this.vencimentoCotacao){
            this.vencimentoCotacao = {};
        }
        this.vencimentoCotacaoText = '';
        if(this.vencimentoCotacao.date1 || this.vencimentoCotacao.date2){
            if(this.vencimentoCotacao.date1){
                this.vencimentoCotacaoText = 'De: ' + formatarData(this.vencimentoCotacao.date1);
            }
            if(this.vencimentoCotacao.date2){
                this.vencimentoCotacaoText += ' Até: ' + formatarData(this.vencimentoCotacao.date2);
            }
        } else  if(this.vencimentoCotacao.last_n_days != null){
            if(this.vencimentoCotacao.last_n_days == 0){
                this.vencimentoCotacaoText = 'Hoje';
            } else if(this.vencimentoCotacao.last_n_days == 6){
                this.vencimentoCotacaoText = 'Últimos 7 dias';
            } else if(this.vencimentoCotacao.last_n_days == 29){
                this.vencimentoCotacaoText = 'Últimos 30 dias';
            } 
        } else if(this.vencimentoCotacao.yesterday){
            this.vencimentoCotacaoText = 'Ontem';
        }
        this.vencimentoCotacao = {...this.vencimentoCotacao};
    }

    handleClickDataVencimento(){
        this.showModalDataVencimento = true;
    }

    closeModalDataVencimento(){
        this.showModalDataVencimento = false;
        this.doSearch();
    }
}