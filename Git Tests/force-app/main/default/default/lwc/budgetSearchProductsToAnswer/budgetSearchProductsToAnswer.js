import { api, LightningElement, track, wire } from 'lwc';
import getDeliveryCenterOptions from '@salesforce/apex/BudgetSearchProducts.getDeliveryCenterOptions';
import getDefaultUserDeliveryCenter from '@salesforce/apex/BudgetSearchProducts.getDefaultUserDeliveryCenter';
import searchProductsToAnswer from '@salesforce/apex/BudgetSearchProducts.searchProductsToAnswer';
import refreshProductsPricesAndStocks from '@salesforce/apex/BudgetSearchProducts.refreshProductsPricesAndStocks';

export default class BudgetSearchProductsAnswer extends LightningElement {
    @api initialProductSearch = null;
    @api baseState = null;
    @api accountId = null;

    @track originalProducts = null;
    @track productsData = null;
    @track lastSearchData = [];

    columns = [
        { 
            label: '',
            fixedWidth: 40, 
            type: 'button-icon',
            typeAttributes: {
                name: 'select-product',
                iconName: 'utility:change_record_type',
                title: 'Vincular produto',
                alternativeText: 'Vincular produto',
            }
        },
        { label: 'Categoria', fieldName: 'category', sortable: true, fixedWidth: 40, hideDefaultActions: true },
        { label: 'Código', fieldName: 'productCode', sortable: true, fixedWidth: 100 },    
        { label: 'Descrição', fieldName: 'description', sortable: true, wrapText: true, initialWidth: 200 },
        { label: 'Est. Filial', fieldName: 'stockAmount', type: 'number', cellAttributes: { alignment: 'right' }, sortable: true, initialWidth: 110 },
        { label: 'Und.', fieldName: 'unities', sortable: true, initialWidth: 80 },
        { label: 'Preço', fieldName: 'priceList', type: 'number', cellAttributes: { alignment: 'right' }, sortable: true, initialWidth: 90 },
        { label: '', fieldName: 'priceBase', sortable: false, initialWidth: 20, hideDefaultActions: true },
        { label: 'Preço Und.Alt.', fieldName: 'alternativeUnitPrice', type: 'number', cellAttributes: { alignment: 'right' }, sortable: true, initialWidth: 90 },
        { label: 'Principio Ativo', fieldName: 'activeIngredient', sortable: true, initialWidth: 190, wrapText: true },
        { label: 'Fabricante', fieldName: 'producer', sortable: true, initialWidth: 190, wrapText: true },
        { label: 'Est. Geral', fieldName: 'totalStockAmount', type: 'number', cellAttributes: { alignment: 'right' }, sortable: true, initialWidth: 110 },
        { 
            iconName: 'utility:cases',
            fixedWidth: 40, 
            type: 'button-icon',
            hideLabel: true,
            cellAttributes: { alignment: 'center' },
            typeAttributes: {
                name: 'show-product-description',
                iconName: 'utility:cases',
                title: 'Descrição técnica',
                alternativeText: 'Visualizar descrição técnica',
            }
        },
    ];
    
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'stockAmount';
    
    stockOptions = [
        { label: "Com saldo", value: "with-stock-only" },
        { label: "Todos os itens",  value: "all" }
    ];

    searchProductValue = null;
    searchProducerValue = null;
    selectedStockOption = 'all';

    selectedDeliveryCenter = null;
    deliveryCenterOptions = [];

    @track isLoadingData = false;
    @track isRefreshingValues = false;

    @track productDescriptionModalVisible = false;
    @track productDetails;

    connectedCallback() {
        this.init();
    }

    async init() {
        const defaultUserDeliveryCenter = await getDefaultUserDeliveryCenter();
        this.selectedDeliveryCenter = defaultUserDeliveryCenter;
        
        await this.getDeliveryCenterOptions();

        if (!!this.initialProductSearch) {
            const [firstWord] = this.initialProductSearch.split(' ');
            if (!!firstWord) {
                this.searchProductValue = firstWord;
                await this.searchProducts();
            }
        } 
    }

