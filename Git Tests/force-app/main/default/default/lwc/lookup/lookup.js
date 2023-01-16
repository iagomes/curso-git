import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import getRecords from '@salesforce/apex/Lookup.getRecords';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Lookup extends LightningElement {
  @api recordId;
  @api targetObject;
  @api searchFields = [];
  @api moreFields = [];
  @api labelNewRecord = 'Criar novo registro';
  @api newRecordButton = false;
  @api disabledCustomLookup = false;
  @api isLink = false;

  @api parentRecordId;
  @api parentRelationField;

  @api objectIconName = 'standard:custom_notification';
  @api inputLabel = 'Selecione um registro';
  @api placeholder = 'Digite para buscar...';

  @api listItemOptions = {
    title: 'Id',
    description: null
  };

  @api standardFormLayout = false;
  @api recordTypeId;

  @track searchFieldsApiNames = null;
  @track moreFieldsApiNames = null;
  @track searchValue = null;
  @track isLoading = true;
  @track desktop = true;

  @track records = null;
  @track noRecords = false;
  @track selectedRecord = null;

  @track showCreateRecordForm = false;

  @track allFields;

  connectedCallback() {
    this.desktop = FORM_FACTOR == 'Large';
    if (this.searchFields) {
      const searchFieldsApiNames = this.searchFields
        .filter(fieldRef => fieldRef.objectApiName === this.targetObject.objectApiName)
        .map(fieldRef => fieldRef.fieldApiName);

      this.searchFieldsApiNames = searchFieldsApiNames;

      const moreFieldsApiNames = this.moreFields
        .filter(fieldRef => fieldRef.objectApiName === this.targetObject.objectApiName)
        .map(fieldRef => fieldRef.fieldApiName);

      this.moreFieldsApiNames = moreFieldsApiNames;
    }

    this.allFields = [...this.searchFields, ...this.moreFields];
  }

  get recordsList() {
    if (!this.records) {
      return null;
    }

    let itemsList = this.records.map(record => {
      const title = record[this.listItemOptions.title] || record['Id'];

      let description = null;

      if (this.listItemOptions.description) {
        if (typeof this.listItemOptions.description === 'string') {
          description = record[this.listItemOptions.description] || null;
        } else if (this.listItemOptions.description.length > 0) {
          let descriptionValues = [];

          this.listItemOptions.description.forEach(field => {
            if (
              typeof record[field] != 'undefined' &&
              record[field] != null &&
              record[field] != ''
            ) {
              descriptionValues.push(record[field]);
            }
          });

          description = descriptionValues.join(' | ');
        }
      }

      return {
        Id: record.Id,
        title,
        description
      }
    });

    return itemsList;
  }

  @wire(getRecord, { recordId: '$recordId', fields: '$allFields' })
  wiredGetRecord({ error, data }) {
    this.isLoading = false;

    if (!this.recordId) {
      this.selectedRecord = null;
      return;
    }

    if (error) {
      console.log(error);
      return;
    }

    if (data) {
      const { id, fields } = data;

      this.selectedRecord = {
        Id: id,
        title: fields[this.listItemOptions.title].value
      };

      let record = { Id: this.recordId };
      this.allFields.forEach(field => {
        record = {
          ...record,
          [field.fieldApiName]: fields[field.fieldApiName]?.value
        }
      })

      this.dispatchEvent(
        new CustomEvent('selectrecord', {
          detail: {
            record
          }
        })
      );
    }
  }

  handleTyping(event) {
    const { value } = event.target;

    if (value.length < 0) {
      this.records = null;
      return;
    }

    this.searchValue = value;
    this.isLoading = true;

    this.handleGetRecords();
  }

  async handleGetRecords() {
    let requestData = {
      targetObject: this.targetObject.objectApiName,
      searchFields: this.searchFieldsApiNames,
      searchValue: this.searchValue,
      moreFields: this.moreFieldsApiNames || null
    };

    if (this.parentRelationField && this.parentRecordId) {
      requestData = {
        ...requestData,
        relations: [{
          parentRelationField: this.parentRelationField.fieldApiName,
          parentRecordId: this.parentRecordId,
        }]
      }
    }

    try {
      const data = await getRecords({ data: JSON.stringify(requestData) });

      if (data) {
        this.records = data.map(item => ({ ...item }));
        this.noRecords = (data.length == 0);
      } else {
        this.records = null;
      }
    } catch (error) {
      console.log(error);
    } finally {
      this.isLoading = false;
    }
  }

  handleOnFocus() {
    this.handleGetRecords();
  }

  handleCloseList() {
    this.records = null;
  }

  handleSelectRecord(event) {
    const { value } = event.target.dataset;

    const record = this.records.find(item => item.Id === value);

    this.selectedRecord = {
      Id: record.id,
      title: record[this.listItemOptions.title]
    };

    this.dispatchEvent(
      new CustomEvent('selectrecord', {
        detail: {
          record
        }
      })
    );
  }

  handleClearSelected() {
    this.selectedRecord = null;
    this.recordId = null;

    this.dispatchEvent(
      new CustomEvent('clearselectedrecord')
    );
  }

  @api clearAll() {
    this.selectedRecord = null;
    this.recordId = null;
    this.searchValue = null;
    this.records = null;
  }

  handleToggleCreateRecord() {
    this.showCreateRecordForm = !this.showCreateRecordForm;    
    this.scrollToTop();
  }

  scrollToTop() {
    if (!this.desktop) {
      const scrollOptions = {
        left: 0,
        top: 0
      }
      parent.scrollTo(scrollOptions);
    }
  }

  async handleSuccessCreate(event) {
    const { id: recordId } = event.detail;

    this.isLoading = true;
    this.recordId = recordId;

    this.handleToggleCreateRecord();
  }
}