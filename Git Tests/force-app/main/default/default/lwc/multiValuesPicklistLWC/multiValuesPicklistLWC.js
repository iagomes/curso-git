import { LightningElement, api, track } from 'lwc';
import { doCalloutWithStdResponse } from 'c/calloutService';
import { MultiOption } from 'c/utilities';
import getPickListValuesList from '@salesforce/apex/UtilitiesController.getPickListValuesList';
import getLookupRecords from '@salesforce/apex/UtilitiesController.getLookupRecords';

export default class MultiValuesPicklistLWC extends LightningElement {

    @track options_ = [];
    @track showSpinner = false;
    @track isSearching = false;
    @track lookupSearchText = '';
    @track textLastChangeDate;
    // @track tableData;
    @api infoText = ' -- Nenhum -- ';
    @api buttonEditIconName = 'utility:down';

    @api skipAutoHideDropdown = false;
    @api dropdownOver = false;
    @api buttonOver = false;
    @api showTable = false;
    @api countSelected;
    @api label;
    @api type = 'button';
    @api getLookupRecords;
    @api hideLimpar = false;
    @api hideEmptyValue = false;
    @api hideOptions;
    @api lookupSelectFields = 'Id;Name';
    @api complexSearchField = '';
    @api tableColumns;
    @api maxRowSelection = 99999;
    @api noneUnselected = false;
    @api boldTitle = false;
    
    @track selectedOptions_;
    @api selectedOptions(value){
        this.setSelectedOptions(value);
    };

    @api getOptions(){
        return this.options_;
    }

    @api setSelectedOptions(value) {
        // console.log('setSelectedOptions...', JSON.stringify(value ? value.map(item => item.selected + ' ' + item.label) : null));
        // console.log('selectedOptions >> ', value, JSON.stringify(this.options_));
        if(this.options_ && this.options_.length > 0){
            // console.log('setSelectedOptions >> a');
            this.selectedOptions_ = value;
            this.options_.forEach(opt => {
                // console.log('setSelectedOptions >> b', opt, opt.label);
                opt.selected = false;
            });
            if(value && this.options_){
                // console.log('setSelectedOptions >> c');
                value.forEach(item => {
                    // console.log('setSelectedOptions >> d', item, item.label);
                    for(let i = 0; i<this.options_.length; i++){
                        // console.log('setSelectedOptions >> e', this.options_[i], this.options_[i].label);
                        if(this.options_[i].value == item.value){
                            this.options_[i].selected = true;
                            // console.log('setSelectedOptions >> f', this.options_[i], this.options_[i].label, this.options_[i].selected);
                            break;
                        }
                    }
                });
            }
            // console.log('selectedOptions >> this.options_:::', JSON.stringify(this.options_));
            this.options = [...this.options_];
        }
    }

    get tableData(){
        return this.showTable && this.options_ && this.options_.length > 0 && this.options_.map(opt => opt.data).filter(opt => {return opt.id != null});
    }

    get selectedOptions(){
        return this.selectedOptions_;
    }

    get isButton() {
        return this.type == 'button';
    }

    get isLookup() {
        return this.type == 'lookup';
    }

    @track privateName;

    @api get name() {
        return this.privateName;
    }

    @api skipLoadOptionsByFieldName = false;
    @track fieldApiName_;
    @api get fieldApiName() {
        return this.fieldApiName_;
    }

    set fieldApiName(value) {
        this.fieldApiName_ = value;
        //console.log(value, 'set fieldApiName this.options:::', JSON.stringify(this.options));
        if(value && (!this.options || this.options.length == 0) && !this.skipLoadOptionsByFieldName){
            //console.log('getPickListValuesList:::', this.fieldApiName_);
            getPickListValuesList({fieldAndObjectApiName: this.fieldApiName_}).then((response) => {
                this.options = response.map(opt => {
                    return new MultiOption(false, opt.value, opt.label);
                });
            });
        }
    }

