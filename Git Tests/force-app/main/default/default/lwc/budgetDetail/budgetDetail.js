import { api, track, LightningElement, wire } from 'lwc';
import {statusFilterConst, itemsTableConst} from './budgetDetailColumns';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getBudgetDataWithItens from '@salesforce/apex/BudgetDetailController.getBudgetDataWithItens';
import setItemTabulacaoN1 from '@salesforce/apex/BudgetDetailController.setItemTabulacaoN1';
import getProgramacaoEntrega from '@salesforce/apex/BudgetDetailController.getProgramacaoEntrega';
import getCustomerCategory from '@salesforce/apex/BudgetDetailController.getCustomerCategory';
import saveBudget from '@salesforce/apex/BudgetDetailController.saveBudget';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { MultiOption } from 'c/utilities';
import CurrUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import { NavigationMixin } from 'lightning/navigation';
import {CurrentPageReference} from 'lightning/navigation';
import { registerListener, fireEvent, unregisterAllListeners } from 'c/pubsub';

export default class BudgetDetail extends NavigationMixin(LightningElement) {
    
    @api recordId;

    @wire(CurrentPageReference)pageRef;

    @track isRendered = false;
    @track showSpinner = true;
    @track viewOnly = false;
    @track isEditable = true;
    @track budgetData = {};
    @track itens = [];
    @track showFilterItems = 'all';
    @track clientCategory = 'all';
    @track showVincularModal_ = false;
    @track itemData = {};
    @track skipItemDataRefresh;
    @track tabulacaoN1PicklistValues;
    @track statusPicklistValues;
    @track loadSelectBUModal;
    @track showEntrega_ = false;
    @track itensDataEntrega = [];

    prfName;
    keepSelectionRow = false;
    @track productSelectedRowsId = [];// é uma lista de listas, cada página em tela tem sua lista, sendo index = (nºda pág. - 1) (ex.: pág 1 = productSelectedRowsId[0])
    allRowsSelected;
    sectionsToDisplay = ["QuoteItems"];
    sectionsToDisplay1 = ["ConsolidatedBudget","FalhaNaIntegracao"];
    tabulacaoN1HideOptions = ['Cotado'];
    vincularProdutoSelected;
    tabulacaoSelecionada;
    updateTimer;
    fieldsToSave = {};
    showToast = true;
    numberOfRows = 0;
    paginationStep = 100;
    currentPageNumber = 1;

    renderedCallback() {
        let scope = this;
        if(!scope.isRendered){
            scope.isRendered = true;
            scope.enforceStyles();
        }
        scope.reloadDynamicStyles();
    }

    connectedCallback(){
        this.getOpportunityAndQuoteItems();
        registerListener('setViewOnly', this.setViewOnly, this);
    }

    get isIntegrating(){
        return !this.budgetData || !this.budgetData.statusIntegracaoPortal || this.budgetData.statusIntegracaoPortal == 'Recebendo dados';
    }

    get MensagemErroIntegracaoPortalCotacoes(){
        return this.budgetData && this.budgetData.MensagemErroIntegracaoPortalCotacoes && this.budgetData.MensagemErroIntegracaoPortalCotacoes.replace(/;/g, "<br/>");
    }

    get hasCotacoesConsolidadas(){
        return this.budgetData && this.budgetData.statusIntegracaoPortal && this.budgetData.statusIntegracaoPortal != 'Recebendo dados' && this.budgetData.consolidadas && this.budgetData.consolidadas.length > 0;
    }

    get maxRowSelection(){
        return this.isEditable ? 9999 : 0;
    }

    get showProductList() {
        return this.budgetData && this.budgetData.statusIntegracaoPortal && this.budgetData.statusIntegracaoPortal != 'Recebendo dados' && this.tabulacaoN1PicklistValues;
    }

    get statusItemsFilter(){
        return statusFilterConst();
    }

    get clientCategoryOptions(){
        let clientOptions = [...new Set(this.itens.map(item =>{return item.categoriaCliente}))].map(cat =>{return {label:cat, value: cat}});
        clientOptions.push({value:'all', label:'Todas categorias'});
        return clientOptions;
    }

    get disableButtons(){
        let vencida = !(this.budgetData && this.budgetData.dataVencimento && (new Date(this.budgetData.dataVencimento)).getTime() >= new Date().getTime());
        return this.viewOnly || vencida;
    }

    get showPreviousPageButton(){
        return this.currentPageNumber > 1;
    }

