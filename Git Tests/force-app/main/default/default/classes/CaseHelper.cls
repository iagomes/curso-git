/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 18-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
public without sharing class CaseHelper {
    
    public static void markReopenedField(Case c, Case oldCase){
        if(oldCase != null && c.Status != oldCase.Status && (oldCase.Status == 'Finalizado' || oldCase.Status == 'Encerrado')) {
            if(c.Status == 'Em Andamento' || c.Status == 'Em Espera' || c.Status == 'Atrasado'){
                c.CasoReaberto__c = true;
                c.ReopenedDatetime__c = Datetime.now();
            }
        }
    }

    public static void fillFinishedDates(Case c, Case oldCase) {
        if(oldCase != null && c.Status != oldCase.Status && (c.Status == 'Finalizado' || c.Status == 'Encerrado')){
            if(c.CasoReaberto__c){
                c.ReopeningFinishedDate__c = Datetime.now();
            } else {
                c.FinishedDate__c = Datetime.now();
            }
        }
    }
    
    public static void checkInvoiceNumbers(Map<Id, Set<Case>> casesByInvoice) {
        
        Set<Case> cases = new Set<Case>();
        for (Id invoiceId : casesByInvoice.keySet()) {
            cases.addAll(casesByInvoice.get(invoiceId));
        }

        for (Case ca : [SELECT Id, CaseNumber, NotaFiscal__c FROM Case 
                        WHERE NotaFiscal__c =: casesByInvoice.keySet()
                        AND Id !=: cases
                        AND Status NOT IN ('Closed')])
        {
            for (Case currentCase : casesByInvoice.get(ca.NotaFiscal__c)) 
            {
               String label = Label.CannotSaveNewCaseWhenOngoingCaseWithSameInvoiceNumber.replace('__CASENUMBER__', ca.CaseNumber);
               currentCase.addError(label); 
            }
        }        
    }

    public static void calculateCaseElapsedTime(Case record) {

        BusinessDays businessDays = BusinessDays.getInstance();
        Datetime endDate = businessDays.getDateConsideringOnlyBusinessDays(record.CreatedDate, System.now());
        Long milliseconds = endDate.getTime() - record.CreatedDate.getTime();

        record.Elapsed_time_in_miliseconds__c = milliseconds;
   
    }    
    
}