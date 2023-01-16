import { LightningElement, api, wire } from 'lwc';
import LABELS from './labels.js';
import getNPSScore from '@salesforce/apex/CaseNPSScoreController.getNPSScore';

export default class CaseNPSScore extends LightningElement {

    @api recordId;

    labels = LABELS;

    nps;
    error;
    nodata = false;
    scoreClass;

    @wire(getNPSScore, { recordId: '$recordId' })
    wiredContacts({ error, data }) {
       
        if (data) {
            this.nps = data;

            if (this.nps.hasOwnProperty('nodata')) {
                this.nodata = true;
            } else {

                let color = '';
                if (this.nps.value > 8) {
                    color = 'green';
                } else if (this.nps.value > 4) {
                    color = 'yellow';
                } else {
                    color = 'red';
                }

                this.scoreClass = 'slds-float_left score ' + color;
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.nps = undefined;
        }
    }

}