    get showNextPageButton(){
        return this.currentPageNumber < this.numberOfPages;
    }

    get numberOfPages(){
        if(!!this.filteredItens){
            return Math.ceil((this.filteredItensSize / this.paginationStep)) || 1;
        }
        return 1;
    }

    get filteredItens(){

        const filterMapObject = {
            'awaitYourResp': !!this.itens && this.itens.filter(item => {
                return (item.style2Class === 'wBack' || item.style2Class == null);
            }),
            'partResp': !!this.itens && this.itens.filter(item => {
                return item.statusItem === 'PARCIALMENTE RESPONDIDO';
            }),
            'noneResp': !!this.itens && this.itens.filter(item => {
                return item.statusItem === 'NENHUMA RESPOSTA';
            }),
            'allResp': !!this.itens && this.itens.filter(item => {
                return item.statusItem === 'TOTALMENTE RESPONDIDO';
            }),
            'quoted': !!this.itens && this.itens.filter(item => {
                return !!item.dynamicIcon;
            }),
            'tabulatedNotOffered': !!this.itens && this.itens.filter(item =>{
                return !!item.tabulatedNotOffered;
            }),
            'all': this.itens
        }
        if(!this.clientCategory || this.clientCategory == 'all'){
            return filterMapObject[this.showFilterItems];
        }else{
            return filterMapObject[this.showFilterItems].filter(item => {return item.categoriaCliente == this.clientCategory});
        }
    }

    get filteredItensSize(){
        return !!this.filteredItens && this.filteredItens.length || null;
    }

    get visibleItens() {
        return this.filteredItens.slice(
            (this.currentPageNumber - 1) * this.paginationStep,
            ((this.currentPageNumber - 1) * this.paginationStep) + this.paginationStep
        );
    }

    get itemsColums (){
        return itemsTableConst();
    }

    get currentSelectedRowsId(){

        let result = this.productSelectedRowsId[this.currentPageNumber - 1];
        return result?.length > 0 ? result : [];
    }

    get allPageRowsChecked(){

        return this.productSelectedRowsId[this.currentPageNumber - 1]?.length == this.visibleItens.length;
    }
    
    get allRowsChecked(){

        return (this.productSelectedRowsId?.flat(1).length == this.filteredItensSize && this.allRowsSelected);
    }

    get multiplaTabulacaoCheckBox(){
        return [
            {value: 'allPage', label: 'Selecionar todos itens da página', selected: this.allPageRowsChecked},
            {value: 'allItens', label: 'Selecionar todos itens da cotação', selected: this.allRowsChecked}
        ];
    }

    get showTabulacaoN1Picklist(){
        return (
            this.isEditable &&
            this.multiplaTabulacaoOptions && this.multiplaTabulacaoOptions.length > 0 && 
            (this.productSelectedRowsId && this.productSelectedRowsId.flat(1).length > 0 ||
            this.allRowsSelected)
        );
    }

    get multiplaTabulacaoOptions(){
        let result;
        
        if(this.tabulacaoN1PicklistValues && this.tabulacaoN1PicklistValues.controllerValues && this.tabulacaoN1PicklistValues.controllerValues["Não Vinculado"]){
            let controllerId = [];
            controllerId.push(this.tabulacaoN1PicklistValues.controllerValues["Não Vinculado"]);
            controllerId.push(this.tabulacaoN1PicklistValues.controllerValues["Vinculado"]);
            result = this.tabulacaoN1PicklistValues.values.filter(opt => {
                return opt.validFor.includes(controllerId[0]) || opt.validFor.includes(controllerId[1]);
            }).map(opt => {
                return new MultiOption(false, opt.value, opt.label);
            });
        }
        return result;
    }

    get showVincularModal(){
        return this.budgetData && this.itemData && this.showVincularModal_;
    }

    get itemIndex(){
        return !!this.filteredItens && this.filteredItens.findIndex(item =>{return item.idPortal === this.itemData.idPortal})+1 || null;
    }

    get showEntrega(){
        return this.itemData && this.showEntrega_;
    }

    setViewOnly(value){
        this.viewOnly = value;
        this.isEditable = !value;
        eval("$A.get('e.force:refreshView').fire();");
    }

    @wire(getRecord, {
        recordId: CurrUserId,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           console.error('PROFILE-ERROR: ',error); 
           
        } else if (data) {
            this.prfName = data.fields.Profile.value.fields.Name.value;
           
        }
    }

