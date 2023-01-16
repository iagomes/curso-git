import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import LABELS from './labels.js';

export default class CaseForwardBackwardCounter extends LightningElement {
    
    @api recordId;
    @track timelines;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Timelines__r',
        fields: ['Timeline__c.Name']
    })listInfo({ error, data }) {
      
        if (data) {
            this.timelines = [];
            let mappedTimeline = new Map();
            data.records.forEach(record => {
                let name = record.fields.Name.value;
                if (mappedTimeline.has(name)) {
                    mappedTimeline.get(name).counter++;                  
                } else {
                    mappedTimeline.set(name, { name: name,  counter: 1 });
                }
            });

            this.timelines = mappedTimeline.values();
        }
    }    

    labels = LABELS;

}