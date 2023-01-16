public class GeneratePDFService{

 
    @InvocableMethod(label='loadClass Pdf' description='load class to generate PDF' callout=true)
    public static void loadClass(List<FlowInputs> flowInputsList) {

        String oppId = '';
        String pdfChoice = '';
        String prodCode = '';
        Boolean landscape = false;
        for (FlowInputs flow : flowInputsList) {
            oppId = flow.opportunityId;
            pdfChoice = flow.pdfChoice;
            prodCode = flow.productCode;
            landscape = flow.landscape;
        }

        TemplatePDF__c template = TemplatePDF__c.getValues(pdfChoice);
        System.debug(flowInputsList);
      
        if (template.PDFTemplateClass__c == 'GeneratePDFOrcamento') {

            GeneratePDFOrcamento.execute(oppId, prodCode, landscape );
        }
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String opportunityId;
        
        @InvocableVariable
        public String pdfChoice;
        
        @InvocableVariable
        public String productCode;
        
        @InvocableVariable
        public Boolean landscape;
    }

    
}