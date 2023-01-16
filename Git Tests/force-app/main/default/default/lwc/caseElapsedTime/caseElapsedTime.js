import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import LABELS from './labels';
import calculateTimeBetweenDates from '@salesforce/apex/BusinessDays.calculateTimeBetweenDates';

const FIELDS = [
    'Case.CreatedDate',
    'Case.FinishedDate__c',
    'Case.ReopenedDatetime__c',    
    'Case.ReopeningFinishedDate__c'
];

export default class CaseElapsedTime extends LightningElement {

    @api recordId;
    wasReopened = false;

    labels = LABELS;

    @track opened = { watch : undefined, interval : undefined };
    @track reopened = { watch : undefined, interval : undefined };
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({error, data}) {
         if (data) {

            if (data.fields.FinishedDate__c.value != null) {
                this.countUpFromTime(data.fields.CreatedDate.value, 'opened', data.fields.FinishedDate__c.value);
            } else {
                this.countUpFromTime(data.fields.CreatedDate.value, 'opened');        
            }
 
            if (data.fields.ReopeningFinishedDate__c.value != null) {
                this.wasReopened = true;
                this.countUpFromTime(data.fields.ReopenedDatetime__c.value, 'reopened', data.fields.ReopeningFinishedDate__c.value);
            } else if (data.fields.ReopenedDatetime__c.value != null) {
                this.wasReopened = true;
                this.countUpFromTime(data.fields.ReopenedDatetime__c.value, 'reopened');
            }            

        }
    }
   
    countUpFromTime(countFromDate, counter, countEndDate) {

        calculateTimeBetweenDates({ startDate: countFromDate, endDate: countEndDate })
        .then((result) => {

            let watch = result;
            watch.hasYears = watch.years > 0;
            watch.hasDays = watch.days > 0;
            this[counter].watch = watch;

            if (countEndDate) {
                return;
            }

            let interval = 60000;
            if (!this[counter].interval) {
                let now = new Date();
                let oneMinuteFromNow = new Date();
                oneMinuteFromNow.setMinutes(oneMinuteFromNow.getMinutes() + 1);
                oneMinuteFromNow.setSeconds(0);
                oneMinuteFromNow.setMilliseconds(0);
                interval = (oneMinuteFromNow.getTime() - now.getTime());
                this[counter].interval = true;
            } 

            setTimeout(this.countUpFromTime.bind(this, countFromDate, counter), interval);

        })
        .catch((error) => {
            this[counter].watch = undefined;
        });

      } 
      

}