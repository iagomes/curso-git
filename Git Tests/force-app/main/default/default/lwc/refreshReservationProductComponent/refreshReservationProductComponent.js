import { LightningElement } from 'lwc';
import refreshProductReservationChannel from '@salesforce/messageChannel/refreshProductReservationChannel__c';
import {createMessageContext, releaseMessageContext, publish} from 'lightning/messageService';

export default class RefreshReservationProductComponent extends LightningElement {

    context = createMessageContext();

    connectedCallback() {
        // window.location.reload(true);
    }

    disconnectedCallback() {
        // window.location.reload(true);
        console.log('entrou');
        // this.dispatchEvent(new CustomEvent('searchproduct'));
        this.publishMessageChannel();
    }

    publishMessageChannel() {
        const message = {
            refreshComponent: 'refresh'
        };
        publish(this.context, refreshProductReservationChannel, message);
    }
}