    @track lookupObject_;
    @api get lookupObject() {
        return this.lookupObject_;
    }

    set lookupObject(value) {
        this.lookupObject_ = value;
    }

    @track lookupFields_;
    @api get lookupFields() {
        return this.lookupFields_;
    }

    set lookupFields(value) {
        this.lookupFields_ = value;
        if(value && this.lookupObject){
            this.type = 'lookup';
            this.getLookupRecords = (searchText) => {
                return new Promise((resolve, reject) => {
                    let params = {
                        searchText: searchText.replace(/\s/g, '%'), 
                        objectName: this.lookupObject, 
                        fieldNames: this.lookupFields.replace(/,/g, ";").split(';'), 
                        lookupSelectFields: this.lookupSelectFields.replace(/,/g, ";").split(';'),
                        complexSearchField: this.complexSearchField
                    };
                    // console.log('params:::', params, JSON.stringify(params));
                    getLookupRecords(params).then((response) => {
                        resolve(response);
                    }).catch(error => reject(error));
                });
            };
        }
    }

    get testOptions(){
        return JSON.stringify(this.options);
    }

    @api get options() {
        return this.options_;
    }

    set options(value) {
        //console.log('value:::', value, this.hideOptions);
        if(this.hideOptions && value){
            value = value.filter(opt => {
                return this.hideOptions.indexOf(opt.label) < 0;
            });
        }
        this.selectedOptions_ = [];
        if (!!value && value.length > 0) {
            if (!this.hideEmptyValue && (!value[0] || value[0].label != ' -- Nenhum -- ')) {
                value = [new MultiOption(!this.noneUnselected, '', ' -- Nenhum -- '), ...value];
            }
            if (this.maxRowSelection > 1 && value[value.length - 1] !== undefined && value[value.length - 1].label != ' -- Selecionar Todos -- ') {
                value = [...value, new MultiOption(false, 'Todos', ' -- Selecionar Todos -- ')];
            }
            this.selectedOptions_ = value.filter(opt => {return opt.selected;});
            let selected = this.selectedOptions_.map(opt => opt.label);
            this.infoText = selected.join(', ') + (this.selectedOptions_.length > 3 ? ', ...' : '');
            if(!this.infoText){
                this.infoText = ' -- Nenhum -- ';
            }
        }
        this.options_ = value;
    }

    set name(value) {
        this.privateName = value;
        this.setAttribute('name', this.privateName);
        this.setAttribute('class', this.privateName);
    }

    @api
    handleClickLimpar(skipResponseEvent) {
        let skipResponse = typeof skipResponseEvent === 'boolean' ? skipResponseEvent : false
        this.infoText = ' -- Nenhum -- ';
        this.lookupSearchText = '';
        // this.template.querySelector('#lookupSearchText').value = this.lookupSearchText;
        this.countSelected = 0;
        this.selectedOptions_ = [];
        this.options_ = this.options_.map(option => {
            option.selected = false;
            return option;
        });;
        this.hideDropDown();
        if(!skipResponse){
            this.fireResponseEvent();
        }
    }