    getOpportunityAndQuoteItems(){
        let scope = this;
        scope.showSpinner = true;
        doCalloutWithStdResponse(scope, getBudgetDataWithItens, {oppId: scope.recordId}).then(response => {
            scope.budgetData = JSON.parse(response.data.budgetData);
            if(!!scope.budgetData && scope.budgetData.statusIntegracaoPortal != 'Recebendo dados'){
                scope.setViewOnly(scope.budgetData.viewOnly);
                scope.itens = JSON.parse(response.data.itemDataList);
                scope.numberOfRows = scope.itens.length;
                if((this.filteredItensSize/100) < scope.currentPageNumber){
                    scope.currentPageNumber = 1;
                }
                scope.showSpinner = false;
                eval("$A.get('e.force:refreshView').fire();");
                scope.refreshConditionPayment();
                scope.skipItemDataRefresh = false;
            }else{
                scope.setViewOnly(true);
                setTimeout(()=>{
                    scope.getOpportunityAndQuoteItems();
                }, 7000);
            }
        }).catch(error =>{
            console.error(error);
        });
    }

    refreshConditionPayment(){
        let conditionPaymentsComponent = this.template.querySelector('c-condition-payment-budget');
        if(conditionPaymentsComponent){
            conditionPaymentsComponent.getConditionPayment();
        }
    }

    handleChangeCategoryFilter(event){
        this.productSelectedRowsId = [];
        this.allRowsSelected = false;
        this.currentPageNumber = 1;
        this.clientCategory = event.target.value;
    }

    handleChangeShowFilterItems(event){
        this.productSelectedRowsId = [];
        this.allRowsSelected = false;
        this.currentPageNumber = 1;
        this.showFilterItems = event.target.value;
    }

    previousPage(){
        this.keepSelectionRow = true;
        if(this.currentPageNumber > 1){
            this.currentPageNumber--;
        }
    }

    nextPage(){
        this.keepSelectionRow = true;
        if(this.numberOfPages > this.currentPageNumber){
            this.currentPageNumber++;
        }
    }

    jumpToFirstPage(){
        this.keepSelectionRow = true;
        this.currentPageNumber = 1;
    }

    jumpToLastPage(){
        this.keepSelectionRow = true;
        this.currentPageNumber = this.numberOfPages;
    }

    handleButtonClick(event){

        this.itemData = this.itens.find( item =>{return item.idPortal === event.detail.recordId});
        
        if(event.detail.button === 'editar-vinculo') {
            this.showVincularModal_ = true;
        }
        else if(event.detail.button == 'mostrar-Entrega') {
                
            this.itensDataEntrega = [];
            getProgramacaoEntrega({ quoteIdPortal: this.itemData.idPortal}).then(result => {

                if (result != null) {
                    this.showEntrega_ = true;
                    for (var i = 0; i < result.length; i++) {
                        this.itensDataEntrega = [...this.itensDataEntrega,{
                            data: result[i].data,
                            quantidade: result[i].quantidade,
                        }];
                    }
                }
        
            }).catch(error => {
                console.error(error);
                this.showSpinnerProducts = false;
            });
        }
    }

    handleRegisterRowCustomCell(event){
        console.log('handleRegisterRowCustomCell', event && JSON.stringify(event.detail));
    }

    // draftValues = [];

    handleProductRowSelection(event){

        let element = this.template.querySelector('c-multi-values-picklist-l-w-c[name="MultiplaTabulacao"]');
        if(element){
            element.handleClickLimpar();
        }

        if(!this.keepSelectionRow){

            let productSelectedRows = event.detail.selectedRows;
            this.productSelectedRowsId[this.currentPageNumber - 1] = [...productSelectedRows.map(p =>{return p.idPortal})];
        }
        else{
            this.keepSelectionRow = false;
        }
    }

    handleCheckBoxAllRows(event){

        if(event.target.value === 'allItens' && event.target.checked){
            let selectedRowsStep = Math.ceil(this.filteredItensSize/this.paginationStep);
            for(let i = 0; i < selectedRowsStep; i++){
                this.productSelectedRowsId[i] = this.filteredItens.map(p =>{return p.idPortal}).slice(
                    i * this.paginationStep,
                    (i * this.paginationStep) + this.paginationStep
                );
            }
            this.allRowsSelected = true;
        }
        else if(event.target.value === 'allPage' && event.target.checked){
            this.productSelectedRowsId[this.currentPageNumber - 1] = this.visibleItens.map(p =>{return p.idPortal});
        }
        else if(event.target.value === 'allPage'){
            this.productSelectedRowsId[this.currentPageNumber - 1] = [];
        }
        else{
            this.allRowsSelected = false;
            this.productSelectedRowsId = [];
        }

    }

