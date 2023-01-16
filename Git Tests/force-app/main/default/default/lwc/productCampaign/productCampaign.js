import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getClientOrderData from '@salesforce/apex/ProductCampaignController.getClientOrderData';
import getProductCampaign from '@salesforce/apex/ProductCampaignController.getProductCampaign';

export default class ProductCampaign extends NavigationMixin(LightningElement) {

    @track isModalOpen;
    @track openSelected = false;
    @track isLoadingProducts = false;
    @track currentSelectedProdCode = "";
    @track savedOrderData = [];
    @track orderDataList = [];
    @track currentListProdCampaign = [];
    @track filteredListProdCampaign = [];
    @track listProdToSearch = [];
    @track textProdToSearch = "";
    @track searchGenericValue = "";
    @track searchCDValue = "";
    @api listProdCampaign = [];
    @api accountId;
    @api tabelaPreco;
    @api condicaoPagamento;

    connectedCallback() {
        console.log('this.currentListProdCampaign');
        console.log(JSON.parse(JSON.stringify(this.currentListProdCampaign)));
        if (this.currentListProdCampaign.length == 0) {
            this.searchProductCampaign();
        }
    }

    closeModal(event) {
        console.log(event);
        this.isModalOpen = false;
    }

    @api openModal() {
        // to open modal set openModal tarck value as true
        this.isModalOpen = true;
    }
    
    searchProductCampaign() {
		console.log('Chamando searchProductCampaign');
        console.log('this.listProdCampaign');
        console.log(this.listProdCampaign);
        this.currentListProdCampaign = [];
        if (this.listProdCampaign.length != 0) {            
            this.listProdCampaign.forEach(item => {
                this.currentListProdCampaign.push({
                    ...item,
                    show: false,
                    selected: false
                });
            });
            this.filteredListProdCampaign = this.currentListProdCampaign;
        }
		// getProductCampaign({ pricebook: this.tabelaPreco, clienteId: this.accountId, offSetValue: "", searchGenericValue: "", searchFabricanteValue: "", condPag: this.condicaoPagamento})
		// 	.then(result => {
        //         this.isLoadingProducts = false;
		// 		console.log('chamada certa!');
		// 		console.log(result);
		// 		if (result != null) {
		// 			result.forEach(item => {
		// 				this.currentListProdCampaign.push({
		// 					...item,
        //                     show: false,
        //                     selected: false
		// 				});
		// 			});
        //             this.filteredListProdCampaign = this.currentListProdCampaign;
		// 		}
		// 	}).catch(error => {
        //         this.isLoadingProducts = false;
		// 		console.log(error);
		// 	});
	}

    handleSelectProduct(event) {
        let prodId = event.currentTarget.dataset.productId;

        this.orderDataList = [];

        if (this.currentSelectedProdCode == prodId) {
            this.filteredListProdCampaign.find(prod => prod.id == prodId).show = !this.filteredListProdCampaign.find(prod => prod.id == prodId).show;
        } else {
            this.showProd(prodId);
        }
        
        if (this.savedOrderData[prodId] == undefined) {
            this.savedOrderData[prodId] = [];
            getClientOrderData({ accId: this.accountId, prodId: prodId })
                .then(result => {
                    this.currentSelectedProdCode = prodId;
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
                    console.log('getClientOrderData: entrou no erro!');
                    console.log(error);
                });
        } else {
            this.currentSelectedProdCode = prodId;
            this.orderDataList = this.savedOrderData[prodId];
        }
    }
    
    handleCheckbox(event) {
        let prodId = event.currentTarget.dataset.productId;
        this.currentListProdCampaign.forEach(prod => {
            if (prod.id == prodId) {
                prod.selected = event.target.checked;
            }
        });
    }

    handleCampaignDescription(event) {
        let regraCamp = event.currentTarget.dataset.campaign;
        if (regraCamp == undefined || regraCamp == '') {
            regraCamp = 'não há regra cadastrada para esse produto.';
        }
        swal('Aviso!', `Informação sobre regra(s) da campanha: ${regraCamp}`, 'warning');
    }

    onChangeSearchProduct(event) {
		this.searchGenericValue = event.target.value;
		console.log(event.target.value);
        this.filterProdList();
	}

    filterProdList() {        
        let fListProdCampaign = [];
        this.currentListProdCampaign.forEach(item => {
            if (item.searchCampaignField.toLowerCase().includes(this.searchGenericValue.toLowerCase())) {
                fListProdCampaign.push(item);
            }
        });
        this.filteredListProdCampaign = fListProdCampaign;
    }

    handleGetMoreProducts() {
        console.log('get more products');
    }

    onSearchProduct() {
        let listProdToSearch = [];
        if (this.currentListProdCampaign.length > 0) {
            this.currentListProdCampaign.forEach(item => {
                if (item.selected) {
                    listProdToSearch.push(item.code);
                }
            })
        }
        console.log(listProdToSearch);
        if (listProdToSearch.length > 0) {
            this.textProdToSearch = listProdToSearch.join(',');
            this.closeModalAndSearchProduct(this.textProdToSearch);
        }
    }

    closeModalAndSearchProduct(prodCode) {
        this.isModalOpen = false;
        this.dispatchEvent(
            new CustomEvent('closecampaign', {
                detail: {
                    record: 'fechou',
                    prodCode: prodCode ? prodCode : null
                }
            })
        );
    }

    showProd(prodId) {
        this.filteredListProdCampaign.forEach(prod => {
            prod.show = prod.id == prodId;
        });
    }
}