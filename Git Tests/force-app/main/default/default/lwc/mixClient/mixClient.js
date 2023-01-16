import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getClientProdData from '@salesforce/apex/MixClientController.getClientProdData';
import getClientOrderData from '@salesforce/apex/MixClientController.getClientOrderData';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class MixClient extends NavigationMixin(LightningElement) {

    @api recordId;
    @api isFromOrderProductScreen = false;
    @track openSelected = false;
    @track productList = [];
    @track orderDataList = [];
    @track searchGenericValue = "";
    @track searchFabricanteValue = "";
    @track isLoadingProducts = true;
    @track isLoadingOrderData = true;
    @track offSetValue = 0;
    @track savedOrderData = [];
    @track currentSelectedProdCode = "";
    @track componentStyle = "max-width: 60rem;"
    @track showMoreProduct = true;
    @track desktop = false;
    @api searchProduct;

    connectedCallback() {
        this.desktop = FORM_FACTOR == 'Large';
        console.log(this.isFromOrderProductScreen);
        if (this.desktop) {
            this.componentStyle = this.desktop ? "max-width: 60rem;" : "width: 100%; max-width: 60rem; min-width: 30rem;";
        }
        if (!this.isFromOrderProductScreen) {
            this.componentStyle = "width: 100%; max-width: 100%; padding: 0;"
        }

        if (this.searchProduct) {
            this.searchGenericValue = this.searchProduct;
        }
        this.searchProducts();
    }

    onChangeSearchProductNome(event) {
        this.searchGenericValue = event.target.value;
        console.log(event.target.value);
        if (event.key === 'Enter') {
            this.handleFilterSearchProd();
        }
    }

    onChangeSearchProductByFabricator(event) {
        console.log(event.target.value);
        this.searchFabricanteValue = event.target.value;
        if (event.key === 'Enter') {
            this.handleFilterSearchProd();
        }
    }

    handleFilterSearchProd() {
        console.log('Buscando produtos filtrados: ');
        this.offSetValue = 0;
        this.productList = [];
        this.searchProducts();
    }

    handleGetMoreProducts() {
        this.offSetValue += 20;
        this.searchProducts();
    }
    
    searchProducts() {
        var elem = document.querySelector('#prodDiv');
        if (elem) {
            const rect = elem.getBoundingClientRect();
            console.log(`height: ${rect.height}`);
        }
        this.isLoadingProducts = true;
        getClientProdData({ accId: this.recordId, offSetValue: this.offSetValue, searchGenericValue: this.searchGenericValue, searchFabricanteValue: this.searchFabricanteValue })
            .then(result => {
                this.isLoadingProducts = false;
                console.log('searchProduct: entrou certo!');
                console.log(result);
                if (result != null) {
                    result.forEach(prod => {
                        this.productList.push({
                            id: prod.id,
                            name: prod.name,
                            code: prod.code,
                            fornecedor: prod.fornecedor,
                            pAtivo: prod.pAtivo,
                            createdDt: new Date(prod.createdDt.replace(' ', 'T')),
                            show: prod.show
                        });
                    });

                    this.productList.sort((a, b) => (a.createdDt < b.createdDt) ? 1 : ((b.createdDt < a.createdDt) ? -1 : 0));                        

                    if (result.length < 20) {
                        this.showMoreProduct = false;
                    } else {
                        this.showMoreProduct = true;
                    }
                }
            }).catch(error => {
                this.isLoadingProducts = false;
                console.log('searchProduct: entrou no erro!');
                console.log(error);
            });
    }

    onSearchProduct(event) {
        let prodCode = event.currentTarget.dataset.productCode;
        this.closeModalAndSearchProduct(prodCode);
    }

    navigateToOrder(event) {
        console.log('Abrir pedido: ');
        console.log(event.currentTarget.dataset.orderId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.orderId,
                actionName: 'view'
            }
        });
    }

    getFormatDate(input) {
        var datePart = input.match(/\d+/g),
            year = datePart[0],
            month = datePart[1],
            day = datePart[2];

        return day + '/' + month + '/' + year;
    }

    closeModalAndSearchProduct(prodCode) {
        this.dispatchEvent(
            new CustomEvent('closemixclient', {
                detail: {
                    record: 'fechou',
                    prodCode: prodCode ? prodCode : null
                }
            })
        );
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false

        this.dispatchEvent(
            new CustomEvent('closemixclient', {
                detail: {
                    record: 'fechou'
                }
            })
        );
    }

    handleSelectProduct(event) {
        let prodId = event.currentTarget.dataset.productId;

        this.orderDataList = [];

        if (this.currentSelectedProdCode == prodId) {
            this.productList.find(prod => prod.id == prodId).show = !this.productList.find(prod => prod.id == prodId).show;
        } else {
            this.showProd(prodId);            
        }
        
        if (this.savedOrderData[prodId] == undefined) {
            this.savedOrderData[prodId] = [];
            getClientOrderData({ accId: this.recordId, prodId: prodId })
                .then(result => {
                    this.currentSelectedProdCode = prodId;
                    this.isLoadingOrderData = false;
                    console.log('getClientOrderData: entrou certo!');
                    console.log(result);
                    if (result != null) {
                        result.forEach(ord => {
                            let currentObj = {
                                ordId: ord.ordId,
                                ordNumber: ord.ordNumber,
                                ordCreatedDate: ord.ordCreatedDate,
                                ordItemCd: ord.ordItemCd,
                                ordScore: ord.ordScore,
                                ordItemScore: ord.ordItemScore,
                                ordItemQuantity: ord.ordItemQuantity,
                                ordItemPrice: new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(ord.ordItemPrice)
                            }
                            this.savedOrderData[prodId].push(currentObj); 
                            this.orderDataList.push(currentObj);
                        });
                    }                
                }).catch(error => {
                    this.isLoadingOrderData = false;
                    console.log('getClientOrderData: entrou no erro!');
                    console.log(error);
                });
        } else {
            this.currentSelectedProdCode = prodId;
            this.orderDataList = this.savedOrderData[prodId];
        }
    }

    showProd(prodId) {
        this.productList.forEach(prod => {
            prod.show = (prod.id == prodId) ? true : false;
        });
    }
}