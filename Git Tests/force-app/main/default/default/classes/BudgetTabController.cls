global without sharing class BudgetTabController {

    
    @AuraEnabled
    public static StandardResponse doSearch(String filtersJson){
        StandardResponse response = new StandardResponse();
        try {
            System.debug('filtersJson:::' + filtersJson);
            BudgetSearchDTO paramsDTO = BudgetSearchDTO.parse(filtersJson);
            System.debug('paramsDTO:::' + JSON.serializePretty(paramsDTO));

            //gambiarra pra fazer mais filtro, e vai aumentando a gambiarra >:(
            if(
                (paramsDTO.produto != null && paramsDTO.produto != '') || 
                (paramsDTO.categoriaSelected != null && !paramsDTO.categoriaSelected.isEmpty())
            ){
                Set<Id> oppIds = paramsDTO.toMap().keySet();
                paramsDTO.listOppId = oppIds;
            }
            Integer count = paramsDTO.toCount();
            System.debug('count:::' + count);
            List<Opportunity> lstQuotes = (List<Opportunity>) paramsDTO.toList();
            System.debug('records:::' + lstQuotes);
            
            response.setData('count', count);
            response.setData('records', lstQuotes);
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse getFixedFilters(){
        StandardResponse response = new StandardResponse();
        try{
            List<UserCustomization__c> userCustomizationList = [
                SELECT Id, Name, BudgetTabFilters__c, StandardFilter__c
                FROM UserCustomization__c 
                WHERE StandardFilter__c = true 
                OR User__c = :UserInfo.getUserId()
            ];

            User currentUser = [
                SELECT Id,
                PinnedCustomFilter__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            Map<String, Object> fixedFilters = new Map<String, Object>();
            List<FixedFilterOption> fixedFiltersOptions = new List<FixedFilterOption>();
            for(UserCustomization__c custom : userCustomizationList){

                fixedFilters.put(custom.Id, JSON.deserializeUntyped(custom.BudgetTabFilters__c));
                fixedFiltersOptions.add(new FixedFilterOption(custom.Id, custom.Name, custom.StandardFilter__c, false));
            }

            response.setData('fixedFiltersOptions', JSON.serialize(fixedFiltersOptions));
            response.setData('fixedFilters', JSON.serialize(fixedFilters));
            response.setData('pinnedFilter', currentUser.PinnedCustomFilter__c);
        }catch(Exception e){
            ExceptionUtils.debug(e);
            response.addError(e.getMessage());
        }
        return response;
    }
    
    @AuraEnabled
    public static StandardResponse saveFixFilter(String filterName, String filterParams){
        StandardResponse response = new StandardResponse();
        try{
            if(String.isEmpty(filterName)){
                response.addError('Adicione um nome ao filtro antes de salvar');
                return response;
            }
            UserCustomization__c userCust = new UserCustomization__c(
                Name = filterName,
                BudgetTabFilters__c = filterParams,
                StandardFilter__c = false,
                User__c = UserInfo.getUserId()   
            );
            insert userCust;
        }catch(Exception e){
            ExceptionUtils.debug(e);
            response.addError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse deleteFixedFilters(List<String> filtersList){
        StandardResponse response = new StandardResponse();
        try {
            Database.delete(filtersList);

        } catch (Exception e) {
            ExceptionUtils.debug(e);
            response.addError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse updatePinnedCustomFilter(String filterId){
        StandardResponse response = new StandardResponse();
        try {
            update new User(Id=UserInfo.getUserId(), PinnedCustomFilter__c = filterId);
        } catch (Exception e) {
            ExceptionUtils.debug(e);
            response.addError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse getUserOrders(){
        StandardResponse response = new StandardResponse();
        try{
            Integer orderCount = 0;
            for(List<Order> ordersList : [
                SELECT Id 
                FROM Order 
                WHERE Status = 'Em digitação' 
                AND OpportunityId IN (SELECT OpportunityId FROM OpportunityTeamMember WHERE UserId = :UserInfo.getUserId()) 
                LIMIT 49999
            ]){
                orderCount += ordersList.size();
            }
            
            response.setData(orderCount);

        }catch(Exception e){
            ExceptionUtils.debug(e);
            response.addError(e.getMessage());
        }
        return response;
    }
    
    //BudgetTabFilters:
    @AuraEnabled
    public static StandardResponse getUsersPicklist(){
        StandardResponse response = new StandardResponse();
        Set<String> busList = new Set<String>();
        List<PicklistOption> userVDEPicklist = new List<PickListOption>();
        List<PicklistOption> userVDIPicklist = new List<PickListOption>();
        try{
            List<Setorizacao__c> setorBusList = [
                SELECT Categoria__c FROM Setorizacao__c WHERE VendedorSuporte__c =: UserInfo.getUserId()
            ];
            
            for(Setorizacao__c setor: setorBusList){
                busList.add(setor.Categoria__c);
            }
            
            Map<Id, User> sameBuVDE = new Map<Id, User>((List<User>)new QueryBuilder('User')
                .addFields(new List<String>{'Id','Name'})
                .addConditions()
                .add(vendedorConditions('Vendedor__c',busList))
                .endConditions()
                .addOrderAsc('Name')
                .toList()
            );

            Map<Id, User> sameBuVDI = new Map<Id, User>((List<User>)new QueryBuilder('User')
                .addFields(new List<String>{'Id','Name'})
                .addConditions()
                .add(vendedorConditions('VendedorSuporte__c',busList))
                .endConditions()
                .addOrderAsc('Name')
                .toList()
            );

            userVDIPicklist.add(new PicklistOption(false,UserInfo.getUserId(),UserInfo.getFirstName()+' '+UserInfo.getLastName()));
            if(!sameBuVDI.isEmpty()){
                
                sameBuVDI.remove(UserInfo.getUserId());
                for(User user : sameBuVDI.values()){
                    userVDIPicklist.add(new PicklistOption(false, user.Id, user.Name));
                }
            }

            userVDEPicklist.add(new PicklistOption(false,UserInfo.getUserId(),UserInfo.getFirstName()+' '+UserInfo.getLastName()));
            if(!sameBuVDE.isEmpty()){
                
                sameBuVDE.remove(UserInfo.getUserId());
                for(User user : sameBuVDE.values()){
                    userVDEPicklist.add(new PicklistOption(false, user.Id, user.Name));
                }
            }
            response.setData('vdi',JSON.serialize(userVDIPicklist));
            response.setData('vde',JSON.serialize(userVDEPicklist));

        }catch(Exception e){
            System.debug(e.getMessage());
            response.addError(e.getMessage());
        }
        
        return response;
    }

    public static QueryBuilder.ComplexCondition vendedorConditions(String vendedorType, Set<String> buList){

        QueryBuilder.ComplexCondition vdeConditions = new QueryBuilder.ComplexCondition();

        vdeConditions.ignoreConditionsForNullValues().andCondition(
            new QueryBuilder.InCondition('Id').ignoreConditionsForNullValues().inCollection(
                new QueryBuilder('Setorizacao__c')
                    .addFields(new List<String>{vendedorType})
                    .addConditions()
                    .add(
                        new QueryBuilder.InCondition('Categoria__c').ignoreConditionsForNullValues().inCollection(buList)
                    )
                    .endConditions()
            )
        );
        return vdeConditions;
    }  

    @AuraEnabled
    public static StandardResponse getMesa(){
        StandardResponse response = new StandardResponse();
        Map<String, String> mesas = new Map<String, String>();
        List<PicklistOption> MesaList = new List<PickListOption>();
        try{
            for(List<Setorizacao__c> listSet : [SELECT mesa__c FROM Setorizacao__c WHERE Mesa__c != null LIMIT 5000]){
                for(Setorizacao__c setor : listSet){
                    mesas.put(setor.Mesa__c, null);
                }
            }
            

            for(Integer i = 0; i < 9; i++){
                Boolean shouldBreak = false;
                for(List<Setorizacao__c> listSet : [SELECT mesa__c FROM Setorizacao__c WHERE Mesa__c NOT IN :mesas.keySet() AND Mesa__c != null LIMIT 5000]){
                    
                    for(Setorizacao__c setor : listSet){
                        mesas.put(setor.Mesa__c, null);
                    }
                    
                    if(listSet.isEmpty()){
                        shouldBreak = true;
                        break;
                    }
                }
                if (shouldBreak) break;
            }

            for (String m : mesas.keySet()){
                MesaList.add(new PicklistOption(false, m, m));
            }
            response.setData(JSON.serialize(MesaList));
        }catch(Exception e){
            System.debug(e.getMessage());
            response.addError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse getCategoria(){
        StandardResponse response = new StandardResponse();
        Set<String> categorias = new Set<String>();
        List<PicklistOption> categoriaList = new List<PickListOption>();
        try{
            for(List<QuoteItem__c> quoteItemList : [SELECT CategoriaCliente__c FROM QuoteItem__c WHERE CategoriaCliente__c != null LIMIT 5000]){
                for(QuoteItem__c qItem : quoteItemList){
                    categorias.add(qItem.CategoriaCliente__c);
                }
            }

            for(Integer i = 0; i < 9; i++){
                Boolean shouldBreak = false;
                for(List<QuoteItem__c> qitemList : [SELECT CategoriaCliente__c FROM QuoteItem__c WHERE CategoriaCliente__c != null AND CategoriaCliente__c NOT IN :categorias LIMIT 5000]){
                    
                    for(QuoteItem__c qItem : qitemList){
                        categorias.add(qItem.CategoriaCliente__c);
                    }
                    if(qitemList.isEmpty()){
                        shouldBreak = true;
                        break;
                    }
                }
                if (shouldBreak) break;
            }

            for (String cat : categorias){
                categoriaList.add(new PicklistOption(false, cat, cat));
            }
            response.setData(JSON.serialize(categoriaList));
        }catch(Exception e){
            System.debug(e.getMessage());
            response.addError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse getVendedor(List<String> userCodeList){
        StandardResponse response = new StandardResponse();
        List<PicklistOption> vendedorList = new List<PickListOption>();
        try{
            List<User> usersList = [
                SELECT CodigoUsuario__c, Name
                FROM User
                WHERE CodigoUsuario__c IN :userCodeList
            ];

            for(User user : usersList){
                vendedorList.add(new PicklistOption(true, user.CodigoUsuario__c, user.Name));
            }
            System.debug(vendedorList);
            response.setData(JSON.serialize(vendedorList));
        }catch(Exception e){
            System.debug(e.getMessage());
            response.addError(e.getMessage());
        }
        System.debug(response);
        return response;
    }

    public class PicklistOption {
        public Boolean selected {get; set;}
        public String value {get; set;}
        public String data {get; set;}
        
        public PicklistOption(Boolean slc,String param1, String param2 ){
            this.selected = slc;
            this.value = param1;
            this.data = param2;
        }
    }

    public class FixedFilterOption{
        public String value {get; set;}
        public String label {get; set;}
        public Boolean standard {get; set;}
        public Boolean isSelected {get; set;}

        public FixedFilterOption(String value, String label, Boolean standard, Boolean isSelected){
            this.value = value;
            this.label = label;
            this.standard = standard;
            this.isSelected = isSelected;
        }
    }
}
