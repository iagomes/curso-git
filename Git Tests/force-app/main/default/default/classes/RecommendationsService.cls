public with sharing class RecommendationsService {

    public static List<RecommendationData> getRecommendations(String contextRecordId, Integer maxResults) {
        List<RecommendationData> recommendations = new List<RecommendationData>();
        
        ConnectApi.NBARecommendations nbaRecommendations = 
            ConnectApi.NextBestAction.executeStrategy('ERB', maxResults, contextRecordId);

        for (ConnectApi.NBARecommendation currentNBARecommendation : nbaRecommendations.recommendations) {
            
            ConnectApi.NBANativeRecommendation nbaRecommendationTarget = 
                (ConnectApi.NBANativeRecommendation) currentNBARecommendation.target;

            ConnectApi.NBAFlowAction nbaRecommendationTargetAction = 
                (ConnectApi.NBAFlowAction) currentNBARecommendation.targetAction;
            
            RecommendationData recommendation = new RecommendationData();
            recommendation.externalId       = currentNBARecommendation.externalId;
            recommendation.targetId         = nbaRecommendationTarget.id;
            recommendation.targetActionId   = nbaRecommendationTargetAction.id;
            recommendation.targetActionName = nbaRecommendationTargetAction.name;
            recommendations.add(recommendation);
        }
        
        return recommendations;
    }

    public static void setReaction(ReactionDataInput reactionDataInput) {
        ConnectApi.RecommendationReactionInput reaction = new ConnectApi.RecommendationReactionInput();
        reaction.strategyName       = 'ERB';
        reaction.externalId         = reactionDataInput.externalId;
        reaction.targetId           = reactionDataInput.targetId;
        //reaction.targetActionId     = reactionDataInput.targetActionId;
        reaction.targetActionName   = reactionDataInput.targetActionName;
        reaction.reactionType       = reactionDataInput.reaction == 'Accepted'
            ? ConnectApi.RecommendationReactionType.ACCEPTED
            : ConnectApi.RecommendationReactionType.REJECTED;

        ConnectApi.NextBestAction.setRecommendationReaction(reaction);

        AnaliseERB__c analise = new AnaliseERB__c(
            Orcamento__c = reactionDataInput.contextRecordId,
            Produto__c = reactionDataInput.externalId,
            Descricao__c = reactionDataInput.reactionMessage,
            StatusRecomendacao__c = reactionDataInput.reactionOption
        );

        insert analise;
    }
    
    @InvocableMethod(label='Get recommendation' description='Get recommendation products for PDF')
    public static List<String> getRecommendationPDF(List<String> oppIdList) {
        GeneralParameters__c parameters = GeneralParameters__c.getValues('Parametro geral');
        String oppId = null;
        for (String str : oppIdList) {
            oppId = str;
        }
        Set<String> productIdSet = new Set<String>();
        // System.debug(LIMIT.);
        List<RecommendationsService.RecommendationData> recommendationList = RecommendationsService.getRecommendations(oppId, Integer.valueOf(parameters.QuantidadeProdutosRecomendados__c));
        for (RecommendationsService.RecommendationData rec : recommendationList) {
            System.debug(rec);
            productIdSet.add(rec.externalId);
        }
        
        String prodCode = '';
        for (Product2 prod : [SELECT Id, ExternalId__c FROM Product2 WHERE Id IN: productIdSet]) {
            if (prodCode != '') {
                prodCode += ',';
            }
            prodCode += prod.ExternalId__c;
            System.debug(prodCode);
        }    
        
        return new List<String>{prodCode};
    }

    public class RecommendationData {
        public String externalId;
        public String targetId;
        public String targetActionId;
        public String targetActionName;
    }

    public class ReactionDataInput {
        public String externalId;
        public String targetId;
        public String targetActionId;
        public String targetActionName;
        public String contextRecordId;
        public String reaction;
        public String reactionOption;
        public String reactionMessage;
    }
}