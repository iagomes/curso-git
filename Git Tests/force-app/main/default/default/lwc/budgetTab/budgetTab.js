import { api, LightningElement, wire, track } from 'lwc';
import doSearch from '@salesforce/apex/BudgetTabController.doSearch';
import getFixedFilters from '@salesforce/apex/BudgetTabController.getFixedFilters';
import getUserOrders from '@salesforce/apex/BudgetTabController.getUserOrders';
import updatePinnedCustomFilter from '@salesforce/apex/BudgetTabController.updatePinnedCustomFilter';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';

export default class BudgetTab extends NavigationMixin(LightningElement){
    
    columns = [
        { label: 'Canal de Vendas', fieldName: 'CanalEntrada__c', wrapText: true, initialWidth: 125, sortable: true, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { 
            label: 'Número Orçamento',
            fieldName: 'opportunityUrl',
            sortable: true,
            wrapText: true,
            cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'}, wrapText: true },
            type: "url",
            initialWidth: 220,
            typeAttributes: { label: { fieldName: 'NumeroOrcamento__c' }}
        },
        { 
            label: 'Data Vencimento',
            initialWidth: 130,
            fieldName: 'DataVencimento__c',
            cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} },
            sortable: true,
            type: 'date',
            typeAttributes: { day: "2-digit", month: "2-digit", year: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit" } 
        },
        { label: 'Id da Cotação', fieldName: 'IdIntegrator__c', wrapText: true, sortable: true, initialWidth: 140, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { label: 'Título Cotação', fieldName: 'Name', wrapText: true, sortable: true, initialWidth: 220, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { 
            label: 'Nome do Cliente',
            initialWidth: 260,
            wrapText: true,
            fieldName: 'accountUrl',
            sortable: true,
            cellAttributes: { alignment: 'left', title: 'AccountName', class:{fieldName: 'StageName'} },
            type: "url",
            typeAttributes: { label: { fieldName: 'AccountName', title: 'AccountName' }}
        },
        { label: 'Itens / Vinculados / Respondidos / Confirmados ',initialWidth: 160, fieldName: 'quoteitemsTotalSize', cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { label: 'Totalmente Respondido', fieldName:'icon', initialWidth: 120, cellAttributes:{iconName: {fieldName: 'answered'}, class:'iconAlign',iconPosition: 'left',}},
        { label: 'Status', fieldName: 'StageName', wrapText: true, initialWidth: 100, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { 
            label: 'Pedido Finalizado?',
            fieldName: 'ordersDoneURL',
            wrapText: true,
            cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'}, wrapText: true },
            type: "url",
            initialWidth: 100,
            typeAttributes: { label: { fieldName: 'ordersDoneLabel' }}
        },
        { label: 'CNPJ do Cliente', fieldName: 'CNPJ__c',wrapText: true, sortable: true, initialWidth: 155, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { label: 'Estado do Cliente', initialWidth: 124, wrapText: true, fieldName: 'AccountBillingState', sortable: true, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { label: 'Cidade do Cliente', fieldName: 'AccountBillingCity',initialWidth: 140, wrapText: true, sortable: true, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        { label: 'Valor', fieldName: 'Amount',initialWidth: 100, sortable: true, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} }, type: 'currency' },
        // { label: 'CNPJ do Cliente (Recebedor)', fieldName: 'CNPJClienteRecebedor__c', cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        //{ label: 'Tipo', fieldName: 'QuoteType__c',wrapText: true, sortable: true, initialWidth: 280, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} } },
        // { label: 'Quantidade Total de Produtos', fieldName: 'TotalOpportunityQuantity', sortable: true, cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} }, type: 'number' },
        { 
            label: 'Data de Criação', 
            sortable: true,
            fieldName: 'CreatedDate', 
            cellAttributes: { alignment: 'left', class:{fieldName: 'StageName'} }, 
            type: 'date',
            wrapText: true,
            initialWidth: 124,
            typeAttributes: { day: "2-digit", month: "2-digit", year: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit" }
        },
    ];
    orderDirection = 'asc';
    orderBy = 'DataVencimento__c';
    statusSearch = ['Novo', 'Em digitação'];
    teamMember = [];
    notAnswered = false;
    expiredValue = false;
    searchText_;
    normText;
    totalNumberOfRows = 0;
    lastRecord;
    itemsPerPage = 200;
    isLoading_ = true;
    openNewFixFilterModal = false;
    userId = Id;
    lastSearchParams = {};
    orderCount;
    
    @wire(getRecord, {
        recordId: Id,
        fields: [NAME_FIELD]
    })wireuser({
        error,
        data
    }) {
        if (error) {
           console.log(error); 
        } else if (data) {
            this.teamMember = [{ value: Id, label: data.fields.Name.value, isSelected: true}];

        }
    }
   
    get sortBy(){
        if(this.orderBy == 'NumeroOrcamento__c'){
            return 'opportunityUrl';
        } else if(this.orderBy == 'Account.Name'){
            return 'accountUrl';
        } else if(this.orderBy == 'Account.BillingCity'){
            return 'AccountBillingCity';
        } else if(this.orderBy == 'Account.BillingState'){
            return 'AccountBillingState';
        } else {
            return this.orderBy;
        }
    }
   
    // new MultiOption(true, Id, this.firstName +' '+ this.lastName)
    get isLoading(){
        return this.isLoading_;
    }
    set isLoading(value){
        this.isLoading_ = value;
        this.template.querySelector('lightning-datatable').isLoading = value;
    }

    get results() {
        return this.totalNumberOfRows ? this.data_.length + '/' + this.totalNumberOfRows : 0;
    }

    data_ = [];

    get data(){
        if(this.isSorting){
            return [];
        }
        // if(this.data_ && this.data_.length > 0 && this.searchText){
        //     return this.data_.filter(item => {
        //         return objectContainsValue(item, this.searchText);
        //     });
        // }
        return this.data_;
    }

    set data(value){
        this.data_ = value;
    }

    openExcludeFilterModal = false;
    closeExcludeFilterModal(){
        this.openExcludeFilterModal = false;
    }

    handleDeleteFilterItens(){
        this.closeExcludeFilterModal();
        this.getFixFilters();
        this.selectedFilter = '';
        this.selectedFilter = this.fixedFiltersOptions.find(fixfilter =>{return fixfilter.label === 'Todos'})?.value;
    }

    get personalizedFilters(){
        return this.fixedFiltersOptions.filter(fixFilter =>{return !fixFilter.standard});
    }

    @api getOrders(){
        let scope = this;
        doCalloutWithStdResponse(scope, getUserOrders, {}).then(response => {
            if(response.data == 49999){
                scope.orderCount = '50000+';
            }else{
                scope.orderCount = response.data;
            }
        }).catch(error => {
            console.error('Error to get orders', JSON.stringify(error));
        });
    }

    handleOrderCountClick(){
        this.dispatchEvent(new CustomEvent('orderclick'));
    }

    navigateOrderListWon() {
        var cmpDefinition = {
            componentDef: "c:orderListWon",
        };
        
        var encodedCmp = btoa(JSON.stringify(cmpDefinition));
        
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedCmp
            }
        });
    }

    handleMenuSelect(event){
        if(event.detail.value === 'deleteFilters'){
            this.openExcludeFilterModal = true;
        }
    }

    handleToggleExpired(event){
        this.expiredValue = !this.expiredValue;
        this.lastRecord = null;
        this.lastSearchParams.lastRecord = null;
        this.orderDirection = this.expiredValue ? 'desc' : 'asc';
        this.orderBy = 'DataVencimento__c';
        this.stopSearchTimeout();
        this.loadingMore = true;
        this.searchTimer = setTimeout(() => {
            // this.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = true;
            this.doSearch(Object.assign(this.lastSearchParams,{expired : this.expiredValue, orderDirection: this.orderDirection, orderBy: this.orderBy}));
        }, 300);
    }

    handleToggleNotAnswered(event){
        this.lastRecord = null;
        this.notAnswered = !this.notAnswered;
        this.lastSearchParams.lastRecord = null;
        this.stopSearchTimeout();
        this.loadingMore = true;
        this.searchTimer = setTimeout(() => {
            // this.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = true;
            this.doSearch(Object.assign(this.lastSearchParams,{notAnswered: this.notAnswered, orderDirection: this.orderDirection}));
        }, 300);
    }

    searchTimer;
    loadMoreData(event) {
        let scope = this;
        
        //Display a spinner to signal that data is being loaded
        this.isLoading = true;

        // console.log('loadMore.start... ', this.isLoading, this.data_, this.totalNumberOfRows, this.orderBy);
        if( this.data_ && this.data_.length > 0){
            // (!this.isSorting || (this.data_ == null || !this.data_)) &&
            if(!this.totalNumberOfRows || this.data_.length >= this.totalNumberOfRows){
                // this.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = false;
                this.isLoading = false;
                this.lastRecord = null;
            } else {

                let lastRecord = this.data_[this.data_.length - 1];
                if(lastRecord){
                    let lookupOrderBy = this.orderBy.split('.');
                    if(lookupOrderBy.length > 1){
                        let resultValue;
                        lookupOrderBy.forEach(val =>{
                            resultValue = (   
                                (resultValue == undefined) && lastRecord[val] ||
                                (resultValue != null && typeof resultValue == 'object' && resultValue[val] != undefined) && resultValue[val] ||
                                resultValue
                            );
                        });
                        this.lastRecord = {
                            id: lastRecord.Id,
                            value: resultValue
                        };

                    }else{
                        this.lastRecord = {
                            id: lastRecord.Id,
                            value: lastRecord[this.orderBy] != undefined ? lastRecord[this.orderBy] : null
                        };

                    }
                }
                this.stopSearchTimeout();
                this.loadingMore = true;
                this.searchTimer = setTimeout(() => {
                    scope.doSearch(Object.assign(this.lastSearchParams, {lastRecord: this.lastRecord}));
                }, 300);
            }
        } else {
            this.isLoading = false;
        }
        // console.log('loadMoreData end...');
    }

    stopSearchTimeout(){
        this.loadingMore = false;
        if(this.searchTimer){
            clearTimeout(this.searchTimer);
        }
    }

    disconnectedCallback(){
        this.stopSearchTimeout();
    }

    get searchText(){
        return this.searchText_;
    }
    set searchText(value){
        this.searchText_ = value;
    }

    refreshTimer;
    handleRefreshTable(evt){
        let scope = this;
        if(scope.refreshTimer != null){
            clearTimeout(scope.refreshTimer);
        }
        if(searchTextTimer == null){
            scope.refreshTimer = setTimeout(function() {
                scope.lastRecord = null;
                scope.lastSearchParams.lastRecord = null;
                scope.doSearch({...scope.lastSearchParams,});
            }, 300);
        }
    }

    setSearchTextWithTimeout(value){
        this.searchText_ = value;
        this.normText = value.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    }

    searchTextTimer;
    setSearchText(evt) {
        let scope = this;
        if(scope.searchTextTimer != null){
            clearTimeout(scope.searchTextTimer);
        }
        scope.searchTextTimer = setTimeout(function() {
            scope.setSearchTextWithTimeout(evt.detail.value);
            if(evt.detail.value.length > 3) {
                scope.lastRecord = null;
                scope.lastSearchParams.lastRecord = null;
                // scope.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = true;
                scope.doSearch({...scope.lastSearchParams,...{searchText: scope.searchText_, normText: scope.normText}});
            }
            if(evt.detail.value.length == 0){
                scope.lastRecord = null;
                scope.lastSearchParams.lastRecord = null;
                scope.lastSearchParams.searchText = null;
                // scope.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = true;
                scope.doSearch({...scope.lastSearchParams});
            }
        }, 1200);
    }
    
    isRendered = false;
    renderedCallback() {
        if(!this.isRendered){
            this.enforceStyles();
            this.isRendered = true;
            this.handleSubscripe();
        }
        this.buildDynamicStyles();
    }

    connectedCallback(){
        
        this.getFixFilters();
        this.getOrders();
    }

    subscription = [];
    @api handleSubscripe(){
        let scope = this;
        const messageCallbackAnswer = function (response) {

            if(response.data.payload.User__c == Id){
                let newData = [...scope.data];
                let rowData = newData.find(d =>{return d.id == response.data.payload.Opportunity__c});
                if(rowData){
                    if(response.data.payload.Answered__c && !scope.notAnswered){
                        
                        rowData.answered = 'standard:task2';
                        rowData.icon = ' ';
                        scope.data_ = newData;
                    }else if(!scope.notAnswered){
                        
                        rowData.answered = '';
                        rowData.icon = '';
                        scope.data_ = newData;
                    }else{
                        
                        let filterData = newData.filter(rd => {return rd.id != response.data.payload.Opportunity__c});
                        
                        scope.data_ = [...filterData];
                    }
                }else if(scope.notAnswered){
                    
                    scope.searchTimer = setTimeout(() => {
                        scope.lastRecord = null;
                        scope.lastSearchParams.lastRecord = null;
                        // scope.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = true;
                        scope.doSearch(scope.lastSearchParams);
                    }, 300);
                }
            }
        };

        const messageCallbackOrder = function (response){
            let owners = response.data.payload.User__c.split(';');
            if(owners.contains(Id)){
               scope.orderCount += response.data.payload.OrderQuant__c;
            }
        };
        subscribe('/event/AnsweredQuote__e', -1, messageCallbackAnswer).then((response) => {
            
            // console.log('inscrito Aswered');
            this.subscription.push(response);
        });
        subscribe('/event/OrderCount__e', -1, messageCallbackOrder).then((response) => {
            
            // console.log('inscrito Order');
            this.subscription.push(response);
        });
    }

    @api handleUnsubscribe() {

        // Invoke unsubscribe method of empApi
        this.subscription.forEach(sub =>{
            
            unsubscribe(sub, (response) => {
                // console.log('unsubscribe() response: ', JSON.stringify(response));
                // Response is true for successful unsubscribe
            });
        })

        
    }

    enforceStyles(){
        let style = document.createElement('style');
        style.innerText = (`

            div.desktop.container.forceStyle.oneOne.navexDesktopLayoutContainer.lafAppLayoutHost.forceAccess.tablet > div.viewport > section > div.navexWorkspaceManager > div > div.tabsetBody.main-content.mainContentMark.fullheight.active.fullLeft.splitViewDisabled > div {
                max-height: 99% !important;
                overflow: revert !important;
            }
        
            c-budget-tab .header .fixed-filters .slds-combobox__input {
                border: none !important;
                border-color: transparent !important;
                padding-left: 0px;
                font-size: large;
                font-weight: 600;
                margin-top: -10px;
                background-color: transparent;
                box-shadow: none !important;
            }

            c-budget-tab div.slds-box.content.slds-is-relative div.search-text-area.slds-grid_align-spread div.search-text-inner-area.slds-col lightning-button {
                font-size: large;
                font-weight: 600;
                margin-top: -10px;
                box-shadow: none !important;
            }

            c-budget-tab .header lightning-combobox {
                margin-top: -5px;
                margin-left: 5px;
            }

            c-budget-tab div.slds-box.content {
                min-height: 100%;
            }

            c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling {
                overflow: auto !important;
            }

            c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable > div.dt-outer-container {
                height: fit-content;
                width: fit-content;
            }

            c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable > div.dt-outer-container > div {
                min-height: 30px !important;
                display: -webkit-box !important;
            }

            c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable .slds-scrollable_y, c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable .slds-scrollable_x {
                overflow: hidden !important;
            }

            c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable .slds-scrollable_y, c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable table {
                width: max-content !important;
            }

            c-budget-tab div.slds-box.content.slds-is-relative c-budget-tab-filters-custom lightning-pill span lightning-button-icon{
                display: none;
            }
            
            c-budget-tab .data-table .wrapped-header-datatable .slds-table .slds-th__action .slds-truncate{
                max-width: 100%;
                overflow: hidden;
                text-overflow: unset;
                white-space: pre-line;
                /* word-wrap: break-word; */
            }
            
            c-budget-tab .data-table .wrapped-header-datatable .slds-table .slds-th__action {
                height: 3rem;
                border-bottom: 1px solid rgb(206 206 206);
            }
            
            c-budget-tab .data-table .wrapped-header-datatable .slds-table .slds-line-height_reset{
                height: 1rem;
            }
            c-budget-tab div.data-table.infinite-scrolling.tabela lightning-datatable table > thead > tr > th lightning-primitive-header-factory > span{
                z-index: 2;
            }
            c-budget-tab div.data-table.infinite-scrolling.tabela lightning-datatable table thead tr th lightning-primitive-header-factory div{
                z-index: 2;
            }

            c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable table tbody tr td.iconAlign lightning-primitive-cell-factory span{
                justify-content: center;
            }
            c-budget-tab div.slds-box.content.slds-is-relative c-budget-tab-filters-custom lightning-pill span lightning-button-icon{
                display: none;
            }
        `);
        this.template.querySelector('.style-element').appendChild(style);
        
    }

    handleFilterVisibilityChange(){
        this.buildDynamicStyles();
    }

    offsetHeight;
    buildDynamicStyles(){
        let scope = this;
        setTimeout(() => {
            let styleWrapper = scope.template.querySelector('div.dynamic-style-container');
    
            let innerText = '';
    
            let containerElement = scope.template.querySelector('div.filters-section');
            if(containerElement && containerElement.offsetHeight && containerElement.parentElement.offsetHeight){
                // c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling > lightning-datatable > div.dt-outer-container > div {
                // console.log('containerElement:::', containerElement);
                if(!scope.offsetHeight){
                    scope.offsetHeight = containerElement.parentElement.offsetHeight;
                }
                // console.log('containerElement.offsetHeight:::', containerElement.offsetHeight);
                // console.log('scope.offsetHeight:::', scope.offsetHeight);
                let maxHeight = scope.offsetHeight - containerElement.offsetHeight - 50;
                // console.log('maxHeight:::', maxHeight);
                innerText += `
                    @media (max-height: 800px) {
                        c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling {
                            max-height: 340px;
                        }
                    }
                    @media (min-height: 801px) {
                        c-budget-tab div.slds-box.content > div.data-table.infinite-scrolling {
                            max-height: ${maxHeight}px;
                        }
                    }
                `;
            }
            
            if(innerText){
            
                // reset the wrapper component
                if(styleWrapper){
                    while (styleWrapper.firstElementChild) {
                        styleWrapper.firstElementChild.remove();
                    }
                }
                
                let style = document.createElement('style');
                // create the new style element
                style.innerText = innerText;
                styleWrapper.appendChild(style);
            }
        }, 10);
    }

    styleTypes = {
        "AguardandoIntegração": ["#eded94","#d3d387", "#a1a137"],
        "Aprovado": ["#b0c2fb","#8ca6f9","#5a74c7"],
        "Cancelada": ["#fca6e8","#ce97c1","#9749a1"],
        "Emdigitação": ["#eded94","#d3d387", "#a1a137"],
        "Encerrado": ["#adadad","#a3a3a3", "#444444"],
        "Falhanaintegração": ["#d3a1ff","#ab80d1", "#7e6a95"],
        "Fechado/Gerado": ["#a0fba1","#8cd38c","#66b767"],
        "Fechado/Perdido": ["#adadad","#a3a3a3", "#444444"],
        "NãoRespondida": ["#adadad","#a3a3a3", "#444444"],
        "GerarPedido": ["#a0fba1","#8cd38c","#66b767"],
        "Respondida": ["#b0c2fb","#8ca6f9","#5a74c7"],
        "Novo":["#ffffff","#e5e5e5", "#9b9898"],
        "SemRetorno": ['#ebcd9d','#e7c38a','#b99b6b'],
        "Red": "#f88081"
    };

    classFactory(){
        let style = document.createElement('style');
        let innerText =``;
        let lastBackground;
        let lastStageName;
        let newD = (new Date()).getTime();
        if(this.data_){
            this.data_.forEach(item => {
                let itStage = item.StageName.replaceAll(' ','');
                let budgetD = (new Date(item.DataVencimento__c)).getTime();
                let background = this.styleTypes[itStage] ? this.styleTypes[itStage][0] : null;
                lastStageName = itStage;
    
                if(background){
                    
                    if(lastBackground == background && lastStageName == itStage){
                        lastBackground = null; 
                        background = this.styleTypes[itStage][1];
                    } else{
                        lastBackground = background;
                    }
    
                    if(
                        itStage == 'Novo' &&
                        newD <= budgetD &&
                        budgetD <= (newD+3600000)
                    ){
                        
                        background = this.styleTypes['Red'];
                    }
    
                    innerText +=`
                        c-budget-tab tbody tr[data-row-key-value="`+item.Id+`"]{
                        background-color: `+ background +`;
                        --lwc-colorBackgroundRowHover:
                        `+background+`;
                        }
                    `;
                    
                }
             
            });
        }

        Object.keys(this.styleTypes).forEach(sty =>{
            innerText +=`
            c-budget-tab c-budget-tab-filters div.content div.filters button.slds-button.`+sty+`.true{
                --slds-c-button-color-background:
               `+this.styleTypes[sty][2]+`;
               color: white;
               font-weight: 400;
               padding-left:10px; padding-right:10px;
            }
            c-budget-tab c-budget-tab-filters div.content div.filters button.slds-button.`+sty+`.false{
                --slds-c-button-color-background:
                `+this.styleTypes[sty][0]+`;
                padding-left:10px; padding-right:10px;
            }
            `;
        });
        if(innerText){

            let element = this.template.querySelector('.style-element-color-bg');
          
            if(element){
                
                while (element.firstChild) {
                    element.removeChild(element.lastChild);
                }
                style.innerText = innerText;
                element.appendChild(style);
            }
        }
    }

    loadingMore;
    handleScroll(e) {
        if( !this.loadingMore && this.data && this.data.length > 0 ){
            this.showSpinner = true;

            if (e.target.offsetHeight + e.target.scrollTop >= e.target.scrollHeight) {
                
                this.loadMoreData();
                
                e.stopPropagation();
                e.preventDefault();
            } else {
                this.showSpinner = false;
            }
        }

    }

    get pinnedFilterIcon(){
        return this.pinnedFilter === this.selectedFilter ? 'utility:pinned' : 'utility:pin';
    }

    selectedFilter;
    @track fixedFiltersOptions = [];
    fixedFilters = {};
    pinnedFilter;
    getFixFilters(){
        let scope = this;
        doCalloutWithStdResponse(scope, getFixedFilters, {}).then(response => {

            scope.fixedFilters = JSON.parse(response.data.fixedFilters);
            scope.fixedFiltersOptions = JSON.parse(response.data.fixedFiltersOptions);
            scope.pinnedFilter = (response.data.pinnedFilter || scope.fixedFiltersOptions.find(fixfilter =>{return fixfilter.label === 'Todos'})?.value);
            scope.selectedFilter = scope.pinnedFilter;
        }).catch(error => {
            console.log('Error to get fixedFilters', JSON.stringify(error));
        }).finally(()=>{
            scope.handlFilterChange(scope.selectedFilter);
        });
    }

    handleNewFilter(){
        this.getFixFilters();
        this.openNewFixFilterModal = false;
    }

    closeModalCustomFilter(evt){
        this.openNewFixFilterModal = false;
    }

    handleFilterPinClick(event){
        if(this.pinnedFilterIcon === 'utility:pinned'){
            this.pinnedFilter = null;
        }else{
            this.pinnedFilter = this.selectedFilter;
        }
        doCalloutWithStdResponse(this, updatePinnedCustomFilter, {filterId : this.pinnedFilter});
    }

    isSorting;
    onHandleSort(evt) {
        let table = this.template.querySelector('div.tabela > lightning-datatable');
        this.searchText_ = '';
        let sortedBy = evt.detail.fieldName;
        this.orderDirection = this.orderDirection == 'asc' ? 'desc' : 'asc';
        table.sortDirection = this.orderDirection;
        if(sortedBy == 'opportunityUrl'){
            this.orderBy = 'NumeroOrcamento__c';
        } else if(sortedBy == 'accountUrl'){
            this.orderBy = 'Account.Name';
        } else if(sortedBy == 'DataVencimento__c'){
            this.orderBy = 'DataVencimento__c';
        } else if(sortedBy == 'AccountBillingCity'){
            this.orderBy = 'Account.BillingCity';
        } else if(sortedBy == 'AccountBillingState'){
            this.orderBy = 'Account.BillingState';
        } else {
            this.orderBy = sortedBy;
        }
        // console.log('onHandleSort.detail:::', JSON.stringify(evt.detail));
        this.lastRecord = null;
        this.isLoading = true;
        this.isSorting = true;
        this.data_ = [];

        this.searchTimer = setTimeout(() => {
            // table.enableInfiniteLoading = true;
            let par = {...this.lastSearchParams,...{orderBy: this.orderBy, orderDirection: this.orderDirection, lastRecord:this.lastRecord}};
            this.doSearch(par);
        }, 300);
    }

    handleFilterClick(evt){
        evt.stopPropagation();
        // this.searchText_ = null;
        this.lastRecord = null;
        if(evt.detail.statusSearch && evt.detail.statusSearch.includes('Gerar Pedido') && evt.detail.quoteIntegratorId && evt.detail.quoteIntegratorId != ''){
            this.orderDirection = 'desc';
            this.expiredValue = true;
        }
        let params = {
            searchStatus: evt.detail.statusSearch.join(';'),
            statusSearch: evt.detail.statusSearch ? evt.detail.statusSearch.filter(item => {return item !== undefined}): undefined,
            canalEntradaSelected: evt.detail.canalEntradaSelected ? evt.detail.canalEntradaSelected.map(item => item.value).filter(item => {return item !== undefined}) : undefined,
            vendedorSelected: evt.detail.vendedorSelected ? evt.detail.vendedorSelected.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
            teamMember: evt.detail.teamMember ? evt.detail.teamMember.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
            mesaSelected: evt.detail.mesaSelected ? evt.detail.mesaSelected.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
            categoriaSelected: evt.detail.categoriaSelected ? evt.detail.categoriaSelected.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
            quoteIntegratorId: evt.detail.quoteIntegratorId,
            quoteType: evt.detail.quoteType,
            cnpjCliente: evt.detail.cnpjCliente,
            nomeCliente: evt.detail.nomeCliente,
            produto: evt.detail.produto,
            ufCliente: evt.detail.ufCliente,
            cidadeCliente: evt.detail.cidadeCliente,
            vencimentoCotacao: evt.detail.vencimentoCotacao,
            orderBy: evt.detail.orderBy,
            orderDirection: this.orderDirection,
            lastRecord: null,
            itemsPerPage: evt.detail.itemsPerPage,
            queryLimit: evt.detail.queryLimit,
            expired: this.expiredValue,
            notAnswered: this.notAnswered,
            searchText: this.searchText_,
            normText: this.normText
        };
        
        // this.template.querySelector('div.tabela > lightning-datatable').enableInfiniteLoading = true;
        this.doSearch(params);
    }

    paramsToSave = [];
    handleSaveFilterClick(evt){
        evt.stopPropagation();
        // this.searchText_ = null;
        this.lastRecord = null;
        let params = [
            {
                statusSearch: evt.detail.statusSearch && evt.detail.statusSearch.length >0 ? evt.detail.statusSearch.filter(item => {return item !== undefined}) : undefined,
                canalEntradaSelected: evt.detail.canalEntradaSelected ? evt.detail.canalEntradaSelected.map(item => item.value).filter(item => {return item !== undefined}) : undefined,
                vendedorSelected: evt.detail.vendedorSelected ? evt.detail.vendedorSelected.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
                teamMember: evt.detail.teamMember ? evt.detail.teamMember.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
                mesaSelected: evt.detail.mesaSelected ? evt.detail.mesaSelected.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
                categoriaSelected: evt.detail.categoriaSelected ? evt.detail.categoriaSelected.map(item =>  item.value).filter(item => {return item !== undefined}) : undefined,
                quoteIntegratorId: evt.detail.quoteIntegratorId,
                quoteType: evt.detail.quoteType,
                cnpjCliente: evt.detail.cnpjCliente,
                nomeCliente: evt.detail.nomeCliente,
                produto: evt.detail.produto,
                ufCliente: evt.detail.ufCliente,
                cidadeCliente: evt.detail.cidadeCliente,
                vencimentoCotacao: evt.detail.vencimentoCotacao,
                orderBy: evt.detail.orderBy,
                orderDirection: this.orderDirection,
                lastRecord: null,
                itemsPerPage: evt.detail.itemsPerPage,
                queryLimit: evt.detail.queryLimit,
                expired: this.expiredValue,
                notAnswered: this.notAnswered,
                searchText: this.searchText_,
                normText: this.normText
            },
            {
                "Status: ":  evt.detail.statusSearch && evt.detail.statusSearch.length >0 ? evt.detail.statusSearch.filter(item => {return item !== undefined}).join('; ') : undefined,
                "Canal de Vendas: ": evt.detail.canalEntradaSelected && evt.detail.canalEntradaSelected.length >0 ? evt.detail.canalEntradaSelected.map(item => item.value).filter(item => {return item !== undefined}).join('; ') : undefined,
                "Representante (VDE): ": evt.detail.vendedorSelected && evt.detail.vendedorSelected.length >0 ? evt.detail.vendedorSelected.map(item =>  item.label).filter(item => {return item !== undefined}).join('; ') : undefined,
                "Vendedor (VDI): ": evt.detail.teamMember && evt.detail.teamMember.length >0 ? evt.detail.teamMember.map(item =>  item.label).filter(item => {return item !== undefined}).join('; ') : undefined,
                "ID da cotação: ": evt.detail.quoteIntegratorId,
                "Tipo de Cotação: ": evt.detail.quoteType,
                "CNPJ do cliente: ": evt.detail.cnpjCliente,
                "Mesa: ": evt.detail.mesaSelected && evt.detail.mesaSelected.length >0 ? evt.detail.mesaSelected.map(item =>  item.label).filter(item => {return item !== undefined}).join('; ') : undefined,
                "Categoria: ": evt.detail.categoriaSelected && evt.detail.categoriaSelected.length >0 ? evt.detail.categoriaSelected.map(item =>  item.label).filter(item => {return item !== undefined}).join('; ') : undefined,
                "Nome do cliente: ": evt.detail.nomeCliente,
                "Produto: ": evt.detail.produto,
                "UF do Cliente: ": evt.detail.ufCliente && evt.detail.ufCliente.length >0 ? evt.detail.ufCliente.filter(item => {return item !== undefined}).join('; ') : undefined,
                "Cidade do Cliente: ": evt.detail.cidadeCliente && evt.detail.cidadeCliente.length >0 ? evt.detail.cidadeCliente.filter(item => {return item !== undefined}).join('; ') : undefined,
                "Data de Vencimento: ": evt.detail.vencimentoCotacaoText,
                "Exibir Vencidos: ": this.expiredValue ? "✓ ": undefined,
                "Apenas Não Respondidos: ": this.notAnswered ? "✓ ": undefined,
                "Busca Geral: ": this.searchText_,
            },
        ];
        this.paramsToSave = params;
        this.openNewFixFilterModal = true;
    }

    handleFixedFilterChange(evt){
        this.handlFilterChange(evt.target.value);
    }

    handlFilterChange(value){
        let params = {...this.fixedFilters[value]};
        this.selectedFilter = value;
        this.expiredValue = params.expired;
        this.searchText = params.searchText;
        this.notAnswered = params.notAnswered;
        this.template.querySelector("c-budget-tab-filters").setSearchCritereas(params, true);
        this.template.querySelector("c-budget-tab-filters").toggleFiltersVisibility(false);
        this.searchTimer = setTimeout(() => {
            this.doSearch(params);
        }, 300);
    }

    @api doSearch(params){
        let scope = this;
        // console.log(JSON.stringify(params));
        scope.isLoading = true;
        if(params == undefined){
            params = scope.setStandardParams();
        }
        if(!scope.lastRecord){
            scope.totalNumberOfRows = 0;
        } else {
            params.lastRecord = scope.lastRecord;
        }
        scope.lastSearchParams = params;
        // console.log('doSearch >> JSON.stringify(params):::', JSON.stringify(params), params, scope.data_.length);
        doCalloutWithStdResponse(scope, doSearch, {filtersJson: JSON.stringify(params)}).then(response => {
            // console.log('doSearch >> doSearch.response:::', {...response});
            // console.log('doSearch >> scope.lastRecord:::', scope.lastRecord);
            if(scope.lastRecord == null || scope.isSorting){
                scope.totalNumberOfRows = response.data.count;
            }
            scope.data_ = [
                ...(!!scope.lastRecord && !!scope.lastRecord.id && !!scope.data_ && scope.data_.length > 0 ? scope.data_ : []), 
                ...response.data.records.map(item => {
                    
                    item.icon = '';
                    item.answered ='';

                    if(item.QuoteItems__r && item.QuoteItems__r.length > 0){
                        let userItems = item.QuoteItems__r.filter(qitem =>{
                            return qitem.Vendedor__c === Id;
                        });
                        let answeredUserItems = userItems.filter(qitem =>{
                            return qitem.TabulacaoN1__c && qitem.TabulacaoN1__c != '';
                        });
                        if(userItems.length > 0 && answeredUserItems.length > 0 && userItems.length == answeredUserItems.length){
                            item.answered = 'standard:task2';
                            item.icon = ' ';
                        }
                    }

                    if(item.Orders && item.Orders.length > 0){
                        let aprOrders = item.Orders.filter(ord =>{
                            return (ord.Status === 'Aprovado');
                        });
                        if(aprOrders && aprOrders.length > 0 && aprOrders.length == item.Orders.length){
                            item.ordersDoneLabel = 'Sim';
                            item.ordersDoneURL = '/lightning/r/Opportunity/'+item.Id+'/related/Orders/view';
                        }
                        else{
                            item.ordersDoneLabel = 'Não';
                            item.ordersDoneURL = '/lightning/r/Opportunity/'+item.Id+'/related/Orders/view';
                        }
                    }
                    else{
                        item.ordersDoneLabel = 'Sem Pedido';
                        item.ordersDoneURL = '/' + item.Id;
                    }
                    item.quoteitemsTotalSize = 
                            '  ' + ((new Set(item.QuoteItems__r?.map(qi =>{ return qi.IdCustomer__c}))).size || 0) + 
                            '  /  ' + (item.QuantidaItensNaoResp__c || 0) + 
                            '  /  ' + (item.QuantidadeItensRespondidos__c || 0) + 
                            '  /  ' + (item.quantidadeItensConfirmados__c || 0);
                    if(item.Account){
                        item.AccountName = item.Account.Name;
                        item.AccountBillingCity = item.Account.BillingCity;
                        item.AccountBillingState = item.Account.BillingState;
                        item.accountUrl = '/' + item.AccountId;
                    }
                    item.id = item.Id;
                    item.opportunityUrl = '/' + item.Id;
                    
                    return item;
                })
            ];

            // console.log('doSearch >> scope.data:::', scope.data, scope.data_ );
            scope.data_ = [...scope.data_].filter(item => { return item !== undefined });
            if (scope.data_.length >= scope.totalNumberOfRows) {
                // scope.template.querySelector('lightning-datatable').enableInfiniteLoading = false;
            } else {
                scope.lastRecord = null;
            }
            if(response.data.records && (response.data.records.length == 0 || response.data.records.length < scope.itemsPerPage)){
                scope.totalNumberOfRows = scope.data_.length;
            }
        }).catch(error => {
            scope.totalNumberOfRows = 0;
            console.log('Callout error:::', error);
            // scope.template.querySelector('div.tabela > lightning-datatable').dispatchEvent(new CustomEvent("customsearchresult", {
            //     detail: {
            //         success: false,
            //         error: error
            //     }
            // }));
        }).finally(()=> {
            // console.log('finally');
            scope.isLoading = false;
            scope.isSorting = false;
            scope.loadingMore = false;
            this.classFactory();
            this.setSearchTimer();
        });
    }

    @track searchTimerText;
    searchTimer;

    setSearchTimer() {
        let scope = this;
        scope.searchTimerText = 'Atualizado há menos de 1 minuto';
        while(scope.searchTimer--){
            clearTimeout(scope.searchTimer);
        }
        //intervalos de 1-9min
        for(let i=1;i<10;i++){
            scope.delayTime(i*60000, 'Atualizado há ');
        }
        //10m
            scope.delayTime(600000, 'Atualizado há mais de ');
        //15m
            scope.delayTime(900000, 'Atualizado há mais de ');
        //intervalos de 10m começando 20m-1h
        for(let i=2;i<5;i++){
            scope.delayTime(i*600000, 'Atualizado há mais de ');
        }
        //intervalos de 30m começando 1h30,2h,3h
        for(let i=3;i<6;i++){
            scope.delayTime(i*1800000, 'Atualizado há mais de ');
        }
    }
    
    delayTime(timer, text){
        let scope = this;

        let hour = Math.trunc(timer/3600000);
        let min = Math.trunc((timer - hour*3600000)/60000);
        let textMin = min > 1 ? min + ' minutos' : min == 1 ? min + ' minuto' : '';
        let textHour = hour > 1 ? hour + ' horas' : hour == 1 ? hour + ' hora' : '';
        let hourAndMin = hour && min ? ' e ' : '';
        let textTm = text + textHour + hourAndMin + textMin;  
        scope.searchTimer = setTimeout(function() {
            // console.log(textTm);    
            scope.searchTimerText = textTm;
        }, timer);
    }
    
    @api getLastParams(){
        return this.lastSearchParams;
    }

    setStandardParams(params){
        if(params === undefined){
            params = {};
        }
        params = Object.assign(
            {
                orderBy: this.orderBy,
                orderDirection: this.orderDirection,
                itemsPerPage: this.itemsPerPage,
                expired: this.expiredValue,
                statusSearch: this.statusSearch,
                teamMember: ['userId'],
            },
            params
        );
        return params;
    }
}