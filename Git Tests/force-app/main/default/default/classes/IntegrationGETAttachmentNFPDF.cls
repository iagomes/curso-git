public without sharing class IntegrationGETAttachmentNFPDF {
    @InvocableMethod(label='Get Fiscal Attachment PDF' 
                    description='Call integration to get the Attachment of this "Nota Fiscal"')
    public static List<String> flowHandlerXML(List<String> nfIdSet){
        return IntegrationGETAttachment.flowHandlerNF(nfIdSet, 'D');
    }

}
