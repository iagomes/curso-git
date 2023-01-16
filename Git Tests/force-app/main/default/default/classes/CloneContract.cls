public without sharing class CloneContract {

    @InvocableMethod(label='Clone Contract' 
                    description='Button to clone the contract and its items')
    public static List<String> flowCloneContract(List<FlowInputs> flowInputs) {
        Id contractId = null;
        Id accountId = null;
        Date vigenciaInicial = null;
        Date vigenciaFinal = null;
        for (FlowInputs flowInput : flowInputs) {
            contractId = flowInput.contractId;
            accountId = flowInput.accountId;
            vigenciaInicial = flowInput.vigenciaInicial;
            vigenciaFinal = flowInput.vigenciaFinal;
        }

        Contract contextContract = null;
        for (Contract o : [SELECT Id, AccountId, CNPJ__c, CodigoCliente__c, CodigoLoja__c, LojaCliente__c, RecordTypeId, TipoRegra__c
                           FROM Contract WHERE Id = :contractId]) {
            
            contextContract = o;
        }
        Contract newContract = new Contract();
        if (contextContract != null) {
            newContract.Status                      = 'Rascunho';
            newContract.AccountId                   = accountId;
            newContract.RecordTypeId                = contextContract.RecordTypeId;
            newContract.TipoRegra__c                = contextContract.TipoRegra__c;

            try {
                insert newContract;
            } catch (DmlException de) {
                throw new ContractException(de.getDmlMessage(0));
            }
            

            List<ItemContrato__c> newContractLineItemList = new List<ItemContrato__c>();

            for (ItemContrato__c oLineItem : [SELECT Id, AccountId__c, CodigoProduto__c, Fornecedor__c, Lote__c, Margem__c, NomeProduto__c, NumeroContrato__c, PrecoMinimo__c, 
                                                PrecoUnitario__c, PrincipioAtivoProduto__c, Quantidade__c, Status__c, ValidadeLote__c, VigenciaFinal__c, VigenciaInicial__c, PercentualDescontoBoleto__c  
                                             FROM ItemContrato__c WHERE NumeroContrato__c = :contextContract.Id]) {
            
            ItemContrato__c newContractLineItem = new ItemContrato__c();
            newContractLineItem.Lote__c                     = oLineItem.Lote__c;
            newContractLineItem.Margem__c                   = oLineItem.Margem__c;
            newContractLineItem.NomeProduto__c              = oLineItem.NomeProduto__c;
            newContractLineItem.NumeroContrato__c           = newContract.Id;
            newContractLineItem.PrecoMinimo__c              = oLineItem.PrecoMinimo__c;
            newContractLineItem.PrecoUnitario__c            = oLineItem.PrecoUnitario__c;
            newContractLineItem.Quantidade__c               = oLineItem.Quantidade__c;
            newContractLineItem.Status__c                   = 'Rascunho';
            newContractLineItem.ValidadeLote__c             = oLineItem.ValidadeLote__c;
            newContractLineItem.VigenciaFinal__c            = vigenciaFinal;
            newContractLineItem.VigenciaInicial__c          = vigenciaInicial;
            newContractLineItem.PercentualDescontoBoleto__c = oLineItem.PercentualDescontoBoleto__c;

            newContractLineItemList.add(newContractLineItem);
            }

            if (!newContractLineItemList.isEmpty()){
                insert newContractLineItemList;
            }
        }

        return new List<String>{newContract.Id};
    }

    public class FlowInputs{

        @InvocableVariable
        public String contractId;
        
        @InvocableVariable
        public String accountId;
        
        @InvocableVariable
        public Date vigenciaInicial;
        
        @InvocableVariable
        public Date vigenciaFinal;
    }

    public class ContractException extends Exception {}
}