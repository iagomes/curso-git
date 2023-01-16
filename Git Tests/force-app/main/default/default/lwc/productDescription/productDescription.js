import { api, LightningElement } from 'lwc';

export default class ProductDescription extends LightningElement {

    @api show = false;
    @api prod;

    closeModalProductDescription(){
        this.dispatchEvent(new CustomEvent('productdescriptioncloseclick'));
    }
}