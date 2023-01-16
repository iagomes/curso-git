public without sharing class ContentDocumentHelper {
    public ContentDocumentHelper() {}

    public static void handleLinkEntity(ContentDocument[] newRecords) {
        Set<String> setDescription = new Set<String>();
        for(ContentDocument ctDocument : newRecords){
            if (ctDocument.Description != null) {
                setDescription.add(ctDocument.Description);
                system.debug(JSON.serializePretty(ctDocument));
            }
        }

        Map<String, Id> mapExIdToSObjectLink = new Map<String, Id>();
        System.debug('setDescription size => ' + setDescription.size());
        if (!setDescription.isEmpty()) {
            System.debug('setDescription => ' + setDescription);
            for(NotasFiscais__c nfs : [SELECT id, ExternalId__c FROM NotasFiscais__c WHERE ExternalId__c IN :setDescription]){
                mapExIdToSObjectLink.put(nfs.ExternalId__c, nfs.id);
            }
            for(TitulosAbertos__c titulos : [SELECT id, NumeroBoleto__c FROM TitulosAbertos__c WHERE NumeroBoleto__c IN :setDescription]){
                mapExIdToSObjectLink.put(titulos.NumeroBoleto__c, titulos.id);
            }
        }

        system.debug(mapExIdToSObjectLink);
        
        List<ContentDocumentLink> ctDocumentLinkList = new List<ContentDocumentLink>();
        for(ContentDocument ctDocument : newRecords){
            if(mapExIdToSObjectLink.containsKey(ctDocument.Description))
                ctDocumentLinkList.add(new ContentDocumentLink(LinkedEntityId = mapExIdToSObjectLink.get(ctDocument.Description),
                                                               ContentDocumentId = ctDocument.id,
                                                               ShareType = 'V',
                                                               Visibility = 'AllUsers'));
        }
        system.debug(ctDocumentLinkList);
        if(!ctDocumentLinkList.isEmpty()){
            insert ctDocumentLinkList;
        }
    }

    public static void deletePaymentAttachment(List<ContentDocument> oldRecords) {
        Set<Id> paymentAttachmentIds = new Set<Id>();
        Set<Id> contentDocumentIds = new Set<Id>();

        for (ContentDocument paymentAttachment : oldRecords) {
            contentDocumentIds.add(paymentAttachment.Id);
        }

        for (Order order : [SELECT Id, AttachmentId__c FROM Order WHERE AttachmentId__c IN: contentDocumentIds LIMIT 1]) {
            paymentAttachmentIds.add(order.AttachmentId__c);
        }
        
        for (ContentDocument paymentAttachment : oldRecords) {
            if (paymentAttachmentIds.contains(paymentAttachment.Id)) {
                paymentAttachment.addError('Não é possível deletar comprovante de pagamento.');
            }
        }
    }
}
