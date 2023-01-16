public without sharing class FileSelfServiceController {

    private String customerId;
    private String invoiceNumber;
    private String orderNumber;
    private String caseId;
    public String url { get; private set; }
    public String documentType { get; private set; }

    public FileSelfServiceController() {
        this.customerId = ApexPages.currentPage().getParameters().get('customerId');
        this.invoiceNumber = ApexPages.currentPage().getParameters().get('invoiceNumber');
        this.documentType = ApexPages.currentPage().getParameters().get('documentType');
        this.orderNumber = ApexPages.currentPage().getParameters().get('orderNumber');
        this.caseId = ApexPages.currentPage().getParameters().get('caseId');
    }


    public void download () {

        this.url = ChatBot.fetchBase64File(new Map<String, String> {
            'customerId' => this.customerId,
            'invoiceNumber' => this.invoiceNumber,
            'documentType' => this.documentType,
            'orderNumber' => this.orderNumber
        });

        Case record = [SELECT Description, Status, BypassValidationRules__c FROM Case WHERE Id =: caseId];
        record.Status = 'Em andamento';
        record.Description += '\n\n' + Label.Customer_accessed_requested_document;

        if (this.url == null || this.url instanceof Id) {
 
            record.Description += '\n' + Label.Service_didnt_find_the_requested_document;
            
            if (String.isNotBlank(this.url)) {
                record.Description += Label.Click_here_to_access_log_details.replace('__LOGID__', this.url);
            }

            record.BypassValidationRules__c = !record.BypassValidationRules__c;
            update record;
            this.url = 'error';
        } else {
            record.Description += '\n' + Label.Service_found_the_requested_document;
            update record; 
            record.BypassValidationRules__c = !record.BypassValidationRules__c;
            record.Status = 'Closed';
            update record;
        }
            
    }

}