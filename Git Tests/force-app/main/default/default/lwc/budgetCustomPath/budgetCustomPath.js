import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import OPPORTUNITYSTAGE from '@salesforce/schema/Opportunity.StageName';

export default class BudgetCustomPath extends LightningElement {
    @api recordId;
    oppStageName;
    isRendered = false;
    renderedCallback(){
        if(!this.isRendered){
            this.enforceStyles();
            this.isRendered = true;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [OPPORTUNITYSTAGE]
    })wirestage({error,data}) {
        if (error) {
           console.log('StageName ERROR: ',error); 
           
        } else if (data) {
            this.oppStageName = data.fields.StageName.value;
            let stgChosen = this.allStageOptions.find((stg =>{return stg.value === this.oppStageName}));
            this.allStageOptions = this.allStageOptions.map(stg =>{
                stg.visible = stg.class != 'inv slds-is-lost';
                return stg;
            });
            stgChosen.visible = true; 
        }
    }

    get stageOptions(){
        return this.allStageOptions.filter(stg =>{return stg.visible});
    }

    allStageOptions = [
        {label:'Novo', value:'Novo', class:'middle', visible:true,},
        {label:'Em digitação', value:'Em digitação', class:'middle', visible:true,},
        {label:'Aguardando Integração', value:'Aguardando Integração', class:'middle', visible:true,},
        {label:'Falha na integração', value:'Falha na integração', class:'inv slds-is-lost', visible:false,},
        {label:'Respondida', value:'Respondida', class:'middle', visible:true,},
        {label:'Sem Retorno', value:'Sem Retorno', class:'inv slds-is-lost', visible:false,},
        {label:'Gerar Pedido', value:'Gerar Pedido', class:'won', visible:true,},
        {label:'Não Respondida', value:'Não Respondida', class:'inv slds-is-lost', visible:false,},
        {label:'Não Ganha', value:'Não Ganha', class:'inv slds-is-lost', visible:false,},
        {label:'Cancelada', value:'Cancelada', class:'inv slds-is-lost', visible:false,},
    ];

    enforceStyles(){
        let scope = this;
        let style = document.createElement('style');
        style.innerText = `
            
            c-budget-custom-path lightning-progress-indicator lightning-progress-step.inv span.slds-path__title{
                color: white;
                font-weight: 400;
            }
        `
        let stylecontent = scope.template.querySelector('.style-budget-custom-path');
        if(stylecontent) stylecontent.appendChild(style);
    }
}