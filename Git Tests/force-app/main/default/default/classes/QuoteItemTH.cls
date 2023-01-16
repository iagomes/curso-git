/**
 * @description       : Trigger Handler using the AutomationController class
 * @author            : Raphael Holanda
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon Solutions
 * @last modified on  : 06-02-2022
 * @last modified by  : raphael.holanda.ext@iconit.com.br
 * Modifications Log 
 * Ver   Date         Author                                Modification
 * 1.0   06-02-2022   raphael.holanda.ext@iconit.com.br     Initial Version
**/
public class QuoteItemTH extends TriggerHandlerV2 {

    private static final String className = 'QuoteItemTH';
    private List<QuoteItem__c> lstNew;
    private List<QuoteItem__c> lstOld;
    private Map<Id, QuoteItem__c> mapOld;
    private Map<Id, QuoteItem__c> mapNew;

    public QuoteItemTH() {
        this.lstNew = (List<QuoteItem__c>) Trigger.new;
        this.lstOld = (List<QuoteItem__c>) Trigger.old;
        this.mapOld = (Map<Id, QuoteItem__c>) Trigger.oldMap;
        this.mapNew = (Map<Id, QuoteItem__c>) Trigger.newMap;
    }

    public override void fixNewDataBeforeInsertOrUpdate() {

        // fill needed data
        //Map<Id,OpportunityLineItem> mapOppLineItemsToUpdate = new Map<Id,OpportunityLineItem>();

        //process automations
        for(QuoteItem__c item: lstNew){
            item = setStatus(item, mapOld);

            // skip status reset
            if(AutomationsController.isRunning('QuoteItemTH.statusAndProductReset') && item.Id != null && SObjectUtils.hasChangedFields(item, mapOld, 'Product__c')){
                if(mapOld.get(item.Id).Status__c != null && mapOld.get(item.Id).Status__c != 'Não Vinculado'){
                    item.Status__c = mapOld.get(item.Id).Status__c;
                    item.Product__c = mapOld.get(item.Id).Product__c;
                    item.TabulacaoN1__c = mapOld.get(item.Id).TabulacaoN1__c;
                    System.debug('Exception::: Não é permitido alterar o produto de uma resposta em andamento.');
                }
            }
            
            if(item.UnitPrice__c != null && (this.mapOld == null || SObjectUtils.hasChangedFields(item, this.mapOld, 'UnitPrice__c'))){
                item.vendedorRespondeu__c = UserInfo.getUserId();
            }
            
            //não é recomendado dar update em outros objetos em contexto before.
            //mapOppLineItemsToUpdate = replicateValuesOnOpportunityLineItem(item, mapOld, mapOppLineItemsToUpdate);
        }

        // if(!mapOppLineItemsToUpdate.isEmpty()){
        //     update mapOppLineItemsToUpdate.values();
        // }

    }

    // public override void beforeUpdate(){
    //     updateDistributionCenterRelationship(mapOld, mapNew);
    // }

    // public override void beforeInsert(){
    //     updateDistributionCenterRelationship(lstNew);
    // }

    public override void afterUpdate(){
        updateOppTeamMemberAnsweredQuoteItems(mapOld, mapNew);
        replicateValuesOnOpportunityLineItem(mapOld, mapNew);
        sendProductLinksToPortal();
        updateOpportunityAndTeamMemberHasChangesUnsync(mapOld, mapNew);
        deleteCondicaoPagamentoCDSemVinculo(mapOld,mapNew);
    }

    public override void afterInsert(){
        updateOppTeamMemberAllQuoteItems(lstNew, false);
        updateOpportunityAndTeamMemberHasChangesUnsync(lstNew);
    }
    
    public override void afterDelete(){
        updateOppTeamMemberAllQuoteItems(lstOld, true);
        deleteCondicaoPagamentoCDSemVinculo(mapOld, mapNew);
    }

