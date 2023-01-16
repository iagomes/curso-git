import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getBudgetItens from '@salesforce/apex/CancelOppItemController.getBudgetItens';
import cloneBudget from '@salesforce/apex/CancelOppItemController.cloneBudget';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';

export default class CancelOppItem extends NavigationMixin(LightningElement) {

    @api recordId;
    @track productList = [];
    @track oppNumber;
    @track currentSelectedProdCode = "";
    @track isRender = false;
    @track isLoading = true;
    @track isPageRendered = false;
    @track allChecked = false;
    @track disableButton = false;

    connectedCallback() {
        Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => {console.log('Files loaded.');}).catch(error => {console.log('error: ' + JSON.stringify(error));});
    }

    renderedCallback() {
        console.log('Entrou renderedCallback callback')
        console.log(this.recordId);
        if (!this.isRender) {
            getBudgetItens({recId: this.recordId})
                .then(result => {
                    this.isLoading = false;
                    console.log('getBudgetItens: entrou certo!');
                    console.log(result);
                    if (result != undefined && result.length > 0) {
                        this.productList = [];
                        result.forEach(prod => {
                            this.productList.push({
                                id: prod.id,
                                chave: prod.chave,
                                prodId: prod.prodId,
                                name: prod.name,
                                code: prod.code,
                                fornecedor: prod.fornecedor,
                                pAtivo: prod.pAtivo,
                                cd: prod.cd,
                                quantidade: prod.quantidade,
                                valorFormatado: new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(prod.valor),
                                valor: prod.valor,
                                oppId: prod.oppId,
                                scoreItem: prod.scoreItem,
                                motivoCancelamento: prod.motivoCancelamento == undefined ? '' : prod.motivoCancelamento,
                                obsCancelamento: prod.obsCancelamento == undefined ? '' : prod.obsCancelamento,
                                desabilitarMotivo: false
                            });
                        })
                        this.oppNumber = result[0].oppNumber;
                        this.isRender = true;
                    }
                }).catch(error => {
                    this.isRender = true;
                    this.isLoading = false;
                    console.log('getBudgetItens: entrou no erro!');
                    console.log(error);
                });
        }
    }

    handleNewVersion() {
        this.disableButton = true;
        console.log('handleNewVersion');
        console.log(JSON.parse(JSON.stringify(this.productList)));
        let hasCancelItens = false;
        this.productList.forEach(item => {
            if (item.motivoCancelamento != '' && item.motivoCancelamento != undefined) {
                hasCancelItens = true;
            }
        });
        if (!hasCancelItens) {
            swal('Aviso!', 'Não é possível atualizar nova versão, nenhum item está sendo cancelado', 'warning');
            this.disableButton = false;
            return;
        }
        if (this.allChecked) {
            for (var i = 0; i < this.productList.length; i++) {
                if (this.productList[0].motivoCancelamento == '' || this.productList[0].motivoCancelamento == undefined) {
                    swal('Aviso!', 'Selecionar o motivo específico no primeiro item', 'warning');
                    this.disableButton = false;
                    return;
                }
                if (i != 0) {
                    this.productList[i].motivoCancelamento = this.productList[0].motivoCancelamento;
                }
            }
        }
        cloneBudget({jsonProdList: JSON.stringify(this.productList)})
            .then(result => {                    
                console.log('updateOppLineItens: entrou certo!');
                console.log(result);
                if (result.length == 18) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result,
                            actionName: 'view'
                        }
                    });
                } else {                    
                    this.disableButton = false;
                }
            }).catch(error => {
                this.disableButton = false;
                swal('Erro!', 'Erro ao gerar nova versão do orçamento, favor contatar o administrador.', 'error');
                console.log('updateOppLineItens: entrou no erro!');
                console.log(error);
            });
    }

    handleCheckAllItens() {
        this.allChecked = !this.allChecked;
        if (this.productList.length > 0) {
            for (var i = 0; i < this.productList.length; i++) {
                if (i != 0) {
                    this.productList[i].desabilitarMotivo = !this.productList[i].desabilitarMotivo;
                }
            }
        }
    }

    onChangeItemCancelReason(event) {
        let itemId = event.currentTarget.dataset.itemId;
        this.productList.find(item => item.chave == itemId).motivoCancelamento = event.detail.value;
        console.log(itemId);
    }    

    onBlurCancelDescription(event) {
        let itemId = event.currentTarget.dataset.itemId;
        this.productList.find(item => item.chave == itemId).obsCancelamento = event.target.value;
        console.log(itemId);
    }

    get cancelReasonOptions(){
        return [
            { label: 'Selecione um motivo', value: ''},
            { label: 'Desistiu da compra', value: 'Desistiu da compra'},
            { label: 'Não tem mais interesse no produto', value: 'Não tem mais interesse no produto'},
            { label: 'Falta de estoque do produto', value: 'Falta de estoque do produto'},
            { label: 'Preço', value: 'Preço'},
            { label: 'Aprovação interna fora do prazo', value: 'Aprovação interna fora do prazo'},
            { label: 'Analise interna financeira', value: 'Analise interna financeira'},
            { label: 'Prazo de entrega', value: 'Prazo de entrega'}
          ];
    }
}