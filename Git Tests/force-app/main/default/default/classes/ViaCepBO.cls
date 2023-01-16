public with sharing class ViaCepBO {

    @InvocableMethod(label='Busca CEP' 
            description='Botão para buscar endereço apartir do CEP ')

    public static List<CepTO> flowCEP(List<String> lCEP) {

        return new List<CepTO>{BuscaCep(lCEP[0]) };     
    }
    @AuraEnabled
    public static CepTO BuscaCep(String cep){
        CepTO cepComp = new CepTO();

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://viacep.com.br/ws/'+cep+'/json/');
        request.setMethod('GET');
        Http http = new Http();
        if (!Test.isRunningTest()) {
            HttpResponse response = http.send(request);
            String jsonResponse = response.getBody();
            if(response.getStatusCode() != 200){
                throw new CepException('Erro no Serviço de consulta de CEP: viacep.com.br');
            }else {   
                cepComp = (CepTO)JSON.deserialize(jsonResponse, CepTO.class);
            }
        } else {
            cepComp.bairro      = 'teste';
            cepComp.localidade  = 'teste';
            cepComp.uf          = 'teste';
            cepComp.cep         = 'teste';
            cepComp.logradouro  = 'teste';
            cepComp.complemento = 'teste';
            cepComp.ibge        = 'teste';
            cepComp.gia         = 'teste';
            cepComp.ddd         = 'teste';
            cepComp.siafi       = 'teste';
        }
        System.debug('cep comp ' + cepComp);
        return cepComp;
    }

    public class CepTO {
        @InvocableVariable(label='Bairro' description='Bairro' )
        @AuraEnabled public string bairro;
        @InvocableVariable(label='Localidade' description='Localidade' )
        @AuraEnabled public string localidade;
        @InvocableVariable(label='UF' description='UF' )
        @AuraEnabled public string uf;
        @InvocableVariable(label='CEP' description='CEP' )
        @AuraEnabled public string cep;
        @InvocableVariable(label='Logradouro' description='Logradouro' )
        @AuraEnabled public string logradouro;
        @InvocableVariable(label='Complemento' description='Complemento' )
        @AuraEnabled public string complemento;
        @InvocableVariable(label='ibge' description='ibge' )
        @AuraEnabled public string ibge;
        @InvocableVariable(label='gia' description='gia' )
        @AuraEnabled public string gia;
        @InvocableVariable(label='ddd' description='ddd' )
        @AuraEnabled public string ddd;
        @InvocableVariable(label='siafi' description='siafi' )
        @AuraEnabled public string siafi;
    }
    public class CepException extends Exception {}
}