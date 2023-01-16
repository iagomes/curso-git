import { LightningElement, api, track } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import getAvailableData from '@salesforce/apex/CustomLookupController.getAvailableData';
import getRecords from '@salesforce/apex/CustomLookupController.getRecords';
import getContaOrdem from '@salesforce/apex/CustomLookupController.getContaOrdem';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_CNPJ_FIELD from '@salesforce/schema/Account.CNPJ__c';
import ACCOUNT_FANTASIA_FIELD from '@salesforce/schema/Account.NomeFantasia__c';

const accountFields = [ACCOUNT_NAME_FIELD, ACCOUNT_CNPJ_FIELD, ACCOUNT_FANTASIA_FIELD];
export default class CustomLookup extends LightningElement {
  @api objectApiName;
  @api fieldApiName = 'name';
  @api objectIconName = 'standard:custom_notification';
  @api inputLabel = 'Selecione um registro';
  @api clientId = '';
  @api checkType = '';
  @api conditionId = '';
  @api disabled = false;
  @api placeholder;
  @api required;

  @track searchValue = null;
  @track recordsList = null;
  @track isLoading = false;
  @api selectedRecord = null;
  @api hideClose = false;

  @track query;

  connectedCallback() {
    console.log('this.checkType ' + this.checkType);
    console.log('accountFields ' + accountFields);
    if(this.checkType =='ContaOrdem'){
        getContaOrdem({
          clientId: this.clientId,
          searchValue: this.searchValue
        }).then(data => {
            console.log(data);
            this.recordsList = JSON.parse(data);
            this.isLoading = false;
            
          })
          .catch(error => {
            console.log(error);
          });
    }else{
      if (accountFields) {
        const searchFieldsApiNames = accountFields
          .filter(fieldRef => fieldRef.objectApiName === this.objectApiName)
          .map(fieldRef => fieldRef.fieldApiName)

        this.generateQueryBase(searchFieldsApiNames);
      }
    }
  }

  generateQueryBase(searchFieldsApiNames) {
    let searchBase = '';
    console.log('searchValue: ' + this.searchValue);
    searchFieldsApiNames.forEach((field, index) => {
      searchBase += `${index > 0 ? ' OR' : ''} ${field} LIKE '%#SEARCH#%'`;
    });

    console.log('this.objectApiName:::', this.objectApiName);

    if (this.objectApiName === 'Pricebook2') {
      this.query = `
        SELECT Id, DataInicio__c, isActive, DataFim__C, NomeCentroDistribuicao__c, CodigoCentroDistribuicao__c, name
        FROM ${this.objectApiName}
        WHERE Id != NULL
        AND ( DataInicio__c <= TODAY OR DataInicio__c = NULL)
        AND ( DataFim__C >= TODAY OR DataFim__c = NULL)
        AND CodigoTabela__c = NULL
        ${searchBase ? 'AND ('+searchBase+')' : '' } LIMIT 50
      `;
      //AND isActive = TRUE
    } else {
      this.query = `
        SELECT ${searchFieldsApiNames.join() || 'Id, Name'}
        FROM ${this.objectApiName}
        WHERE Id != NULL
        ${searchBase ? 'AND ('+searchBase+')' : '' } LIMIT 50
      `;
    }

    console.log('this.query:::', this.query);
  }

  handleTyping(event) {
    const { value } = event.target;

    if (value.length < 1) {
      this.recordsList = null;
      return;
    }

    this.searchValue = value;
    this.isLoading = true;

    this.handleGetRecords();
  }

  handleGetRecords() {
    const formattedQuery = this.query.replace(/#SEARCH#/g, this.searchValue);
    console.log(formattedQuery);
    console.log('this.checkType ' + this.checkType);
    if (this.checkType == 'Account') {
      getRecords({ query: formattedQuery, checkType: this.objectApiName }).then(data => {
        console.log('getRecords: entrou certo!');
        console.log(data);
        this.recordsList = JSON.parse(data);
        this.isLoading = false;
      }).catch(error => {
        console.log('getRecords: entrou no erro!');
        console.log(error);
      });
    } else {    
        getAvailableData({
          clientId: this.clientId,
          conditionId: this.conditionId,
          filter: this.searchValue,
          checkType : this.checkType
        }).then(data => {
            console.log(data);
            this.recordsList = JSON.parse(data);
            this.isLoading = false;
            
          })
          .catch(error => {
            console.log(error);
          });
    }      
  }
  handleFocus(event) {

      console.log('conta ordem ' + this.checkType);

    if(this.checkType =='ContaOrdem'){
        getContaOrdem({
          clientId: this.clientId,
          searchValue: this.searchValue
        }).then(data => {
            console.log(data);
            this.recordsList = JSON.parse(data);
            this.isLoading = false;
            
          })
          .catch(error => {
            console.log(error);
          });
    }else{
      if (event.target.value == '') {
        const formattedQuery = this.query.replace(/#SEARCH#/g, this.searchValue);
        console.log('formattedQuery:: ', formattedQuery);
        getRecords({ query: formattedQuery, checkType: this.objectApiName}).then(data => {
          console.log('getRecords: entrou certo!');
          console.log(data);
          this.recordsList = JSON.parse(data);
          this.isLoading = false;
        }).catch(error => {
          console.log('getRecords: entrou no erro!');
          console.log(error);
        });
      } else {       
        getAvailableData({
          clientId: this.clientId,
          conditionId: this.conditionId,
          filter: this.searchValue,
          checkType : this.checkType
        }).then(data => {
            console.log(data);
            this.recordsList = JSON.parse(data);
            this.isLoading = false;
            
          })
          .catch(error => {
            console.log(error);
          });
      }
    }
  }
  handleFocus(event) {
      console.log('conta ordem 2 ' + this.checkType);

    if(this.checkType =='ContaOrdem'){
        getContaOrdem({
          clientId: this.clientId,
          searchValue: this.searchValue
        }).then(data => {
            console.log(data);
            this.recordsList = JSON.parse(data);
            this.isLoading = false;
            
          })
          .catch(error => {
            console.log(error);
          });
    }else{

      if (event.target.value == '') {
        const formattedQuery = this.query.replace(/#SEARCH#/g, this.searchValue);
        console.log('formattedQuery:: ', formattedQuery);
        getRecords({ query: formattedQuery, checkType: this.objectApiName}).then(data => {
          console.log('getRecords: entrou certo!');
          console.log(data);
          this.recordsList = JSON.parse(data);
          this.isLoading = false;
        }).catch(error => {
          console.log('getRecords: entrou no erro!');
          console.log(error);
        });
      }
    }
  }

  handleSelectRecordClick(event) {
    const { value } = event.target.dataset;
    this.handleSelectRecord(value)
  }
  handleSelectRecord(value) {
    const record = value == null ? null : this.recordsList.find(item => item.id === value);

    this.selectedRecord = record;
    console.log(record);

    // this.recordsList = null;

    this.dispatchEvent(
      new CustomEvent('selectrecord', {
        detail: {
          record: this.selectedRecord
        }
      })
    );
  }

  handleClearSelectedClose() {
    this.handleClearSelected();
    this.handleSelectRecord(null);
  }

  @api
  handleClearSelected() {
    console.log(null);
    this.selectedRecord = null;
    this.searchValue = null;
    this.recordsList = null;
  }
}