    public static void updateOpportunityAndTeamMemberHasChangesUnsync(Map<Id, QuoteItem__c> mapOld, Map<Id, QuoteItem__c> mapNew){
        Set<String> oppLineItemIdSet = new Set<String>();
        List<QuoteItem__c> changedItems = new List<QuoteItem__c>();
        
        for(Id key : mapNew.keySet()){
            oppLineItemIdSet.add(mapOld.get(key).OpportunityLineItem__c);
            oppLineItemIdSet.add(mapNew.get(key).OpportunityLineItem__c);
        }

        Map<Id, OpportunityLineItem> oppLineItemMap = new Map<Id, OpportunityLineItem>([
            SELECT Id,
            BloqueadoRegionalizacao__c,
            Comentarios__c,
            FatorConversao__c, ForaMalha__c,
            Quantity, QuantidadePortal__c,
            TipoConversao__c,
            UnitPrice,
            ValorPortal__c, ValorCx__c
            FROM OpportunityLineItem
            WHERE Id IN : oppLineItemIdSet
        ]);

        for(Id key : mapNew.keySet()){
            QuoteItem__c oldQItem = mapOld.get(key);
            QuoteItem__c newQItem = mapNew.get(key);
            OpportunityLineItem oldOppLineItem = oppLineItemMap.get(oldQItem.OpportunityLineItem__c);
            OpportunityLineItem newOppLineItem = oppLineItemMap.get(newQItem.OpportunityLineItem__c);
            if(checkAnswerChange(oldQItem, newQItem, oldOppLineItem, newOppLineItem)){
                changedItems.add(newQItem);
            }
        }

        if(!changedItems.isEmpty()){
            updateOpportunityAndTeamMemberHasChangesUnsync(changedItems);
        }
    }

    public static Boolean checkAnswerChange(
        QuoteItem__c oldQItem,
        QuoteItem__c newQItem,
        OpportunityLineItem oldOppLineItem,
        OpportunityLineItem newOppLineItem
    ){
        Boolean result = (
            oldQItem.TabulacaoN1__c != newQItem.TabulacaoN1__c ||
            oldQItem.Product__c != newQItem.Product__c ||
            oldQItem.CNPJCD__c != newQItem.CNPJCD__c  ||
            oldQItem.OpportunityLineItem__c != newQItem.OpportunityLineItem__c ||
            oldQItem.FatorConversao__c != newQItem.FatorConversao__c ||
            oldQItem.TipoConversao__c != newQItem.TipoConversao__c ||
            oldQItem.VendedorRespondeu__c != newQItem.VendedorRespondeu__c
        );

        if(oldOppLineItem != null || newOppLineItem != null){
            result = result || (
                oldOppLineItem?.Quantity != newOppLineItem?.Quantity ||
                oldOppLineItem?.UnitPrice != newOppLineItem?.UnitPrice ||
                oldOppLineItem?.ValorPortal__c != newOppLineItem?.ValorPortal__c ||
                oldOppLineItem?.QuantidadePortal__c != newOppLineItem?.QuantidadePortal__c ||
                oldOppLineItem?.foraMalha__c != newOppLineItem?.foraMalha__c ||
                oldOppLineItem?.FatorConversao__c != newOppLineItem?.FatorConversao__c ||
                oldOppLineItem?.TipoConversao__c != newOppLineItem?.TipoConversao__c ||
                oldOppLineItem?.Comentarios__c != newOppLineItem?.Comentarios__c ||
                oldOppLineItem?.ValorCx__c != newOppLineItem?.ValorCx__c ||
                oldOppLineItem?.BloqueadoRegionalizacao__c != newOppLineItem?.BloqueadoRegionalizacao__c
            );
        }
        
        return result;
    }

