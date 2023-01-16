/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 18-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
public without sharing class CaseTH extends TriggerHandler {


    public CaseTH(System.TriggerOperation operation, List<Case> newRecordList, List<Case> oldRecordList, Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        super(operation, newRecordList, oldRecordList, newMap, oldMap);
    }

      // @TRIGGER METHODS
    private static Boolean runTrigger;

    static {
        runTrigger = true;
    }

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static Boolean enableTrigger(){
        return runTrigger = true;
    }

    public static Boolean disableTrigger(){
        return runTrigger = false;
    }
    // @END TRIGGER METHODS

    // @TRIGGER HANDLERS

    /*
    * Purpose: BEFORE_INSERT handler method
    */
    public override void beforeInsert() {
        
        Map<Id, Set<Case>> casesByInvoice = new Map<Id, Set<Case>>();     
        
        for (Case c: (Case[])newRecordList) {
           
            if (c.NotaFiscal__c != null) {
                Set<Case> cases = casesByInvoice.get(c.Id);
                if (cases == null) {
                    cases = new Set<Case>();
                    casesByInvoice.put(c.NotaFiscal__c, cases);
                }
                cases.add(c);
            }
        }

        // run bulk functions
        CaseHelper.checkInvoiceNumbers(casesByInvoice);
                
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        
        Map<Id, Set<Case>> casesByInvoice = new Map<Id, Set<Case>>();     
        
        for (Case c: (Case[])newRecordList) {
            Case oldCase;
            if (this.oldMap != null) {
                oldCase = (Case) this.oldMap.get(c.Id);
            }
            
            if (c.NotaFiscal__c !=null) {
                Set<Case> cases = casesByInvoice.get(c.Id);
                if (cases == null) {
                    cases = new Set<Case>();
                    casesByInvoice.put(c.NotaFiscal__c, cases);
                }
                cases.add(c);
            }

            if (c.Status != oldCase.Status && c.Status == 'Closed') {
                CaseHelper.calculateCaseElapsedTime(c);
            }

            // run single record functions
            CaseHelper.markReopenedField(c, oldCase);
            CaseHelper.fillFinishedDates(c, oldCase);
        }

        // run bulk functions
        CaseHelper.checkInvoiceNumbers(casesByInvoice);
        
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS

}