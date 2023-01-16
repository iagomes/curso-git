@IsTest
public with sharing class FileSelfServiceControllerTest {

    @testSetup
    public static void setup() {
        Account acc = TestUtility.createAccPJ();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Order ord = TestUtility.createOrder(acc);
        insert ord;        
        
        NotasFiscais__c nf = TestUtility.createNotaFiscal(ord, acc);
        nf.Conta__c = acc.Id;
        insert nf;     
        
        Case c = TestUtility.createCase(acc, ctt);
        c.NotaFiscal__c = nf.Id;  
        insert c;             
    }    
    
    @IsTest
    static void getFileSuccess() { 
        
        Test.startTest();

        PageReference myVfPage = Page.FileSelfService;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('customerId', '02643718000121');
        ApexPages.currentPage().getParameters().put('orderNumber', '0001');
        ApexPages.currentPage().getParameters().put('documentType','paymentSlip');
        ApexPages.currentPage().getParameters().put('caseId', [SELECT Id FROM Case].Id);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{"TituloAberto" : [{"PEDIDO":"0001","NUM":"0002", "CGC_CD":"", "PREFIXO":"", "TIPO":"", "PARCELA":""}], "boleto":"document"}', null));
        FileSelfServiceController controller = new FileSelfServiceController();
        try {
            controller.download();
        } catch(Exception ex) {
        }
        Test.stopTest();
    } 

    @IsTest
    static void getFileError() { 
        
        Test.startTest();

        PageReference myVfPage = Page.FileSelfService;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('customerId', '02643718000121');
        ApexPages.currentPage().getParameters().put('orderNumber', '0001');
        ApexPages.currentPage().getParameters().put('documentType','paymentSlip');
        ApexPages.currentPage().getParameters().put('caseId', [SELECT Id FROM Case].Id);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'NOK', '', null));
        FileSelfServiceController controller = new FileSelfServiceController();
        try {
            controller.download();
        } catch(Exception ex) {
        }
        Test.stopTest();
    } 

}