    public static void updateOpportunityAndTeamMemberHasChangesUnsync(List<QuoteItem__c> lstNew){
        Map<String, Opportunity> oppIdMap = new Map<String, Opportunity>();
        Map<String, List<String>> mapOpportunityIdByUserId = new Map<String, List<String>>();
        Set<String> userIdSet = new Set<String>();

        for(QuoteItem__c qItem : lstNew){
            if(qItem.TabulacaoN1__c != null){
                if(!oppIdMap.containsKey(qItem.OpportunityId__c)){
                    oppIdMap.put(qItem.OpportunityId__c, new Opportunity(Id = qItem.OpportunityId__c, HasChangesUnsync__c = true));
                }
                
                if(!mapOpportunityIdByUserId.containsKey(qItem.OpportunityId__c)){
                    mapOpportunityIdByUserId.put(qItem.OpportunityId__c, new List<String>());
                }

                mapOpportunityIdByUserId.get(qItem.OpportunityId__c).add(qItem.Vendedor__c);
                userIdSet.add(qItem.Vendedor__c);
            }
        }

        List<OpportunityTeamMember> oppTeamMemberListToUpdate = new List<OpportunityTeamMember>(); 
        if(!oppIdMap.isEmpty() && !userIdSet.isEmpty()){
            List<OpportunityTeamMember> oppTeamMemberList = [
                SELECT Id, OpportunityId, UserId
                FROM OpportunityTeamMember 
                WHERE HasChangesUnsync__c = false
                AND OpportunityId IN :mapOpportunityIdByUserId.keySet()
                AND UserId IN :userIdSet
            ];

            for(OpportunityTeamMember oppTM : oppTeamMemberList){
                if(mapOpportunityIdByUserId.get(oppTM.OpportunityId)?.contains(oppTM.UserId)){
                    oppTeamMemberListToUpdate.add(new OpportunityTeamMember(Id = oppTM.Id, HasChangesUnsync__c = true));
                }
            }
        }

        if(!oppIdMap.values()?.isEmpty()){
            update oppIdMap.values();
        }

        if(!oppTeamMemberListToUpdate.isEmpty()){
            update oppTeamMemberListToUpdate;
        }
    }

    public static void updateDistributionCenterRelationship(Map<Id, QuoteItem__c> mapOld, Map<Id, QuoteItem__c> mapNew){
        List<QuoteItem__c> changedItems = new List<QuoteItem__c>();
        for(Id key: mapOld.keySet()){
            QuoteItem__c oldQItem = mapOld.get(key);
            QuoteItem__c newQItem = mapNew.get(key);
            if(oldQItem.CNPJCD__c != newQItem.CNPJCD__c){
                changedItems.add(newQItem);
            }
        }
        if(!changedItems.isEmpty()){
            updateDistributionCenterRelationship(changedItems);
        }
    }

    public static void updateDistributionCenterRelationship(List<QuoteItem__c> lstNew){
        
        for(QuoteItem__c newQItem : lstNew){
            if(String.isNotEmpty(newQItem.CNPJCD__c)){
                newQItem.PaymentConditionByDC__r = new CondicaoPagamentoPorCD__c(ExternalId__c = newQItem.CNPJCD__c + '_' + newQItem.OpportunityId__c);
            }
        }
    }


    public static void deleteCondicaoPagamentoCDSemVinculo(Map<Id, QuoteItem__c> mapOld, Map<Id, QuoteItem__c> mapNew){
        Set<String> distCenterIdSet = new Set<String>();

        for(Id key: mapOld.keySet()){
            QuoteItem__c oldQItem = mapOld?.get(key);
            QuoteItem__c newQItem = mapNew?.get(key);
            if(String.isNotEmpty(oldQItem?.PaymentConditionByDC__c) && oldQItem?.PaymentConditionByDC__c != newQItem?.PaymentConditionByDC__c){
                distCenterIdSet.add(oldQItem.PaymentConditionByDC__c);
            }
        }
        
        if(distCenterIdSet.isEmpty()){
            return;
        }

        List<AggregateResult> quoteItensAggrList = [
            SELECT Count(Id), PaymentConditionByDC__c
            FROM QuoteItem__c
            WHERE PaymentConditionByDC__c IN :distCenterIdSet
            GROUP BY PaymentConditionByDC__c
            HAVING Count(Id) > 0
        ];

        for(AggregateResult aggrResult : quoteItensAggrList){
            distCenterIdSet.remove((String)aggrResult.get('PaymentConditionByDC__c'));
        }

        if(!distCenterIdSet.isEmpty()){
            delete [SELECT Id FROM CondicaoPagamentoPorCD__c WHERE Id IN :distCenterIdSet];
        }
    }

