@IsTest
public with sharing class OpportunityCreatePDFTest { 
    @TestSetup
    static void makeData(){
        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaLaboratoryOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reprocessamento-Pedido',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;
       
    }
    @IsTest
    public static void flowCreatePDFTest() {
        TemplatePDF__c template = new TemplatePDF__c(Name = 'ElfaQuoteTemplate', Id	= null);
        insert template;
        Product2 product        = TestUtility.createProduct();
        insert product;
        User user               = TestUtility.createUser();
        insert user;
        Opportunity opportunity = TestUtility.createOpportunity(user);
        insert opportunity;
        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        pricebookEntry.IsActive       = true;
        update pricebookEntry;
        OpportunityLineItem opportunityLineItem = TestUtility.createOpportunityLineItem(opportunity, product, pricebookEntry);
        insert opportunityLineItem;
        opportunityLineItem.ValorUn__c = 10.00;
        update opportunityLineItem;

        OpportunityCreatePDF.FlowInputs flowInput = new OpportunityCreatePDF.FlowInputs();
        flowInput.opportunityId = opportunity.id;
        flowInput.pdfChoice = 'ElfaQuoteTemplate';
        flowInput.productCode = '000001,000002';

        OpportunityCreatePDF.flowCreatePDF(new List<OpportunityCreatePDF.FlowInputs>{flowInput});
    }
}
