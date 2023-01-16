public without sharing class BudgetSearchDTO {

    public Boolean nullsLast {get{return this.nullsLast == null ? true : this.nullsLast;}set;}

    public Set<Id> listOppId                            { get; set; }
    public List<String> statusSearch                    { get; set; }
    public List<String> canalEntradaSelected            { get; set; }
    public List<String> vendedorSelected                { get; set; }
    public List<String> teamMember                      { get; set; }
    public String quoteIntegratorId                     { get; set; }
    public String quoteType                             { get; set; }
    public String cnpjCliente                           { get; set; }
    public String nomeCliente                           { get; set; }
    public List<String> mesaSelected                    { get; set; }
    public List<String> categoriaSelected               { get; set; }
    public String searchText                            { get; set; }
    public String normText                              { get; set; }
    public Decimal searchNumber                         { get; set; }
    public List<String> ufCliente                       { get; set; }
    public List<String> cidadeCliente                   { get; set; }
    public DateRange vencimentoCotacao                  { get; set; }
    public String produto                               { get; set; }
    public Boolean notAnswered                          { get; set; }
    public Set<Id> answeredQuoteIds                     { get; set; }
    public Boolean expired                              { get; set; }
    public Boolean dateSearch                           { get; set; }
    public Boolean hourSearch                           { get; set; }
    public Boolean minuteSearch                         { get; set; }
    public Map<String,String> lastRecord                { get; set; }
    public String orderBy                               = 'DataVencimento__c';
    public String orderDirection                        = 'DESC';
    public Integer itemsPerPage                         = 20;
    public Integer queryLimit {
        get {
            if(this.queryLimit == null){
                this.queryLimit = this.itemsPerPage;
            }
            return this.queryLimit;
        }
        set;
    }

    public List<SObject> toList(){
        QueryBuilder query = new QueryBuilder('Opportunity')
            .addFields(new List<String>{
                'Id', 
                'Amount', 
                'Account.BillingCity', 
                'Account.BillingState', 
                'Account.CNPJ__c', 
                'Account.Name', 
                'AccountId', 
                'CanalEntrada__c', 
                'CloseDate',
                'CNPJ__c', 
                'CreatedDate',
                'DataVencimento__c',
                'IdIntegrator__c', 
                'Name',
                'QuantidadeItensConfirmados__c',
                'QuantidadeItensRespondidos__c',
                'QuantidaItensNaoResp__c',
                'QuantidadeItensTotal__c',
                'NumeroOrcamento__c',
                //'QuoteType__c',
                'StageName', 
                'TotalOpportunityQuantity'
            })
            .addSubQuery(new QueryBuilder('QuoteItems__r').addFields(new List<String>{'Id', 'Product__c','Vendedor__c','Status__c','IdCustomer__c','TabulacaoN1__c'}))
            .addSubQuery(orderSubQuery())
            .addConditions()
            .add(buildConditions(true))
            .endConditions();
        
            
            System.debug(this.orderBy);
            System.debug(this.orderDirection.equals('DESC')? 'DESC' : 'ASC');
            System.debug(this.nullsLast ? 'LAST' : 'FIRST');
        query.addOrder(new QueryBuilder.Order(this.orderBy, this.orderDirection.equals('DESC')? 'DESC' : 'ASC', this.nullsLast ? 'LAST' : 'FIRST'));
        query.addOrder(new QueryBuilder.Order('Id', 'ASC', this.nullsLast ? 'LAST' : 'FIRST'));
        query.setLimit(this.queryLimit);

        return query.toList();
    }

    public Map<Id, SObject> toMap(){
        return new QueryBuilder('Opportunity')
            .addFields(new List<String>{'Id'})
            .addConditions()
            .add(buildConditions(false))
            .endConditions()
            .toMap();
    }

    public Integer toCount(){
        return new QueryBuilder('Opportunity')
            .addConditions()
            .add(buildConditions(false))
            .endConditions()
            .toCount();
    }
    
    public static BudgetSearchDTO parse(String jsonObj){
        BudgetSearchDTO response;
        System.debug('\n\nRequestBody:: ' + jsonObj);

        try {
            response = (BudgetSearchDTO) JSON.deserialize(jsonObj, BudgetSearchDTO.class);
        } catch(Exception ex) {
            System.debug('\n\nRequestBody:: ' + jsonObj);
            throw ex;
        }
        
        Map<String, String> mapNewValues = new Map<String, String>{
            '\\\\' => '',
            '\\\'' => '\\\\\\\''
        };

        response.statusSearch                       = StringUtils.replaceSpecialCharacters(response.statusSearch, mapNewValues);
        response.canalEntradaSelected               = StringUtils.replaceSpecialCharacters(response.canalEntradaSelected, mapNewValues);
        response.vendedorSelected                   = StringUtils.replaceSpecialCharacters(response.vendedorSelected, mapNewValues);
        response.teamMember                         = StringUtils.replaceSpecialCharacters(response.teamMember, mapNewValues);
        response.quoteIntegratorId                  = StringUtils.replaceSpecialCharacters(response.quoteIntegratorId, mapNewValues);
        response.quoteType                          = StringUtils.replaceSpecialCharacters(response.quoteType, mapNewValues);
        response.cnpjCliente                        = StringUtils.replaceSpecialCharacters(response.cnpjCliente, mapNewValues);
        response.mesaSelected                       = StringUtils.replaceSpecialCharacters(response.mesaSelected, mapNewValues);
        response.categoriaSelected                  = StringUtils.replaceSpecialCharacters(response.categoriaSelected, mapNewValues);
        response.nomeCliente                        = StringUtils.replaceSpecialCharacters(response.nomeCliente, mapNewValues);
        response.ufCliente                          = StringUtils.replaceSpecialCharacters(response.ufCliente, mapNewValues);
        response.cidadeCliente                      = StringUtils.replaceSpecialCharacters(response.cidadeCliente, mapNewValues);
        response.searchText                         = StringUtils.replaceSpecialCharacters(response.searchText, mapNewValues);
        response.normText                           = StringUtils.replaceSpecialCharacters(response.normText, mapNewValues);
        response.produto                            = StringUtils.replaceSpecialCharacters(response.produto, mapNewValues);
        

        if(response.teamMember != null  && !response.teamMember.isEmpty()){
            Integer userIndex = response.teamMember.indexOf('userId');
            if(userIndex != -1){
                response.teamMember.remove(userIndex);
                response.teamMember.add(UserInfo.getUserId());
            }
        }else{
            response.teamMember = null;
        }
        
        response.vendedorSelected = response.vendedorSelected != null && response.vendedorSelected.isEmpty() ? null : response.vendedorSelected;
        response.mesaSelected = response.mesaSelected != null && response.mesaSelected.isEmpty() ? null : response.mesaSelected;


        if(response.statusSearch != null){
            Integer statusIndex = response.statusSearch.indexOf('Encerrado');
            if(statusIndex != -1){
                response.statusSearch.remove(statusIndex);
                response.statusSearch.add('Fechado/Ganho');
                response.statusSearch.add('Fechado/Perdido');
            }

        }

        if(response.searchText != null){

            response.searchNumber = StringUtils.transformToNumber(response.searchText);
            response.dateSearch = StringUtils.isDateDDMMYY(response.searchText);
            response.hourSearch = StringUtils.isDateTimeDDMMYYhh(response.searchText);
            response.minuteSearch = StringUtils.isDateTimeDDMMYYhhmm(response.searchText);
        }

        if(String.isBlank(response.orderBy)){
            response.orderBy = 'DataVencimento__c';
        }

        if(String.isBlank(response.orderDirection)){
            response.orderDirection = 'DESC';
        } else {
            response.orderDirection = response.orderDirection.toUpperCase();
        }

        response.expired = response.expired == true;
        response.notAnswered = response.notAnswered == true;

        return response;
    }

    public QueryBuilder orderSubQuery(){
        return new QueryBuilder('Orders')
            .addFields(new List<String>{'Id', 'Status'})
            .addConditions()
            .add(new QueryBuilder.CompareCondition('RecordType.Name').eq('Pedido pai'))
            .endConditions();
    }

    public QueryBuilder.ComplexCondition buildConditions(Boolean addLimit){
        if(this.listOppId != null && !this.listOppId.isEmpty()){
            QueryBuilder.ComplexCondition result = new QueryBuilder.ComplexCondition();
                
            result.andCondition(
                new QueryBuilder.InCondition('Id').inCollection(queryQuoteItems())
            )
            .andCondition(
                new QueryBuilder.InCondition('Id').ignoreConditionsForNullValues().inCollection(this.listOppId)
            );

            if(addLimit && this.lastRecord != null && !this.lastRecord.isEmpty()){
                String lastValue = this.lastRecord.get('value');
                String lastId = this.lastRecord.get('id');
                String fieldType = SObjectUtils.getFieldType('Opportunity', this.orderBy);
                Boolean isDesc = this.orderDirection.equals('DESC');
                System.debug('lastValue$: '+lastValue);
                System.debug('lastId$: '+lastId);
                QueryBuilder.ComplexCondition ordByLimit = new QueryBuilder.ComplexCondition();
                if(this.nullsLast){
                    if(String.isNotBlank(lastId) && lastValue != null){
                        if(isDesc){
                            ordByLimit.orCondition(new QueryBuilder.CompareCondition(this.orderBy).lt(lastValue, this.orderBy, 'Opportunity'));
                        }else{
                            ordByLimit.orCondition(new QueryBuilder.CompareCondition(this.orderBy).gt(lastValue, this.orderBy, 'Opportunity'));
                        }
                        ordByLimit.orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.NullCondition(this.orderBy).isNull())
                            .andCondition(new QueryBuilder.CompareCondition('Id').gt(lastId))
                        );
                        ordByLimit.orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.CompareCondition(this.orderBy).eq(lastValue, this.orderBy, 'Opportunity'))
                            .andCondition(new QueryBuilder.CompareCondition('Id').gt(lastId))
                        );
                    }
                    else if(String.isNotEmpty(lastId)){
                        ordByLimit.andCondition(new QueryBuilder.CompareCondition('Id').gt(lastId));
                        ordByLimit.andCondition(new QueryBuilder.NullCondition(this.orderBy).isNull());
                    }
                    result.andCondition(ordByLimit);
                }
            }
            
            return result;
        }

        QueryBuilder.ComplexCondition result = 
            new QueryBuilder.ComplexCondition()
                .andCondition(
                    new QueryBuilder.LikeCondition('QuoteType__c').ignoreConditionsForNullValues().likeAnyBoth(this.quoteType)
                )
                .andCondition(
                    new QueryBuilder.InCondition('Account.BillingCity').ignoreConditionsForNullValues().inCollection(this.cidadeCliente)
                )
                .andCondition(
                    new QueryBuilder.InCondition('Account.BillingState').ignoreConditionsForNullValues().inCollection(this.ufCliente)
                )
                .andCondition(
                    new QueryBuilder.LikeCondition('Account.Name').ignoreConditionsForNullValues().likeAnyBoth(this.nomeCliente)
                )
                .andCondition(
                    new QueryBuilder.InCondition('StageName').ignoreConditionsForNullValues().inCollection(this.statusSearch)//convertListToSet
                )
                .andCondition(
                    new QueryBuilder.InCondition('CanalEntrada__c').ignoreConditionsForNullValues().inCollection(this.canalEntradaSelected)
                )
                .andCondition(
                    new QueryBuilder.CompareCondition('IdIntegrator__c').ignoreConditionsForNullValues().eq(this.quoteIntegratorId)
                )
                .andCondition(
                    new QueryBuilder.ComplexCondition()
                    .orCondition(new QueryBuilder.LikeCondition('Account.CNPJ__c').ignoreConditionsForNullValues().likeAnyBoth(this.cnpjCliente))
                    .orCondition(new QueryBuilder.LikeCondition('CNPJClienteRecebedor__c').ignoreConditionsForNullValues().likeAnyBoth(this.cnpjCliente))
                );
                
                if(this.notAnswered){
                    result.andCondition(
                        new QueryBuilder.InCondition('Id').notIn(
                            new QueryBuilder('OpportunityTeamMember')
                            .addFields(new List<String>{'OpportunityId'})
                            .addConditions()
                            .add(
                                new QueryBuilder.ComplexCondition()
                                .andCondition(
                                new QueryBuilder.CompareCondition('QuoteIsAnswered__c').ignoreConditionsForNullValues().eq(true))
                                .andCondition(
                                new QueryBuilder.CompareCondition('UserId').ignoreConditionsForNullValues().eq(UserInfo.getUserId()))
                            )
                            .endConditions()
                        )
                    );
                }
                if((this.mesaSelected != null && !this.mesaSelected.isEmpty()) || (this.teamMember != null && !this.teamMember.isEmpty()) || (this.vendedorSelected != null && !this.vendedorSelected.isEmpty())){
                    result.andCondition(
                        new QueryBuilder.InCondition('AccountId')
                        .inCollection(
                            new QueryBuilder('Setorizacao__c')
                                .addFields(new List<String>{'Conta__c'})
                                .addConditions()
                                .add(
                                    new QueryBuilder.ComplexCondition()
                                    .andCondition(new QueryBuilder.InCondition('Mesa__c').ignoreConditionsForNullValues().inCollection(this.mesaSelected))
                                    .andCondition(new QueryBuilder.InCondition('VendedorSuporte__c').ignoreConditionsForNullValues().inCollection(this.teamMember))
                                    .andCondition(new QueryBuilder.InCondition('Vendedor__c').ignoreConditionsForNullValues().inCollection(this.vendedorSelected))
                                )
                                .endConditions()
                            )
                    );
                }


                if(this.mesaSelected != null && !this.mesaSelected.isEmpty()){
                    result.andCondition(
                    new QueryBuilder.InCondition('AccountId')
                    .inCollection(
                        new QueryBuilder('Setorizacao__c')
                            .addFields(new List<String>{'Conta__c'})
                            .addConditions()
                            .add(new QueryBuilder.InCondition('Mesa__c')
                            .inCollection(this.mesaSelected))
                            .endConditions()
                        )
                    );
                }
                

            if(this.vencimentoCotacao != null && this.vencimentoCotacao.isNotEmpty()){
                System.debug('this.vencimentoCotacao:::' + JSON.serializePretty(this.vencimentoCotacao));
                result.andCondition(this.vencimentoCotacao.toQueryBuilderCondition('DataVencimento__c'));
            }else if(this.expired){
                result.andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').lte(Datetime.now()));
            }else{
                result.andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').gte(Datetime.now()));
            }
            if(this.orderBy.toLowerCase() == 'lastvieweddate'){
                result.andCondition(new QueryBuilder.CompareCondition(this.orderBy).gt(Datetime.now().addDays(-15)));
            }

            if(this.searchText != null && this.searchText != '' && this.searchText.length() >= 4){
                if(this.dateSearch != null && this.dateSearch){
                result.andCondition(
                    new QueryBuilder.ComplexCondition()
                    .orCondition(
                        new QueryBuilder.ComplexCondition()
                        .andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').lte(Datetime.parse(this.searchText+' 00:00').addMinutes(-1)+1))
                        .andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').gte(Datetime.parse(this.searchText+' 00:00')))
                    )
                    .orCondition(
                        new QueryBuilder.ComplexCondition()
                        .andCondition(new QueryBuilder.CompareCondition('CreatedDate').gte(Datetime.parse(this.searchText+' 00:00')))
                        .andCondition(new QueryBuilder.CompareCondition('CreatedDate').lte(Datetime.parse(this.searchText+' 00:00').addMinutes(-1)+1)) 
                    )
                );
                }else if(this.hourSearch != null && this.hourSearch){
                    result.andCondition(
                        new QueryBuilder.ComplexCondition()
                        .orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').gte(Datetime.parse(this.searchText+':00')))
                            .andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').lte(Datetime.parse(this.searchText+':00').addHours(1).addMinutes(-1)))
                        )
                        .orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.CompareCondition('CreatedDate').gte(Datetime.parse(this.searchText+':00')))
                            .andCondition(new QueryBuilder.CompareCondition('CreatedDate').lte(Datetime.parse(this.searchText+':00').addHours(1).addMinutes(-1)))     
                        )
                    );
                }else if(this.minuteSearch!= null && this.minuteSearch){
                    result.andCondition(
                        new QueryBuilder.ComplexCondition()
                        .orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').gte(Datetime.parse(this.searchText)))
                            .andCondition(new QueryBuilder.CompareCondition('DataVencimento__c').lte(Datetime.parse(this.searchText).addMinutes(1)))
                        )
                        .orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.CompareCondition('CreatedDate').gte(Datetime.parse(this.searchText)))
                            .andCondition(new QueryBuilder.CompareCondition('CreatedDate').lte(Datetime.parse(this.searchText).addMinutes(1)))
                        )
                    );
                } else{
                    String normTextUP = String.isNotBlank(this.normText) ? this.normText.toUpperCase() : null;
                    QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition()
                        .orCondition(new QueryBuilder.LikeCondition('StageName').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('QuoteType__c').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('QuoteType__c').ignoreConditionsForNullValues().likeAnyBoth(this.normText))
                        .orCondition(new QueryBuilder.LikeCondition('Account.BillingCity').ignoreConditionsForNullValues().likeAnyBoth(normTextUP))
                        .orCondition(new QueryBuilder.LikeCondition('Account.CNPJ__c').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('Account.Name').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('Account.Name').ignoreConditionsForNullValues().likeAnyBoth(normTextUP))
                        .orCondition(new QueryBuilder.LikeCondition('CanalEntrada__c').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('CNPJ__c').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('IdIntegrator__c').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('Name').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('Name').ignoreConditionsForNullValues().likeAnyBoth(normTextUP))
                        .orCondition(new QueryBuilder.LikeCondition('NumeroOrcamento__c').ignoreConditionsForNullValues().likeAnyBoth(this.searchText))
                        .orCondition(new QueryBuilder.LikeCondition('NumeroOrcamento__c').ignoreConditionsForNullValues().likeAnyBoth(normTextUP));
                        
                        if(this.searchNumber != null){
                            complex.orCondition(new QueryBuilder.CompareCondition('Amount').ignoreConditionsForNullValues().eq(this.searchNumber));
                        }
                    result.andCondition(complex);
                }
            }

            if(addLimit && this.lastRecord != null && !this.lastRecord.isEmpty()){
                String lastValue = this.lastRecord.get('value');
                String lastId = this.lastRecord.get('id');
                String fieldType = SObjectUtils.getFieldType('Opportunity', this.orderBy);
                Boolean isDesc = this.orderDirection.equals('DESC');
                System.debug('lastValue$: '+lastValue);
                System.debug('lastId$: '+lastId);
                QueryBuilder.ComplexCondition ordByLimit = new QueryBuilder.ComplexCondition();
                if(this.nullsLast){
                    if(String.isNotBlank(lastId) && lastValue != null){
                        if(isDesc){
                            ordByLimit.orCondition(new QueryBuilder.CompareCondition(this.orderBy).lt(lastValue, this.orderBy, 'Opportunity'));
                        }else{
                            ordByLimit.orCondition(new QueryBuilder.CompareCondition(this.orderBy).gt(lastValue, this.orderBy, 'Opportunity'));
                        }
                        ordByLimit.orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.NullCondition(this.orderBy).isNull())
                            .andCondition(new QueryBuilder.CompareCondition('Id').gt(lastId))
                        );
                        ordByLimit.orCondition(
                            new QueryBuilder.ComplexCondition()
                            .andCondition(new QueryBuilder.CompareCondition(this.orderBy).eq(lastValue, this.orderBy, 'Opportunity'))
                            .andCondition(new QueryBuilder.CompareCondition('Id').gt(lastId))
                        );
                    }
                    else if(String.isNotEmpty(lastId)){
                        ordByLimit.andCondition(new QueryBuilder.CompareCondition('Id').gt(lastId));
                        ordByLimit.andCondition(new QueryBuilder.NullCondition(this.orderBy).isNull());
                    }
                    result.andCondition(ordByLimit);
                }
            }
        return result;
    }

    public QueryBuilder queryQuoteItems(){
        
        QueryBuilder.ComplexCondition qitemConditions = new QueryBuilder.ComplexCondition()
        .andCondition(
            new QueryBuilder.InCondition('OpportunityId__c').inCollection(this.listOppId)
        );

        if(String.isNotBlank(this.produto)){
            qitemConditions.andCondition(
                new QueryBuilder.ComplexCondition()
                .orCondition(
                    new QueryBuilder.LikeCondition('Product__r.Name').likeAnyBoth(this.produto)
                )
                .orCondition(
                    new QueryBuilder.LikeCondition('Product__r.ProductCode').likeAnyBoth(this.produto)
                )
            );
        }

        if(this.categoriaSelected != null && !this.categoriaSelected.isEmpty()){
            qitemConditions.andCondition(
                new QueryBuilder.InCondition('CategoriaCliente__c').inCollection(this.categoriaSelected)
            );
        }

        QueryBuilder qitemQuery = new QueryBuilder('QuoteItem__c')
            .addFields(new List<String>{'OpportunityId__c'})
            .addConditions().add(qitemConditions).endConditions();
        return qitemQuery;
    }

    public class DateRange {
        public String date1                       { get; set; }
        public String date2                       { get; set; }
        public Boolean yesterday                  { get; set; } 
        public Integer last_n_days                { get; set; }

        public DateRange(Boolean yesterday){
            this.yesterday = yesterday;     
           }

        public QueryBuilder.ComplexCondition toQueryBuilderCondition(String fieldName){
            Date today = System.today();
            
            QueryBuilder.ComplexCondition result = new QueryBuilder.ComplexCondition();
            if(this.date1 != null || this.date2 != null){
                if(this.date1 != null){
                    result.andCondition(new QueryBuilder.CompareCondition(fieldName).gte(this.date1, fieldName, 'Opportunity'));
                }
                if(this.date2 != null){
                    result.andCondition(new QueryBuilder.CompareCondition(fieldName).lte(this.date2, fieldName, 'Opportunity'));
                }
            } else if(this.last_n_days == 0){
                result.andCondition(new QueryBuilder.CompareCondition(fieldName).lte(today-1, fieldName, 'Opportunity'));
                result.andCondition(new QueryBuilder.CompareCondition(fieldName).gte(today, fieldName, 'Opportunity'));
            }else if(this.last_n_days != null){
                result.andCondition(new QueryBuilder.CompareCondition(fieldName).lte(today, fieldName, 'Opportunity'));
                result.andCondition(new QueryBuilder.CompareCondition(fieldName).gte(today-this.last_n_days, fieldName, 'Opportunity'));
            } else if(this.yesterday == true){
                result.andCondition(new QueryBuilder.CompareCondition(fieldName).lte(today, fieldName, 'Opportunity'));
                result.andCondition(new QueryBuilder.CompareCondition(fieldName).gte(today-1, fieldName, 'Opportunity'));
            }
            
            System.debug('result:::' + JSON.serializePretty(result));
            System.debug('ComplexCondition:::' + JSON.serializePretty(this));
            return result;
        }

        public Boolean isNotEmpty(){
            return this.date1 != null || this.date2 != null || this.last_n_days != null || (this.yesterday == true);
        }
    }

}