    closeVincularModal(){
        try {
            
            this.showVincularModal_ = false;
            // this.paginationDirection = null; *
            this.skipItemDataRefresh = true;
            this.itemData = null;
            this.getOpportunityAndQuoteItems();
        } catch (error) {
            console.error(error);
        }
    }

    handlePreviousItemClick(event){
        let indexOfItem = this.filteredItens.findIndex(item =>{
            return item.idPortal === this.itemData.idPortal;
        });

        if(indexOfItem - event.detail > 0){
            this.itemData = this.filteredItens[indexOfItem - event.detail];
        }else{
            this.itemData = this.filteredItens[0];
        }
    }

    handleNextItemClick(event){
        let indexOfItem = this.filteredItens.findIndex(item =>{
            return item.idPortal === this.itemData.idPortal;
        });

        if(indexOfItem + event.detail < this.filteredItensSize){
            this.itemData = this.filteredItens[indexOfItem + event.detail];
        }else{
            this.itemData = null;
            this.getOpportunityAndQuoteItems();
        }
    }

    refreshQuoteItems(event){
        if(event){
            event.stopPropagation();
            event.preventDefault();
        }
        this.skipItemDataRefresh = true;
        // this.getQuoteItems();
       
        eval("$A.get('e.force:refreshView').fire();");
    }

    // handleRefreshLine(event){
    //     let scope = this;
    //     event.stopPropagation();
    //     let newItem;
    //     if(event && event.detail && event.detail.quoteitem && event.detail.quoteitem.id){
    //         scope.itens = scope.itens.map(item => {
    //             if(item.id == event.detail.quoteitem.id){
    //                 scope.itemData = item = {...item, ...event.detail.quoteitem};
    //                 newItem = item;
    //             }
    //             return item;
    //         });
            
    //         // let currentResp = scope.itemData.respostas.find(res => res.vendedorId === scope.userId);
    //         // let respostasGrup = scope.itens.map(it =>{return it.respostas;});
    //         // let respostas = [].concat.apply([], respostasGrup);
    //         // let respRespTotal = respostas.filter(item =>{return item.vendedorId === scope.userId});
    //         //o que fazer com os atigos?
    //         // let itensRespondidos = respostas.filter(item =>{return item.vendedorId == scope.userId && item.tabulacaoN1});
    //         // if(itensRespondidos.length != 0 && itensRespondidos.length == respRespTotal.length){
    //         //     let param ={
    //         //         TabulacaoN1__c:'Aceite',
    //         //         TabulacaoN2__c:'Cotação Enviada TT',
    //         //     }
    //         //     this.template.querySelector('c-budget-detail-tabulacao').setFields(param);
    //         //     this.skipItemDataRefresh = true;
    //         //     this.showToast = false;
    //         //     scope.callSaveMethod(false,param);
    //         // }else if(itensRespondidos.length == 1 && itensRespondidos[0].id == currentResp.id){
    //         //     let param ={
    //         //         TabulacaoN1__c :'Aceite',
    //         //         TabulacaoN2__c :'Cotação Enviada Parcial',
    //         //     }
    //         //     this.template.querySelector('c-budget-detail-tabulacao').setFields(param);
    //         //     this.skipItemDataRefresh = true;
    //         //     this.showToast = false;
    //         //     scope.callSaveMethod(false,param);
    //         // }
    //         //NÃO APAGAR COMENTÁRIO ACIMA
    //         this.skipItemDataRefresh = true;
    //         this.showToast = false;
    //         scope.callSaveMethod(false);

    //     }
    //     if(newItem){
    //         scope.template.querySelector('c-budget-detail-edit-item').quoteitem = newItem;
    //     }
    // }

    handleUpdateQuoteItem(event){
        event.stopPropagation();
        let currentItemId = this.itemData.idPortal;
        this.skipItemDataRefresh = true;
        this.getOpportunityAndQuoteItems();
        this.itemData = this.itens.find(item => item.idPortal === currentItemId);
        this.showVincularModal_ = false;
        this.showVincularModal_ = true;
        eval("$A.get('e.force:refreshView').fire();");
    }

