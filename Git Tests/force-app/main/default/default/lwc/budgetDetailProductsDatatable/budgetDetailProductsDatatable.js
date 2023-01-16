import LightningDatatable from 'lightning/datatable';
import customButtons from './customButtons.html';
import customPicklist from './customPicklist.html';
import customIcon from './customIcon.html';

export default class BudgetDetailProductsDatatable extends LightningDatatable {
    static customTypes = {
        CustomButtons: {
            template: customButtons,
            typeAttributes: ['recordId', 'isEntrega', 'indexB'],
        },
        CustomPicklist: {
            template: customPicklist,
            typeAttributes: ['recordId', 'recordTypeId', 'fieldApiName', 'isEditable', 'controllerFieldApiName', 'controllerValue', 'value', 'picklistValues'],
        },
        CustomIcon: {
            template: customIcon,
            typeAttributes: ['iconName', 'size', 'tooltip']
        }
    };
}