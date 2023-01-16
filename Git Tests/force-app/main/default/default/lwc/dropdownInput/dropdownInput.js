import { LightningElement, api, track } from 'lwc';
import { MultiOption } from 'c/utilities';
import getPickListValuesList from '@salesforce/apex/UtilitiesController.getPickListValuesList';

export default class DropdownInput extends LightningElement {


    @api label;
    @api boldTitle;
    @api hideLimpar;
    @api required;
    @api disabled;
    @api removeSelectAll = false;
    
    inputValue;
    showOptions = false;

    @track options_ = [];
    @track optionList = [];

    privateName;
    @api
    get name(){
        return this.privateName;
    }
    set name(value)  {
        this.privateName = value;
        this.setAttribute('name', this.privateName);
        this.setAttribute('class', this.privateName);
    }

    @api
    get options(){
        return this.optionList;
    }
    set options(value){
        this.options_ = [];
        this.optionList = [];

        if(!!value && value.length > 0){
            value.forEach(vl => {
                let vlCopy = {...vl};
                this.options_.push(vlCopy);
                this.optionList.push(vlCopy);
            });
            if(!this.removeSelectAll){
                let allValue = {value:'%todos%', label:'--SELECIONAR TODOS--', isSelected: false};
                this.options_.push(allValue);
                this.optionList.push(allValue);
            }
        }
    }

    get hasList(){
        return (this.optionList?.length > 0);
    }

    fieldApiName_;
    @api
    get fieldApiName(){
        return this.fieldApiName_;
    }
    set fieldApiName(value) {
        this.fieldApiName_ = value;
        if(value && (!this.options || this.options.length == 0)){

            getPickListValuesList({fieldAndObjectApiName: this.fieldApiName_}).then((response) => {
                this.options = response.map(opt => {
                    return {value: opt.value, label: opt.label, isSelected: false};
                });
            });
        }
    }


    handleOnFocus(){
        this.showOptions = true;
    }

    handleOnBlur(){
        this.showOptions = false;
    }

    handleChangeInput(event){
        this.showOptions = true;
        this.inputValue = event.target.value;

        if(this.inputValue !== '' && this.inputValue !== undefined && this.inputValue !== null){
            let result = this.options_.filter(opt =>{
                return (opt.label).toLowerCase().indexOf(this.inputValue.toLowerCase()) >= 0
            });
            this.optionList = [...result];
        }
        else{
            this.optionList = [...this.options_];
        }
        
    }

    handleClearButton(){
        this.clearSelections(false);
    }

    @api clearSelections(skipSend){

        this.options_ = this.options_.map(opt => {
            opt.isSelected = false;
            return {...opt};
        });
        this.optionList = [...this.options_];
        this.inputValue = '';

        if(!skipSend){
            this.sendOptionSelection();
        }

    }

    sendOptionSelection(){
        this.dispatchEvent(new CustomEvent('optionselection', 
            {detail: JSON.stringify({
                field: this.privateName,
                selectedOptions: this.getSelectedValues()
            })}
        ));
    }

    handleSelectOption(event){
        const item = event.target.dataset;
        if(item.value == '%todos%'){
            this.optionList = [...this.options_];
            this.inputValue = '';
        }

        this.optionList = this.optionList.map(opt =>{
            if(opt.value === item.value || item.value == '%todos%'){
                opt.isSelected = (item.isSelected == false || item.isSelected == 'false');
            }
            return opt;
        });
            
        

        this.sendOptionSelection();
    }

    @api getSelectedValues(){
        return this.options_.filter(opt =>{return opt.isSelected});
    }

    @api setSelectedOptions(value){
        if(this.privateName == 'city'){
            console.log(JSON.stringify(value));
            //console.log(JSON.stringify(this.options_));
        }
        this.optionList = this.options_.map(opt =>{
            if(Array.isArray(value) && value.includes(opt.value)){
                opt.isSelected = true;
                if(this.privateName == 'city'){
                    console.log(opt.value);
                }
            }
            return {...opt};
        });

        this.options_ = [...this.optionList];
        console.log('this.optionList', JSON.stringify(this.optionList));
        this.inputValue = '';
    }
}