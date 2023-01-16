import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';
import getDeliveryCenters from '@salesforce/apex/CreateReservationFormController.getDeliveryCenters';
import getRecordTypeOptions from '@salesforce/apex/CreateReservationFormController.getRecordTypeOptions';

import { publish, MessageContext } from 'lightning/messageService';
import closeConsoleTab from '@salesforce/messageChannel/CloseConsoleTab__c';

export default class CreateReservationForm extends NavigationMixin(LightningElement) {
  @api objectApiName = 'Reserva__c';

  @track deliveryCenterOptions = [];

  @track reservationTypeOptions = [];
  @track selectedReservationType;

  @track startDate;
  @track endDate;
  @track description;
  @track deliveryCenter;

  @track isLoading = false;
  @track error;

  @wire(getDeliveryCenters)
  handleGetDeliveryCenters({ error, data }) {
    if (data) {
      console.log(JSON.stringify(data));
      this.deliveryCenterOptions = data;
    } else {
      this.deliveryCenterOptions = [];
      console.log(error);
    }
  }

  @wire(getRecordTypeOptions)
  handleGetRecordTypes({ error, data }) {
    if (data) {
      console.log(JSON.stringify(data));
      this.reservationTypeOptions = data;
    } else {
      this.reservationTypeOptions = [];
      console.log(error);
    }
  }

  @wire(MessageContext)
  messageContext;
  
  handleChangeDeliveryCenter(event) {
    this.deliveryCenter = event.detail.value;
  }

  handleChange(event) {
    switch(event.target.name) {
      case 'start-date':
        this.startDate = event.target.value;
        break;
      case 'end-date':
        this.endDate = event.target.value;
        break;
      case 'description':
        this.description = event.target.value;
        break;
      case 'reservation-type':
        this.selectedReservationType = event.target.value;
        break;

      default:
        break;
    }
  }

  validateFields() {
    if (!this.startDate || !this.endDate || !this.selectedReservationType || !this.deliveryCenter) {
      this.error = 'Verifique todos os campos obrigatórios.';
      return false;
    }

    if (!this.startDate > !this.endDate) {
      this.error = 'Data de início não pode ser maior que data final.';
      return false;
    }

    if ( this.description != undefined && this.description.length > 25) {
        
      this.error = 'A descrição deve conter até 25 caracteres';
      return false;

    }
    
    this.error = null;
    return true;
  }

  async handleSave() {
    console.log(this.startDate);
    const isValid = this.validateFields();

    if (!isValid) { 
      return;
    }

    const data = {
      apiName: "Reserva__c",
      fields: {
        InicioReserva__c: new Date(this.startDate+'T00:00:00'),
        FimReserva__c: new Date(this.endDate+'T00:00:00'),
        RecordTypeId: this.selectedReservationType,
        Descricao__c: this.description,
        CodigoCD__c: this.deliveryCenter
      }
    }

    try {
      this.isLoading = true;
      
      const result = await createRecord(data);
      const { id: recordId } = result;

      publish(this.messageContext, closeConsoleTab, { recordId });

    } catch (error) {
      console.log(error);
      this.isLoading = false;
    }
  }
}