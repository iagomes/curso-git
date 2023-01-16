@IsTest
public with sharing class CalcScoreTest {
    @TestSetup
    static void makeData(){
        CalcScore.CalcData calcData1 = new CalcScore.CalcData('2');
        CalcScore.CalcData calcData2 = new CalcScore.CalcData('3');
    }
    @IsTest
    public static void setupTest() {
        Product2 product                       = TestUtility.createProduct();
        insert product;
        User user                              = TestUtility.createUserTwo();
        insert user;
        Account acc                            = TestUtility.createAccount();
        insert acc;
        Order order                            = TestUtility.createOrderTwo(acc);
        insert order;
        Opportunity opportunity                = TestUtility.createOpportunity(user);
        insert opportunity;
        
        PricebookEntry pricebookEntry          = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        pricebookEntry.UnitPrice               = 1.00;
        pricebookEntry.IsActive                = true;
        update pricebookEntry;

        OpportunityLineItem oportunityLineItem = TestUtility.createOpportunityLineItem(opportunity, product, pricebookEntry);
        insert oportunityLineItem;
        OrderItem orderItem                    = TestUtility.createOrderItem(order, product, pricebookEntry);
        insert orderItem;

        CalcSCore.CalcData calcData3 = new CalcScore.CalcData(oportunityLineItem);
        CalcSCore.CalcData calcData4 = new CalcScore.CalcData(orderItem);
    }

    @IsTest
    public static void calcUnitMgTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        //System.assertEquals(8.42, calcData.calcUnitMg(), 'calcUnitMgTest');
        //calcData.reverseCalc();
    }

    @IsTest
    public static void calcListMgTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        //System.assertEquals(14.67, calcData.calcListMg(), 'calcListMgTest');
    }

    @IsTest
    public static void calcTotalTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        //System.assertEquals(1750, calcData.calcTotal(), 'calcTotalTest');
    }

    @IsTest
    public static void calcTotalListTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        //System.assertEquals(1878, calcData.calcTotalList(), 'calcTotalListTest');
    }

    @IsTest
    public static void calcBUMgTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        //System.assertEquals(0.01, calcData.calcBUMg(), 'calcBUMgTest');
    }

    @IsTest
    public static void calcScoreTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        //System.assertEquals(0.573960463531015678254942058623040, calcData.calcScore(), 'calcScoreTest');
    }

    @IsTest
    public static void calcScoreMixTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        calcData.isContract = false;
        //System.assertEquals(8.42, calcData.calcScoreMix(), 'calcScoreMixTest');
    }

    @IsTest
    public static void calcScoreFinalTest() {
        String str = '1';
        CalcScore.CalcData calcData = new CalcScore.CalcData(str);
        calcData.isContract = true;
        //System.assertEquals(57.3960463531015678254942058623040000, calcData.calcScoreFinal(), 'calcScoreFinalTest');
    }
    
    @IsTest
    public static void putFLDTest() {
        CalcScore.CalcDataOrder calcDataOrder = new CalcScore.CalcDataOrder();
        CalcScore.CalcData calcData           = new CalcScore.CalcData('1');
        calcDataOrder.putFLD(calcData);
    }
    
    @IsTest
    public static void calcScoreCalcDataTest() {
        CalcScore.CalcData calcScore           = new CalcScore.CalcData('1');
        List<CalcScore.CalcData> calcScoreList = new List<CalcScore.CalcData>();
        CalcScore.CalcDataOrder calcDataOrder  = new CalcScore.CalcDataOrder();

        calcDataOrder.totalAmount     = 1;
        calcDataOrder.totalAmountList = 10;

        calcScoreList.add(calcScore);
        calcDataOrder.calcScore(calcScoreList);
    }

    @IsTest
    public static void setScalePriceTest() {
        System.assertEquals(0, CalcScore.setScalePrice(null), 'setScalePriceTest');
    }

    @IsTest
    public static void calcProductsScreenTest() {
        String str = '[]';
        System.assertNotEquals(null, CalcScore.calcProductsScreen('[]'), 'calcProductsScreenTest');
    }

    @IsTest
    public static void reverseCalcScreenTest() {
        String str = '[]';
        System.assertNotEquals(null, CalcScore.reverseCalcScreen('[]'), 'reverseCalcScreenTest');
    }

    @IsTest
    public static void calcProductsTest() {
        System.assertNotEquals(null, CalcScore.calcProducts('[]'), 'calcProductsTest');
    }

    @IsTest
    public static void calcProductsTestTwo() {
        CalcScore.CalcData calcData           = new CalcScore.CalcData('1');
        List<CalcScore.CalcData> calcDataList = new List<CalcScore.CalcData>();

        calcData.isContract = true;
        calcData.isCampaign = true;
        calcData.isLab = true;
        calcDataList.add(calcData);
        
        System.assertNotEquals(null, CalcScore.calcProducts(calcDataList), 'calcProductsTestTwo');
    }

    @IsTest
    public static void calcSingleOrderItemProductTest() {
        Account acc                      = TestUtility.createAccount();
        insert acc;
        Order newOrder                   = TestUtility.createOrder(acc);
        insert newOrder;
        Product2 newProduct              = TestUtility.createProduct();
        insert newProduct;
        PricebookEntry newPricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        newPricebookEntry.UnitPrice = 1.00;
        newPricebookEntry.isActive = true;
        update newPricebookEntry;
        OrderItem newOrderItem           = TestUtility.createOrderItem(newOrder, newProduct, newPricebookEntry);
        insert newOrderItem;
        
        System.assertNotEquals(null, CalcScore.calcSingleOrderItemProduct(newOrderItem.Id), 'calcSingleOrderItemProductTest');
    }

    @IsTest
    public static void calcSingleOppLineItemProductTest() {
        Product2 newProduct                    = TestUtility.createProduct();
        insert newProduct;
        User newUser                           = TestUtility.createUser();
        insert newUser;
        Opportunity newOpportunity             = TestUtility.createOpportunity(newUser);
        insert newOpportunity;
        PricebookEntry newPricebookEntry       = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        newPricebookEntry.UnitPrice = 10.00;
        newPricebookEntry.isActive  = true;
        update newPricebookEntry;
        OpportunityLineItem newOpportunityItem = TestUtility.createOpportunityLineItem(newOpportunity, newProduct, newPricebookEntry);
        insert newOpportunityItem;

        System.assertNotEquals(null, CalcScore.calcSingleOppLineItemProduct(newOpportunityItem.Id), 'calcSingleOppLineItemProductTest');
    }

    @IsTest
    public static void calcOppLineItemProductsTest() {
        Product2 newProduct                       = TestUtility.createProduct();
        insert newProduct;    
        User newUser                              = TestUtility.createUser();
        insert newUser;   
        Opportunity newOpportunity                = TestUtility.createOpportunity(newUser);
        insert newOpportunity;    
        PricebookEntry newPricebookEntry          = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        newPricebookEntry.UnitPrice = 10.00;
        newPricebookEntry.isActive  = true;
        update newPricebookEntry;
        OpportunityLineItem newOpportunityItem    = TestUtility.createOpportunityLineItem(newOpportunity, newProduct, newPricebookEntry);
        insert newOpportunityItem;

        Set<Id> opportunityItemId = new Set<Id>();
        opportunityItemId.add(newOpportunityItem.Id);

        System.assertNotEquals(null, CalcScore.calcOppLineItemProducts(opportunityItemId), 'calcOppLineItemProductsTest');
    }

    @IsTest
    public static void calcOrderItemProductsTest() {
        Account acc                      = TestUtility.createAccount();
        insert acc;
        Order newOrder                   = TestUtility.createOrder(acc);
        insert newOrder;
        Product2 newProduct              = TestUtility.createProduct();
        insert newProduct;
        PricebookEntry newPricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        newPricebookEntry.UnitPrice = 1.00;
        newPricebookEntry.isActive  = true;
        update newPricebookEntry;
        OrderItem newOrderItem           = TestUtility.createOrderItem(newOrder, newProduct, newPricebookEntry);
        insert newOrderItem;

        Set<Id> orderItemId       = new Set<Id>();
        orderItemId.add(newOrderItem.Id);

        System.assertNotEquals(null, CalcScore.calcOrderItemProducts(orderItemId), 'calcOrderItemProductsTest');
    }

    @IsTest
    public static void calcSingleOrderTest() {
        Account acc    = TestUtility.createAccount();
        insert acc;
        Order newOrder = TestUtility.createOrder(acc);
        insert newOrder;

        System.assertNotEquals(null, CalcScore.calcSingleOrder(newOrder.Id), 'calcSingleOrderTest');
    }

    @IsTest
    public static void calcSingleOpportunityTest() {
        User newUser               = TestUtility.createUser();
        insert newUser;
        Opportunity newOpportunity = TestUtility.createOpportunity(newUser);
        insert newOpportunity;

        System.assertNotEquals(null, CalcScore.calcSingleOpportunity(newOpportunity.Id), 'calcSingleOpportunityTest');
    }

    @IsTest
    public static void calcOpportunityTest() {
        User newUser               = TestUtility.createUser();
        insert newUser;
        Opportunity newOpportunity = TestUtility.createOpportunity(newUser);
        insert newOpportunity;

        Set<Id> opportunityIdSet   = new Set<Id>();
        opportunityIdSet.add(newOpportunity.Id);

        System.assertNotEquals(null, CalcScore.calcOpportunity(opportunityIdSet), 'calcOpportunityTest');
    }

    @IsTest
    public static void calcOrdersTest() {
        Account acc    = TestUtility.createAccount();
        insert acc;
        Order newOrder = TestUtility.createOrder(acc);
        insert newOrder;

        Set<Id> orderIdSet   = new Set<Id>();
        orderIdSet.add(newOrder.Id);

        System.assertNotEquals(null, CalcScore.calcOrders(orderIdSet), 'calcOrdersTest');
    }
}