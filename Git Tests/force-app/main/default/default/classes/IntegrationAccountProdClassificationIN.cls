@RestResource(urlMapping='/accountProductClassification/*')
global without sharing class IntegrationAccountProdClassificationIN {

    public static final String CUSTOM_METADATA_TYPE = 'ClassificacaoClienteProduto';

    @HttpPost
    global static void upsertAccountProductClassification() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.addHeader('Content-Type', 'application/json');

        String requestBody = req.requestBody.toString();
        
        RequestEntry body = (RequestEntry) JSON.deserialize(requestBody, RequestEntry.class);
        
        Metadata.DeployContainer containerMetadata = createMetadataContainer();

        for (ClassificationData classificationItem : body.request) {
            String key = 
                'CL_' +
                classificationItem.CodigoClasseCliente + '_' +
                classificationItem.CodigoClasseProduto;
            
            Metadata.CustomMetadata customMetadata = createCustomMetadata(key);

            customMetadata.values.add(createCustomMetadataValue(
                'ClasseCliente__c',
                classificationItem.CodigoClasseCliente
            ));

            customMetadata.values.add(createCustomMetadataValue(
                'ClasseClienteNome__c',
                classificationItem.ClasseClienteNome
            ));

            customMetadata.values.add(createCustomMetadataValue(
                'ClasseProduto__c',
                classificationItem.CodigoClasseProduto
            ));

            customMetadata.values.add(createCustomMetadataValue(
                'ClasseProdutoNome__c',
                classificationItem.ClasseProdutoNome
            ));

            containerMetadata.addMetadata(customMetadata);
        }

        try {
            Id asyncresultId = Metadata.Operations.enqueueDeployment(containerMetadata, null);
            res.statusCode = 201;
            res.responseBody = Blob.valueOf('{ "error": null, "asyncJobId": "' + asyncresultId + '" }');
        } catch(Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{ "error": ' + e.getMessage() + ' }');
        }
    }

    public static Metadata.DeployContainer createMetadataContainer() {
        return new Metadata.DeployContainer();
    }

    public static Metadata.CustomMetadata createCustomMetadata(String key) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = CUSTOM_METADATA_TYPE + '.' + key;
        customMetadata.label = key;
        return customMetadata;
    }

    public static Metadata.CustomMetadataValue createCustomMetadataValue(
        String field, 
        String value
    ) {
        Metadata.CustomMetadataValue customMetadataValue = new Metadata.CustomMetadataValue();
        customMetadataValue.field = field;
        customMetadataValue.value = value;
        return customMetadataValue;
    }

    public class RequestEntry {
        List<ClassificationData> request;
    }

    public class ClassificationData {
        public String CodigoClasseCliente;
        public String ClasseClienteNome;
        public String CodigoClasseProduto;
        public String ClasseProdutoNome;
    }
}
