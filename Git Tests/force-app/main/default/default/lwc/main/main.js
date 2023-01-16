import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// importing refresh view
import { updateRecord } from 'lightning/uiRecordApi';

//importing toast message event
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Main extends NavigationMixin(LightningElement) {

    @track loading = false;
    @api recordId;
    @track showDetail = true;
    @track totalPrice = 0;
    @track margemTotal = 0;
    @track margemAlvoTotal = 0;
    @track margemTotalString = "0%";
    @track margemAlvoTotalString = "0%";
    @track totalPriceString = "R$ 0";
    @track prodList = [
        {
         "id" : "prod1",   
         "code" : "0004774",   
         "nome" : "EQ.SISTEMA FECHADO IRRIGADOR              10312556",   
         "principioAtivo" : "                              ",    
         "fabricante" : "MEDSONDA IND. E COM. DE PROD. HOSP. DESC. LTDA.",   
         "anvisa" : "80163570027",   
         "categoria" : "TUBO",   
         "precoFabrica" : "R$ 0,77",  
         "precoTabela" : "R$ 0,77" ,  
         "temperatura" : "2C a 8C",  
         "ean" : "7898487863873"    
        },
        {
         "id" : "prod2",   
         "code" : "0004773",  
         "nome" : "CORSET ALTA COMPRESSAO BASE M                50327",   
         "principioAtivo" : "                              ",    
         "fabricante" : "PLIE CONFECCOES LTDA",   
         "anvisa" : "ISENTO",   
         "categoria" : "OUTROS",   
         "precoFabrica" : "R$ 118,84",  
         "precoTabela" : "R$ 118,84" ,  
         "temperatura" : "2C a 8C",  
         "ean" : "7890856124202  "    
        },
        {
         "id"             : "prod3",   
         "code"           : "0004772",  
         "nome"           : "CORSET ALTA COMPRESSAO BASE GG               50327",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS",   
         "precoFabrica"   : "R$ 118,84",  
         "precoTabela"    : "R$ 118,84" ,  
         "temperatura"    : "15C a 30C",  
         "ean"            : "7890856124226  "    
        },
        {
         "id"             : "prod4",   
         "code"           : "0004771",  
         "nome"           : "CORSET ALTA COMPRESSAO BASE G                50327",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS", 
         "precoFabrica"   : "R$ 106,35",  
         "precoTabela"    : "R$ 106,35" ,  
         "temperatura"    : "Inferior a 25C",  
         "ean"            : "7890856124219  "    
        },
        {
         "id"             : "prod5",   
         "code"           : "0004770",  
         "nome"           : "CORSET BASE M                                50320",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS", 
         "precoFabrica"   : "R$ 66,21",  
         "precoTabela"    : "R$ 66,21" ,  
         "temperatura"    : "Nao aplica",  
         "ean"            : "7890856108738  "    
        },
        {
         "id"             : "prod6",   
         "code"           : "0004769",  
         "nome"           : "CORSET BASE GG                               50320",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS",  
         "precoFabrica"   : "R$ 52,14",  
         "precoTabela"    : "R$ 52,14" ,  
         "temperatura"    : "Nao aplica",  
         "ean"            : "7890856108752  "    
        },
        {
         "id"             : "prod7",   
         "code"           : "0004768",  
         "nome"           : "CORSET BASE G                                50320",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS",   
         "precoFabrica"   : "R$ 59,26",  
         "precoTabela"    : "R$ 52,26" ,  
         "temperatura"    : "Nao aplica",  
         "ean"            : "7890856108745  "    
        },
        {
         "id"             : "prod8",   
         "code"           : "0004767",  
         "nome"           : "IMPLANTE GEL STX 340 HP P. ALTO XTRA       THPX340",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "JOHNSON E JOHNSON DO BRASIL IND. COM. PROD. PARA SAUDE LTDA ",   
         "anvisa"         : "80145901324         ",   
         "categoria"      : "PROTESE MAMARIA     ",   
         "precoFabrica"   : "R$ 822,53",  
         "precoTabela"    : "R$ 822,53" ,  
         "temperatura"    : "15C a 30C",  
         "ean"            : "08717694023674 "    
        },
        {
         "id"             : "prod9",   
         "code"           : "0004766",  
         "nome"           : "IMPLANTE GEL STX 325 HP P. ALTO XTRA       THPX325",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "JOHNSON E JOHNSON DO BRASIL IND. COM. PROD. PARA SAUDE LTDA ",   
         "anvisa"         : "80145901324         ",   
         "categoria"      : "PROTESE MAMARIA     ",   
         "precoFabrica"   : "R$ 1371,16",  
         "precoTabela"    : "R$ 1371,16" ,  
         "temperatura"    : "2C a 8C",  
         "ean"            : "0871769402363  "    
        },
        {
         "id"             : "prod10",   
         "code"           : "0004765",  
         "nome"           : "IMPLANTE GEL STX 285 HP P. ALTO XTRA       THPX285",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "JOHNSON E JOHNSON DO BRASIL IND. COM. PROD. PARA SAUDE LTDA ",   
         "anvisa"         : "80145901324         ",   
         "categoria"      : "PROTESE MAMARIA     ",   
         "precoFabrica"   : "R$ 987,70",  
         "precoTabela"    : "R$ 987,70" ,  
         "temperatura"    : "2C a 8C",  
         "ean"            : "0871769402363  "    
        }
    ];
    @track cdList = [
        {
         "id" : "cd1",  
         "code" : "0004774",   
         "nome" : "EQ.SISTEMA FECHADO IRRIGADOR              10312556",   
         "principioAtivo" : "                              ",   
         "fabricante" : "MEDSONDA IND. E COM. DE PROD. HOSP. DESC. LTDA.",   
         "anvisa" : "80163570027",   
         "categoria" : "TUBO",   
         "precoFabrica" : 0.77,  
         "precoTabela" :  0.77 ,  
         "precotabela" :  0.77 ,  
         "temperatura" : "2C a 8C",  
         "ean" : "7898487863873"   ,
         
         "index" : "1",  
         "cds" : "01 - São Paulo",   
         "lote" : "709515-04/2021",   
         "estoque" : "500 CX",   
         "un" : "UN",   
         "quantidade" : 0,  
         "unitario" : 15 ,  
         "desconto" : 0,    
         "valorTotal" : 0,  
         "custoDif" : 0.3,
         "custo" : 0.2,
         "margem" : 0,
         "margemAlvo" : "20%",    
         "margemAlvoInput" : 20     
        },
        {
         "id" : "cd2",  
         "code" : "0004774",   
         "nome" : "EQ.SISTEMA FECHADO IRRIGADOR              10312556",   
         "principioAtivo" : "                              ",   
         "fabricante" : "MEDSONDA IND. E COM. DE PROD. HOSP. DESC. LTDA.",   
         "anvisa" : "80163570027",   
         "categoria" : "TUBO",   
         "precoFabrica" : 0.77,  
         "precoTabela" :  0.77 ,  
         "precotabela" :  0.77 ,  
         "temperatura" : "2C a 8C",  
         "ean" : "7898487863873"   ,
         
         "index" : "2", 
         "cds" : "04 - Brasilia",   
         "lote" : "709575-04/2021",   
         "estoque" : "850 CX",   
         "un" : "UN",   
         "quantidade" : 0,  
         "unitario" : 17 ,  
         "desconto" : 0,    
         "valorTotal" : 0,  
         "custoDif" : 7,
         "custo" : 9,
         "margem" : 0,
         "margemAlvo" : "20%",    
         "margemAlvoInput" : 20  
        }
    ];
    @track cdListAditional = [
        {
         "id" : "cd7",   
         "code" : "0004773",  
         "nome" : "CORSET ALTA COMPRESSAO BASE M                50327",   
         "principioAtivo" : "                              ",    
         "fabricante" : "PLIE CONFECCOES LTDA",   
         "anvisa" : "ISENTO",   
         "categoria" : "OUTROS",   
         "precoFabrica" : 118.84,  
         "precoTabela" : 118.84,  
         "precotabela"    : 118.84 ,  
         "temperatura" : "2C a 8C",  
         "ean" : "7890856124202  ",

         "index" : "3",  
         "cds" : "01 - São Paulo",   
         "lote" : "709515-04/2021",   
         "estoque" : "500 CX",   
         "un" : "UN",   
         "quantidade" : 10,  
         "unitario" : 118.84 ,  
         "desconto" : 0,    
         "valorTotal" : 1188.40,  
         "custoDif" : 0.3,
         "custo" : 0.2,
         "margem" : 0,
         "margemAlvo" : "20%",    
         "margemAlvoInput" : 20     
        },
        {
         "id" : "cd8",   
         "code" : "0004773",  
         "nome" : "CORSET ALTA COMPRESSAO BASE M                50327",   
         "principioAtivo" : "                              ",    
         "fabricante" : "PLIE CONFECCOES LTDA",   
         "anvisa" : "ISENTO",   
         "categoria" : "OUTROS",   
         "precoFabrica" : 118.84,  
         "precoTabela" : 118.84,  
         "precotabela"    : 118.84 ,  
         "temperatura" : "2C a 8C",  
         "ean" : "7890856124202  ",
         
         "index" : "4", 
         "cds" : "04 - Brasilia",   
         "lote" : "709575-04/2021",   
         "estoque" : "850 CX",   
         "un" : "UN",   
         "quantidade" : 10,  
         "unitario" : 118.84 ,  
         "desconto" : 0,    
         "valorTotal" : 1188.40,  
         "custoDif" : 7,
         "custo" : 9,
         "margem" : 0,
         "margemAlvo" : "20%",    
         "margemAlvoInput" : 20  
        }, 
        {
         "id"             : "cd8",   
         "code"           : "0004772",  
         "nome"           : "CORSET ALTA COMPRESSAO BASE GG               50327",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS",   
         "precoFabrica"   : 118.84,  
         "precoTabela"    : 118.84 ,  
         "precotabela"    : 118.84 ,  
         "temperatura"    : "15C a 30C",  
         "ean"            : "7890856124226  ", 

         "index" : "5",  
         "cds" : "01 - São Paulo",   
         "lote" : "709515-04/2021",   
         "estoque" : "500 CX",   
         "un" : "UN",   
         "quantidade" : 10,  
         "unitario" : 118.84 ,  
         "desconto" : 0,    
         "valorTotal" : 1188.40,  
         "custoDif" : 0.3,
         "custo" : 0.2,
         "margem" : 0,
         "margemAlvo" : "20%",    
         "margemAlvoInput" : 20     
        },
        {
         "id"             : "cd9",   
         "code"           : "0004772",  
         "nome"           : "CORSET ALTA COMPRESSAO BASE GG               50327",   
         "principioAtivo" : "                              ",    
         "fabricante"     : "PLIE CONFECCOES LTDA",   
         "anvisa"         : "ISENTO",   
         "categoria"      : "OUTROS",   
         "precoFabrica"   : 118.84,  
         "precoTabela"    : 118.84 ,  
         "precotabela"    : 118.84 ,  
         "temperatura"    : "15C a 30C",  
         "ean"            : "7890856124226  ", 
         
         "index" : "6", 
         "cds" : "04 - Brasilia",   
         "lote" : "709575-04/2021",   
         "estoque" : "850 CX",   
         "un" : "UN",   
         "quantidade" : 10,  
         "unitario" : 118.84 ,  
         "desconto" : 0,    
         "valorTotal" : 1188.40,  
         "custoDif" : 7,
         "custo" : 9,
         "margem" : 0,
         "margemAlvo" : "20%",    
         "margemAlvoInput" : 20  
        }
    ];
    @track prodFilterList = this.prodList;


    @track filteredProdList = this.prodList;

    @track openSectionProdList;
    @track openSectionProd;
    @track openSectionSelectedItens;
    @api label;

    connectedCallback() {
        console.log(this.recordId);
        if (typeof this.openSectionProdList === 'undefined') this.openSectionProdList = true;
        if (typeof this.openSectionSelectedItens === 'undefined') this.openSectionSelectedItens = true;
    }

    onChangeSearchProduct(event) {
        console.log(event.target.value);
        var regex = new RegExp(event.target.value, 'gi');
        this.filteredProdList = this.prodList.filter(
            row => regex.test(row.nome)
        );
    }

    addProdObject(product) {

        console.log(product);
        console.log(product.nome);
        var addProd = new Object();
        return addProd;
    }

    get sectionClassProdList() {
        return this.openSectionProdList ? 'slds-section slds-is-open' : 'slds-section';
    }

    get sectionClassSelectedItens() {
        return this.openSectionSelectedItens ? 'slds-section slds-is-open' : 'slds-section';
    }

    handleClickSectionProdList() {
        this.openSectionProdList = !this.openSectionProdList;
    }

    handleClickSectionProd() {
        this.openSectionProd = !this.openSectionProd;
    }

    handleClickSectionSelectedItens() {
        this.openSectionSelectedItens = !this.openSectionSelectedItens;
    }
    
    showLoading(show) {
        this.loading = show;
    }
    /*
    filterList(event) {
        debugger;
        prodFilterList = [];

        var val = event.target.value;
        prodList.forEach(function(item){
            if(item.nome.contains(val) || item.principioAtivo.contains(val) || item.fabricante.contains(val))
                prodFilterList.push(item);
        }, {prodFilterList, val});
    }*/

    async createOrder() {
        try {

            this.showLoading(true);

            this.showLoading(false);
            const evt = new ShowToastEvent({
                title: 'Pedido Gerado com Sucesso',
                message: 'Pedido foi gerado com Sucesso e integrado com o TOTVS',
                variant: 'success',
            });

            this.dispatchEvent(evt);

            if (!response.hasError) {
                this.closeQuickAction();
            }

        }
        catch(e) {
            console.log(e);
        }
    }
    async createQuote() {
        try {

            this.showLoading(true);

            this.showLoading(false);
            const evt = new ShowToastEvent({
                title: 'Orçamento Gerado',
                message: 'Orçamento de Numero: 0000101 gerado com Sucesso!!',
                variant: 'success',
            });

            this.dispatchEvent(evt);

            if (!response.hasError) {
                this.closeQuickAction();
            }

        }
        catch(e) {
            console.log(e);
        }
    }
    async sendApproval() {
        try {

            this.showLoading(true);

            this.showLoading(false);
            const evt = new ShowToastEvent({
                title: 'Orçamento enviado para aprovação',
                message: 'Devido o desconto informado, orçamento caiu para aprovação!!',
                variant: 'success',
            });

            this.dispatchEvent(evt);

            if (!response.hasError) {
                this.closeQuickAction();
            }

        }
        catch(e) {
            console.log(e);
        }
    }
    
    closeQuickAction() {
        console.log('fechando quick action');

        this.refreshView();
        
        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
    }

    calcPrice(event){
        debugger;
        var fieldName = event.target.name;
        var titleName = parseFloat(event.target.title) - 1;
        if(titleName <= 1)
            this.cdList[titleName][event.target.name] = event.target.value ? event.target.value : 0;
        else{
            titleName = parseFloat(event.target.title) - 3;
            this.cdListAditional[titleName][event.target.name] = event.target.value ? event.target.value : 0;
        }
        if(titleName <= 1){
            if(fieldName == 'unitario'){
                this.calcPriceUnit(titleName);
            }
            if(fieldName == 'margem'){
                this.calcPriceMargem(titleName);
            }
            if(fieldName == 'desconto'){
                this.calcPriceDesconto(titleName);
            }
            if(fieldName == 'quantidade'){
                this.calcPriceQuantidade(titleName);
            }
            this.formatVal(titleName);
        }else{
            if(fieldName == 'unitario'){
                this.calcPriceUnitAdd(titleName);
            }
            if(fieldName == 'margem'){
                this.calcPriceMargemAdd(titleName);
            }
            if(fieldName == 'desconto'){
                this.calcPriceDescontoAdd(titleName);
            }
            if(fieldName == 'quantidade'){
                this.calcPriceQuantidadeAdd(titleName);
            }
            this.formatValAdd(titleName);

        }
    }
    calcPriceUnit(titleName){
        this.cdList[titleName].desconto = (1 - (parseFloat(this.cdList[titleName].unitario)/parseFloat(this.cdList[titleName].precotabela)))*100;
        this.cdList[titleName].desconto = parseFloat(this.cdList[titleName].desconto) < 0 ? 0 : (parseFloat(this.cdList[titleName].desconto) > 100 ? 100 : parseFloat(this.cdList[titleName].desconto));
        this.cdList[titleName].valorTotal = parseFloat(this.cdList[titleName].unitario) * parseFloat(this.cdList[titleName].quantidade);
        this.cdList[titleName].margem = (1 - (parseFloat(this.cdList[titleName].custo)/(parseFloat(this.cdList[titleName].unitario)*(1.1))))*100;
    }
    calcPriceMargem(titleName){
        this.cdList[titleName].unitario = (parseFloat(this.cdList[titleName].custo)/(1-(parseFloat(this.cdList[titleName].margem)/100)))/1.1
        this.cdList[titleName].desconto = (1 - (parseFloat(this.cdList[titleName].unitario)/parseFloat(this.cdList[titleName].precotabela)))*100;
        this.cdList[titleName].desconto = parseFloat(this.cdList[titleName].desconto) < 0 ? 0 : (parseFloat(this.cdList[titleName].desconto) > 100 ? 100 : parseFloat(this.cdList[titleName].desconto));
        this.cdList[titleName].valorTotal = parseFloat(this.cdList[titleName].unitario) * parseFloat(this.cdList[titleName].quantidade);
    }
    calcPriceDesconto(titleName){
        this.cdList[titleName].unitario = parseFloat(this.cdList[titleName].precotabela) * (1-(parseFloat(this.cdList[titleName].desconto)/100))

        this.cdList[titleName].valorTotal = parseFloat(this.cdList[titleName].unitario) * parseFloat(this.cdList[titleName].quantidade);
        this.cdList[titleName].margem = (1 - (parseFloat(this.cdList[titleName].custo)/(parseFloat(this.cdList[titleName].unitario)*(1.1))))*100;
    }
    calcPriceQuantidade(titleName){
        this.cdList[titleName].valorTotal = parseFloat(this.cdList[titleName].unitario) * parseFloat(this.cdList[titleName].quantidade);
    }
    formatVal(titleName){
        this.cdList[titleName].quantidade  = parseFloat(parseFloat(this.cdList[titleName].quantidade).toFixed(2));
        this.cdList[titleName].desconto    = parseFloat(parseFloat(this.cdList[titleName].desconto).toFixed(2));
        this.cdList[titleName].valorTotal  = parseFloat(parseFloat(this.cdList[titleName].valorTotal).toFixed(2));
        this.cdList[titleName].margem      = parseFloat(parseFloat(this.cdList[titleName].margem).toFixed(2));
        this.cdList[titleName].unitario    = parseFloat(parseFloat(this.cdList[titleName].unitario).toFixed(2));

        var sumMargem = 0;
        var sumTotal = 0;
        var summargemAlvoInput = 0;
        var qtd = 0;
        this.cdList.forEach(function(item){
            sumTotal +=  item.valorTotal;
            sumMargem += item.margem ;
            summargemAlvoInput += item.margemAlvoInput ;
            if(item.quantidade){
                qtd++;
            }
        }, {sumMargem, sumTotal, summargemAlvoInput, qtd});

        qtd = (qtd == 0 ? 1 : qtd);
        this.margemTotal = sumMargem / qtd;
        this.totalPrice = sumTotal;
        this.margemAlvoTotal = summargemAlvoInput / qtd;

        this.margemTotalString = this.margemTotal+'%';
        this.margemAlvoTotalString = this.margemAlvoTotal+'%';
        this.totalPriceString  = 'R$ '+this.totalPrice;
    }
    calcPriceUnitAdd(titleName){
        this.cdListAditional[titleName].desconto = (1 - (parseFloat(this.cdListAditional[titleName].unitario)/parseFloat(this.cdListAditional[titleName].precotabela)))*100;
        this.cdListAditional[titleName].desconto = parseFloat(this.cdListAditional[titleName].desconto) < 0 ? 0 : (parseFloat(this.cdListAditional[titleName].desconto) > 100 ? 100 : parseFloat(this.cdListAditional[titleName].desconto));
        this.cdListAditional[titleName].valorTotal = parseFloat(this.cdListAditional[titleName].unitario) * parseFloat(this.cdListAditional[titleName].quantidade);
        this.cdListAditional[titleName].margem = (1 - (parseFloat(this.cdListAditional[titleName].custo)/(parseFloat(this.cdListAditional[titleName].unitario)*(1.1))))*100;
    }
    calcPriceMargemAdd(titleName){
        this.cdListAditional[titleName].unitario = (parseFloat(this.cdListAditional[titleName].custo)/(1-(parseFloat(this.cdListAditional[titleName].margem)/100)))/1.1
        this.cdListAditional[titleName].desconto = (1 - (parseFloat(this.cdListAditional[titleName].unitario)/parseFloat(this.cdListAditional[titleName].precotabela)))*100;
        this.cdListAditional[titleName].desconto = parseFloat(this.cdListAditional[titleName].desconto) < 0 ? 0 : (parseFloat(this.cdListAditional[titleName].desconto) > 100 ? 100 : parseFloat(this.cdListAditional[titleName].desconto));
        this.cdListAditional[titleName].valorTotal = parseFloat(this.cdListAditional[titleName].unitario) * parseFloat(this.cdListAditional[titleName].quantidade);
    }
    calcPriceDescontoAdd(titleName){
        this.cdListAditional[titleName].unitario = parseFloat(this.cdListAditional[titleName].precotabela) * (1-(parseFloat(this.cdListAditional[titleName].desconto)/100))

        this.cdListAditional[titleName].valorTotal = parseFloat(this.cdListAditional[titleName].unitario) * parseFloat(this.cdListAditional[titleName].quantidade);
        this.cdListAditional[titleName].margem = (1 - (parseFloat(this.cdListAditional[titleName].custo)/(parseFloat(this.cdListAditional[titleName].unitario)*(1.1))))*100;
    }
    calcPriceQuantidadeAdd(titleName){
        this.cdListAditional[titleName].valorTotal = parseFloat(this.cdListAditional[titleName].unitario) * parseFloat(this.cdListAditional[titleName].quantidade);
    }
    formatValAdd(titleName){
        this.cdListAditional[titleName].quantidade  = parseFloat(parseFloat(this.cdListAditional[titleName].quantidade).toFixed(2));
        this.cdListAditional[titleName].desconto    = parseFloat(parseFloat(this.cdListAditional[titleName].desconto).toFixed(2));
        this.cdListAditional[titleName].valorTotal  = parseFloat(parseFloat(this.cdListAditional[titleName].valorTotal).toFixed(2));
        this.cdListAditional[titleName].margem      = parseFloat(parseFloat(this.cdListAditional[titleName].margem).toFixed(2));
        this.cdListAditional[titleName].unitario    = parseFloat(parseFloat(this.cdListAditional[titleName].unitario).toFixed(2));

        var sumMargem = 0;
        var sumTotal = 0;
        var summargemAlvoInput = 0;
        var qtd = 0;
        this.cdListAditional.forEach(function(item){
            sumTotal +=  item.valorTotal;
            sumMargem += item.margem ;
            summargemAlvoInput += item.margemAlvoInput ;
            if(item.quantidade){
                qtd++;
            }
        }, {sumMargem, sumTotal, summargemAlvoInput, qtd});

        qtd = (qtd == 0 ? 1 : qtd);
        this.margemTotal = sumMargem / qtd;
        this.totalPrice = sumTotal;
        this.margemAlvoTotal = summargemAlvoInput / qtd;

        this.margemTotalString = this.margemTotal+'%';
        this.margemAlvoTotalString = this.margemAlvoTotal+'%';
        this.totalPriceString  = 'R$ '+this.totalPrice;
    }
	handleNavigate() { 
	   this[NavigationMixin.Navigate]({
			type: 'standard__navItemPage',
			attributes: {
				apiName: 'Entrega_Futura'
			}
		});
    }
	handleNavigateMix() { 
	   this[NavigationMixin.Navigate]({
			type: 'standard__navItemPage',
			attributes: {
				apiName: 'MixProduto'
			}
		});
    }
}