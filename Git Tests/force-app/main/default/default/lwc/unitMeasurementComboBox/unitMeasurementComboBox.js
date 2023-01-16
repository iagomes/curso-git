import { api, LightningElement,track } from 'lwc';

export default class UnitMeasurementComboBox extends LightningElement {
    @api prim;
    @api sec;
    @api terc;
    @track options = [];

    connectedCallback(){
        this.options.push({ label: this.prim, value: this.prim });
        if(this.prim != this.sec && this.sec != null && this.sec != ''){
            this.options.push({ label: this.sec, value: this.sec });
        }
        console.log('terc 1 ',this.terc);
        this.terc = this.terc == null || this.terc == '' ? this.prim : this.terc;
        console.log('terc',this.terc);
    }

    alterValueTtl(event){
        event.preventDefault();
        let selected = event.detail;
        const productSelected = new CustomEvent("selected", {
            detail : selected   
        });
        this.dispatchEvent(productSelected);
    }
}