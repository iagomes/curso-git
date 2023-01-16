import { LightningElement, api } from 'lwc';

export default class BudgetDetailProductsDatatableCustomIcon extends LightningElement {
    @api iconName;
    @api size;
    @api tooltip;

    showTooltip = false;
    handleIconFocus(){
        this.showTooltip = true;
    }
    handleIconLeave(){
        this.showTooltip = false;
    }
}