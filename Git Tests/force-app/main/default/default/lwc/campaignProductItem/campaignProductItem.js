import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import saveProducts from "@salesforce/apex/CampaignManagementController.saveProducts";
import deleteProduct from "@salesforce/apex/CampaignManagementController.deleteProduct";

export default class CampaignProductItem extends LightningElement {
  @api productData = null;
  @api campaignItems = [];
  @api campaignId;
  
  @api distributionCenterOptions = [];
  
  @track selectedOptions = [];
  @track isLoading = false;

  get alreadyAdded() {
    return !!this.productData.ItemCampanha__r?.length > 0 || false;
  }

  get distributionCentersCount() {
    if (this.campaignItems.length === 0) {
      return "Nenhum selecionado";
    }

    return `${this.campaignItems.length} selecionados`;
  }

  get _selectedOptions() {
    if (!this.campaignItems) {
      return [];
    }
    
    return this.campaignItems.map(item => item.CNPJCD__c);
  }

  handleOnSelectDistributionCenters(event) {
    const { selectedOptions } = event.detail;
    this.selectedOptions = selectedOptions;

    console.log(selectedOptions.length);

    let updatedCampaignList = [];

    selectedOptions.forEach(currDistributionCenter => {
      let campaingItem = {
        Id: null,
        NomeProduto__c: this.productData.Id,
        CNPJCD__c: currDistributionCenter,
        NomeEmpresa__c: this.distributionCenterOptions[currDistributionCenter],
        VigenciaInicial__c: null,
        VigenciaFinal__c: null,
        Meta__c: null,
        MetaVolume__c: null,
        customKey: `${this.productData.ProductCode}#${currDistributionCenter}`
      }
      
      const item = this.campaignItems.find(
        currItem => currItem.CNPJCD__c === currDistributionCenter
      );
      
      if (item) {
        campaingItem = {...item};
      }

      updatedCampaignList.push(campaingItem);
    });

    // console.log("updatedCampaignList", JSON.parse(JSON.stringify(updatedCampaignList)));

    this.campaignItems = updatedCampaignList;
  }

  handleChangeFieldValue(event) {
    const { name, value, dataset } = event.target;
    const datasetId = dataset.id;

    console.log( name, value, datasetId);

    const campaignItems = this.campaignItems.map(campaignItem => {
      if (campaignItem.customKey !== datasetId) {
        return campaignItem;
      }

      let updatedItem = JSON.parse(JSON.stringify(campaignItem));

      switch(name) {
        // case 'validity-from': {
        //   updatedItem.VigenciaInicial__c = value;
        //   break;
        // }

        // case 'validity-to': {
        //   updatedItem.VigenciaFinal__c = value;
        //   break;
        // }

        case 'goal-volume': {
          updatedItem.MetaVolume__c = Number(value) || null;
          break;
        }

        case 'goal-amount': {
          updatedItem.Meta__c = Number(value) || null;
          break;
        }

        default:
          break;
      }

      return updatedItem;
    });

    this.campaignItems = campaignItems;
  }

  async handleAddOrUpdateProduct() {
    console.log("handleAddOrUpdateProduct");

    // const validityError = this.checkValidityFields();

    // if (validityError) {
      // const evt = new ShowToastEvent({
      //   title: validityError.title,
      //   message: validityError.message,
      //   variant: validityError.variant,
      // });

      // this.dispatchEvent(evt);
      // return;
    // }

    this.isLoading = true;

    try {

      const records = this.campaignItems.map(item => ({
        Id: item.Id || null,
        Campanha: this.campaignId,
        NomeProduto: item.NomeProduto__c,
        CNPJCD: item.CNPJCD__c || null,
        NomeEmpresa: item.NomeEmpresa__c,
        VigenciaInicial: item.VigenciaInicial__c,
        VigenciaFinal: item.VigenciaFinal__c,
        MetaValor: item.Meta__c,
        MetaVolume: item.MetaVolume__c
      }));

      console.log(JSON.parse(JSON.stringify(records)));

      const refreshedList = await saveProducts({
        campaignId: this.campaignId,
        records: JSON.stringify(records) 
      });

      console.log("retorno refreshedList", JSON.stringify(refreshedList));

      const customEvent = new CustomEvent("addproduct", {
        detail: {
          productData: { Id: this.productData.Id },
          refreshedList
        }
      });
  
      this.dispatchEvent(customEvent);

      const successEvtToast = new ShowToastEvent({
        title: "Tudo certo",
        message: "O registros foram atualizados com sucesso.",
        variant: "success",
      });
      this.dispatchEvent(successEvtToast);

      this.isLoading = false;

    } catch (error) {
      console.error(error);
      this.isLoading = false;

      const errorEvtToast = new ShowToastEvent({
        title: "Algo deu errado.",
        message: "Erro ao salvar os registros.",
        variant: "error",
      });
      this.dispatchEvent(errorEvtToast);
    }
  }

  checkValidityFields() {
    let validity;

    this.campaignItems.forEach(item => {
      // if (item.VigenciaInicial__c && item.VigenciaFinal__c) {
      //   if (new Date(item.VigenciaInicial__c) > new Date(item.VigenciaFinal__c)) {
      //     validity = {
      //       title: "Erro ao validar informações.",
      //       message: "Vigência inicial não pode ser maior que vigência final",
      //       variant: "error"
      //     };
      //   }
      // } else {
      //   validity = {
      //     title: "Erro ao validar informações.",
      //     message: "É obrigatório informar vigência inicial e final",
      //     variant: "error"
      //   };
      // }
    });

    return validity;
  }

  handleDeleteProduct(event) {
    const datasetId = event.target.dataset.id;
    const campaignItem = this.campaignItems.find(item => item.customKey === datasetId);

    if (!campaignItem) {
      console.log("Algo deu errado!");
    }

    if (!campaignItem.Id) {
      this.campaignItems = this.campaignItems.filter(item => item.customKey !== datasetId);
      return;
    }

    const customEvent = new CustomEvent("deleteproduct", {
      detail: { 
        Id: campaignItem.Id, 
      }
    });

    this.dispatchEvent(customEvent);
  }
}