import { api, LightningElement } from 'lwc';

export default class BudgetDetailProductsDatatableColumnButtons extends LightningElement {
    
    @api recordId;
    @api isEntrega;
    @api indexB;
    @api disconnectFromParent;

    isVisible = true;

    get isVinculado() {
        return this.itemData && this.itemData.itemId ? true : false;
    }

    get variant() {
        return this.isVinculado ? '' : 'brand';
    }

    get itemUrl() {
        return this.itemData ? '/' + this.itemData.itemId : null;
    }

    handleButtonClick(event) {
        this.template.dispatchEvent(new CustomEvent('custombuttonclick', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                button: event.target.name,
                recordId: this.recordId,
                itemData: this.itemData,
                indexB: this.indexB
            }
        }));
    }
}