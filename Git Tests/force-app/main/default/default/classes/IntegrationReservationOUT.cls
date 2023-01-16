global with sharing class IntegrationReservationOUT {

    global class listReservationRequest {
        public List<ReservationRequest> reservations;
        public listReservationRequest (List<ReservationRequest> reservations){
            this.reservations = reservations;
        }        
    }

    global class ReservationRequest {
        public String CgcEmp;
        public String descricao;
        public String validade;
        public String tipo;
        public String CodigoReserva;
        public Integer ValorLimite;
        public List<ReservationAccountsRequest> clientes;
        public List<ReservationProductsRequest> produtos;
        
        public ReservationRequest (String reserveCode, String descReserva, String cnpjCD, String limiteDate, String type,list<ReservationAccountsRequest> listAccounts, list<ReservationProductsRequest> listProducts){
            this.CgcEmp = cnpjCD;
            this.descricao = descReserva;
            this.validade = limiteDate;
            this.tipo = type == 'Reserva de cliente' ? 'C': 'G';
            this.clientes = listAccounts;
            this.produtos = listProducts;
            this.CodigoReserva = reserveCode;
            this.ValorLimite = 15000000;
        }
    }

    global class ReservationAccountsRequest {
        public String cnpj;
        public String regiao;
        
        public ReservationAccountsRequest (DestinatarioReserva__c reservationObj){
            this.cnpj         = reservationObj.Cliente__r.CNPJ__c != null ? reservationObj.Cliente__r.CNPJ__c : reservationObj.Cliente__r.CPF__c;
            this.regiao       = reservationObj.CodigoRegiao__c;
        }
    }

    global class ReservationProductsRequest {
        public String armazem;
        public String codigo;
        public Decimal quantidade;
        
        
        public ReservationProductsRequest (ProdutoReserva__c reservationObj){
            this.armazem      = reservationObj.Armazem__c;
            this.codigo       = reservationObj.Produto__r.ExternalId__c;
            this.quantidade   = reservationObj.QuantidadeReservada__c;
            
        }
    }

    public class ResultClass{
        public String message {get;set;}
        public String detailMessage {get;set;}
    }

    global class ReservationRequestDelete {
        public String CgcEmp;
        public String CodigoReserva;
        public String tipo;
        public List<ReservationAccountsRequest> clientes;
        public List<ReservationProductsRequest> produtos;
        
        public ReservationRequestDelete (String cnpjCD, String reserveCode, String type,list<ReservationAccountsRequest> listAccounts, list<ReservationProductsRequest> listProducts){
            this.CgcEmp = cnpjCD;
            this.tipo = type == 'Reserva de cliente' ? 'C': 'G';
            this.clientes = listAccounts;
            this.produtos = listProducts;
            this.CodigoReserva = reserveCode;
        }
    }

    public static ResultClass sendReservationERP(List<Reserva__c> listReservation, Boolean isInsert) {
        ResultClass resultobj = new ResultClass();

        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ProdutoReserva__c> reservationMap = new Map<String, ProdutoReserva__c>();

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }

        try {
            
            Integracoes__c intCustomerApi = new Integracoes__c();
            
            System.debug('====== listReservation'+ listReservation);
            if(listReservation.size() > 0){

                Map<Id, List<ProdutoReserva__c>> productsMap = new Map<Id, List<ProdutoReserva__c>>();
                for(ProdutoReserva__c r : [SELECT Id, Reserva__r.CodigoCD__c, Armazem__c, Reserva__c, Produto__r.ExternalId__c, QuantidadeReservada__c, QuantidadeAtiva__c, Reserva__r.CodigoReserva__c, CodigoProduto__c, StatusReserva__c FROM ProdutoReserva__c WHERE Reserva__c IN :listReservation AND ( StatusReserva__c ='Aguardando Integração' OR StatusReserva__c ='Erro de integração') ORDER BY Reserva__r.FimReserva__c DESC]){
                    if (productsMap.containsKey(r.Reserva__c)){
                        productsMap.get(r.Reserva__c). add(r);
                    }else{
                        List<ProdutoReserva__c> productList = new List<ProdutoReserva__c>();
                        productList.add(r);
                        productsMap.put(r.Reserva__c, productList);
                    }

                    if (!String.isBlank(r.Reserva__r.CodigoReserva__c)) {
                        
                        if (!reservationMap.containsKey(r.Reserva__r.CodigoReserva__c.substring(5, 11)+r.CodigoProduto__c)) {
                        
                            reservationMap.put(r.Reserva__r.CodigoReserva__c.substring(5, 11)+r.CodigoProduto__c, r);
                        }
                    }
                  
                }

                Map<Id, List<DestinatarioReserva__c>> destMap = new Map<Id, List<DestinatarioReserva__c>>();
                for(DestinatarioReserva__c r : [SELECT Id, CodigoRegiao__c, Reserva__c, Cliente__c, Cliente__r.CNPJ__c, Cliente__r.CPF__c, Cliente__r.CodigoRegiao__c FROM DestinatarioReserva__c WHERE Reserva__c IN :listReservation ORDER BY Reserva__r.FimReserva__c DESC]){
                    if (destMap.containsKey(r.Reserva__c)){
                        destMap.get(r.Reserva__c).add(r);
                    }else{
                        List<DestinatarioReserva__c> destList = new List<DestinatarioReserva__c>();
                        destList.add(r);
                        destMap.put(r.Reserva__c, destList);
                    }
                }

                List<ReservationRequest> reservationsList = new List<ReservationRequest>();
                Set<String> setAccountCnpj = new Set<String>();
                for(Reserva__c r : listReservation){
                    List<ReservationAccountsRequest> listReservationAccountReq =  new List<ReservationAccountsRequest>();
                    if (destMap.containsKey(r.Id)){
                        for(DestinatarioReserva__c dest : destMap.get(r.Id)){

                            ReservationAccountsRequest accountObj = new ReservationAccountsRequest(dest);

                            // if (!setAccountCnpj.contains(accountObj.cnpj)) {
                                
                                listReservationAccountReq.add(accountObj);
                                setAccountCnpj.add(accountObj.cnpj);

                            // }
                        }
                    }

                    List<ReservationProductsRequest> listReservationItemReq = new List<ReservationProductsRequest>();
                    if (productsMap.containsKey(r.Id)){
                        for(ProdutoReserva__c prod : productsMap.get(r.Id)){
                            ReservationProductsRequest productObj = new ReservationProductsRequest(prod);
                            listReservationItemReq.add(productObj);
                        }
                    }

                    if (String.isBlank(r.CodigoReserva__c)) {

                        intCustomerApi = Integracoes__c.getValues(IntegrationConstants.RESERVATION_POST_METADATA);
                        ReservationRequest reservationReq = new ReservationRequest(null, r.Descricao__c, mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(r.CodigoCD__c) ? mapDistributionCenterCodeToListaCentroDistribuicao.get(r.CodigoCD__c).CNPJCD__c : null, IntegrationContractOUT.getFormattedDate(Date.valueOf(r.FimReserva__c)), r.RecordType.Name, listReservationAccountReq, listReservationItemReq);
                        reservationsList.add(reservationReq);
                        
                    }else{
                        
                        intCustomerApi = isInsert ? Integracoes__c.getValues(IntegrationConstants.RESERVATION_INC_METADATA) : Integracoes__c.getValues(IntegrationConstants.RESERVATION_ALT_METADATA);
                        ReservationRequest reservationReq = new ReservationRequest(r.CodigoReserva__c.substring(5, 11),  r.Descricao__c, mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(r.CodigoCD__c) ? mapDistributionCenterCodeToListaCentroDistribuicao.get(r.CodigoCD__c).CNPJCD__c : null, IntegrationContractOUT.getFormattedDate(Date.valueOf(r.FimReserva__c)), r.RecordType.Name, listReservationAccountReq, listReservationItemReq);
                        reservationsList.add(reservationReq);
                    }                    
                                       
                    System.debug('reservationsList ===> ' + reservationsList);
                   
                }
                listReservationRequest requestRes = new listReservationRequest(reservationsList);

                String body = Json.serialize(reservationsList[0]);
                
                System.debug('body ===> ' + body);  
            
                System.debug('====== intCustomerApi'+ intCustomerApi);
                String method   = intCustomerApi.Method__c;
                String endpoint = intCustomerApi.Endpoint__c;
                String username = intCustomerApi.User__c;
                String password = intCustomerApi.Password__c;
                
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setHeader(IntegrationConstants.AUTHORIZATION, IntegrationConstants.BASIC + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
                req.setHeader(IntegrationConstants.HEADER_TYPE_CONTENT, IntegrationConstants.HEADER_TYPE_CONTENT_JSON);
                req.setMethod(method);
                req.setTimeout(IntegrationConstants.TIMEOUT);
                req.setBody(body);

                HttpResponse resp = new HttpResponse();
                resp = new Http().send(req);
                String resultString = resp.getBody();  
                
                System.debug('resultString ===> ' + resultString);
                IntegrationUtils.WSLog(IntegrationConstants.RESERVATION, IntegrationConstants.OUTBOUND, body, resultString, (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) ? false : true);
                resultobj = (ResultClass)JSON.deserialize(resultString, ResultClass.class);

                if (method == 'POST') {

                    List<ProdutoReserva__c> listPd = new  List<ProdutoReserva__c>();

                    for (ReservationProductsRequest reservationProduct : reservationsList[0].produtos) {

                        for (String key : productsMap.keySet()) {

                            for (ProdutoReserva__c pd : productsMap.get(key)) {

                                if (reservationProduct.codigo == pd.CodigoProduto__c) {
                                    
                                    pd.StatusReserva__c = resultobj.message != 'Cadastro realizado com Sucesso !!!' ? IntegrationConstants.STATUS_INTEGRATION_ERROR : IntegrationConstants.STATUS_INTEGRATION_ACTIVE;
                                    pd.QuantidadeAtiva__c = resultobj.message != 'Cadastro realizado com Sucesso !!!' ? pd.QuantidadeAtiva__c : reservationProduct.quantidade;
                                    pd.ChaveUnica__c = resultobj.message != 'Cadastro realizado com Sucesso !!!' ? '' : pd.Reserva__r.CodigoCD__c + resultobj.detailMessage + pd.CodigoProduto__c + pd.Armazem__c;
                                   
                                    listPd.add(pd);
                                }
                                
                            }

                        }
                    }

                    update listPd;

                }else{
                    for (ReservationProductsRequest pd : reservationsList[0].produtos) {
                        String key = reservationsList[0].CodigoReserva+pd.codigo;
                        
                        if (checkProductInErrorMessage(pd.codigo, resultobj.message)) {
                            if(reservationMap.get(key).StatusReserva__c != 'Ativa') {
                                reservationMap.get(key).StatusReserva__c = IntegrationConstants.STATUS_INTEGRATION_ERROR;
                                reservationMap.get(key).QuantidadeAtiva__c = reservationMap.get(key).QuantidadeAtiva__c;
                            }
                        } else {
                            if (resultobj.detailMessage != 'Reserva alterada com sucesso !!!') {
                                reservationMap.get(key).StatusReserva__c = IntegrationConstants.STATUS_INTEGRATION_ERROR;
                                reservationMap.get(key).QuantidadeAtiva__c = reservationMap.get(key).QuantidadeAtiva__c;
                            } else {
                                reservationMap.get(key).StatusReserva__c = IntegrationConstants.STATUS_INTEGRATION_ACTIVE;
                                reservationMap.get(key).QuantidadeAtiva__c = pd.quantidade;
                            }
                        }
                    }
    
                    update reservationMap.values();
                }
            }
        } catch (Exception e){
            resultobj.message = e.getMessage();
            resultobj.detailMessage = '';
            System.debug(e.getMessage());
        }
        
        return resultobj;
    }

    public static Boolean checkProductInErrorMessage(String productCode, String erpMessage) {
        String unavailableStockMessage = 'Produtos com saldo indisponivel para alteracao/inclusao na reserva';

        if (erpMessage.contains(unavailableStockMessage)) {
            List<String> paramsString = erpMessage.split('>>>'); // msg >>> codProduto, codProduto..

            if (paramsString.size() == 2) {
                return paramsString[1].contains(productCode);
            }
        }

        return false;
    }

    public static List<Reserva__c> getReservations(List<Id> reservationsList){
        return [
            SELECT 
                Id, 
                CodigoReserva__c,
                CodigoReservaProtheus__c,
                FimReserva__c, 
                CentroDistribuicao__c, 
                MensagemErroIntegracao__c, 
                StatusReserva__c, 
                RecordType.Name, 
                CodigoCD__c, 
                Descricao__c 
            FROM Reserva__c 
            WHERE Id IN :reservationsList
        ];
    }

    @InvocableMethod(label='Send Reservation to Protheus' 
                    description='Send Reservation to Protheus')
    public static void sendToProtheus(List<Id> reservationIdList) {
        List<Reserva__c> listReservation = getReservations(reservationIdList);
        System.debug(JSON.serialize(listReservation));
        ResultClass response = IntegrationReservationOUT.sendReservationERP(listReservation, true);
        updateReservationInt(listReservation,response);
    }

    public static void updateReservationInt(List<Reserva__c> listReservation, ResultClass response){
        List<Reserva__c> reserUpdateList = new List<Reserva__c>();
        for(Reserva__c r : listReservation){
            r.MensagemErroIntegracao__c = response.message;
            if (response.message == 'Cadastro realizado com Sucesso !!!') {
                
                r.CodigoReserva__c = r.CodigoCD__c + response.detailMessage;
            }
            r.ErroIntegracao__c  = true;
            reserUpdateList.add(r);
        }
        update reserUpdateList;
    }

    @future(callout = true)
    public static void asyncSendToProtheus(List<Id> reservationIdList) {
        List<Reserva__c> listReservation = getReservations(reservationIdList);
        System.debug(JSON.serialize(listReservation));
        ResultClass response = IntegrationReservationOUT.sendReservationERP(listReservation, true);
        updateReservationInt(listReservation,response);
    }

    public static ResultClass deleteProductReservationERP(List<Reserva__c> listReservation, String productReservationId) {

        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ProdutoReserva__c> reservationMap = new Map<String, ProdutoReserva__c>();
        ResultClass resultobj = new ResultClass();

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }

        try {
            
            Integracoes__c intCustomerApi = new Integracoes__c();
            List<ReservationRequestDelete> reservationsList = new List<ReservationRequestDelete>();

            
            System.debug('====== listReservation'+ listReservation);
            if(listReservation.size() > 0){

                Map<Id, List<ProdutoReserva__c>> productsMap = new Map<Id, List<ProdutoReserva__c>>();
                for(ProdutoReserva__c r : [SELECT Id, Reserva__r.CodigoCD__c, Armazem__c, Reserva__c, Produto__r.ExternalId__c, QuantidadeReservada__c, QuantidadeAtiva__c, Reserva__r.CodigoReserva__c, CodigoProduto__c FROM ProdutoReserva__c WHERE Id =: productReservationId]){
                    if (productsMap.containsKey(r.Reserva__c)){
                        productsMap.get(r.Reserva__c). add(r);
                    }else{
                        List<ProdutoReserva__c> productList = new List<ProdutoReserva__c>();
                        productList.add(r);
                        productsMap.put(r.Reserva__c, productList);
                    }

                    if (!String.isBlank(r.Reserva__r.CodigoReserva__c)) {
                        
                        if (!reservationMap.containsKey(r.Reserva__r.CodigoReserva__c.substring(5, 11)+r.CodigoProduto__c)) {
                        
                            reservationMap.put(r.Reserva__r.CodigoReserva__c.substring(5, 11)+r.CodigoProduto__c, r);
                        }
                    }
                  
                }

                Set<String> setAccountCnpj = new Set<String>();                

                List<ReservationProductsRequest> listReservationItemReq = new List<ReservationProductsRequest>();

                intCustomerApi = Integracoes__c.getValues(IntegrationConstants.RESERVATION_DEL_METADATA);

                for (Reserva__c r : listReservation) {
                    
                    for(ProdutoReserva__c prod : productsMap.get(r.Id)){
                        ReservationProductsRequest productObj = new ReservationProductsRequest(prod);
                        listReservationItemReq.add(productObj);
                    }
                    ReservationRequestDelete deleteRequest = new ReservationRequestDelete(mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(r.CodigoCD__c) ? mapDistributionCenterCodeToListaCentroDistribuicao.get(r.CodigoCD__c).CNPJCD__c : null, r.CodigoReserva__c.substring(5, 11), r.RecordType.Name, new List<ReservationAccountsRequest>(), listReservationItemReq);
                    reservationsList.add(deleteRequest);
                }         
                   
                }

                String body = Json.serialize(reservationsList[0]);
                
                System.debug('body ===> ' + body);  
            
                System.debug('====== intCustomerApi'+ intCustomerApi);
                String method   = intCustomerApi.Method__c;
                String endpoint = intCustomerApi.Endpoint__c;
                String username = intCustomerApi.User__c;
                String password = intCustomerApi.Password__c;
                
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setHeader(IntegrationConstants.AUTHORIZATION, IntegrationConstants.BASIC + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
                req.setHeader(IntegrationConstants.HEADER_TYPE_CONTENT, IntegrationConstants.HEADER_TYPE_CONTENT_JSON);
                req.setMethod(method);
                req.setTimeout(IntegrationConstants.TIMEOUT);
                req.setBody(body);

                HttpResponse resp = new HttpResponse();
                resp = new Http().send(req);
                String resultString = resp.getBody();
                resultobj = (ResultClass)JSON.deserialize(resultString, ResultClass.class);
                
                System.debug('resultString ===> ' + resultString);
                System.debug('resultobj ===> ' + resultobj);
                IntegrationUtils.WSLog(IntegrationConstants.RESERVATION, IntegrationConstants.OUTBOUND, body, resultString, (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) ? false : true);
                    
                // return resultobj.message != 'Exclusao realizada com sucesso' ? false : true;
                return resultobj;


        }catch (Exception e){
            // resultobj.message = e.getMessage();
            // resultobj.detailMessage = '';
            System.debug(e.getMessage());
            ResultClass result = new ResultClass();
            result.message = e.getMessage();
            result.detailMessage = e.getStackTraceString();
            return result;
        }
    }

    public static Boolean deleteReservationHeaderERP(List<Reserva__c> listReservation) {
        if (listReservation.size() > 0) {
            Reserva__c currentReservation = listReservation[0];

            ListaCentroDistribuicao__c deliveryCenter = [
                SELECT 
                    Id, 
                    CNPJCD__c
                FROM ListaCentroDistribuicao__c 
                WHERE CodigoCD__c =: currentReservation.CodigoCD__c
                LIMIT 1
            ];

            if (deliveryCenter == null) {
                return false;
            }
            
            try {
                ReservationRequestDelete deleteRequest = new ReservationRequestDelete(
                    deliveryCenter.CNPJCD__c,
                    currentReservation.CodigoReservaProtheus__c,
                    currentReservation.RecordType.Name,
                    new List<ReservationAccountsRequest>(),
                    new List<ReservationProductsRequest>()
                );
                    
                String body = JSON.serialize(deleteRequest);
                System.debug('body ===> ' + body);
                
                ResultClass resultobj = new ResultClass();
                Integracoes__c intCustomerApi = Integracoes__c.getValues(IntegrationConstants.RESERVATION_DEL_METADATA);
                System.debug('====== intCustomerApi'+ intCustomerApi);
                String method   = intCustomerApi.Method__c;
                String endpoint = intCustomerApi.Endpoint__c;
                String username = intCustomerApi.User__c;
                String password = intCustomerApi.Password__c;

                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setHeader(IntegrationConstants.AUTHORIZATION, IntegrationConstants.BASIC + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
                req.setHeader(IntegrationConstants.HEADER_TYPE_CONTENT, IntegrationConstants.HEADER_TYPE_CONTENT_JSON);
                req.setMethod(method);
                req.setTimeout(IntegrationConstants.TIMEOUT);
                req.setBody(body);

                HttpResponse resp = new HttpResponse();
                resp = new Http().send(req);
                String resultString = resp.getBody();
                resultobj = (ResultClass) JSON.deserialize(resultString, ResultClass.class);
                
                System.debug('resultString ===> ' + resultString);
                System.debug('resultobj ===> ' + resultobj);
                IntegrationUtils.WSLog(IntegrationConstants.RESERVATION, IntegrationConstants.OUTBOUND, body, resultString, (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) ? false : true);
                    
                return resultobj.message != 'Exclusao realizada com sucesso' ? false : true;
            } catch (Exception e) {
                System.debug(e.getMessage());
                return false;
            }
        } else {
            return false;
        }
    }
}