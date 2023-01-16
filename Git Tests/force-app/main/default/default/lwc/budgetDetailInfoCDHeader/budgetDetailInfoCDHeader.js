import { LightningElement, api, wire } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import {unregisterAllListeners, registerListener, fireEvent } from 'c/pubsub';

export default class BudgetDetailInfoCDHeader extends LightningElement {
    @api resp;
    @wire (CurrentPageReference)pageRef;
    refreshDisable = true;
    connectedCallback(){

        registerListener('enableRefreshMalha', this.enableRefreshMalha, this);
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }

    refreshMalha(){
        fireEvent(this.pageRef,'newRespSelected', null);
    }
    //needRefactor
    openHistoric(){
        this.dispatchEvent(new CustomEvent('openhistoric'));
    }
    openModalProductDescription(){
        this.dispatchEvent(new CustomEvent('openproductdesc'));
    }

    enableRefreshMalha(){
        this.refreshDisable = false;
    }
}
