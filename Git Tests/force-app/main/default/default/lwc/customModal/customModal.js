import { LightningElement, api } from 'lwc';
// import opportunityTabIcons from '@salesforce/resourceUrl/opportunityTabIcons';

export default class CustomModal extends LightningElement {
    @api title;
    @api headerIconSrc;
    @api iconWidth = '33';
    @api iconHeight = '33';
    @api iconViewBox = '0 0 33 19';
    @api hidefooter = false;
    @api hideButtonNext = false;
    @api hideCloseButton = false;
    @api showfooterproposal = false;
    @api removepadding = false;
    @api showConfirmationButton = false;
    @api showCancelButton = false;
    @api showYesButton = false;
    @api showNoButton = false;
    @api removeBackdrop = false;
    @api initStyle = 'slds-modal slds-fade-in-open slds-modal_medium';
    @api containerStyle = 'slds-modal__container';
    @api role = 'dialog';

    @api removeStandardClasses = false;
    get sectionClass() {
        return this.removeStandardClasses ? "" : "slds-modal slds-fade-in-open";
    }

    get divClass() {
        return this.removeStandardClasses ? "" : "slds-modal__container";
    }

    iconsSrc = {
        // "thumbs": opportunityTabIcons + '/fi-br-thumbs-up.svg#fi-br-thumbs-up',    
        // "ban": opportunityTabIcons + '/fi-br-ban.svg#fi-br-ban',
    };


    handleCloseClick(){
        this.dispatchResult({action: 'close'})
        this.dispatchEvent(new CustomEvent('closeclick'));
    }

    handleConfirmClick() {
        this.dispatchResult({ action: 'confirm' })
    }

    handleCancelClick() {
        this.dispatchResult({ action: 'close' })
    }

    handleYesClick() {
        this.dispatchResult({ action: 'yes' })
    }

    handleNoClick() {
        this.dispatchResult({ action: 'no' })
    }

    handleActionNext() {
        this.dispatchResult({ action: 'next' })
        this.dispatchEvent(new CustomEvent('actionnext'));
    }

    dispatchResult(detail) {
        console.log('hanldeClick', detail.action, detail);
        this.dispatchEvent(new CustomEvent('modalresult', {
            detail: detail
        }));
    }

    connectedCallback() {
        console.log('response connectedCallback', this.response);
    }

    removePadding() {
        let allTabs = this.template.querySelectorAll('.slds-modal__content');
        allTabs.forEach((elm, idx) => {
            console.log(elm)
            elm.classList.remove("slds-p-around_medium");
        });
    }

    handleKeyDown(event) {
        if (event.code == 'Escape') {
            this.handleCloseClick();
            event.preventDefault();
            event.stopImmediatePropagation();
        }
    }

}