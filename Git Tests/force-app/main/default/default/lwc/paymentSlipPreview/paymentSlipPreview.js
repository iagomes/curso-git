import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
//controller methods
import getPaymentSlip from '@salesforce/apex/PaymentSlipPreviewController.getPaymentSlip';

export default class PaymentSlipPreview extends NavigationMixin(LightningElement) {

    @track paymentSlip = [];
    @api recordId;

    async getPaymentSlip(){
        console.log('recordId'+this.recordId);
        let paymentSlipString = await getPaymentSlip({recordId: this.recordId});
        this.paymentSlip = JSON.parse(paymentSlipString);
        if (this.paymentSlip.TituloAberto){
            this.paymentSlip.TituloAberto.forEach(item =>{
                if (item.DATA_INCLUSAO){
                    item.DATA_INCLUSAO = item.DATA_INCLUSAO.split('T')[0];
                }
            });
        }
    }

    connectedCallback(){
        this.getPaymentSlip();
    }
    
}