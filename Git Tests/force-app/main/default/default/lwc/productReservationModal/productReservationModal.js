import { LightningElement, api, track } from 'lwc';
import getUnlimitedReservedProductsModal from '@salesforce/apex/ReservationManagement.getUnlimitedReservedProductsModal';

export default class ProductReservationModal extends LightningElement {
    //lookup
    @api isLoadingProductsTransfer = false;
    @track reserveSearchFields = ["Name"];
    @track reserveItemOptions = { title: 'Name'};
    @api reserveId;
    @track reserveWhereFieldList = ["CodigoCD__c"];
    @track reserveOperators = ['='];
    @track reserveMoreFields = ["StatusReserva__c", "CodigoCD__c", "SaldoFinanceiroConsumido__c", "SaldoFinanceiroDisponivel__c"];
    get reserveParentRecordList() {
		return [this.reserve.DistributionCenterCode];
	}
    //end lookup
    showProductToTransfer = false;
    isLoadingModal = false;
    @track reservationProductList = [];
    @api reserveToTransfer;
    @api reserve = {"Id": "", "DistributionCenterCode": ""};
    @api _transferProductsMode = false;
    @api disableContinue = false;

    sldsModalClass = "slds-modal slds-fade-in-open";

    @api set transferProductsMode(value) {
        console.log('value ====> ' + value);
        if(value != undefined) {
            this._transferProductsMode = !this._transferProductsMode;
        }
    }

    get transferProductsMode() {
        return this._transferProductsMode;
    }

    handleCancel(event) {
        this.reservationProductList = [];
        this.showProductToTransfer = false;
        this.isLoadingModal = false;
        this.sldsModalClass = this.sldsModalClass.replace(" slds-modal_small", "");
        this._transferProductsMode = !this._transferProductsMode;
        this.dispatchEvent(new CustomEvent('selectrecordclear'));
    }

    changeReserved(event) {
		const { record } = event.detail;
		console.log('record =>' + JSON.stringify(record));
        
		this.dispatchEvent(new CustomEvent('selectrecord', {detail: {record}}));
		// this.recordList.accountIdDisabled = record.Id;
	}

    clearReserved() {
        console.log('entrou aqui');
        // const { record } = '';
        // console.log('record ==> ' + record);
        this.dispatchEvent(new CustomEvent('selectrecordclear'));
		// this.recordList.accountIdDisabled = null;
	}

    connectedCallback() {
        
    }

    async handleContinueOnClick(event) {
        this.showProductToTransfer = true;
        this.isLoadingModal = true;
        this.reservationProductList = await getUnlimitedReservedProductsModal({reserveId: this.reserve.Id});
        if(this.reservationProductList.length > 0) {
            this.reservationProductList.forEach(prod => {
                prod.valorTotal = Number(prod.priceAverage) * Number(prod.reservedQuantity);
                prod.quantityTransfer = 0;
            });
            this.sldsModalClass = this.sldsModalClass + " slds-modal_small";
            this.isLoadingModal = false;
            this.showProductToTransfer = true;
            console.log('this.reservationProductList ==> ' + JSON.stringify(this.reservationProductList));
        } else {
            this.isLoadingModal = false;
            this.showProductToTransfer = false;
            swal('Atenção!', 'Nenhum produto que possa ser transferido encontrado.', 'warning');
        }
    }

    async handleTransferProducts(event) {
        let reservationProductToTransfer = [];
        this.reservationProductList.forEach(prod => {
            if(prod.quantityTransfer != null && prod.quantityTransfer != undefined && prod.quantityTransfer != 0) {
                reservationProductToTransfer.push(this.cloneObj(prod));
            }
        });

        if(reservationProductToTransfer.length > 0) {
            console.log('reservationProductToTransfer ==> ' + JSON.stringify(reservationProductToTransfer));
            this.isLoadingProductsTransfer = true;
            this.dispatchEvent(new CustomEvent('transferproducts', {detail: {reservationProductToTransfer}}));
        } else {
            swal('Atenção!', 'Nenhum produto que possa ser transferido encontrado.', 'warning');
        }

    }

    async handleBackModal(event) {
        this.reservationProductList = [];
        this.showProductToTransfer = false;
        this.sldsModalClass = this.sldsModalClass.replace(" slds-modal_small", "");
        console.log('this.sldsModalClass ==> ' + JSON.stringify(this.sldsModalClass));
        console.log('reserveId ==> ' + JSON.stringify(this.reserveId));
    }

    async onChangeQuantityTransfer(event) {
		console.log(event.target.value);
		let prodId = event.currentTarget.dataset.productid;
		let armazem = event.currentTarget.dataset.armazem;
		console.log('armazem => ' + JSON.stringify(armazem));
		console.log('prodId => ' + JSON.stringify(prodId));
		let quantityTransfer = Number(event.target.value);
		console.log('quantityTransfer => ' + JSON.stringify(quantityTransfer));
		if (event.target.value) {
			let prod = this.cloneObj(this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)));
            console.log('prod.quantityTransfer => ' + JSON.stringify(prod.quantityTransfer));
			if(Number(quantityTransfer) <= (Number(prod.reservedQuantity - prod.consumedQuantity))) {
				this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = quantityTransfer;
			} else {
                this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = null;

				await swal('Aviso!', 'Não é possível inserir uma quantidade à transferir maior do que ' + Number(prod.reservedQuantity - prod.consumedQuantity).toString() + '.', 'warning').then((ok) => {
					if(ok) {
                        console.log('prod.quantityTransfer if => ' + JSON.stringify(prod.quantityTransfer));
						this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = prod.quantityTransfer;
					} else {
						// this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = 0;
                        console.log('prod.quantityTransfer else => ' + JSON.stringify(prod.quantityTransfer));
						this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = prod.quantityTransfer;
					}
				});
			}
			console.log('prod => ' + JSON.stringify(prod));
			console.log('this.reservationProductList => ' + JSON.stringify(this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer));
		} else {
			this.reservationProductList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = undefined;
		}
	}

    cloneObj(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    @api transferLoadingChange() {
        this.isLoadingProductsTransfer = !this.isLoadingProductsTransfer;
    }

    @api closeAll() {
        this.reservationProductList = [];
        this.showProductToTransfer = false;
        this.isLoadingModal = false;
        this.sldsModalClass = this.sldsModalClass.replace(" slds-modal_small", "");
        this._transferProductsMode = !this._transferProductsMode;
        this.dispatchEvent(new CustomEvent('selectrecordclear'));
    }
}