    handleSelection(event) {
        //console.log('event:::', event, JSON.stringify(event.currentTarget.dataset));
        let item = event.currentTarget;
        if(this.hideEmptyValue && this.selectedOptions_.length == 1 && item.dataset.selected == "true"){
            console.log('a.0.1');
            return;
        } 
        else if(this.options_ && this.options_.length == 1){
            console.log('a.0.2');
            this.options_[0].selected = true;
            this.selectedOptions_ = [this.options_[0]];
            this.infoText = this.options_[0].label;
            // Dispatches the event.
            this.removeClassFromComponent(true);
            this.fireResponseEvent();

        } 
        else if (item && item.dataset) {
            console.log('a.0.3');
            this.infoText = '';
            this.countSelected = 0;

            let lastOption = this.options_ && this.options_.length > 0 ? this.options_[this.options_.length - 1] : null;
            console.log('a');
            let selectAll = item.dataset.selected && lastOption && item.dataset.value == 'Todos' && this.options_[this.options_.length - 1].label == ' -- Selecionar Todos -- ';
            console.log('b', JSON.stringify(this.options_));
            if (selectAll) {
                console.log('D');
                this.infoText = 'Todos';
                this.options_[this.options_.length - 1].selected = false;
            }

            console.log('e');

            this.options_.forEach((option, index) => {

                if (selectAll) {
                    option.selected = true;
                }
                
                if (option.value == item.dataset.value) {
                    option.selected = selectAll || (!option.selected);
                    item.dataset.selected = option.selected;
                }
                if (option.selected && !selectAll) {
                    this.infoText += (this.infoText != '' ? ', ' : '') + option.label;
                    this.countSelected++;
                }

            });
            console.log('k', selectAll);

            if (selectAll) {
                this.hideDropDown();
            } else if(this.isButton){
                if (this.infoText === '') {
                    this.infoText = ' -- Nenhum -- ';
                } else if (this.countSelected == this.options.length) {
                    this.infoText = 'Todos';
                }
            }

            this.options_ = [...this.options_];
            this.selectedOptions_ = this.options_.filter(opt => opt.selected == true);

            if(this.selectedOptions_.length > 1 && this.selectedOptions_[0].label == ' -- Nenhum -- '){
                this.selectedOptions_[0].pop();
                this.options_[0].selected = false;
            }

            while(this.selectedOptions_ && this.selectedOptions_.length > this.maxRowSelection){
                for(let i = 0; i < this.options_.length; i++){
                    let opt = this.options_[i];
                    console.log(JSON.stringify(opt), item.dataset.label);
                    if(opt.selected && opt.label != item.dataset.label){
                        opt.selected = false;
                        this.selectedOptions_ = this.selectedOptions_.filter(selected => {return opt.label != selected.label});
                        this.infoText = this.selectedOptions_.map(opt => opt.label).join(',');
                        this.removeClassFromComponent(true);
                        break;
                    }
                };
            }
            this.options_ = [...this.options_];

            // Dispatches the event.
            this.fireResponseEvent();
        }
        console.log('this.selectedOptions_:::', this.selectedOptions_);
        console.log('this.maxRowSelection:::', this.maxRowSelection);
        if(this.selectedOptions_ && this.selectedOptions_.length == this.maxRowSelection){
            this.hideDropDown();
        }
    }
    // handleLookupTextChange(event){

    // }

    searchTimer;
    handleLookupTextChange(event) {
        let scope = this;
        scope.lookupSearchText = event.target.value;
        clearTimeout(scope.searchTimer);
        scope.searchTimer = setTimeout(() => {
            scope.callGetLookupRecordsMethod();
        }, 250);
    }

    @api callGetLookupRecordsMethod() {
        if (this.lookupSearchText && this.lookupSearchText.length > 2 && ((!Number(this.lookupSearchText) && Number(this.lookupSearchText) !== 0) || Number(this.lookupSearchText).toString().length > 1)) {
            this.handleElementMouseEnter();
            this.getLookupRecords(this.lookupSearchText)
                .then((response) => {
                    if(typeof response === 'string'){
                        response = JSON.parse(response);
                    }
                    if (!response.hasError) {
                        let options = [];
                        if(!this.hideEmptyValue){
                            options = [new MultiOption(this.options && this.options[0] ? this.options[0].selected : false , '', ' -- Nenhum -- ')];
                        }
                        if (response.data && response.data.records) {
                            response.data.records.forEach((record, index) => {
                                options.push(new MultiOption(false, record, null));
                            });
                            if (this.maxRowSelection > 1 && options && options[options.length - 1] && options[options.length - 1].label != ' -- Selecionar Todos -- ') {
                                options.push(new MultiOption(false, 'Todos', ' -- Selecionar Todos -- '));
                            }
                        }
                        //console.log('options:::', options, JSON.stringify(options));
                        this.options_ = [...options];
                    }

                })
                .finally(() => {
                    this.addClassToComponent();
                });
        }
    }

