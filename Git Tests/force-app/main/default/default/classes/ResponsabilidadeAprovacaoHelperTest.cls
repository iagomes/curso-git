@isTest
public with sharing class ResponsabilidadeAprovacaoHelperTest {
   
    public static final Id MOTHERORDER_RECORDTYPE  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId(); 
    public static final Id DIRECT_ORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId(); 

    @TestSetup
    static void makeData(){       
      
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        Order ord1 = TestUtility.createOrder(acc);
        ord1.RecordTypeId = MOTHERORDER_RECORDTYPE;
        ord1.AprovadoComercial__c = false;
        ord1.AprovadoPricing__c   = false;
        ord1.RejeicaoProcesso__c  = false;
        insert ord1;
        
        Order ord2 = TestUtility.createOrder(acc);
        ord2.RecordTypeId = DIRECT_ORDER_RECORDTYPE;
        ord2.AprovadoComercial__c = false;
        ord2.AprovadoPricing__c   = false;
        ord2.RejeicaoProcesso__c  = false;
        ord2.PedidoPai__c = ord1.Id;
        insert ord2;

        Id pricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id][0].Id;

        List<OrderItem> listOrderItem = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.orderId          = ord1.Id;
        orderItem1.Product2Id       = prod.Id;
        orderItem1.pricebookEntryId = pricebookEntryId;
        orderItem1.Quantity         = 5;
        orderItem1.UnitPrice        = 50;
        orderItem1.PrecoTotal__c    = 50;
        orderItem1.Lote__c          = '10';
        orderItem1.TipoOperacao__c  = '11';
        orderItem1.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem1);
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.orderId          = ord2.Id;
        orderItem2.Product2Id       = prod.Id;
        orderItem2.pricebookEntryId = pricebookEntryId;
        orderItem2.Quantity         = 5;
        orderItem2.UnitPrice        = 50;
        orderItem2.PrecoTotal__c    = 50;
        orderItem2.Lote__c          = '10';
        orderItem2.TipoOperacao__c  = '11';
        orderItem2.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem2);
        insert listOrderItem;

        ResponsabilidadeAprovacao__c respAprovacao = new ResponsabilidadeAprovacao__c();
        respAprovacao.UsuarioAprovador__c = UserInfo.getUserId();
        respAprovacao.Categorias__c = 'M';
        respAprovacao.CodigoMesa__c = 'TESTE';
        respAprovacao.Regiao__c ='99';

        insert respAprovacao;

        ResponsabilidadeAprovacao__c respAprovacao2 = new ResponsabilidadeAprovacao__c();
        respAprovacao2.UsuarioAprovador__c = UserInfo.getUserId();      

        insert respAprovacao2;

    }

    @isTest
    public static void createUserTerritoryAssiciation(){       
        
         
        Territory2Model tModel = ActingTableTerritoryManagement.getTerritory2Model('Mesas');
        Territory2Type tType = ActingTableTerritoryManagement.getTerritory2Type('Mesas');
        
        Test.startTest();
        Territory2 t = TestUtility.createTerritory2(tModel.Id, tType.Id);
        insert t;

      
        Test.stopTest();

        UserTerritory2Association userAssociation = new UserTerritory2Association(
            Territory2Id = t.id,
            UserId = UserInfo.getUserId()
        );
        
        insert userAssociation;
        
        List<ResponsabilidadeAprovacao__c> listResp = [SELECT Id, Name, Regiao__c,UsuarioAprovador__c  FROM ResponsabilidadeAprovacao__c];      

        ResponsabilidadeAprovacaoHelper.createUserTerritoryAssiciation( new Map<Id, ResponsabilidadeAprovacao__c>{listResp[0].Id => listResp[0]});
        ResponsabilidadeAprovacaoHelper.createUserTerritoryAssiciation( new Map<Id, ResponsabilidadeAprovacao__c>{listResp[1].Id => listResp[1]});
        ResponsabilidadeAprovacaoHelper.deleteUserTerritoryAssiciation( listResp);
    }
}
