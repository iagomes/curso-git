import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import { MessageContext, publish } from "lightning/messageService";
import closeConsoleTab from "@salesforce/messageChannel/CloseConsoleTab__c";

import getCampaignData from "@salesforce/apex/CampaignManagementController.getCampaignData";
import getAvailableProducts from "@salesforce/apex/CampaignManagementController.getAvailableProducts";
import saveProducts from "@salesforce/apex/CampaignManagementController.saveProducts";
import deleteProduct from "@salesforce/apex/CampaignManagementController.deleteProduct";
import createItemsByCSVFile from "@salesforce/apex/CampaignManagementController.createItemsByCSVFile";


export default class CampaignManagement extends NavigationMixin(LightningElement) {
  @api recordId = undefined;

  @track isLoading = false;

  @track baseParams;
  @track campaign;
  @track campaignItems;

  @track filterProductValue = null;
  @track filterProducerValue = null;

  @track _pageMode = "edit"; // edit | add-products
  @track currentPageReference;

  @track isFetchingProducts = false;
  @track addProductsList = null;

  @track isImportCSVModalOpen = false;
  @track acceptedFormats = ['.csv'];
  
  /** 
   * Métodos de configuração de tela
   */

  @wire(CurrentPageReference)
  setCurrentPageReferenceParams(currentPageReference) {
    this.currentPageReference = currentPageReference;

    const { state } = currentPageReference;

    if (state) {
      const { c__recordId } = state;
      this.recordId = c__recordId || undefined;
    }
  }
  
  get pageMode() {
    return {
      edit: this._pageMode === "edit",
      addproducts: this._pageMode === "add-products" 
    }
  }

  handleAddProductsPageMode() {
    this.filterProducerValue = null;
    this.filterProductValue = null;
    this._pageMode = "add-products";

    this.handleGetProducts();
  }

  handleEditPageMode() {
    this._pageMode = "edit";
  }

  @wire(MessageContext)
  messageContext;

  handlePublishCloseTab() {
    publish(this.messageContext, closeConsoleTab);
  }

  /** 
   * Métodos relacionados aos dados da tela
   */

  @wire(getCampaignData, { campaignId: "$recordId" })
  wiredLoadCampaignData({ data, error }) {
    if (data) {
      const { campaign, campaignItems, params } = data;

      this.baseParams = params;
      this.campaign = campaign;
      this.campaignItems = this.refreshCampaignItems(campaignItems);

    } else if (error) {
      console.error(error);
      this.campaignData = null;
      this.campaignItems = null;
    }
  }

  get campaignItemsEmpty() {
    if (!this.campaignItems || this.campaignItems.length === 0) {
      return true;
    }

    return false;
  }

  handleOnChangeFilter(event) {
    const { name, value } = event.target;

    if (name === "filter-product") {
      this.filterProductValue = value;
    }

    if (name === "filter-producer") {
      this.filterProducerValue = value;
    }
  }

  handleOnKeyPress(event) {
    if (event.keyCode === 13 && !this.isFetchingProducts) {
      this.handleGetProducts();
    }
  }

  async handleGetProducts() {
    this.isFetchingProducts = true;

    const params = {
      filter: {
        product: this.filterProductValue,
        producer: this.filterProducerValue
      },
      offset: 0
    }

    try {
      const { products } = await getAvailableProducts({ 
        data: JSON.stringify(params) 
      });

      this.addProductsList = this.buildAddProductList(products);
      
    } catch (error) {
      console.log(error);
      this.addProductsList = null;
    } finally {
      this.isFetchingProducts = false;
    }
  }

  buildAddProductList(products) {
    if (!products || products.length === 0) {
      return null;
    }

    const productList = products.map(currProduct => {
      const selectedItem = this.campaignItems.find(item => item.Id === currProduct.Id);
      const campaignItemData = selectedItem?.ItemCampanha__r || null;

      return this.buildCampaignItemObject(currProduct, campaignItemData);
    });
    
    return productList;
  }

  buildCampaignItemObject(productData, campaignItemData) {
    // console.log(
    //   JSON.parse(JSON.stringify(productData)), 
    //   JSON.parse(JSON.stringify(campaignItemData))
    // );

    const product = {
      Id: productData.Id,
      Name: productData.Name,
      ProductCode: productData.ProductCode,
      Description: productData.Description || "Sem descrição",
      Fornecedor__r: {
        Name: productData.Fornecedor__c 
          ? productData.Fornecedor__r.Name
          : "Sem fornecedor",
      }
    };

    let ItemCampanha__r = [];

    if (campaignItemData && campaignItemData.length > 0) {
      ItemCampanha__r = campaignItemData;
    }

    return { ...product,  ItemCampanha__r };
  }

