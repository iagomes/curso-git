public without sharing class ConditionPaymentBudgetController {
    @AuraEnabled
    public static StandardResponse getConditionPayment(String oppId){
        StandardResponse response = new StandardResponse();
        List<String> cnpjList = new List<String>();
        List<BudgetCtrl.DistCenterDTO> responsedata = new List<BudgetCtrl.DistCenterDTO>();
        try {
            List<CondicaoPagamentoPorCD__c> condPayCDlist = BudgetDetailSelector.getCondicaoPagamentoPorCD(oppId);
            for(CondicaoPagamentoPorCD__c conpg : condPayCDlist){
                cnpjList.add(conpg.CNPJCD__c);
            }
            Map<String,BudgetCtrl.SomatoriaDTO> sumaryMap = getSumaryResponse(oppId, cnpjList);
            for(CondicaoPagamentoPorCD__c cd : condPayCDlist){
                if(sumaryMap.containsKey(cd.CNPJCD__c)){
                    BudgetCtrl.DistCenterDTO distCenter = new BudgetCtrl.DistCenterDTO(sumaryMap.get(cd.CNPJCD__c), cd);
                    responsedata.add(distCenter);
                }
            }
            response.setData(JSON.serialize(responsedata));
           
        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        
        return response;
    }

    public static Map<String,BudgetCtrl.SomatoriaDTO> getSumaryResponse(String oppId, List<String> CNPJList){
        Map<String,BudgetCtrl.SomatoriaDTO> response = new Map<String,BudgetCtrl.SomatoriaDTO>();
        Decimal AmountOK = 0;
        //response.resp = 0;
        //response.totItem = 0;
        
        for(List<QuoteItem__c> listOli: [
            SELECT OpportunityLineItem__r.QuantidadePortal__c, OpportunityLineItem__r.ValorPortal__c,
            OpportunityLineItem__r.CNPJCD__c, OpportunityId__r.QuantidadeItensTotal__c  
            FROM QuoteItem__c 
            WHERE Product__c != null 
            AND OpportunityLineItem__c != null
            AND OpportunityId__c =: oppId ORDER BY Product__c
        ]){
            
            for(QuoteItem__c oli: listOli){
                if(response.get(oli.OpportunityLineItem__r.CNPJCD__c) == null){
                    response.put(oli.OpportunityLineItem__r.CNPJCD__c, new BudgetCtrl.SomatoriaDTO());

                    response.get(oli.OpportunityLineItem__r.CNPJCD__c).resp = 0;
                    response.get(oli.OpportunityLineItem__r.CNPJCD__c).totItem = 0;
                    response.get(oli.OpportunityLineItem__r.CNPJCD__c).qtdItensTotal = 0;
                }
                
                Decimal qntPortal = oli.OpportunityLineItem__r.QuantidadePortal__c != null ? oli.OpportunityLineItem__r.QuantidadePortal__c : 0;
                Decimal valuePortal = oli.OpportunityLineItem__r.ValorPortal__c != null ? oli.OpportunityLineItem__r.ValorPortal__c : 0;
                Decimal totItem = qntPortal * valuePortal; 
                AmountOK += totItem;

                if(!CNPJList.isEmpty() && CNPJList.contains(oli.OpportunityLineItem__r?.CNPJCD__c)){
                    response.get(oli.OpportunityLineItem__r.CNPJCD__c).totItem += totItem;
                    response.get(oli.OpportunityLineItem__r.CNPJCD__c).qtdItensTotal = oli.OpportunityId__r.QuantidadeItensTotal__c;
                    response.get(oli.OpportunityLineItem__r.CNPJCD__c).resp++;
                }
            }
        }
        
        if(AmountOK != 0){
            try {
                Opportunity opp = new Opportunity();
                opp.Id = oppId;
                opp.TotalPortal__c = AmountOK.setScale(6, RoundingMode.HALF_UP);
                update opp;
            } catch (Exception ex) {}
        }
        for(BudgetCtrl.SomatoriaDTO resp : response.values()){
            resp.totItem = resp.totItem.setScale(6, RoundingMode.HALF_UP);
        }

        return response;
    }

}
