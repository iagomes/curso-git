public without sharing class ReservationProductTriggerHelper {

    public ReservationProductTriggerHelper() {}

    public static final Id RESERVATION_REGION_RECORDTYPE = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaRegional').getRecordTypeId();
    public static final Id RESPONSABILITY_RESERVATION_REGION_RECORDTYPE = Schema.SObjectType.ResponsabilidadeAprovacao__c.getRecordTypeInfosByDeveloperName().get('AprovacaoReserva').getRecordTypeId();
    public static final Set<String> setProductRegion = new Set<String>();  
    public static final Set<String> setProductClient = new Set<String>();  
    public static final Set<String> setClients = new Set<String>();  

    public static void validateStatusReservation(Map<Id, ProdutoReserva__c> newMap){

        List<ProdutoReserva__c> lstReservationApproval = new List<ProdutoReserva__c>();
        List<Id> lstReservationIntegration = new List<Id>();
        List<ProdutoReserva__c> lstReservationDelete = new List<ProdutoReserva__c>();
        Map<String,String> mapApproval = new Map<String,String>();
        Set<Id> resultIds = new Set<Id>();
        List<ProdutoReserva__c> lstReservationTransfer = new List<ProdutoReserva__c>();
        List<ProdutoReserva__c> lstReservationTransferReject = new List<ProdutoReserva__c>();
        Set<String> setReceiverReservation = new Set<String>();
        Set<String> setProduct = new Set<String>();

      
        for (ProdutoReserva__c reservationProduct : newMap.values()) {

            if (reservationProduct.StatusReserva__c == 'Aguardando aprovação') {              

                lstReservationApproval.add(reservationProduct);
                resultIds.add(reservationProduct.Reserva__c);

            }else if (reservationProduct.StatusReserva__c == 'Aguardando Integração') {
              
                if (!String.isBlank(reservationProduct.ReservaRecebedora__c)) {
                    lstReservationTransfer.add(reservationProduct);
                    setReceiverReservation.add(reservationProduct.ReservaRecebedora__c);
                    setProduct.add(reservationProduct.Produto__c);
                }
                lstReservationIntegration.add(reservationProduct.Reserva__c);
                mapApproval.put(reservationProduct.Id, 'Approve');
               

            }else if (reservationProduct.StatusReserva__c == 'Rejeitada' || reservationProduct.StatusReserva__c == 'Ativa') {
              
                if (reservationProduct.StatusReserva__c == 'Ativa') {

                    if (!String.isBlank(reservationProduct.ReservaRecebedora__c)) {
                        lstReservationTransferReject.add(reservationProduct);
                        setReceiverReservation.add(reservationProduct.ReservaRecebedora__c);
                        setProduct.add(reservationProduct.Produto__c);
                    }
                    
                } else {
                    
                     //lstReservationIntegration.add(reservationProduct);
                    mapApproval.put(reservationProduct.Id, 'Reject');
                }
               
               

            }
            // else if (reservationProduct.StatusReserva__c == 'Aguardando envio de exclusão') {              
                
            //     lstReservationDelete.add(reservationProduct);
            // }

        }

        if (lstReservationApproval.size() > 0) {

            Map<String,List<DestinatarioReserva__c>> mapReservation = getRecordTypeReservation(resultIds);
        
            validateTypeApproval(lstReservationApproval, mapReservation );

        }

        if (lstReservationIntegration.size() > 0) {

            System.debug(lstReservationTransfer);

            if (lstReservationTransfer.size() > 0) {
                
                lstReservationIntegration.addAll(reservationTransfer(lstReservationTransfer, setReceiverReservation, setProduct,true));
            }            

            IntegrationReservationOUT.asyncSendToProtheus(lstReservationIntegration);
        }

        if (lstReservationTransferReject.size() > 0) {
                
            reservationTransfer(lstReservationTransfer, setReceiverReservation, setProduct, false);
        }

        // if (lstReservationDelete.size() > 0) {
            
        //     //sendReservationDelete(lstReservationDelete);
        // }

        if (mapApproval.size() > 0) {
            updateApprovalStep(mapApproval);
        }
    }
     
    public static void validateTypeApproval(List<ProdutoReserva__c> lstReservaAprovacao, Map<String,List<DestinatarioReserva__c>> mapReservation){

        List<ProdutoReserva__c> lstReservationRegion = new List<ProdutoReserva__c>();
        List<ProdutoReserva__c> lstReservationClient = new List<ProdutoReserva__c>();
        
        for (ProdutoReserva__c productReservation : lstReservaAprovacao) {
            System.debug('============================ '+mapReservation.get(productReservation.Reserva__c));
            
            if (mapReservation.get(productReservation.Reserva__c)[0].Reserva__r.RecordTypeId == RESERVATION_REGION_RECORDTYPE) {

                lstReservationRegion.add(productReservation);
                setProductRegion.add(productReservation.Produto__c);
            
            }else{

                lstReservationClient.add(productReservation);
                setProductClient.add(productReservation.Produto__c);
            }            
        }

        if (lstReservationRegion.size() > 0) {

            reservationApproval(lstReservationRegion,  mapReservation , true, null);

        } else if (lstReservationClient.size() > 0) {            

            reservationApproval(lstReservationClient,  mapReservation , false, getClientRegionReservation(setClients));
            
        }
    }
    
    public static void reservationApproval(List<ProdutoReserva__c> lstReservationProduct, Map<String,List<DestinatarioReserva__c>> mapReservation, Boolean isRegion, Map<String,List<String>> mapReservationClient){

        String recType = RESPONSABILITY_RESERVATION_REGION_RECORDTYPE;
        Set<String> setRegion = new Set<String>();
        Set<String> setCategoryProduct = new Set<String>();
        Map<String, String> mapCategoryProduct = isRegion ? getProductCategory(setProductRegion) : getProductCategory(setProductClient);
        Map<String, String> mapApprover = new Map<String, String>();
        Map<String, List<String>> mapApproverList = new Map<String, List<String>>();
        Map<String, ProdutoReserva__c> mapRegionCategoryxReservation = new Map<String, ProdutoReserva__c>();
        String categories = '';

        for (ProdutoReserva__c produtoReserva : lstReservationProduct) {
            
            for (DestinatarioReserva__c destination : mapReservation.get(produtoReserva.Reserva__c)) {

                if (isRegion) {

                    setRegion.add(destination.CodigoRegiao__c);

                    if (!mapRegionCategoryxReservation.containsKey(destination.CodigoRegiao__c + mapCategoryProduct.get(produtoReserva.Produto__c) +produtoReserva.Produto__c)) {
                    
                        mapRegionCategoryxReservation.put(destination.CodigoRegiao__c + mapCategoryProduct.get(produtoReserva.Produto__c) +produtoReserva.Produto__c, produtoReserva);
                    } 

                }else{
                    if(mapReservationClient.containsKey(destination.Cliente__c)) {
                        for (String region : mapReservationClient.get(destination.Cliente__c)) {

                            setRegion.add(region);
                        
                            if (!mapRegionCategoryxReservation.containsKey(region + mapCategoryProduct.get(produtoReserva.Produto__c)+produtoReserva.Produto__c)) {
                            
                            mapRegionCategoryxReservation.put(region + mapCategoryProduct.get(produtoReserva.Produto__c)+produtoReserva.Produto__c, produtoReserva);
                            }                         
                        } 
                    }
                 
                }
            }                    
           
            setCategoryProduct.add(mapCategoryProduct.get(produtoReserva.Produto__c));            
        }
         System.debug(setRegion);
         System.debug(setCategoryProduct);
         System.debug(recType);
        categories = string.valueof(setCategoryProduct).replace('{', '').replace('}', '').replace(',', ';');
         System.debug(categories);
        List<ResponsabilidadeAprovacao__c> lstApprovers = getApprovers(setRegion, categories, new Set<String>{recType});
         System.debug(lstApprovers);

        if (lstApprovers.size() > 0) {
            
            for (ResponsabilidadeAprovacao__c respApproval : lstApprovers) {           
                
                List<string> categoria = respApproval.Categorias__c != null ? respApproval.Categorias__c.split(';') : new List<string>() ;

                for(string cat : categoria) {
            
                    if (!mapApprover.containsKey(respApproval.Regiao__c + cat)) {
                
                        mapApprover.put(respApproval.Regiao__c + cat, respApproval.UsuarioAprovador__c);
                    }              
                }

                if (!mapApproverList.containsKey(respApproval.Regiao__c)) {
                    
                    mapApproverList.put(respApproval.Regiao__c, new List<String>{respApproval.UsuarioAprovador__c});

                }else{
                    
                    mapApproverList.get(respApproval.Regiao__c).add(respApproval.UsuarioAprovador__c);
                }       
                
            }

            System.debug('lstApprovers '+lstApprovers);
            System.debug('mapApprover '+mapApprover);

            sendReservationApproval(mapApprover, mapRegionCategoryxReservation, mapApproverList);
        }
    }

    public static void sendReservationApproval(Map<String, String> mapApprover, Map<String, ProdutoReserva__c> mapRegionCategoryxReservation, Map<String, List<String>> mapApproverList){

        Approval.ProcessResult[] processResults = null;
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest> ();
        Set<String> setApprovers = new Set<String>();
        Set<String> setIds = new Set<String>();
       
        System.debug(mapRegionCategoryxReservation.size());
        for (String reservation : mapRegionCategoryxReservation.keySet()) {

            string Auxreservation = reservation.left(reservation.length()-18);

            if (!setApprovers.contains(mapApprover.get(Auxreservation)) && mapApprover.get(Auxreservation)!= null) {

                requests.add(getProcessRequest(mapRegionCategoryxReservation.get(reservation).Id, mapApprover.get(Auxreservation), String.isBlank(mapRegionCategoryxReservation.get(reservation).ReservaRecebedora__c) ? 'ProdutoReserva_Aprovacao' : 'ProdutoReserva_AprovTransferencia'));
                setApprovers.add(mapApprover.get(Auxreservation));
                setIds.add(mapRegionCategoryxReservation.get(reservation).Id);

            }else  if (setApprovers.contains(mapApprover.get(Auxreservation)) && mapApprover.get(Auxreservation)!= null && !setIds.contains(mapRegionCategoryxReservation.get(reservation).Id)) {

                requests.add(getProcessRequest(mapRegionCategoryxReservation.get(reservation).Id, mapApprover.get(Auxreservation), String.isBlank(mapRegionCategoryxReservation.get(reservation).ReservaRecebedora__c) ? 'ProdutoReserva_Aprovacao' : 'ProdutoReserva_AprovTransferencia'));
                setIds.add(mapRegionCategoryxReservation.get(reservation).Id);
            }
            
            if (mapApproverList.containsKey(Auxreservation.Substring(0, Auxreservation.length() -1))) {

                for (String approversWithoutCategory : mapApproverList.get(Auxreservation.Substring(0, Auxreservation.length() -1))) {

                    if (!setApprovers.contains(approversWithoutCategory)) {
                        setApprovers.add(approversWithoutCategory);                       
                        requests.add(getProcessRequest(mapRegionCategoryxReservation.get(reservation).Id, approversWithoutCategory, String.isBlank(mapRegionCategoryxReservation.get(reservation).ReservaRecebedora__c) ? 'ProdutoReserva_Aprovacao' : 'ProdutoReserva_AprovTransferencia'));
                    } else {
                        requests.add(getProcessRequest(mapRegionCategoryxReservation.get(reservation).Id, approversWithoutCategory, String.isBlank(mapRegionCategoryxReservation.get(reservation).ReservaRecebedora__c) ? 'ProdutoReserva_Aprovacao' : 'ProdutoReserva_AprovTransferencia'));
                    }              
                }                
            }
               
            System.debug('====mapApproverList '+mapApproverList);                 
            
        }
        System.debug('====setApprovers '+setApprovers);   
        System.debug('====requests '+requests.size());   
        try {
            processResults = Approval.process(requests, true);
        }catch (System.DmlException e) {
            System.debug('Exception Is ' + e.getMessage());
        }
    }

    public static Map<String, String> getProductCategory(Set<String> setProduto){

        List<Product2> lstProduto = [SELECT id, CategoriaComercial__c FROM Product2 WHERE Id IN:setProduto];
        Map<String, String> mapCategoriaProduto = new Map<String, String>();       

        for (Product2 pd : lstProduto) {
            
            if (!mapCategoriaProduto.containsKey(pd.Id)) {
                
                mapCategoriaProduto.put(pd.Id, pd.CategoriaComercial__c == 'R' ? 'S': pd.CategoriaComercial__c);
            }
        }
        
        return mapCategoriaProduto;
    }

    public static List<ResponsabilidadeAprovacao__c> getApprovers(Set<String> setRegiao, String categorias, Set<String> setRecordtype){

        List<ResponsabilidadeAprovacao__c> lstAprovadores = [
                                                                SELECT id, Regiao__c, Categorias__c, UsuarioAprovador__c
                                                                FROM
                                                                ResponsabilidadeAprovacao__c
                                                                WHERE
                                                                Regiao__c IN:setRegiao
                                                                AND RecordTypeId IN: setRecordtype 
                                                                AND (Categorias__c INCLUDES(:categorias) 
                                                                OR Categorias__c = null)                                                               
                                                            ];
        return lstAprovadores;
    }

    public static Approval.ProcessSubmitRequest getProcessRequest(Id reservaId, Id userId, String processoDef) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Aprovação da reserva de produto');
        req.setObjectId(reservaId);
        req.setProcessDefinitionNameOrId(processoDef);
        req.setNextApproverIds(new Id[] {userId});

        return req;
    }

    public static void updateApprovalStep(Map<String, String> mapAprovacoes){

        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId IN :mapAprovacoes.keySet() 
            AND ProcessInstance.Status = 'Pending'
        ];

        System.debug('==== workItems' + workItems);
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        for(ProcessInstanceWorkitem workItem : workItems){

            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItem.Id);          
            req.setAction(mapAprovacoes.get(workItem.ProcessInstance.TargetObjectId));
            requests.add(req);
        }
        Approval.ProcessResult[] processResults = Approval.process(requests);
    }

    public static void validateQuantityUsed( Map<Id, ProdutoReserva__c> oldMap){
      
        for (ProdutoReserva__c productReservation : oldMap.values()) {

            if (productReservation.QuantidadeConsumida__c > 0 ) {              

                //productReservation.addError('A Reserva não pode ser deletada com saldo utilizado!');
            }
        }
    }

    public static Map<String,List<DestinatarioReserva__c>> getRecordTypeReservation(Set<Id> setIds){

        Map<String,List<DestinatarioReserva__c>> mapReservation = new Map<String,List<DestinatarioReserva__c>>();
        List<DestinatarioReserva__c> listReservation = [
                                                            SELECT Id, Reserva__r.RecordTypeId, Reserva__c, CodigoRegiao__c, Cliente__c
                                                            FROM
                                                            DestinatarioReserva__c
                                                            WHERE
                                                            Reserva__c IN:setIds                                                              
                                                       ];
        System.debug(setIds);
        for (DestinatarioReserva__c reservationDestination : listReservation) {

            if (!mapReservation.containsKey(reservationDestination.Reserva__c)) {

                mapReservation.put(reservationDestination.Reserva__c, new List<DestinatarioReserva__c>{reservationDestination});
                
            }else{
                mapReservation.get(reservationDestination.Reserva__c).add(reservationDestination);
            }

            System.debug(reservationDestination.Cliente__c );
            if (reservationDestination.Cliente__c != null) {
                setClients.add(reservationDestination.Cliente__c);
            }
            
        }
        System.debug(setClients);
        System.debug(mapReservation);
        return mapReservation;
    }

    public static Map<String,List<String>> getClientRegionReservation(Set<String> setIds){

        Map<String,List<String>> mapReservationRegion = new Map<String,List<String>>();
        List<Setorizacao__c> listReservation = [
                                                    SELECT Id, Conta__c, Regiao__c
                                                    FROM
                                                    Setorizacao__c
                                                    WHERE
                                                    Conta__c IN:setIds                                                              
                                               ];

        for (Setorizacao__c reservationRegion : listReservation) {

            if (!mapReservationRegion.containsKey(reservationRegion.Conta__c)) {

                mapReservationRegion.put(reservationRegion.Conta__c, new List<String>{reservationRegion.Regiao__c});
                
            }else{

                mapReservationRegion.get(reservationRegion.Conta__c).add(reservationRegion.Regiao__c);
            }
           
        }
       
        System.debug(setIds);
        System.debug(mapReservationRegion);
        return mapReservationRegion;
    }

    public static List<Id> reservationTransfer(List<ProdutoReserva__c> lstReservationTransfer, Set<String> setReceiverReservation, Set<String> setProduct, Boolean isApproved){
        
        List<Reserva__c> lstReceiverReservationProduct = getReservationProductTransfer(setReceiverReservation, setProduct);
        Map<String, ProdutoReserva__c> mapReceiverReservationProduct = new Map<String, ProdutoReserva__c>();
        List<ProdutoReserva__c> lstInsertReservationProductReceiver = new List<ProdutoReserva__c>();
        ProdutoReserva__c productReceiver = new ProdutoReserva__c();
        List<Id> lstReservationIntegration = new List<Id>();     
        List<FeedItem> lstFeedItem = new List<FeedItem>();
        Map<String,String> mapReservationReceiverName = new Map<String,String>();
        
        System.debug('==== lstReceiverReservationProduct'+lstReceiverReservationProduct);

        if (lstReceiverReservationProduct.size() > 0) {
            
            for (Reserva__c resTransfer : lstReceiverReservationProduct) {

                if (!mapReservationReceiverName.containsKey(resTransfer.Id)) {
                          
                    mapReservationReceiverName.put(resTransfer.Id, resTransfer.Name);
                }

                if (resTransfer.ProdutosReserva__r.size() > 0) {

                    for (ProdutoReserva__c resTransferPd : resTransfer.ProdutosReserva__r) {

                        if (!mapReceiverReservationProduct.containsKey(resTransferPd.Reserva__c+'-'+resTransferPd.Produto__c)) {
                            mapReceiverReservationProduct.put(resTransferPd.Reserva__c+'-'+resTransferPd.Produto__c, resTransferPd);
                        }                      

                    }                    
                }                
            }
        }       

        for (ProdutoReserva__c res : lstReservationTransfer) {
           
            if (!mapReceiverReservationProduct.containsKey(res.ReservaRecebedora__c+'-'+res.Produto__c) && isApproved) {

                lstInsertReservationProductReceiver.add(createInstanceReservationProduct(res));                    
                
            }else{

                mapReceiverReservationProduct.get(res.ReservaRecebedora__c+'-'+res.Produto__c).QuantidadeReservada__c += res.QuantidadeTransferida__c;

                if (!isApproved) {
                    
                    mapReceiverReservationProduct.get(res.ReservaRecebedora__c+'-'+res.Produto__c).StatusReserva__c = 'Ativa';

                }else{

                    mapReceiverReservationProduct.get(res.ReservaRecebedora__c+'-'+res.Produto__c).StatusReserva__c = 'Aguardando integração';
                }
                

                if (mapReceiverReservationProduct.get(res.ReservaRecebedora__c+'-'+res.Produto__c).StatusReserva__c != 'Aguardando aprovação') {
                    
                    lstReservationIntegration.add(mapReceiverReservationProduct.get(res.ReservaRecebedora__c+'-'+res.Produto__c).Id);
                }
            }            

            lstFeedItem.add(createChatterReservationList(res, mapReservationReceiverName.get(res.ReservaRecebedora__c),isApproved));
            mapReceiverReservationProduct.put(res.Reserva__c+'-'+res.Produto__c, updateTransferQuantity(res));
        }

        if (lstInsertReservationProductReceiver.size() > 0) {
            
            insertReservationProductTransfer(lstInsertReservationProductReceiver);
        }
        
        if (lstFeedItem.size() > 0) {
           insert lstFeedItem;
        }
        
        System.debug(mapReceiverReservationProduct.values());
        update mapReceiverReservationProduct.values();

        return lstReservationIntegration;

    }

    public static ProdutoReserva__c createInstanceReservationProduct(ProdutoReserva__c res){
        
        ProdutoReserva__c productReceiver = new ProdutoReserva__c();
        productReceiver.Reserva__c = res.ReservaRecebedora__c;
        productReceiver.Produto__c = res.Produto__c;
        productReceiver.QuantidadeReservada__c = res.QuantidadeTransferida__c;
        // productReceiver.QuantidadeAtiva__c = res.QuantidadeAtiva__c;
        productReceiver.QuantidadeAtiva__c = 0;
        productReceiver.Armazem__c = res.Armazem__c;
        productReceiver.Preco__c = res.Preco__c;
        productReceiver.StatusReserva__c = 'Aguardando integração';

        return productReceiver;

    }

    public static void insertReservationProductTransfer(List<ProdutoReserva__c> lstInsertProductReceiver){

        insert lstInsertProductReceiver; 
    }

    public static List<Reserva__c> getReservationProductTransfer(Set<String> setReceiverReservation, Set<String> setProduct){

        return  [
                    SELECT Id, Name, CodigoReserva__c, CodigoCD__c, (SELECT Id, Reserva__c, QuantidadeTransferida__c, QuantidadeReservada__c, StatusReserva__c, Produto__c FROM ProdutosReserva__r WHERE Produto__c IN:setProduct)
                    FROM Reserva__c 
                    WHERE Id IN: setReceiverReservation 
                ];
    }

    public static ProdutoReserva__c updateTransferQuantity(ProdutoReserva__c res){        
      
        ProdutoReserva__c productReceiver = new ProdutoReserva__c();
        productReceiver.Id = res.Id;
        productReceiver.QuantidadeReservada__c = res.QuantidadeReservada__c;
        productReceiver.QuantidadeReservada__c -= res.QuantidadeTransferida__c;
        productReceiver.QuantidadeTransferida__c = null;
        productReceiver.ReservaRecebedora__c = null;
       
        return productReceiver;
    }

    public static FeedItem createChatterReservationList(ProdutoReserva__c reservationsender, String nameReservationReceiver, Boolean isApproved){

        String bodyMsg = isApproved ?'.\nQuantidade transferida: '+String.valueOf(reservationsender.QuantidadeTransferida__c.setScale(0))  :' não foi aprovada.';
        FeedItem feed = new FeedItem();
        feed.ParentId = reservationsender.Reserva__c;  
        feed.Body     = 'Transferência realizada do produto '+ reservationsender.CodigoProduto__c  +' para a reserva '+ nameReservationReceiver+ bodyMsg;

        return feed;
    }

    public static void updateLastDateReservationMovement(Map<Id, ProdutoReserva__c> mapReservation, Map<Id, ProdutoReserva__c> mapReservationOld){
       
        for (ProdutoReserva__c productReservation : mapReservation.values()) {
            
            ProdutoReserva__c oldProdutoReserva = mapReservationOld.get(productReservation.Id);

            if (productReservation.QuantidadeConsumida__c != oldProdutoReserva.QuantidadeConsumida__c) {
                
                productReservation.DataUltimaMovimentacao__c = System.now();
            }
           
        }     
    }

    
    public static void populateChaveUnica(List<ProdutoReserva__c> newRecordList){

        Set<String> setReservation = new Set<String>();
        List<Reserva__c> lstreservation = new List<Reserva__c>();
        Map<String, String> mapProd = new Map<String, String>();
        Map<Id, Product2> mapProductcode = new Map<Id, Product2>();

        System.debug(newRecordList);

        for (ProdutoReserva__c produtoReserva : newRecordList) {

            setReservation.add(produtoReserva.Reserva__c);
            mapProd.put(produtoReserva.Produto__c, '');
            
        }

        mapProductcode = new Map<ID, Product2>([SELECT Id, ProductCode FROM Product2 WHERE Id IN: mapProd.keySet()]);


        for (Product2 pd : mapProductcode.values()) {

            mapProd.put(pd.Id, pd.ProductCode);
            
        }

        lstreservation = getReservationProductTransfer(setReservation, mapProd.keySet());

        for (ProdutoReserva__c produtoReserva : newRecordList) {

            for (Reserva__c reserva : lstreservation) {
                System.debug('=============== '+reserva.CodigoReserva__c);
                System.debug('=============== '+produtoReserva.ChaveUnica__c);

                if (produtoReserva.Reserva__c == reserva.Id && (String.isBlank(produtoReserva.ChaveUnica__c) || produtoReserva.ChaveUnica__c == null)) {
                    
                    produtoReserva.ChaveUnica__c = reserva.CodigoReserva__c + mapProd.get(produtoReserva.Produto__c) + produtoReserva.Armazem__c;
                }
            
            }
            
        }

    }
}