public class OrderListWonController {
   
    @AuraEnabled
    public static StandardResponse getOrdersListWonFromCurrentUser(){        
        StandardResponse response = new StandardResponse();
                   
            for(List<Order> ordersList : [
                SELECT  Id, OrderNumber, AccountId, Account.Name, EffectiveDate, TotalAmount, Status, Idportalcotacoes__c, (select CentroDistribuicao__c from OrderItems)
                FROM    Order 
                WHERE   Status = 'Em digitação' 
                AND     OpportunityId IN (
                            SELECT  OpportunityId 
                            FROM    OpportunityTeamMember 
                            WHERE   UserId = :UserInfo.getUserId()
                        ) 
                LIMIT 49999
            ]){
                
                response.setData('records',ordersList);
            }
        
        return response;
    }

}