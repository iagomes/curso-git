import LightningDatatable from 'lightning/datatable';
import customButtons from './customButtons.html';
import customPicklist from './customPicklist.html';

export default class BudgetDetailRespostaDataTable extends LightningDatatable {

    static customTypes = {
        CustomButton: {
            template: customButtons,
            typeAttributes: ['recordId', 'toolTipLabel', 'iconName', 'actionClick', 'hideButton', 'scopeFather'],
        },
        CustomPicklist: {
            template: customPicklist,
            typeAttributes: ['recordId', 'recordTypeId', 'fieldApiName', 'isEditable', 'controllerFieldApiName', 'controllerValue', 'value', 'picklistValues', 'hideOptions'],
        }
    };
}