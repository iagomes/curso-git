import { LightningElement, api, track } from 'lwc';
import getLotes from '@salesforce/apex/OrderScreenController.getLotes';
import getShelfLifeProducts from '@salesforce/apex/ProductDistributionCenterLotsController.getShelfLifeProducts';

export default class ProductDistributionCenterLots extends LightningElement {
    @api product; // resp
    @api distributionCenter;
 
    @track isModalOpen = false;
    @track isLoadingLotes = false;

    @track lots = null;
    @track shelfLifePriceByLot = null;

    connectedCallback() {
        console.log('product', JSON.stringify(this.product));
        console.log('distributionCenter', JSON.stringify(this.distributionCenter));
    }

    closeModal(event) {
        this.isModalOpen = false;
    }

    openModal(event) {
        this.isModalOpen = true;
        this.isLoadingLotes = true;

        this.handleGetShelflifeData();
    }

    async handleGetShelflifeData() {
        try {
            const response = await getShelfLifeProducts({
                productId: this.product.prodId,
                distributionCenterCNPJ: this.distributionCenter.cnpj
            });

            console.log('handleGetShelflifeData');
            console.log(JSON.stringify(response));

            this.shelfLifePriceByLot = JSON.parse(response);

            await this.handleGetLots();
            
        } catch (error) {
            console.log('Erro ao buscar os produtos shelflife');
            console.log(error);
        }
    }

    async handleGetLots() {
        try {
            const result = await getLotes({ 
                clienteCGC: this.distributionCenter.cnpj, 
                productCode: this.product.prodCode 
            });
        
            console.log('getLotes: entrou certo!');
            console.log(JSON.stringify(result));

            if (result != null && result.length > 0) {
                
                const lots = result.map((lot) => {
                    const shelfLifePrice = this.shelfLifePriceByLot[lot?.lote];

                    const formattedPrice = shelfLifePrice && this.getCurrencyFormat(shelfLifePrice);

                    return {
                        name: lot.lote,
                        validityDate: new Date(lot.validade),
                        validity: new Date(lot.validade).toLocaleDateString('pt-BR') || null,
                        stock: Number(lot.estoque) || null,
                        price: formattedPrice || null
                    }
                });

                const sortedLots = lots.length > 0 
                    ? lots.sort((a, b) => new Date(a.validityDate) - new Date(b.validityDate))
                    : null;

                this.lots = sortedLots;
                this.isLoadingLotes = false;

            } else {
                this.lots = null;
                this.isLoadingLotes = false;
            }

        } catch(error) {
            this.isLoadingLotes = false;
            this.lots = null;
            console.log('Erro ao buscar os lotes');
            console.log(error);
        }
    }

    getCurrencyFormat(price) {
		return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(price);
	}
}