  async handleOnAddProduct(event) {
    
    // console.log(JSON.stringify(event.detail));
    this.isLoading = true;
    
    const { refreshedList } = event.detail;

    console.log("handleOnAddProduct PAI", JSON.parse(JSON.stringify(refreshedList)));
    
    // console.log("productData", JSON.parse(JSON.stringify(productData)));
    // console.log("campaignItems", JSON.parse(JSON.stringify(campaignItems)));
    
    // const product = this.campaignItems.find(currProduct => currProduct.Id = productData.Id);
    // console.log("this.campaignItems", JSON.parse(JSON.stringify(this.campaignItems)));
    
    // let listToUpdate = [];
    
    // campaignItems.forEach(currItem => {
    //   let existCampaignItem = null; 
      
    //   if (product) {
    //     // console.log("(product)", JSON.parse(JSON.stringify(product)));
    //     existCampaignItem = product.ItemCampanha__r.find(campaignItem => 
    //       campaignItem.CNPJCD__c === currItem.CNPJCD__c
    //     );
    //   }

    //   if (existCampaignItem) {
    //     listToUpdate.push({
    //       ...existCampaignItem,
    //       ...currItem
    //     });
    //   } else {
    //     listToUpdate.push({
    //       ...currItem,
    //       NomeProduto__c: productData.Id,
    //       Campanha__c: this.recordId
    //     });
    //   }
    // });

    // const records = listToUpdate.map(item => ({
    //   Id: item.Id || null,
    //   Campanha: item.Campanha__c,
    //   NomeProduto: item.NomeProduto__c,
    //   CNPJCD: item.CNPJCD__c || null,
    //   NomeEmpresa: item.NomeEmpresa__c,
    //   VigenciaInicial: item.VigenciaInicial__c,
    //   VigenciaFinal: item.VigenciaFinal__c,
    //   MetaValor: item.Meta__c,
    //   MetaVolume: item.MetaVolume__c
    // }));
    
    // // console.log("records =>", JSON.stringify(records));

    // const refreshedProducts = await saveProducts({
    //   campaignId: this.recordId,
    //   records: JSON.stringify(records) 
    // });

    this.campaignItems = this.refreshCampaignItems(refreshedList);

    if (!!this.addProductsList && this.addProductsList.length > 0) {
      this.addProductsList = this.refreshAddProductList();
    }

    this.isLoading = false;
  }

  async handleDeleteProduct(event) {
    this.isLoading = true;

    const { Id } = event.detail;
    console.log("delete", Id);
    
    const refreshedProducts = await deleteProduct({ 
      campaignId: this.recordId, 
      recordId: Id 
    });

    this.campaignItems = this.refreshCampaignItems(refreshedProducts);

    if (!!this.addProductsList && this.addProductsList.length > 0) {
      this.addProductsList = this.refreshAddProductList();
    }

    this.isLoading = false;
  }

  refreshCampaignItems(campaignItems) {
    let productMap = {};

    // console.log("load campaignItems", JSON.parse(JSON.stringify(campaignItems)));

    campaignItems.forEach(item => {
      let product = productMap[item.NomeProduto__c] || null;

      if (!product) {
        product = {
          Id: item.NomeProduto__c,
          ProductCode: item.NomeProduto__r.ProductCode,
          Name: item.NomeProduto__r.Name,
          Description: item.NomeProduto__r.Description || "Sem descrição",
          Fornecedor__r: { Name: item.NomeProduto__r.Fornecedor__r?.Name || "Sem fornecedor" },
          ItemCampanha__r: []
        }
      }

      product.ItemCampanha__r.push({
        Id: item.Id,
        Campanha__c: item.Campanha__c,
        NomeProduto__c: item.NomeProduto__c,
        CNPJCD__c: item.CNPJCD__c,
        NomeEmpresa__c: item.NomeEmpresa__c,
        VigenciaInicial__c: item.VigenciaInicial__c || null,
        VigenciaFinal__c: item.VigenciaFinal__c || null,
        Meta__c: item.Meta__c || null,
        MetaVolume__c: item.MetaVolume__c || null,
        customKey: `${item.NomeProduto__r.ProductCode}#${item.CNPJCD__c}`
      });

      productMap[item.NomeProduto__c] = product;
    });

    // console.log("productMap", productMap);

    return Object.values(productMap);
  }

  refreshAddProductList() {
    const refreshedList = this.addProductsList.map(currProduct => {
      const campaignItemProduct = this.campaignItems.find(item => item.Id === currProduct.Id);
      
      let ItemCampanha__r = [];

      if (campaignItemProduct) {
        ItemCampanha__r = campaignItemProduct.ItemCampanha__r;
      }

      return { ...currProduct, ItemCampanha__r };
    });

    return refreshedList;
  }

  openImportCSVModal() {
    this.isImportCSVModalOpen = true;
  }

  closeImportCSVModal() {
    this.isImportCSVModalOpen = false;
  }

  async handleUploadFinished(event) {
    this.isLoading = true;

    const { files } = event.detail;
    const [uploadedFile] = files;

    console.log(uploadedFile.name, uploadedFile.documentId);

    const refreshedProducts = await createItemsByCSVFile({ 
      campaignId: this.recordId, 
      documentId: uploadedFile.documentId 
    });

    console.log("onfinish", JSON.stringify(refreshedProducts));

    this.campaignItems = this.refreshCampaignItems(refreshedProducts);

    if (!!this.addProductsList && this.addProductsList.length > 0) {
      this.addProductsList = this.refreshAddProductList();
    }

    this.closeImportCSVModal();

    this.isLoading = false;
  }
}