import { LightningElement, api, wire } from 'lwc';
import Customer_survey from '@salesforce/label/c.Customer_survey';
import NPS_token from '@salesforce/label/c.NPS_token';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import ContactId_FIELD from '@salesforce/schema/Case.ContactId';
import ContactEmail_FIELD from '@salesforce/schema/Case.ContactEmail';
import AccountIdentification_FIELD from '@salesforce/schema/Case.Customer_Id__c';
import CaseNumber_FIELD from '@salesforce/schema/Case.CaseNumber';
import CaseOwnerName_FIELD from '@salesforce/schema/Case.OwnerName__c';
import EmpresaDemandanteNPS_FIELD from '@salesforce/schema/Case.Empresa_Demandante_NPS__c';

const fields = [ContactId_FIELD,
                ContactEmail_FIELD,
                AccountIdentification_FIELD,
                CaseNumber_FIELD,
                CaseOwnerName_FIELD,
                EmpresaDemandanteNPS_FIELD];

export default class Chatbot_nps extends LightningElement {

    @api recordId;
    @api inputParams;

    customer_survey = Customer_survey;
    nps_token = NPS_token;

    connectedCallback() {
        this.recordId = this.inputParams.replace('lwc:nps:', '');
    }

    @wire(getRecord, { recordId: '$recordId', fields: fields})
    caseRecord;

    get contactId() {
        return getFieldValue(this.caseRecord.data, ContactId_FIELD);
    }

    get contactEmail() {
        return getFieldValue(this.caseRecord.data, ContactEmail_FIELD);
    }
    
    get accountIdent() {
        return getFieldValue(this.caseRecord.data, AccountIdentification_FIELD);
    }
    
    get caseNumber() {
        return getFieldValue(this.caseRecord.data, CaseNumber_FIELD);
    }    

    get caseOwnerName() {
        return getFieldValue(this.caseRecord.data, CaseOwnerName_FIELD);
    }  
    
    get empresaDemandanteNPS() {
        return getFieldValue(this.caseRecord.data, EmpresaDemandanteNPS_FIELD);
    }  

    get url() {
        return `https://survey.solucx.com.br/${this.nps_token}/emoticons?name=${this.contactId}&email=${this.contactEmail}&store_id=${this.empresaDemandanteNPS}&employee_id=n%2Fa&amount=1&journey=atendimento&customer_id=${this.accountIdent}&param_CNPJ=${this.accountIdent}&transaction_id=${this.caseNumber}&param_atendente=${this.caseOwnerName}&cpf=${this.accountIdent}`;
    }

}