    async getDeliveryCenterOptions() {
        try {
            const response = await getDeliveryCenterOptions();
            const optionsData = JSON.parse(response);

            this.deliveryCenterOptions = optionsData;

        } catch(error) {
            console.log('Erro ao buscar opções');
        }
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.productsData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.productsData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleInputCommit(event) {
        const { name, value } = event.target;
        
        switch(name) {
            case 'search-product': {
                this.searchProductValue = value;
                break;
            }
            case 'search-producer': {
                this.searchProducerValue = value;
                break;
            }

            default: break;
        }

        if (!!this.searchProductValue || this.searchProducerValue) {
            this.searchProducts();
        } else {
            this.clearProductList();
        }
    }

    handleRadioFilter(event) {
        const { value } = event.target;
        this.selectedStockOption = value;

        this.filterProductsBasedOnStock(value);
    }

    handleChangeDeliveryCenter(event) {
        this.selectedDeliveryCenter = event.detail.value;
        this.refreshProductsPricesAndStocks();
    }

    async searchProducts() {
        this.isLoadingData = true;

        try {
            const params = {
                product: this.searchProductValue || null,
                producer: this.searchProducerValue || null,

                priceParams: {
                    accountId: this.accountId,
                    companyCode: this.selectedDeliveryCenter,
                    pricebookCode: 'B01', // por enquanto está fixa
                    state: this.baseState
                }
            };

            const response = await searchProductsToAnswer({ 
                queryFilter: JSON.stringify(params)
            });

            const responseData = JSON.parse(response);
            const convertedData = this.convertDataToDatatable(responseData);

            this.productsData = convertedData.length > 0 ? JSON.parse(JSON.stringify(convertedData)) : null;
            this.lastSearchData = convertedData.length > 0 ? JSON.parse(JSON.stringify(convertedData)) : null;
            this.originalProducts = responseData.products;

            this.sortDirection = 'desc';
            this.sortedBy = 'stockAmount'

            this.filterProductsBasedOnStock(this.selectedStockOption);
        } catch (error) {
            console.log('error:', error);
            this.clearProductList();
        } finally {
            this.isLoadingData = false;
        }
    }

    async refreshProductsPricesAndStocks() {
        this.isRefreshingValues = true;

        try {
            const params = {
                productsIds: this.originalProducts.map((product) => product.Id),
                priceParams: {
                    accountId: this.accountId,
                    companyCode: this.selectedDeliveryCenter,
                    pricebookCode: 'B01', // por enquanto está fixa
                    state: this.baseState
                }
            };

            const response = await refreshProductsPricesAndStocks({ 
                params: JSON.stringify(params)
            });

            this.updateProductPricesAndStocksData(JSON.parse(response));
        } catch (error) {
            console.log('Erro ao atualizar os valores.');
            console.log(JSON.stringify(error));
        } finally {
            this.isRefreshingValues = false;
        }
    }

    convertDataToDatatable(entryData) {
        const data = entryData.products.map((product) => {
            let secondUnitFormatted = '';

            if (
                !!product.SegundaUnidade__c &&
                !!product.TipoConversao__c && 
                !!product.FatorConversao__c
            ) {
                if (product.TipoConversao__c == 'D') {
                    secondUnitFormatted = `(${product.SegundaUnidade__c} ${product.FatorConversao__c})`;
                } else {
                    secondUnitFormatted = `(${product.FatorConversao__c} ${product.SegundaUnidade__c})`;
                }
            }

            const unities = `${product.UnidadeMedida__c} ${secondUnitFormatted}`;
            const stockAmount = entryData.companyStocks[product.Id];
            const totalStockAmount = entryData.stocks[product.Id];
            const productPrices = entryData.productsPrices[product.Id];

            const dataItem = {
                productId: product.Id || '',
                category: product.CategoriaComercial__c || '',
                productCode: product.ProductCode || '',
                unities: unities || '',
                stockAmount: stockAmount || 0,
                totalStockAmount: totalStockAmount || 0,
                description: product.Name,
                activeIngredient: product.Description || '',
                producer: product.Fornecedor__r?.Name || '',

                alternativeUnit: product.SegundaUnidade__c || '',
                conversionType: product.TipoConversao__c || '',
                conversionFactor: Number(product.FatorConversao__c) || 0
            }

            const { price, priceBaseIcon } = this.getPriorityProductPrice(productPrices);
            dataItem.priceList = price || 0;
            dataItem.priceBase = priceBaseIcon || '';
            
            const { alternativeUnitPrice } = this.getAlternativeUnitPrice(dataItem, price);
            dataItem.alternativeUnitPrice = alternativeUnitPrice || null;

            return dataItem;
        });

        return data;
    }

    updateProductPricesAndStocksData(data) {
        const { productsPrices, companyStocks } = data;

        const updatedProductsData = JSON.parse(JSON.stringify(this.productsData));
        const updatedLastSearchedData = JSON.parse(JSON.stringify(this.lastSearchData));

        updatedProductsData.forEach((product, index, currentList) => {
            const { price, priceBaseIcon } = this.getPriorityProductPrice(
                productsPrices[product.productId]
            );
            currentList[index].priceList = price || 0;
            currentList[index].priceBase = priceBaseIcon || '';
            
            const { alternativeUnitPrice } = this.getAlternativeUnitPrice(product, price);
            currentList[index].alternativeUnitPrice = alternativeUnitPrice || null;
            
            const stockAmount = companyStocks[product.productId];
            currentList[index].stockAmount = stockAmount || 0;
        });

        updatedLastSearchedData.forEach((product, index, currentList) => {
            const { price, priceBaseIcon } = this.getPriorityProductPrice(
                productsPrices[product.productId]
            );
            currentList[index].priceList = price || 0;
            currentList[index].priceBase = priceBaseIcon || '';

            const { alternativeUnitPrice } = this.getAlternativeUnitPrice(product, price);
            currentList[index].alternativeUnitPrice = alternativeUnitPrice || null;

            const stockAmount = companyStocks[product.productId];
            currentList[index].stockAmount = stockAmount || 0;
        });

        this.productsData = updatedProductsData;
        this.lastSearchData = updatedLastSearchedData;
    }

    getPriorityProductPrice(productPrices) {
        let price = 0;
        let priceBaseIcon = '';

        if (!!productPrices?.contractPrice) {
            price = productPrices.contractPrice;
            priceBaseIcon = '🤝';
        } 
        else if (!!productPrices?.campaignPrice) {
            price = productPrices.campaignPrice;
            priceBaseIcon = '🎯';
        }
        else if (productPrices?.campaignType === 'CampanhaVendedor') {
            price = productPrices.priceList || 0;
            priceBaseIcon = '🎯';
        }
        else if (!!productPrices?.priceList) {
            price = productPrices.priceList;
        }

        return { price, priceBaseIcon };
    }

    getAlternativeUnitPrice(product, price) {
        let alternativeUnitPrice;

        if (price > 0) {
            if (product.conversionType == 'M' && product.conversionFactor > 0) {
                alternativeUnitPrice = price / product.conversionFactor;
            }

            if (product.conversionType == 'D' && product.conversionFactor > 0) {
                alternativeUnitPrice = price * product.conversionFactor;
            }
        }

        return { alternativeUnitPrice };
    }

    clearProductList() {
        this.originalProducts = null;
        this.productsData = null;
        this.lastSearchData = null;
    }

    filterProductsBasedOnStock(type, ignoreSort = false) {
        if (type == 'with-stock-only') {
            if (this.productsData != null) {
                const filteredList = this.productsData.filter((item) => item.totalStockAmount > 0);
                this.productsData = filteredList.length > 0 ? filteredList : null;
            }
        } else {
            this.productsData = this.lastSearchData;
        }

        if (!ignoreSort && this.productsData != null) {
            this.handleSort({
                detail: {
                    fieldName: this.sortedBy,
                    sortDirection: this.sortDirection
                }
            });
        }
    }

    handleRowAction(event) {
        const { action, row } = event.detail;

        const { name: actionName } = action;
        const { productId } = row;
        
        switch(actionName) {
            case 'select-product': {
                this.onSelectProduct(productId);
                break;
            }

            case 'show-product-description': {
                this.onOpenProductDescriptionModal(productId);
                break;
            }

            default: break;
        }
    }

    onSelectProduct(productId) {
        this.dispatchEvent(new CustomEvent('selectproduct', {
            detail: {
                productId
            }
        }));
    }

    onOpenProductDescriptionModal(productId) {
        const productData = this.originalProducts.find((product) => product.Id === productId);
        
        if (productData) {
            this.productDetails = {
                code: productData.ProductCode,
                nome: productData.Name,
                anvisa: productData.NumeroAnvisa__c,
                ean: productData.EANProduto__c,
                precoFabricaCx: '',
                descTecnica: productData.DescricaoTecnica__c,
            };

            this.productDescriptionModalVisible = true;
        }
    }

    handleCloseProductDescriptionModal() {
        this.productDetails = null;
        this.productDescriptionModalVisible = false;
    }
}