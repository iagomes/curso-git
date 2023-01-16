public without sharing class ContentVersionHelper {
    public ContentVersionHelper() {}
    
    public static void updateCtDocumentDescription(ContentVersion[] newRecords) {
        Map<Id, String> mapCtVersionIdToKey = new Map<Id, String>();

        for(ContentVersion ctVersion : newRecords){
            system.debug(JSON.serializePretty(ctVersion));
            mapCtVersionIdToKey.put(ctVersion.ContentDocumentId, ctVersion.Description);
        }

        List<ContentDocument> listContentDocument = new List<ContentDocument>();
        for (ContentDocument ctDocument : [SELECT Id, Description FROM ContentDocument WHERE Id IN: mapCtVersionIdToKey.keySet()]) {
            ctDocument.Description = mapCtVersionIdToKey.get(ctDocument.Id);
            listContentDocument.add(ctDocument);
        }

        system.debug(listContentDocument);

        if (!listContentDocument.isEmpty()) {
            update listContentDocument;
            ContentDocumentHelper.handleLinkEntity(listContentDocument);
        }
    }
}
