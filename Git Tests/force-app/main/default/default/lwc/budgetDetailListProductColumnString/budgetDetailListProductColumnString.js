import { LightningElement, api } from 'lwc';

export default class budgetDetailListProductColumnString extends LightningElement {
    @api recordId;
    @api date;
    @api stage;
    @api amount;

}