public without sharing class IntegrationGETAttachmentNFXML {
    @InvocableMethod(label='Get Fiscal Attachment XML' 
                    description='Call integration to get the Attachment of this "Nota Fiscal"')
    public static List<String> flowHandlerPDF(List<String> nfIdSet){
        return IntegrationGETAttachment.flowHandlerNF(nfIdSet, 'X');
    }
}
