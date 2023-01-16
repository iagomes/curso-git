@isTest
public class GeneratePDFServiceTest {

    @IsTest
    static void loadClassTest(){
        
      
        GeneratePDFService.FlowInputs flInp = new GeneratePDFService.FlowInputs();

        Account account = TestUtility.createAccPJ();
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoContaOrdem').getRecordTypeId(),
            PrazoValidade__c = 10,
            Filtro_PDF__c = 'Ordem alfabética'
        );
        insert opportunity;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        insert product;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        insert pricebookEntry;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100
        );
        insert opportunityLineItem;


        flInp.opportunityId = opportunity.Id;
        flInp.pdfChoice = 'GeneratePDFOrcamento';
        flInp.productCode = product.ProductCode;
        flInp.landscape = false;

        TemplatePDF__c template = new TemplatePDF__c(Name = 'GeneratePDFOrcamento', Id = null);
        insert template;

        GeneratePDFService.loadClass(new List<GeneratePDFService.FlowInputs>{flInp});


        TemplatePDF__c template2 = new TemplatePDF__c(Name = 'GeneratePDFOrcamento', Id = null, PDFTemplateClass__c='GeneratePDFOrcamento');
        insert template2;

        flInp.landscape = true;

        GeneratePDFService.loadClass(new List<GeneratePDFService.FlowInputs>{flInp});


        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        PageReference pageRef = Page.PDFOrcamento;
        pageRef.getParameters().put('id', opportunity.Id);
        pageRef.getParameters().put('prdCode', flInp.productCode);
        pageRef.getParameters().put('landScape', 'false'); 

        Test.setCurrentPage(pageRef);
        // GeneratePDFOrcamento generatePDFOrcamento = new GeneratePDFOrcamento(sc);
        
       
        
    }
    
    
}
