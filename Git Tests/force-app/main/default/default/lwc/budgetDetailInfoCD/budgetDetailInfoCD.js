import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference} from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

export default class BudgetDetailInfoCD extends LightningElement {

	@wire(CurrentPageReference) pageRef;

	//infoCDController
	showSpinner = false;
	showCDs = false;
	@api oppId;
	@api resp;
	@api cnpj;
	@api accountType;
	@api pricebook;
	@api condpag;
	@api uf;
	@api quantidade;
	@api accountid;
	@api cdsBloqueados;

	showHistoric = false;
	showProductDescriptionModal = false;

	connectedCallback(){
		registerListener('fatorSelected', this.registerFatorConversao, this);
		registerListener('controllSpinner', this.controllSpinner, this);
	}

	disconnectedCallback(){
		this.showSpinner = false;
		unregisterAllListeners(this);
	}

	registerFatorConversao(){
		this.showCDs = true;
	}

	controllSpinner(event){
		this.showSpinner = event;
	}

	buttonCloseClick(event) {
		this.dispatchEvent(new CustomEvent('closeclick'));
	}

	handleOpenHistoric(event){
		this.showHistoric = !this.showHistoric;
	}

	handleOpenProductDesc(event){
		this.showProductDescriptionModal = !this.showProductDescriptionModal;
	}

	handleNextPage(event){
		this.dispatchEvent(new CustomEvent('nextpageedititem'));
	}
}