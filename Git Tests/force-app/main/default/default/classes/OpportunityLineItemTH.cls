/**
 * @description       : Trigger Handler using the AutomationController class
 * @author            : Raphael Holanda
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @linkedin          : https://www.linkedin.com/in/raphaelsoares95/
 * @company           : Icon Solutions
 * @last modified on  : 03-02-2022
 * @last modified by  : raphael.holanda.ext@iconit.com.br
 * Modifications Log 
 * Ver   Date         Author                                Modification
 * 1.0   03-02-2022   raphael.holanda.ext@iconit.com.br     Initial Version
**/
public class OpportunityLineItemTH extends TriggerHandlerV2 {

    private static final String className = 'OpportunityLineItemTH';
    private List<OpportunityLineItem> lstNew;
    private List<OpportunityLineItem> lstOld;
    private Map<Id, OpportunityLineItem> mapOld;
    private Map<Id, OpportunityLineItem> mapNew;

    public OpportunityLineItemTH() {
        this.lstNew = (List<OpportunityLineItem>) Trigger.new;
        this.lstOld = (List<OpportunityLineItem>) Trigger.old;
        this.mapOld = (Map<Id, OpportunityLineItem>) Trigger.oldMap;
        this.mapNew = (Map<Id, OpportunityLineItem>) Trigger.newMap;
    }

    public override void fixNewDataBeforeInsertOrUpdate() {

        // fill needed data
        Set<String> product2Ids = new Set<String>();

        for(OpportunityLineItem item: lstNew){
            if(String.isNotBlank(item.Product2Id)){
                product2Ids.add(item.Product2Id);
            }
        }

        Map<Id,Product2> mapProducts = new Map<Id,Product2>([
            SELECT 
                Id,
                ExternalId__c,
                (
                    SELECT Id, UnitPrice
                    FROM PricebookEntries
                    WHERE 
                        IsActive = TRUE
                        AND Pricebook2Id =: ProductHelper.STANDARD_PRICEBOOK_ID
                    LIMIT 1
                )
            FROM Product2 
            WHERE Id IN: product2Ids
        ]);

        //process automations
        for(OpportunityLineItem item: lstNew){
            
            if(item.Product2Id != null && item.PricebookEntryId == null){
                item.PricebookEntryId = mapProducts.get(item.Product2Id).PricebookEntries[0].Id;
                item.UnitPrice = mapProducts.get(item.Product2Id).PricebookEntries[0].UnitPrice;
            }

        }


    }
}