    public static void updateOppTeamMemberAllQuoteItems(List<QuoteItem__c> lstNew, Boolean isDelete){

        Map<String, OpportunityTeamMember> oppTMToUpsert = new Map<String, OpportunityTeamMember>();
        Map<String, List<QuoteItem__c>> qItemMapByOpp = (Map<String, List<QuoteItem__c>>)SObjectUtils.mapObjectsByField(lstNew, 'OpportunityId__c', true);
        Map<String, List<QuoteItem__c>> qItemMapByUser =(Map<String, List<QuoteItem__c>>)SObjectUtils.mapObjectsByField(lstNew, 'Vendedor__c', true);

        Map<Id, OpportunityTeamMember> oppTeamMap = new Map<Id, OpportunityTeamMember>([
            SELECT Id, UserId, OpportunityId, AnsweredQuotes__c, AllQuotes__c
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :qItemMapByOpp.keySet()
            AND UserId IN :qItemMapByUser.keySet()
            FOR UPDATE
        ]);

        for(OpportunityTeamMember oppTM : oppTeamMap.values()){
            oppTMToUpsert.put(oppTM.OpportunityId+'_'+oppTM.UserId, oppTM);
        }

        for(QuoteItem__c qItem : lstNew){
            if(qItem.Vendedor__c == null || qItem.OpportunityId__c == null){
                continue;
            }
            OpportunityTeamMember oppTM = oppTMToUpsert.get(qItem.OpportunityId__c+'_'+qItem.Vendedor__c);
            if(oppTM == null){
                oppTM = new OpportunityTeamMember(
                    UserId = qItem.Vendedor__c,
                    OpportunityId = qItem.OpportunityId__c,
                    AllQuotes__c = 0,
                    AnsweredQuotes__c = 0,
                    TeamMemberRole = 'Sales Rep',
                    OpportunityAccessLevel = 'EDIT'
                );
            }
            Boolean isAnswered = qItem.TabulacaoN1__c != null;

            if(isDelete){
                
                oppTM.AllQuotes__c = (oppTM.AllQuotes__c != null && oppTM.AllQuotes__c > 0) ? oppTM.AllQuotes__c - 1 : 0;
                if(isAnswered){
                    oppTM.AnsweredQuotes__c = (oppTM.AnsweredQuotes__c != null && oppTM.AnsweredQuotes__c > 0) ? oppTM.AnsweredQuotes__c - 1 : 0;
                }
            }else{

                oppTM.AllQuotes__c = oppTM.AllQuotes__c != null ? oppTM.AllQuotes__c + 1 : 1;
                if(isAnswered){
                    oppTM.AnsweredQuotes__c = oppTM.AnsweredQuotes__c != null ? oppTM.AnsweredQuotes__c + 1 : 1;
                }
            }
            
            oppTMToUpsert.put(oppTM.OpportunityId+'_'+oppTM.UserId, oppTM);
        }
        upsert oppTMToUpsert.values();
    }

