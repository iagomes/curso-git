import { LightningElement, api, track, wire } from 'lwc';
export default class UnitMeasurement extends LightningElement {
    @api isModalOpen = false;
    @api disabled = false;
    @api products;
    @track recordTypeId;
    @track prodList = [];
    @track recordTypeId;

    connectedCallback(){
        this.prodList = [];
        console.log('BBBBBBBBBBBBBBBBBBBB', this.products);
        this.prodList = JSON.parse(this.products);
        this.prodList = this.prodList.filter(cd => cd.selected === true);
    }
    
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.scrollToTop();
        this.isModalOpen = true;
        this.prodList = [];
        this.prodList = JSON.parse(this.products);
        this.prodList = this.prodList.filter(cd => cd.selected === true);

    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        const productSelected = new CustomEvent("selected", {
            detail : JSON.stringify({prodId : '' , value : '', action : 'close'})
        });
        this.dispatchEvent(productSelected);
        this.isModalOpen = false;
    }

    scrollToTop() {
        if (!this.desktop) {
            const scrollOptions = {
				left: 0,
				top: 0,
				behavior: 'smooth'
			}
			parent.scrollTo(scrollOptions);
        }
    }

    hasErrors() {
        let hasError = false;
        console.log(hasError);
        return hasError;
    }

    alterValueTtl(event){
        event.preventDefault();
        let targetId = event.currentTarget.dataset.id;
        let selected = event.detail;
        console.log('targetId',targetId);
        console.log('selected',selected);
        const productSelected = new CustomEvent("selected", {
            detail : JSON.stringify({prodId : targetId , value : selected.value, action : 'add'})
        });
        this.dispatchEvent(productSelected);
    }
}