    addClassToComponent() {
        let component = this.template.querySelector('.main-div');
        if (component) {
            if (this.options_ && this.options_.length > 0) {
                component.classList.add('slds-is-open');
                window.setTimeout(() => {
                    this.removeClassFromComponent();
                }, 500);
            } else {
                component.classList.remove('slds-is-open');
            }
            window.setTimeout(() => {
                this.removeClassFromComponent();
            }, 850);
        }
    }

    removeClassFromComponent(forceClose) {
        let component = this.template.querySelector('.main-div');
        if (component && (forceClose || (!this.dropdownOver) && (!this.buttonOver))) {
            component.classList.remove('slds-is-open');
        }
    }

    handleClick(e) {
        // console.log('handleClick:::', e);
        this.addClassToComponent();
    }

    handleTableClick(event){
        // console.log('handleTableClick...');
        clearTimeout(this.tableFireSelectedEventResponseTimer);
        this.tableFireSelectedEventResponseTimer = window.setTimeout(() => {
            this.tableFireSelectedEventResponse();
        }, 200);
    }

    tableFireSelectedEventResponseTimer;
    tableFireSelectedEventResponse(){
        
        let selectedRows = this.getSelectedRows();

        if(selectedRows){
            // console.log('tableFireSelectedEventResponse >> selected:::', selectedRows);
            if(selectedRows && selectedRows.length > 0){
                let selectedIds = selectedRows.map(row => row.Id);
                // console.log('this.selectedOptions_:::', this.selectedOptions_);
                // console.log('this.options_:::', this.options_);
                this.selectedOptions_ = [];
                this.options_.forEach(opt => {
                    opt.selected = selectedIds.indexOf(opt.data.Id) >= 0;
                    if(opt.selected){
                        this.selectedOptions_.push(opt);
                    }
                });
                this.fireResponseEvent();
                this.removeClassFromComponent();
            }
        }
    }

    @api getSelectedRows(){
        let selectedRows;
        let element = this.template.querySelector('lightning-datatable');
        // console.log('getSelectedRows >> element:::', element);
        if(element){
            selectedRows = element.getSelectedRows();
        }
        return selectedRows;
    }

    handleDropDownMouseEnter() {
        this.dropdownOver = true;
    }

    handleElementMouseEnter() {
        this.buttonOver = true;
        this.addClassToComponent();
    }

    handleElementMouseLeave() {
        this.buttonOver = false;
        setTimeout(() => {
            this.removeClassFromComponent();
        }, 150);
    }
    
    handleDropDownMouseLeave() {
        if(!this.skipAutoHideDropdown){
            this.dropdownOver = false;
            setTimeout(() => {
                this.removeClassFromComponent();
            }, 150);
        }
    }

    fireResponseEvent() {
        this.dispatchEvent(new CustomEvent("multivaluespicklistvaluechange", {
            detail: JSON.stringify({
                field: this.privateName,
                selectedOptions: this.selectedOptions
            })
        }));
    }

    hideDropDown() {
        this.buttonOver = false;
        this.dropdownOver = false;
        this.removeClassFromComponent();
    }

    resetTimeout(){
        clearTimeout(this.searchTimer);
    }

    renderedCallback() {
        let scope = this;
        if(!scope.isRendered){
            scope.isRendered = true;
            scope.enforceStyles();
        }
    }

    enforceStyles(){
        let additionalStyles = document.createElement('style');
        additionalStyles.innerText = `
            c-multi-values-picklist-l-w-c .dt-outer-container > .slds-scrollable_x {
                overflow: hidden !important;
                overflow-x: hidden !important;
            }
        `;
        this.template.querySelector('.style-element-container').appendChild(additionalStyles);
    }
}