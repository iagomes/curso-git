import LightningDatatable from 'lightning/datatable';
import customButtons from './customButtons.html';
import customString from './customString.html';
import customCircle from './customCircle.html';

export default class budgetDetailListProduct extends LightningDatatable {
    static customTypes = {
        customButtons: {
            template: customButtons,
            typeAttributes: ['itemData'],
        },
        customString:{
            template: customString,
            typeAttributes: ['recordId','date','stage','amount'],
        },
        customCircle:{
            template: customCircle,
            typeAttributes: ['recordId','simbol'],
        },
    };
}