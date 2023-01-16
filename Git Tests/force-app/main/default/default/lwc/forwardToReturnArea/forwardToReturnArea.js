import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ForwardToReturnArea extends LightningElement {
    @api recordId;

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }        
}