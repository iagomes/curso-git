import { LightningElement, api } from 'lwc';
import fetchBase64File from '@salesforce/apex/ChatBot.fetchBase64File';
import LABELS from './labels.js';

export default class Chatbot_document_download extends LightningElement {

    @api inputParams;

    url;
    errorMessage;     
    clickHereText;
    hasError = false;
    loaded = false;

    labels = LABELS;

    connectedCallback() {

        debugger;

        let params = JSON.parse(this.inputParams.replace('lwc:docDown:', '').replace(/&quot;/g, '"'));
        let customerId = params.cId;
        let invoiceNumber = params.inNum;
        let documentType = params.docT;
        let orderNumber = params.oNum;

        switch (documentType) {
            case 'invoice':
                this.errorMessage = this.labels.Error_when_generating_invoice;
                this.clickHereText = this.labels.Click_here_to_download_your_invoice;
                break;
            case 'paymentSlip':
                this.errorMessage = this.labels.Error_when_generating_payment_slip;
                this.clickHereText = this.labels.Click_here_to_download_your_payment_slip;
                break;
            default:
              console.log(`Sorry, we are out of ${documentType}.`);
        }          

        fetchBase64File({ params: { 
                            customerId: customerId,
                            invoiceNumber: invoiceNumber,
                            documentType: documentType,
                            orderNumber: orderNumber
        }})
        .then((result) => {
            if (result) {
                this.generateBlobUrl(result);
            } else {   
                this.hasError = true;
            }
        })
        .catch((error) => {
            this.hasError = true;
        });        

    }

    base64ToArrayBuffer(base64) {
        let binaryString = window.atob(base64);
        let binaryLen = binaryString.length;
        let bytes = new Uint8Array(binaryLen);
        for (let i = 0; i < binaryLen; i++) {
            let ascii = binaryString.charCodeAt(i);
            bytes[i] = ascii;
       }
       return bytes;
    }

    generateBlobUrl(base64) {
        let byte = this.base64ToArrayBuffer(base64);
        let blob = new Blob([byte], { type: "application/pdf" });
        this.url = URL.createObjectURL(blob);
        this.loaded = true;
        let container = this.template.querySelector('div[ishtmlcontainer=true]');
        container.innerHTML = this.clickHereText;
        let downloadAnchor = container.querySelector("a[name=download]");
        downloadAnchor.target = "_blank";
        downloadAnchor.href = this.url;        
    }

}