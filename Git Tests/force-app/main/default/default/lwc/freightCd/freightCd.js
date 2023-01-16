import { LightningElement, api, track } from 'lwc';

import freightTypeError from '@salesforce/label/c.FreightCdError';

export default class FreightCd extends LightningElement {
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @api isModalOpen = false;
    @api receivedCdList;
    @api listFreightValue = [];
    @api disabled = false;

    @track cdListFilter = [];
    @track hasInputError = false;
    @track isAddBlock = false;
    @track disableSave = false;

    connectedCallbackRebase() {
        this.cdListFilter = [];
        console.log('FRETE');
        
        if (typeof(this.receivedCdList) !== 'object') {
            this.receivedCdList = JSON.parse(this.receivedCdList);
        }

        let cdsToTotalValueRefresh = [];
        this.receivedCdList.forEach(cd => {
            if (cdsToTotalValueRefresh[cd.cnpjCd] == undefined) {
                cdsToTotalValueRefresh[cd.cnpjCd] = Number(cd.valorTotal);
                console.log('valorFrete:', cd.valorFrete);
                console.log('tipoFrete:', cd.tipoFrete);
                this.cdListFilter.push({
                    id: cd.id,
                    cnpjNome: cd.cds + " - " + cd.cnpjCd,
                    cnpjCd: cd.cnpjCd,
                    valorTotal: cd.valorTotal,
                    valorTotalScreen: cd.valorTotal,
                    valorFrete: cd.valorFrete ? cd.valorFrete : 0,
                    errorMessage: null,
                    tipoFrete: cd.tipoFrete ? cd.tipoFrete : null,
                    freteNecessario: cd.tipoFrete != 'FOB' ? false : true
                });
            } else {
                cdsToTotalValueRefresh[cd.cnpjCd] += Number(cd.valorTotal);
                this.cdListFilter.find(cdFilter => cdFilter.cnpjCd == cd.cnpjCd).valorTotal = Number(cdsToTotalValueRefresh[cd.cnpjCd]);
                this.cdListFilter.find(cdFilter => cdFilter.cnpjCd == cd.cnpjCd).valorTotalScreen = Number(cdsToTotalValueRefresh[cd.cnpjCd].toFixed(2));
            }
        });

        this.hasErrors();
    }
    
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.connectedCallbackRebase();
        this.scrollToTop();
        this.isModalOpen = true;
    }

    scrollToTop() {
        if (!this.desktop) {
            const scrollOptions = {
				left: 0,
				top: 0,
				behavior: 'smooth'
			}
			parent.scrollTo(scrollOptions);
        }
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

    submitDetails() {
        console.log('Ta certo?');
        if (!this.hasErrors()) {
            this.isModalOpen = false;
            console.log('ta certo');

            this.listFreightValue = [];

            this.cdListFilter.forEach(cd => {
                this.listFreightValue.push({
                    id: cd.id, 
                    cnpjCd: cd.cnpjCd,
                    valorFrete: cd.valorFrete,
                    tipoFrete: cd.tipoFrete
                })
            });
            
            console.log(JSON.parse(JSON.stringify(this.listFreightValue)));

            this.dispatchEvent(
                new CustomEvent('freightvalues', {
                    detail: {
                        record: JSON.stringify(this.listFreightValue)
                    }
                })
            );
        } else {
            console.log('ta errado');
        }
    }

    handleFreightValue(event) {
        let currentCnpjCd = event.currentTarget.dataset.cnpj;
        let freightValue = Number(event.target.value);
        console.log(freightValue);
        if (freightValue < 0) {
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).errorMessage = 'Valor inválido';
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).valorFrete = 0;
        } else {
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).errorMessage = null;
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).valorFrete = freightValue;
        }

        this.hasErrors();
    }

    onChangeFreightType(event) {
        const currentCnpjCd = event.currentTarget.dataset.cnpj;
        const tipoFrete = event.detail.value;
        console.log('Dataset cnpjCd:', event.currentTarget.dataset.cnpj);
        this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).tipoFrete = tipoFrete;
        console.log(JSON.parse(JSON.stringify(this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd))));

        if (tipoFrete == 'FOB') {
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).freteNecessario = true;
        } else {
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).freteNecessario = false;
            this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).valorFrete = 0;
        }
        console.log('Valor frete: ', this.cdListFilter.find(cd => cd.cnpjCd === currentCnpjCd).valorFrete);

        this.hasErrors();
    }

    get optionsFreightType() {
        return [
            { label: 'CIF', value: 'CIF' },
            { label: 'FOB', value: 'FOB' },
            { label: 'CLIENTE RETIRA', value: 'CLIENTE RETIRA' },
        ];
    }

    hasErrors() {
        let hasError = false;
        this.cdListFilter.forEach(cd => {
            if (cd.errorMessage != null || cd.tipoFrete == null) {
                hasError = true;
            }
        });

        console.log(hasError);

        if (hasError) {
            this.disableSave = true;
        } else {
            this.disableSave = false;
        }
        return hasError;
    }
}