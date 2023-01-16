import { LightningElement, wire, track, api } from 'lwc';
import userId from '@salesforce/user/Id';
import getBudgetList from '@salesforce/apex/BudgetSummaryController.getBudgetList';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class BudgetSummary extends LightningElement {
    // APIs
    @api accountName = '';

    // TRACKs
    @track isModelOpen = true;
    @track allBudgets = false;
    @track budgetList = [];
    @track desktop = false;

    connectedCallback() {
        this.desktop = FORM_FACTOR == 'Large';
        this.scrollToTop();
    }

    @track budgetStatusOptions = [
        { label: 'À vencer/Em aberto', value: 'open' },
        { label: 'Vencidos/Perdidos', value: 'closed' },
    ];
    @track budgetStatusValue = 'open';

    @track isLoading = false;

    // WIREs
    @wire(getBudgetList, {
        userId, 
        accountId: '$accountName',
        budgetStatus: '$budgetStatusValue',
        allBudgets: '$allBudgets'
    })
    wiredOpportunities(result) {
        const {data, error} = result;

        if (data) {
            console.log('data', data);
            this.budgetList = data;
            this.isLoading = false;
        }

        if (error) {
            console.log('error', error);
            this.budgetList = null;
            this.isLoading = false;
        }
    }

    get budgetListIsEmpty() {
        return this.budgetList === null || !this.budgetList.length > 0;
    }

    handleChangeBudgetStatus(event) {
        const selectedOption = event.detail.value;
        this.budgetStatusValue = selectedOption;
        this.isLoading = true;
    }

    currentClient() {
        this.budgetStatusValue = 'open';
        this.allBudgets = false;
        this.isLoading = true;
    }

    otherBudgets() {
        this.budgetStatusValue = 'open';
        this.allBudgets = true;
        this.isLoading = true;
    }

    openModal() {
        this.isModelOpen = true;
        this.scrollToTop();
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

    closeModal() {
        this.isModelOpen = false;
    }
}
