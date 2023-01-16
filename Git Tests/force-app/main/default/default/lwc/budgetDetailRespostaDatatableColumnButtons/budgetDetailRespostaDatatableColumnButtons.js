import { LightningElement,api } from 'lwc';

export default class BudgetDetailRespostaDatatableColumnButtons extends LightningElement {

    @api recordId;
    @api toolTipLabel;
    @api iconName;
    @api actionClick;
    @api scopeFather;

    handleClick(){
        this.actionClick(this.recordId, this.scopeFather);
    }
}