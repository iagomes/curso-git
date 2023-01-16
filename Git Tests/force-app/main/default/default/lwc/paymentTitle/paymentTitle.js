import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
//controller methods
import getPaymentTitle from '@salesforce/apex/PaymentSlipPreviewController.getPaymentTitle';
import getBoleto from '@salesforce/apex/PaymentSlipPreviewController.getBoleto';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class PaymentTitle extends NavigationMixin(LightningElement) {
    
    @track paymentTitle = [];
    @track paymentTitleDue = [];
    @track overduePaymentTitle = [];
    @track paymentTitleDueTotal = [];
    @track overduePaymentTitleTotal = [];
    @track pageNumber1 = true;
    @track isLastPage = true;
    @track pageNumber = 0;
    @track pagVencer = false;
    @track pagVencido = false;
    @track showTitleDue = false;
    @track showOverDueTitle = false;
    @track showCreditAnalysis = false;
    @track pesquisalista = '';
    @track activeSection = 'cdaccordion';
    @track pageNumber1Venc = true;
    @track isLastPageVenc = true;
    @track loading = false;
    @track pageNumberVenc = 0;
    // @track myColumns = [];
    // @track lineMax1 = 1;
    @api recordId;
    @api objectApiName = 'Título';
    @track device = false;
    async getPaymentTitle(){
        
        let paymentTitleString = await getPaymentTitle({recordId: this.recordId});
        // console.log('paymentTitleString ' + paymentTitleString );
        this.paymentTitle = JSON.parse(paymentTitleString);
        this.paymentTitleDueTotal = [];
        this.overduePaymentTitleTotal = [];
        this.paymentTitle.limCredito = (this.paymentTitle.limCredito == null || this.paymentTitle.limCredito == undefined) ? 0 : this.paymentTitle.limCredito.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'}); 
        this.paymentTitle.saldo = (this.paymentTitle.saldo == null || this.paymentTitle.saldo == undefined) ? 0 : this.paymentTitle.saldo.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
        this.paymentTitle.saldoAVencer = (this.paymentTitle.saldoAVencer == null || this.paymentTitle.saldoAVencer == undefined) ? 0 : this.paymentTitle.saldoAVencer.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
        this.paymentTitle.saldoVencido = (this.paymentTitle.saldoVencido == null || this.paymentTitle.saldoVencido == undefined) ? 0 : this.paymentTitle.saldoVencido.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
        this.paymentTitle.maiorCompra = (this.paymentTitle.maiorCompra == null || this.paymentTitle.maiorCompra == undefined) ? 0 : this.paymentTitle.maiorCompra.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
        this.paymentTitle.totalCompra = (this.paymentTitle.totalCompra == null || this.paymentTitle.totalCompra == undefined) ? 0 : this.paymentTitle.totalCompra.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
        this.paymentTitle.maiorTitulo = (this.paymentTitle.maiorTitulo == null || this.paymentTitle.maiorTitulo == undefined) ? 0 : this.paymentTitle.maiorTitulo.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
        if(this.paymentTitle.TituloAberto != null ){
            for (var i = 0; i < this.paymentTitle.TituloAberto.length; i++) {
                // console.log('valors ' +  this.paymentTitle.TituloAberto[i].VALOR.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'}));

                this.paymentTitle.TituloAberto[i].VALOR = this.paymentTitle.TituloAberto[i].VALOR.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
                this.paymentTitle.TituloAberto[i].SALDO = this.paymentTitle.TituloAberto[i].SALDO.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});
                this.paymentTitle.TituloAberto[i].MULTA = this.paymentTitle.TituloAberto[i].MULTA.toLocaleString('pt-br',{style: 'currency', currency: 'BRL'});

                if(this.paymentTitle.TituloAberto[i].VENCREA >= this.paymentTitle.dataHoje){
                    this.paymentTitle.TituloAberto[i].VENCREA = this.paymentTitle.TituloAberto[i].VENCREA.substring(8,10) + '-' + this.paymentTitle.TituloAberto[i].VENCREA.substring(5,7) + '-' + this.paymentTitle.TituloAberto[i].VENCREA.substring(0,4); 
                    this.paymentTitle.TituloAberto[i].DATA_INCLUSAO = this.paymentTitle.TituloAberto[i].DATA_INCLUSAO.substring(8,10) + '-' + this.paymentTitle.TituloAberto[i].DATA_INCLUSAO.substring(5,7) + '-' + this.paymentTitle.TituloAberto[i].DATA_INCLUSAO.substring(0,4); 
                    this.paymentTitleDueTotal.push(this.paymentTitle.TituloAberto[i]);
                }else{
                    this.paymentTitle.TituloAberto[i].VENCREA = this.paymentTitle.TituloAberto[i].VENCREA.substring(8,10) + '-' + this.paymentTitle.TituloAberto[i].VENCREA.substring(5,7) + '-' + this.paymentTitle.TituloAberto[i].VENCREA.substring(0,4); 
                    this.paymentTitle.TituloAberto[i].DATA_INCLUSAO = this.paymentTitle.TituloAberto[i].DATA_INCLUSAO.substring(8,10) + '-' + this.paymentTitle.TituloAberto[i].DATA_INCLUSAO.substring(5,7) + '-' + this.paymentTitle.TituloAberto[i].DATA_INCLUSAO.substring(0,4); 
                    this.overduePaymentTitleTotal.push(this.paymentTitle.TituloAberto[i]);
                }
            }
        }
        // console.log('this.overduePaymentTitleTotal ' + JSON.stringify(this.overduePaymentTitleTotal) )
        
        if(this.paymentTitleDueTotal.length > 0){
            if(this.paymentTitleDueTotal.length > 20){
                this.paymentTitle.pagVencer = true;
                this.pageNumber = 20;
                this.isLastPage = false;
                for (var i = 0; i < 20; i++) {
                    this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
                }
            }else{
                this.paymentTitleDue = this.paymentTitleDueTotal;
            }
        }
        if(this.overduePaymentTitleTotal.length > 0){
            if(this.overduePaymentTitleTotal.length > 20){
                this.paymentTitle.pagVencido = true;
                this.pageNumberVenc = 20;
                this.isLastPageVenc = false;
                for (var i = 0; i < 20; i++) {
                    this.overduePaymentTitle.push(this.overduePaymentTitleTotal[i]);
                }
            }else{
                this.overduePaymentTitle = this.overduePaymentTitleTotal;
            }
        }
    }

    mobileVoltar(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: result,
                objectApiName: this.recordId,
                actionName: 'view'
            }
        });

    }

    boleto(event){
        var dadosBoleto =  event.target.value;
        console.log('nome 1' +JSON.stringify(dadosBoleto) );
        // console.log('valor botão');
        // console.log(dadosBoleto);
        this.loading = true;
        console.log('this.loading ' + this.loading);

        getBoleto({ recordId: this.recordId, cgc: dadosBoleto.CGC_CD, numeroBoleto: dadosBoleto.NUM,  prefixo: dadosBoleto.PREFIXO, tipo: dadosBoleto.TIPO, parcela: dadosBoleto.PARCELA   })
        .then(result => {
            console.log('getBoleto: entrou certo!');
            console.log(result); 
            this.loading = false;
            console.log('this.loading 2 ' + this.loading);

            if(result.msg == ''){
                console.log('retornoou');
                this.navegar(result.boleto);
            }else{
                const evt = new ShowToastEvent({
                    title: 'Erro',
                    message: result.msg,
                    variant: 'Error'
                });
                this.dispatchEvent(evt);
        
            }
    
        }).catch(error => {
            this.loading = false;
            console.log('getBoleto: entrou no erro!');
            console.log(error);
        });

    }
    navegar(result){
        // window.open('https://='+ msg1);
        console.log('teste');
        console.log(result);

        var url = window.location.href.split('force.com');
        console.log(url);

        // var urlName = 'https://elfa--devnac--c.documentforce.com/servlet/servlet.FileDownload?file='+result;
        var urlName = url[0] + 'force.com/servlet/servlet.FileDownload?file='+result;
        console.log(urlName);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: urlName, 
            }
        });
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: result, //'00P21000005btr8EAA',
        //         actionName: 'view'
        //     }
        // });
    }
    myFunction(event){
        const { value } = event.target;
        this.pesquisalista = value;

        var qtdVencer = 0;
        var qtdVencido = 0;
        this.paymentTitle.pagVencido = false;
        this.pageNumberVenc = 0;
        this.isLastPageVenc = true;
        this.paymentTitle.pagVencer = false;
        this.pageNumber = 0;
        this.isLastPage = true;
        console.log('this.pesquisalista ' + this.pesquisalista);
        if(this.paymentTitleDueTotal.length > 0){
            // console.log(' teste seiji ' +   JSON.stringify(this.paymentTitleDueTotal) );
            for (var i = 0; i <  this.paymentTitleDueTotal.length; i++) {
                if(qtdVencer == 0){
                    this.paymentTitleDue = [];
                }
                if (this.paymentTitleDueTotal[i].PEDIDO.includes(this.pesquisalista)) {
                    console.log(' ACHOU PEDIDO ' );
                    qtdVencer = qtdVencer + 1;
                    this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
                } else{
                    if (this.paymentTitleDueTotal[i].VENCREA.includes(this.pesquisalista))  {
                    console.log(' ACHOU VENCIMENTO ' );
                        qtdVencer = qtdVencer + 1;
                        this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
                    }else{
                        if (this.paymentTitleDueTotal[i].NUM.includes(this.pesquisalista)) {
                    console.log(' ACHOU NUMERO ' );
                            qtdVencer = qtdVencer + 1;
                            this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
                        }
                    }
                }
                if(qtdVencer == 20){
                    this.paymentTitle.pagVencer = false;
                    this.pageNumber = 20;
                    this.isLastPage = false;

                    break;
                }
            }
        }
        if(this.overduePaymentTitleTotal.length > 0){
            console.log('this.pesquisalista2  ' + this.pesquisalista);

            for (var i = 0; i <  this.overduePaymentTitleTotal.length; i++) {
                console.log(' rodou' );
                if(qtdVencido == 0){
                    this.overduePaymentTitle = [];
                }
                if (this.overduePaymentTitleTotal[i].PEDIDO.includes(this.pesquisalista)) {
                    console.log(' ACHOU PEDIDO2 ' );
                    qtdVencido = qtdVencido + 1;
                    this.overduePaymentTitle.push(this.overduePaymentTitleTotal[i]);
                } else{
                    if (this.overduePaymentTitleTotal[i].VENCREA.includes(this.pesquisalista) ) {
                        console.log(' ACHOU VENCIMENTO2 ' );
                        qtdVencido = qtdVencido + 1;
                        this.overduePaymentTitle.push(this.overduePaymentTitleTotal[i]);
                    }else{
                        if (this.overduePaymentTitleTotal[i].NUM.includes(this.pesquisalista)) {
                            console.log(' ACHOU NUMERO2 ' );
                            qtdVencido = qtdVencido + 1;
                            this.overduePaymentTitle.push(this.overduePaymentTitleTotal[i]);
                        }
                    }
                }
                if(qtdVencido == 20){
                    this.paymentTitle.pagVencido = true;
                    this.pageNumberVenc = 20;
                    this.isLastPageVenc = false;
                    break;
                }
            }
        }
        if(qtdVencer == 0 && qtdVencido == 0){
            console.log('vazio ');
            if(this.paymentTitleDueTotal.length > 0){
                if(this.paymentTitleDueTotal.length > 20){
                    this.paymentTitle.pagVencer = true;
                    this.pageNumber = 20;
                    this.isLastPage = false;
                    for (var i = 0; i < 20; i++) {
                        this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
                    }
                }else{
                    this.paymentTitleDue = this.paymentTitleDueTotal;
                }
            }
            if(this.overduePaymentTitleTotal.length > 0){
                if(this.paymentTitleDueTotal.length > 20){
                    this.paymentTitle.pagVencer = true;
                    this.pageNumber = 20;
                    this.isLastPage = false;
                    for (var i = 0; i < 20; i++) {
                        this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
                    }
                }else{
                    this.paymentTitleDue = this.paymentTitleDueTotal;
                }
            }
        }

    }
    
    handleShowCreditAnalysis(){
        this.showCreditAnalysis = !this.showCreditAnalysis;
    }
    handleShowTitleDue(){
        this.showTitleDue = !this.showTitleDue;
    }
    handleShowOverDueTitle(){
        this.showOverDueTitle = !this.showOverDueTitle;
    }
    connectedCallback(){
        this.device = FORM_FACTOR != 'Large';
        this.getPaymentTitle();
    }
    handlePrev(){
        this.paymentTitle.pagVencer = true;
        this.isLastPage = false;
        var tamanho = this.pageNumber1 - 20
        if(tamanho = 0){
            this.pageNumber1 = true;
        }
        this.paymentTitleDue = [];
        for (var i = tamanho; i < this.pageNumber; i++) {
            this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
        }

    }

    handleNext(){
        this.pageNumber1 = false;
        var tamanho = this.pageNumber + 20;
        if(tamanho >= this.paymentTitleDueTotal.length){
            tamanho = this.paymentTitleDueTotal.length;
            this.isLastPage = true;
        }
        this.paymentTitleDue = [];
        if(this.paymentTitleDue.length = 0){
            console.log('this.paymentTitleDue ');
        }
        for (var i = this.pageNumber ; i < tamanho ; i++) {
            this.paymentTitleDue.push(this.paymentTitleDueTotal[i]);
        }

    }
    handlePrevVenc(){
        this.paymentTitle.pagVencido = true;
        this.isLastPageVenc = false;
        var tamanho = this.pageNumber1Venc - 20
        if(tamanho = 0){
            this.pageNumber1Venc = true;
        }
        this.overduePaymentTitle = [];
        for (var i = tamanho; i < this.pageNumberVenc; i++) {
            this.overduePaymentTitle.push(this.overduePaymentTitleTotal[i]);
        }
    }

    handleNextVenc(){
        console.log('TOPPP 2');
        this.pageNumber1Venc = false;
        var tamanho = this.pageNumberVenc + 20;
        if(tamanho >= this.overduePaymentTitleTotal.length){
            tamanho = this.overduePaymentTitleTotal.length;
            this.isLastPageVenc = true;
        }
        this.overduePaymentTitle = [];
        if(this.overduePaymentTitle.length = 0){
            console.log('this.overduePaymentTitle ');
        }
        for (var i = this.pageNumberVenc ; i < tamanho ; i++) {
            this.overduePaymentTitle.push(this.overduePaymentTitleTotal[i]);
        }

    }

    exportContactData(){

        let columnHeader = ['Centro de distribuicao', 'Numero', 'Parcela', 'Tipo' , 'Saldo', 'Valor', 'Vencimento Real', 'Emissao de N/F'];
        let columnHeaderCredito = ['Grau de Risco', 'Saldo' ,'Saldo a Vencer', 'Saldo Vencido', 'Maior Titulo' , 'Limite de Credito', 'Maior Compra', 'Media Atraso'];
        let doc = '<table>';
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '    border-color: rgb(236, 236, 236);';
        doc += '}';          
        doc += '</style>';

        doc += '<script src="https://cdn.sheetjs.com/xlsx-latest/package/dist/xlsx.full.min.js"></script>';

        //CLIENTE
        doc += '<tr>';
        doc += '<th colspan="8" style="background-color: rgb(210, 210, 210);font-weight: 900">'+ this.paymentTitle.NomeCliente +'</th>'   
        doc += '</tr>';

        doc += '<tr>';
        doc += '<th colspan="8"  style="border:none">'+'</th>'   
        doc += '</tr>';

        //ANALISE FINANCEIRA TITLE
        doc += '<tr>';
        doc += '<th colspan="8" style="background-color: rgb(210, 210, 210);font-weight: 900">'+ 'ANALISE FINANCEIRA' +'</th>'   
        doc += '</tr>';

        doc += '<tr>';
        doc += '<th colspan="8"  style="border:none">'+'</th>'   
        doc += '</tr>';

        //ANALISE DE CREDITO TITLE
        doc += '<tr>';
        doc += '<th colspan="8" style="background-color: rgb(210, 210, 210);font-weight: 900">'+ 'ANALISE DE CREDITO' +'</th>'   
        doc += '</tr>';

         //ANALISE DE CREDITO HEADER
        doc += '<tr>';
        columnHeaderCredito.forEach(element => {            
            doc += '<th style="background-color: rgb(210, 210, 210);font-weight: 900">'+ element +'</th>'           
        });
        doc += '</tr>';

        //ANALISE DE CREDITO BODY         
        doc += '<tr>';
        doc += '<th style="font-weight: normal">'+this.paymentTitle.grauRisco+'</th>'; 
        doc += '<th style="font-weight: normal">'+this.paymentTitle.saldo.replace(/\s/g, '')+'</th>'; 
        doc += '<th style="font-weight: normal">'+this.paymentTitle.saldoAVencer.replace(/\s/g, '')+'</th>';
        doc += '<th style="font-weight: normal">'+this.paymentTitle.saldoVencido.replace(/\s/g, '')+'</th>'; 
        doc += '<th style="font-weight: normal">'+this.paymentTitle.maiorCompra.replace(/\s/g, '')+'</th>';
        doc += '<th style="font-weight: normal">'+this.paymentTitle.limCredito.replace(/\s/g, '')+'</th>'; 
        doc += '<th style="font-weight: normal">'+this.paymentTitle.maiorCompra.replace(/\s/g, '')+'</th>'; 
        doc += '<th style="font-weight: normal">'+this.paymentTitle.mediaAtraso+'</th>'; 
        doc += '</tr>';

        doc += '<tr>';
        doc += '<th colspan="8"  style="border:none">'+'</th>'   
        doc += '</tr>';

        //TITULOS A VENCER TITLE
        doc += '<tr>';
        doc += '<th colspan="8" style="background-color: rgb(210, 210, 210);font-weight: 900">'+ 'TITULOS A VENCER' +'</th>'   
        doc += '</tr>';
        //TITULOS A VENCER HEADER
        doc += '<tr>';
        columnHeader.forEach(element => {            
            doc += '<th style="background-color: rgb(210, 210, 210);font-weight: 900">'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        this.paymentTitleDueTotal.forEach(record => {
            doc += '<tr>';
            doc += '<th style="font-weight: normal">'+record.EMPRESA+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.NUM+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.PARCELA+'</th>';
            doc += '<th style="font-weight: normal">'+record.TIPO+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.SALDO.replace(/\s/g, '')+'</th>';
            doc += '<th style="font-weight: normal">'+record.VALOR.replace(/\s/g, '')+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.VENCREA+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.DATA_INCLUSAO+'</th>'; 
            doc += '</tr>';
        });

        doc += '<tr>';
        doc += '<th colspan="8"  style="border:none">'+'</th>'    
        doc += '</tr>';

        doc += '</table>';        

        doc += '<table>';
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '    border-color: rgb(236, 236, 236);';
        doc += '}';          
        doc += '</style>';

         //TITULOS EM ATRASO TITLE
         doc += '<tr>';
         doc += '<th colspan="8" style="background-color: rgb(210, 210, 210);font-weight: 900">'+ 'TITULOS EM ATRASO' +'</th>'   
         doc += '</tr>';

        //TITULOS EM ATRASO HEADER
        doc += '<tr>';
        columnHeader.forEach(element => {            
            doc += '<th style="background-color: rgb(210, 210, 210);font-weight: 900">'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        this.overduePaymentTitleTotal.forEach(record => {
            console.log('num '+ typeof record.NUM);
           
            doc += '<tr>';
            doc += '<th style="font-weight: normal">'+record.EMPRESA+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.NUM+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.PARCELA+'</th>';
            doc += '<th style="font-weight: normal">'+record.TIPO+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.SALDO.replace(/\s/g, '')+'</th>';
            doc += '<th style="font-weight: normal">'+record.VALOR.replace(/\s/g, '')+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.VENCREA+'</th>'; 
            doc += '<th style="font-weight: normal">'+record.DATA_INCLUSAO+'</th>'; 
            doc += '</tr>';
        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel;charset=UTF-8,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        downloadElement.download = 'Titulos.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();

    }
}