    @wire(getPicklistValues, { fieldApiName: 'OpportunityLineItem.TabulacaoN1__c', recordTypeId: '0120j00000091K6AAI' }) //random recordTypeId
    getPicklistTabulacaoN1Values(response) {
        if(response && response.data){
            this.tabulacaoN1PicklistValues = response.data;
        }
    }


    @wire(getPicklistValues, { fieldApiName: 'OpportunityLineItem.Status__c', recordTypeId: '0120j00000091K6AAI' }) //random recordTypeId
    getPicklistWithControlledValues(response) {
        if(response && response.data){
            this.statusPicklistValues = response.data;
        }
    }

    handleMultiValuesPickListValueChange(customEvent) {
        let data = JSON.parse(customEvent.detail);
        if(data.field == "MultiplaTabulacao"){
            if(data.selectedOptions && data.selectedOptions.length > 0){
                if(this.budgetData.categorias.length == 1){
                    
                    this.setItemTabulacaoN1(data.selectedOptions.map(opt => opt.value)[0], this.budgetData.categorias);
                    this.productSelectedRowsId = [];
                    this.allRowsSelected = false;
                }else{
                    
                    this.tabulacaoSelecionada = data.selectedOptions.map(opt => opt.value)[0];
                    this.loadSelectBUModal = true;
                }
            }

        }
    }