    public static void updateOppTeamMemberAnsweredQuoteItems(Map<Id, QuoteItem__c> mapOld, Map<Id, QuoteItem__c> mapNew){
        
        List<QuoteItem__c> changedQItemList = new List<QuoteItem__c>();
        for(QuoteItem__c qItem : mapNew.values()){
            QuoteItem__c oldItem = mapOld.get(qItem.Id);
            if( (qItem.TabulacaoN1__c == null && oldItem.TabulacaoN1__c != null) || (qItem.TabulacaoN1__c != null && oldItem.TabulacaoN1__c == null) ){
                changedQItemList.add(qItem);
            }
        }
        if(!changedQItemList.isEmpty()){
            Map<String, List<SObject>> qItemMapByOpp = SObjectUtils.mapObjectsByField(changedQItemList, 'OpportunityId__c', true);
            Map<String, List<SObject>> qItemMapByUser = SObjectUtils.mapObjectsByField(changedQItemList, 'Vendedor__c', true);
            Map<Id, OpportunityTeamMember> oppTeamMap = new Map<Id, OpportunityTeamMember>([
                SELECT Id, UserId, OpportunityId, AnsweredQuotes__c, AllQuotes__c
                FROM OpportunityTeamMember
                WHERE OpportunityId IN :qItemMapByOpp.keySet()
                AND UserId IN :qItemMapByUser.keySet()
                FOR UPDATE
            ]);
            for(OpportunityTeamMember oppTM : oppTeamMap.values()){
                List<SObject> qitemForThisVend = SobjectUtils.filterLists(qItemMapByOpp.get(oppTM.OpportunityId), qItemMapByUser.get(oppTM.UserId));
                
                List<SObject> qItemAnswered = SObjectUtils.filterAttrNeq(qitemForThisVend, 'TabulacaoN1__c', null);
                List<SObject> qItemUnanswered = SObjectUtils.filterAttrEq(qitemForThisVend, 'TabulacaoN1__c', null);
    
                Integer result = qItemAnswered.size() - qItemUnanswered.size();
                oppTM.AnsweredQuotes__c = oppTM.AnsweredQuotes__c != null ? oppTM.AnsweredQuotes__c + result : result;
            }
            update oppTeamMap.values();
        }
    }

    public static Map<Id,OpportunityLineItem> replicateValuesOnOpportunityLineItem(Map<Id, QuoteItem__c> mapOld, Map<Id, QuoteItem__c> mapNew){
        //Portal 980
        Map<Id,OpportunityLineItem> mapOppLineItemsToUpdate = new Map<Id,OpportunityLineItem>();
        for(QuoteItem__c item : mapNew.values()){
            if(item.OpportunityLineItem__c != null){
                OpportunityLineItem oppLineItem = new OpportunityLineItem(Id = item.OpportunityLineItem__c);
    
                if(SObjectUtils.hasChangedFields(item, mapOld, new Set<String>{'Status__c', 'TabulacaoN1__c'})){
                    oppLineItem.Status__c = item.Status__c;
                    oppLineItem.TabulacaoN1__c = item.TabulacaoN1__c;
                    mapOppLineItemsToUpdate.put(item.OpportunityLineItem__c, oppLineItem);
                }
    
            } 

        }
        if(!mapOppLineItemsToUpdate.isEmpty()) update mapOppLineItemsToUpdate.values();
        return mapOppLineItemsToUpdate;
    }

    public static QuoteItem__c setStatus(QuoteItem__c item, Map<Id,QuoteItem__c> mapOld){
        //PORTAL-980 (PORTAL-1069)

        Boolean condPagChange = SObjectUtils.hasChangedFields(item, mapOld, new Set<String>{'Quantity__c', 'UnitPrice__c', 'CNPJCD__c'});
        Boolean fixedStatus = (new List<String>{'Vinculado', 'Respondido', 'Aprovado'}).toString().containsIgnoreCase(item.Status__c);

        if(item.CNPJCD__c != null && item.Product__c != null && item.TabulacaoN1__c != 'Cotado'){
            item.TabulacaoN1__c = 'Cotado';
        }
        if(item.Product__c != null && (!fixedStatus || condPagChange)){
            item.Status__c = 'Vinculado';
            item.TabulacaoN1__c = item.CNPJCD__c == null ? null : 'Cotado';
        }

        return item;
    }

    public void sendProductLinksToPortal(){
        if(lstNew.size() <= 100){
            Set<Id> itemsToLink = new Set<Id>();
            for(QuoteItem__c item: lstNew){
                if(item.Product__c != null && item.Product__c != mapOld.get(item.Id).Product__c){
                    itemsToLink.add(item.Id);
                }
            }
            if(!itemsToLink.isEmpty() && !Test.isRunningTest()){
                IntegrationPortalVinculoOUT.sendAsync(itemsToLink);
            }
        }
    }

}