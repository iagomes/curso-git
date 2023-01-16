import { LightningElement, api, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class InstallmentDates extends LightningElement {
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @api isModalOpen = false;
    @api totalValue;
    @api receivedDtList = [];
    @api dtQuantityAllowed;
    @api disabled = false;
    @track listInstallmentDates = [];
    @track numberDays = 0;
    @track hasInputError = false;
    @track isAddBlock = false;
	@track desktop;

    connectedCallback() {
		this.desktop = FORM_FACTOR == 'Large';
        var today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate(), 0);

        if (this.receivedDtList.length > 0) {
            this.receivedDtList.forEach((item, index)=> {
                let currentDate = new Date(new Date(item).getFullYear(), new Date(item).getMonth(), new Date(item).getDate() + 1, 0);
                let daysBetween = this.getDaysBetween(today, currentDate);
                let stringDays = daysBetween > 1 ? daysBetween + ' dias' : daysBetween + ' dia';
                console.log('daysBetween');
                console.log(daysBetween);
                var dateObj = {
                    key: new Date().getTime() + index,
                    date: today,
                    formattedDate: item,
                    daysBetween: daysBetween == 0 ? "Hoje" : daysBetween > 0 ? stringDays : "",
                    errorMessage: currentDate < today ? 'Data não pode ser menor que hoje.' : null
                }
                console.log(dateObj);
                this.listInstallmentDates.push(dateObj);
            });
        }
        
        if (this.listInstallmentDates.length == this.dtQuantityAllowed) {
            this.isAddBlock = true;
        }
        
        this.checkDuplicateDates();
    }
    
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
        this.scrollToTop();
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

    submitDetails() {
        if (this.listInstallmentDates.length == 0) {
            console.log('Nenhuma data inserida');
        }

        if (!this.checkDuplicateDates()) {
            this.receivedDtList = [];
            this.listInstallmentDates.forEach(item => {
                this.receivedDtList.push(item.formattedDate);
            });
            this.isModalOpen = false;
            console.log('ta certo');
            console.log(JSON.parse(JSON.stringify(this.receivedDtList)));

            this.dispatchEvent(
                new CustomEvent('selectdates', {
                    detail: {
                        record: JSON.stringify(this.receivedDtList)
                    }
                })
            );
        } else {
            console.log('ta errado');
        }
    }

    checkDuplicateDates() {
        let hasError = false;
        let newSelectedDate = [];
        const listDt = this.listInstallmentDates.map(item => item.formattedDate);
        this.listInstallmentDates.forEach(item => {
            let obj = {
                key: item.key, 
                date: item.date,
                formattedDate: item.formattedDate,
                daysBetween: item.daysBetween,
                errorMessage: item.errorMessage 
            };
            const size = listDt.filter(fmtDate => fmtDate === item.formattedDate).length;
            if (size > 1) {
                obj.errorMessage = 'Data duplicada!';
                hasError = true;
            } else if (obj.errorMessage != 'Data não pode ser menor que hoje.'){
                obj.errorMessage = null;
            } else {
                hasError = true;
            }

            if (obj.errorMessage) {
                hasError = true;
            }

            newSelectedDate = [...newSelectedDate, obj];
        })

        this.listInstallmentDates = newSelectedDate;

        return hasError;
    }

    handleNumberDays(event) {
        this.numberDays = Number(event.target.value);
    }

    handleAddDate() {
        console.log(this.numberDays);

        if (this.numberDays < 0) {
            this.hasInputError = true;
            return;
        }

        this.hasInputError = false; 

        var today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate(), 0);
        var selectedDate = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate(), 0);
        console.log(selectedDate);
        console.log(selectedDate.setDate(selectedDate.getDate() + this.numberDays));
        let daysBetween = this.getDaysBetween(today, selectedDate);
        let stringDays = daysBetween > 1 ? daysBetween + ' dias' : daysBetween + ' dia';

        var day   = selectedDate.getDate() > 9 ? selectedDate.getDate() : '0' + selectedDate.getDate();
        var month = selectedDate.getMonth() + 1 > 9 ? selectedDate.getMonth() + 1 : '0' + (selectedDate.getMonth() + 1);
        var year  = selectedDate.getFullYear();

        var formattedDate = year + '-' + month + '-' + day;

        var dateObj = {
            key: new Date().getTime(),
            date: selectedDate,
            formattedDate: formattedDate,
            daysBetween: daysBetween == 0 ? "Hoje" : daysBetween > 0 ? stringDays : "",
            errorMessage: null,
            isValid: true
        }
        
        this.listInstallmentDates.push(dateObj);

        console.log(this.listInstallmentDates.length);
        if (this.listInstallmentDates.length == this.dtQuantityAllowed) {
            this.isAddBlock = true;
        } 
        
        this.checkDuplicateDates();
    }

    handleRemoveDate(event) {
        let key = event.currentTarget.dataset.id;
        console.log(key);
        this.listInstallmentDates = this.listInstallmentDates.filter(item => item.key != key);
        this.isAddBlock = false;
        this.checkDuplicateDates();
    }

    handleChangeDate(event) {
        let key = event.currentTarget.dataset.id;
        let selectedDate = new Date(event.detail.value + 'T00:00:00');
        
        let index = this.listInstallmentDates.findIndex(item => item.key == key);

        let today = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate(), 0);
        let daysBetween = this.getDaysBetween(today, selectedDate);
        console.log(today);
        console.log(selectedDate);
        console.log(new Date());
        this.listInstallmentDates[index].formattedDate = event.detail.value;
        this.listInstallmentDates[index].daysBetween = daysBetween == 0 ? "Hoje" : daysBetween > 0 ? (daysBetween > 1 ? daysBetween + ' dias' : daysBetween + ' dia') : "";
        console.log('this.listInstallmentDates[index].daysBetween');
        console.log(this.listInstallmentDates[index].daysBetween);
        this.listInstallmentDates[index].date = selectedDate;

        if (selectedDate < today) {
            console.log('FALSE');
            this.listInstallmentDates[index].errorMessage = 'Data não pode ser menor que hoje.'
        } else {
            console.log('TRUE');
            this.listInstallmentDates[index].errorMessage = null;
        }

        this.checkDuplicateDates();
    }

    getDaysBetween(today, currentDate) {
        var daysBetween = Math.floor((currentDate.getTime() - today.getTime()) / (1000*60*60*24));
        console.log(daysBetween);
        return daysBetween;
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
}