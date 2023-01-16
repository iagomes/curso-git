import { api, LightningElement } from 'lwc';

export default class budgetDetailListProductColumnButtons extends LightningElement {
    
    @api recordId;
    @api itemData = {};

    get showVincularButton() {
        console.log('showVincularButton:::', this.itemData && this.itemData.prodCode);
        return this.itemData && this.itemData.id && (this.itemData.prodCode == null || (this.itemData.status != 'Resgatado' && this.itemData.status != 'Respondido'));
    }

    get variant() {
        return (!this.itemData || this.itemData.prodCode == null) ? '' : 'brand';
    }

    handleButtonClick(event) {
        let detail = {
            button: event.target.name,
            recordId: this.recordId,
            itemData: this.itemData,
        };
        this.template.dispatchEvent(new CustomEvent('vincularclick', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: detail
        }));
    }
}