    setItemTabulacaoN1(tabulacaoN1, categorias){
        let scope = this;

        if(scope.productSelectedRowsId && scope.productSelectedRowsId.length > 0) {
            scope.manageFilteredRows();
            let params = {
                quoteItemIdsPortal: scope.productSelectedRowsId.flat(1),
                accId: scope.budgetData.ClienteEmissorId,
                oppId: scope.budgetData.oppId,
                categorias: categorias,
                tabulacaoN1: tabulacaoN1,
            };

            doCalloutWithStdResponse(scope, setItemTabulacaoN1, params).then(response => {
                
                scope.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: 'As tabulações dos itens selecionados foram alteradas com sucesso.', variant: 'success' }));

                // scope.getQuoteItems();
                scope.loadSelectBUModal = false;
            }).catch(()=> {
                scope.showSpinner = false;
                let modalcomponent = scope.template.querySelector('c-budget-detail .modal-multitabulacao c-budget-detail-select-b-u');
                if(!!modalcomponent){
                    modalcomponent.controlSpinner = false;
                }
            }).finally(()=>{
                scope.tabulacaoSelecionada = undefined;
                scope.getOpportunityAndQuoteItems();
            });
            
        }
    }

    manageFilteredRows(){
        if(!this.allRowsSelected){
            return;
        }
        let itensToRemove = this.filteredItens
            .filter(item =>{return !this.productSelectedRowsId?.flat(1).includes(item.idPortal)})
            .map(item =>{return item.idPortal})
        this.productSelectedRowsId = this.itens
            .filter(item =>{return !itensToRemove.includes(item.idPortal)})
            .map(item =>{return item.idPortal});
    }

    closeshowEntrega(){
        this.showEntrega_ = false;
    }

    closeModalSelectBU(event){
        this.loadSelectBUModal = false;
    }

    handleAddResponseModalBu(event){
        this.setItemTabulacaoN1(this.tabulacaoSelecionada, event.detail);
        this.productSelectedRowsId = [];
        this.allRowsSelected = false;
    }

    handleEnviarOrcamentoClick(event){
        let cdValues;
        let paymentConditionsTabsElement = this.template.querySelector('c-condition-payment-budget');
        if(paymentConditionsTabsElement){
            cdValues = paymentConditionsTabsElement.getCurrentValues();
        }
        this.callSaveMethod(true, undefined, cdValues);
    }

    callSaveMethod(sendBudgetToPortal, otherParams, cdValues){
        let scope = this;
        scope.viewOnly = true;
		if(scope.updateTimer != null){
			clearTimeout(scope.updateTimer);
		}
        scope.loadFormFields();
        scope.showSpinner = true;
        let params = {
            sendBudgetToPortal: sendBudgetToPortal,
            opp:{...scope.fieldsToSave, StageName: scope.budgetData.StageName, ...otherParams},
            cdValues: cdValues
        };
        scope.updateTimer = setTimeout(function() {
            doCalloutWithStdResponse(scope, saveBudget, params).then(response => {
                if(scope.showToast){
                    scope.dispatchEvent(new ShowToastEvent({ title: 'Sucesso!', message: 'Orçamento '+ (sendBudgetToPortal ? 'enviado' : 'salvo') + ' com sucesso.', variant: 'success' }));
                }else{
                    scope.showToast = true;
                }
                eval("$A.get('e.force:refreshView').fire();");
                if(sendBudgetToPortal){
                    scope.navigateBudgetTab();
                }else{
                    // scope.getQuoteItems();
                }
                
            }).catch(error =>{
                let conPayComp = scope.template.querySelector('c-condition-payment-budget');
                if(!!conPayComp){
                    conPayComp.getConditionPayment();
                }
            }).finally(()=>{
                scope.showSpinner = false;
                scope.viewOnly = false;
            });
        }, 1500);
    }

    loadFormFields(){

        this.fieldsToSave = Object.assign(
            this.template.querySelector('.details-form1 c-lightning-record-form-by-layout-name').getFields(), 
            this.template.querySelector('c-budget-detail-tabulacao').getFields(), 
            {
                recordId: undefined, 
                recordTypeId: undefined
            }
        );
        return this.fieldsToSave;
    }

    navigateBudgetTab() {
        this[NavigationMixin.Navigate]({
            type: 'standard__app',
            attributes: {
                pageRef: {
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: 'Orcamentos'
                    }
                }
            }
        });
    }

    enforceStyles(){
        let style = document.createElement('style');
        style.innerText = `
            c-budget-detail > div.budget-detail > c-budget-detail-tabulacao lightning-accordion .slds-accordion__summary,
            c-budget-detail > div.budget-detail > div.details-form lightning-accordion, 
            c-budget-detail > div.budget-detail > div.details-form lightning-accordion .slds-accordion__summary,
            c-budget-detail > div.budget-detail > div.product-list > lightning-accordion, 
            c-budget-detail > div.budget-detail > div.product-list > lightning-accordion .slds-accordion__summary {
                --sds-c-accordion-summary-color-background: #e1e6eb !important;
                --sds-c-accordion-heading-text-color: #909396 !important;
                --sds-c-accordion-heading-text-color-hover: #909396 !important;
                padding: 9px !important;
                border-radius: 4px !important;
            }
            c-budget-detail > div.content.budget-detail .details-form > lightning-accordion.accordion .slds-accordion__summary,
            c-budget-detail > div.content.budget-detail .product-list > lightning-accordion .slds-accordion__summary {
                margin-bottom: 15px!important;
            }
            c-budget-detail .modal-vincular div .produto-solicitado {
                position: relative;
                padding: 1em 1.5em;
            }
            c-budget-detail .modal-vincular div .produto-solicitado > label {
                position: absolute;
                top: -1.35em;
                left: 0.5em;
                background-color: white;
                padding: 0.5em;
            }
            c-budget-detail .modal-vincular div .produto-solicitado > div > div > div > div {
                display: inline-grid;
            }
            c-budget-detail .modal-vincular div .produto-solicitado > div > div > div > div > label { */
                color: gray;
                font-size: smaller;
            }
            c-budget-detail .modal-vincular div .produto-solicitado > div > div > div > div > span { */
                font-size: larger;
            }
            c-budget-detail .modal-vincular div .produto-vinculado {
                margin: 1.8em 0 1em 0;
                position: relative;
            }
            c-budget-detail .modal-vincular div .produto-vinculado > label {
                position: absolute;
                top: -1.35em;
                left: 0.5em;
                background-color: white;
                padding: 0.5em;
            }
            c-budget-detail .modal-vincular .slds-modal__footer lightning-button {
                margin: 0 0.25em;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y table.slds-table thead tr th {
                padding-left: 0 !important;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y table tbody {
                border-right: 0 !important;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y table tbody tr {
                position: relative !important;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_x {
                background-color: white;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y thead lightning-primitive-resize-handler {
                opacity: 0 !important;
                z-index: 1000 !important;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y thead lightning-primitive-resize-handler:hover {
                opacity: 1 !important;
                z-index: 1000 !important;
            }
            c-budget-detail c-budget-detail-products-datatable div.slds-scrollable_y thead lightning-primitive-resize-handler:active {
                opacity: 1 !important;
                z-index: 1000 !important;
            }
            c-budget-detail .footer-buttons {
                text-align-last: center;
            }
            c-budget-detail .row-content {
                padding: 0 2rem 2rem 2rem;
            }
            c-budget-detail tbody button.picklist-button{
                border: none !important;
                background-color: transparent !important;
            }
            c-budget-detail tbody button.picklist-button:hover {
                background-color: white !important;
            }
            c-budget-detail > div.content.budget-detail > div.product-list > lightning-input {
                left: 91% !important;
                top: 52px !important;
                z-index: 9 !important;
            }
            c-budget-detail > div.content.budget-detail > div.product-list > lightning-input .slds-checkbox_faux_container .slds-checkbox_on {
                display: none !important;
            }
            c-budget-detail > div.content.budget-detail > div.product-list > lightning-input .slds-checkbox_faux_container .slds-checkbox_off {
                display: none !important;
            }
            
            c-budget-detail-products-datatable-column-buttons lightning-button button {
                height: 26px;
                margin: 4px;
            }

            c-budget-detail-products-datatable-column-buttons lightning-button {
                display: contents;
            }
            
            c-budget-detail-products-datatable-column-buttons lightning-button-icon button[name="mostrar-produto"] {
                height: 26px;
                width: 26px;
                display: inline;
                float: right;
                margin: 4px 10px 4px 4px;
            }
            
            c-budget-detail-products-datatable-column-buttons lightning-button-icon {
                display: contents;
            }
            
            c-budget-detail-products-datatable-column-buttons .mostrar-produto {
                display: inline;
            }

            c-budget-detail-products-datatable-column-buttons lightning-button-icon button[name="mostrar-Entrega"] {
                height: 26px;
                width: 26px;
                display: inline;
                float: right;
                margin: 4px 10px 4px 4px;
            }
            
            c-budget-detail-products-datatable-column-buttons lightning-button-icon {
                display: contents;
            }
            
            c-budget-detail-products-datatable-column-buttons .mostrar-Entrega {
                z-index: 2;
                display: inline;
            }

            
            c-budget-detail-products-datatable-column-buttons lightning-button-icon button[name="editar-vinculo"] {
                height: 26px;
                width: 26px;
                margin: 4px;
                display: inline;
                float: right;
            }

            c-budget-detail-products-datatable-column-buttons lightning-button[data-vinculado="true"] button {
                background-color: lightgray;
                color: gray;
            }

            c-budget-detail-resposta-data-table span.slds-radio_faux {
                margin-right: 0;
                right: 10px;
            }

            c-budget-detail-products-datatable .gBackgText{
                background-color: #b2ebb2 !important;
                color: green !important;
                font-weight: 500;
            }
            c-budget-detail-products-datatable .wBackgText{ 
                color: green !important;
                font-weight: 500;
            }

            c-budget-detail-products-datatable .gBackyText{ 
                background-color: #b2ebb2 !important;
                color: #d5a700 !important;
                font-weight: 500;
            }
            c-budget-detail-products-datatable .wBackyText{ 
                color: #d5a700 !important;
                font-weight: 500;
            }

            c-budget-detail-products-datatable .gBack{
                background-color: #b2ebb2 !important;
            }

            c-budget-detail lightning-datatable .slds-scrollable_y, c-budget-detail lightning-datatable table {
                width: max-content !important;
            }

            .navexStandardManager .slds-template__container .slds-spinner_container, .navexStandardManager>.center .s1FixedTop {
                z-index: 999999;
            }
            c-budget-detail c-budget-detail-edit-item c-budget-detail-product div.slds-section.slds-is-open.slds-card lightning-layout  button{
                top: 20px;
            }
            c-budget-detail div.details-form1  lightning-record-edit-form-edit lightning-input-field.AccountId lightning-lookup lightning-lookup-desktop lightning-grouped-combobox lightning-base-combobox button{
                display: none;
            }
            c-budget-detail div.details-form1  lightning-record-edit-form-edit lightning-input-field.CondicaoPagamento__c lightning-lookup lightning-lookup-desktop lightning-grouped-combobox lightning-base-combobox button{
                display: none;
            }

            c-budget-detail c-condition-payment-budget div.details-form.details-form0 c-lightning-record-form-by-layout-name lightning-record-edit-form-edit lightning-accordion lightning-accordion-section div.slds-form__item.slds-form-element.Integradora__c{
                display: none;
            }

            flexipage-component2 lst-related-list-single-container laf-progressive-container lst-related-list-single-aura-wrapper lst-list-view-manager-header force-list-view-manager-button-bar lightning-button-icon.forceRefreshButton button[title="Refresh"]{
                display: none;
            }
            
            c-budget-detail c-condition-payment-budget div.slds-col.slds-size_2-of-2.condition-payment-text-area lightning-textarea div.slds-form-element__control.slds-grow.textarea-container{
                padding-left: 16.4%;
            }

            flexipage-component2 lst-related-list-single-container laf-progressive-container lst-related-list-single-aura-wrapper lst-list-view-manager-header div lst-list-view-manager-settings-menu lightning-button-menu button[title="List View Controls"]{
                display: none;
            }
            flexipage-component2 lst-related-list-single-container laf-progressive-container lst-related-list-single-aura-wrapper lst-list-view-manager-header force-list-view-manager-button-bar lightning-button-icon.forceRefreshButton button[title="Atualizar"]{
                display: none;
            }
            flexipage-component2 lst-related-list-single-container laf-progressive-container lst-related-list-single-aura-wrapper lst-list-view-manager-header div lst-list-view-manager-settings-menu lightning-button-menu button[title="Controles de exibição de lista"]{
                display: none;
            }
            flexipage-component2 lst-related-list-single-container laf-progressive-container lst-related-list-single-aura-wrapper div.slds-col.slds-no-space.forceListViewManagerPrimaryDisplayManager div.autoHeight.hideSelection.forceListViewManagerGrid div.listViewContent.slds-table--header-fixed_container div.uiScroller.scroller-wrapper.scroll-bidirectional.native table tbody tr td div.forceVirtualActionMarker.forceVirtualAction a.rowActionsPlaceHolder{
                display: none;
            }
            c-budget-detail c-budget-detail-edit-item div.product-search-container c-multi-values-picklist-l-w-c div.slds-truncate {
                white-space: break-spaces;
            }
            
            c-budget-detail c-budget-detail-edit-item div.product-search-container c-multi-values-picklist-l-w-c .slds-table_header-fixed_container.slds-scrollable_x {
                overflow: inherit;
            }

            c-budget-detail c-budget-detail-edit-item c-budget-detail-resposta c-budget-detail-resposta-data-table table thead tr th lightning-primitive-header-factory span.slds-th__action .slds-truncate{
                max-width: 100%;
                overflow: hidden;
                text-overflow: unset;
                white-space: pre-line;
                /* word-wrap: break-word; */
            }
            c-budget-detail c-budget-detail-edit-item c-budget-detail-resposta c-budget-detail-resposta-data-table table thead tr th lightning-primitive-header-factory > div.slds-th__action{
                height: 3rem;
                border-bottom: 1px solid rgb(206 206 206);
                left: 0px;
            }
                        
            c-budget-detail c-budget-detail-edit-item c-budget-detail-resposta c-budget-detail-resposta-data-table table tbody tr td c-multi-values-picklist-l-w-c[name=TabulacaoN1__c] button span{
                max-width: 100%;
                overflow: hidden;
                text-overflow: unset;
                white-space: pre-line;
                line-height: 120%;
            }
            
            c-budget-detail c-budget-detail-edit-item c-budget-detail-resposta c-budget-detail-resposta-data-table table thead tr th lightning-primitive-header-factory span.slds-th__action {
                height: 3rem;
                border-bottom: 1px solid rgb(206 206 206);
            }

            c-budget-detail c-budget-detail-edit-item c-budget-detail-resposta c-budget-detail-resposta-data-table table thead tr.slds-line-height_reset{
                height: 1rem;
            }
        `;
        this.template.querySelector('.style-element-container').appendChild(style);
    }

    reloadDynamicStyles(){
        let style = document.createElement('style');
        
        // Get style wrapper element
        let wrapperElement = this.template.querySelector('.dynamic-style-container');

        let innerText = '';

        if(this.budgetData){
            if(this.budgetData.StageName != 'Cancelada' ){
                innerText += `
                    c-budget-detail .details-form1 div.slds-form__item.OrcamentoCancelado__c {
                        display: none;
                    }
                `;
            } else {
                innerText += `
                    c-budget-detail .details-form1 lightning-input-field.OrcamentoCancelado__c label {
                        color: red;
                        font-weight: 600;
                    }
                    c-budget-detail .details-form1 lightning-input-field.OrcamentoCancelado__c input {
                        font-weight: 600;
                    }
                `;
            }
        }
        
        if(innerText){
        
            // reset the wrapper component
            if(wrapperElement){
                while (wrapperElement.firstChild) {
                    wrapperElement.removeChild(wrapperElement.lastChild);
                }
            }
            
            // create the new style element
            style.innerText = innerText;
            wrapperElement.appendChild(style);
        }
    }
}