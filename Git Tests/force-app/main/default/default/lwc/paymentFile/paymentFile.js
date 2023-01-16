import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendAttachment from '@salesforce/apex/IntegrationPaymentAttachment.sendAttachment';
import updatePayment from '@salesforce/apex/IntegrationPaymentAttachment.updatePayment';
import ORDER_PAYMENT_ATTACHMENT from '@salesforce/schema/Order.ComprovanteAnexado__c';
import ORDER_ATTACHMENT from '@salesforce/schema/Order.AttachmentId__c';
import PARENT_ACCOUNT_NAME from '@salesforce/schema/Order.PedidoPai__r.Account.Name';
import ORDER_ACCOUNT_NAME from '@salesforce/schema/Order.Account.Name';
import PARENT_ORDER_STATUS from '@salesforce/schema/Order.PedidoPai__r.Status';
import ORDER_STATUS from '@salesforce/schema/Order.Status';
import ORDER_ID from '@salesforce/schema/Order.Id';

export default class PaymentFile extends LightningElement {
	@api recordId;
	
	@wire(getRecord, { recordId: '$recordId', fields: [ORDER_PAYMENT_ATTACHMENT, PARENT_ORDER_STATUS, ORDER_STATUS, PARENT_ACCOUNT_NAME, ORDER_ACCOUNT_NAME] })
	orderAttachment;

	get acceptedFormats() {
		return ['.jpg', '.jpeg'];
	}
	get hasAttachment() {
		return getFieldValue(this.orderAttachment.data, ORDER_PAYMENT_ATTACHMENT);
	}
	get parentOrderStatus() {
		return getFieldValue(this.orderAttachment.data, PARENT_ORDER_STATUS);
	}
	get orderStatusIntegration() {
		let status;
		const statusIntegration = getFieldValue(this.orderAttachment.data, ORDER_STATUS);
		if (statusIntegration == 'Aguardando comprovante') {
			if (this.hasAttachment) {
				status = 'Aguardando integração do comprovante.';
			} else {
				status = 'Aguardando comprovante!';
			}
		} else if (statusIntegration == 'Aguardando aprovação RA') {
			status = 'Aguardando aprovação RA';
		} else if (statusIntegration == 'Cancelado') {
			status = 'Pedido cancelado.';
		}

		return status;
	}
	get parentAccountName() {
		console.log('Entrou parentAccountName =>', PARENT_ACCOUNT_NAME);
		return getFieldValue(this.orderAttachment.data, PARENT_ACCOUNT_NAME);
	}
	get orderAccountName() {
		console.log('Entrou orderAccountName =>', ORDER_ACCOUNT_NAME);
		return getFieldValue(this.orderAttachment.data, ORDER_ACCOUNT_NAME);
	}
	get isSale() {
		if (this.parentAccountName != this.orderAccountName)
			return false;
		else
			return true;
	}

	handleUploadFinished(event){
		this.updateRecord(event.detail.files);
	}

	async updateRecord(files) {
		try {
			var statusIntegration = 'Aguardando';
			// const fields = {};
			// fields[ORDER_ID.fieldApiName] = this.recordId;
			// fields[ORDER_ATTACHMENT.fieldApiName] = (files[0].documentId).toString();
			// fields[ORDER_PAYMENT_ATTACHMENT.fieldApiName] = true;
			// const recordInput = { fields };

			// await updateRecord(recordInput);
			await updatePayment({ orderId: this.recordId, documentId: (files[0].documentId).toString()});
			
			if (this.orderStatusIntegration == 'Aguardando comprovante!') {
				statusIntegration = await sendAttachment({
					orderId: this.recordId
				});
			}

			if (statusIntegration == 'Ok'){
				this.showToastEvent('Sucesso', 'Comprovante de pagamento enviado com sucesso!!', 'success');
			}else if (statusIntegration == 'Aguardando'){
				this.showToastEvent('Atenção!', 'Comprovante salvo. Será enviado quando o Status for "Aguardando comprovante".', 'warning');
			}else{
				this.showToastEvent('Erro', 'Erro no envio do comprovante de para o Protheus, será reenviado novamente em 1 hora.', 'error');
			}
				this.updateRecordView();
		} catch (error) {
			this.showToastEvent('Erro', 'Falha no envio do comprovante de pagamento.', 'error');
			console.log(error);
		}
	}

	showToastEvent(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant
			})
		);
	}

	updateRecordView() {
		setTimeout(() => {
			 eval("$A.get('e.force:refreshView').fire();");
		}, 500); 
	 }
}