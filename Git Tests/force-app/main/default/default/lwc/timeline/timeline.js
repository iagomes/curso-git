import { LightningElement, wire, api, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import LABELS from './labels.js';
import calculateTimeBetweenDates from '@salesforce/apex/BusinessDays.calculateTimeBetweenDates';

export default class Timeline extends LightningElement {

    @api recordId;
    @track timelines = [];

    labels = LABELS;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Timelines__r',
        fields: ['Timeline__c.End_date__c', 'Timeline__c.Name', 'Timeline__c.CreatedDate', 'Timeline__c.Id']
    }) listInfo({ error, data }) {

        if (data) {

            let index = 0;
            data.records.forEach(record => {

                let timeline = {
                    id: record.fields.Id.value,
                    name: record.fields.Name.value,
                    startDate: record.fields.CreatedDate.value,
                    endDate: record.fields.End_date__c.value != null ? record.fields.End_date__c.value : undefined,
                    days: undefined,
                    years: undefined,
                    hours: undefined,
                    mins: undefined,
                    secs: undefined,
                    hasYears: undefined,
                    hasDays: undefined,
                    interval: false,
                    index: index
                };

                this.countUpFromTime(timeline);
                index++;

            });

        }
        console.log('df');
    }

    countUpFromTime(timeline) {

        calculateTimeBetweenDates({ startDate: timeline.startDate, endDate: timeline.endDate })
            .then((result) => {

                let oldTimelines = JSON.parse(JSON.stringify(this.timelines));
                timeline.days = result.days;
                timeline.years = result.years;
                timeline.hours = result.hours;
                timeline.mins = result.minutes;
                timeline.secs = result.seconds;
                timeline.hasYears = timeline.years > 0;
                timeline.hasDays = timeline.days > 0;

                if (timeline.endDate) {
                    oldTimelines[timeline.index] = timeline;
                    this.timelines = oldTimelines;
                    return;
                }

                let interval = 60000;
                if (!timeline.interval) {
                    let now = new Date();
                    let oneMinuteFromNow = new Date();
                    oneMinuteFromNow.setMinutes(oneMinuteFromNow.getMinutes() + 1);
                    oneMinuteFromNow.setSeconds(0);
                    oneMinuteFromNow.setMilliseconds(0);
                    interval = (oneMinuteFromNow.getTime() - now.getTime());
                    timeline.interval = true;
                }

                oldTimelines[timeline.index] = timeline;
                this.timelines = oldTimelines;

                setTimeout(this.countUpFromTime.bind(this, timeline), interval);

            })
            .catch((error) => {
               
            });

    }

}