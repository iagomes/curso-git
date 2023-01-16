public class CalcScore {
    public class CalcData{
        public String productBu {get;set;}
        public String productCode {get;set;}

        public String cdId {get;set;}
        public String observacaoComercial {get;set;}

        public Boolean isContract {get;set;}
        public Boolean isCampaign {get;set;}
        public Boolean isLab {get;set;}

        public Decimal cost {get;set;}
        public Decimal quantity {get;set;}
        public Decimal unitPrice {get;set;}
        public Decimal listPrice {get;set;}
        public Decimal taxPercent {get;set;}
        

        public Decimal calcProd {get;set;}
        public Decimal calcMix {get;set;}
        public Decimal calcBu {get;set;}
        
        public Decimal scoreProd {get;set;}
        public Decimal scoreMix {get;set;}
        public Decimal scoreFinal {get;set;}

        public Decimal newDiscount {get;set;}

        public Decimal margem {get;set;}
        public Decimal margemAlvo {get;set;}


        public CalcData(String item){
            this.isContract = false;
            this.getCalcParameter();
            if(item == '1'){
                this.cost = 1150;
                this.unitPrice = 1750;
                this.productBu = 'Especialidades';
                this.productCode = '3070';
                this.quantity = 1;
                this.listPrice = 1878;
                this.taxPercent = 28.24;
                this.calcBU = 8;
                this.cdId = '1';
                this.observacaoComercial = '';
            }else if(item == '2'){
                this.cost = 2.554467;
                this.unitPrice = 4;
                this.productBu = 'Materias';
                this.productCode = '0004375';
                this.quantity = 10;
                this.listPrice = 2.443309;
                this.taxPercent = 0;
                this.calcBu = 18;
                this.cdId = '1';
                this.observacaoComercial = '';
            }else if(item == '3'){
                this.cost = 1150;
                this.unitPrice = 1750;
                this.productBu = 'Especialidades';
                this.productCode = '3070';
                this.quantity = 1;
                this.listPrice = 1878;
                this.taxPercent = 28.24;
                this.calcBU = 8;
                this.cdId = '1';
                this.observacaoComercial = '';
            }
        }
        public CalcData(OpportunityLineItem oppItem){
            this.cost = oppItem.Custo__c;
            this.unitPrice = oppItem.UnitPrice;
            this.productBu = oppItem.Product2.CategoriaComercial__c;
            this.productCode = oppItem.Product2.ProductCode;
            this.quantity = oppItem.Quantity;
            this.listPrice = oppItem.ListPrice;
            this.taxPercent = oppItem.Imposto__c;
            this.isContract = false;
            this.observacaoComercial = oppItem.ObservacoesComercial__c;
            this.getCalcParameter();
        }
        public CalcData(OrderItem ordItem){
            this.cost = orditem.Custo__c;
            this.unitPrice = orditem.UnitPrice;
            this.productBu = orditem.Product2.CategoriaComercial__c;
            this.productCode = orditem.Product2.ProductCode;
            this.quantity = orditem.Quantity;
            this.listPrice = orditem.ListPrice;
            this.taxPercent = orditem.Imposto__c;
            this.isContract = false;
            this.observacaoComercial = orditem.ObservacoesComercial__c;
            this.getCalcParameter();
        }
        public Decimal calcUnitMg(){
            Decimal tax = (this.unitPrice * (this.taxPercent/100)); 
            Decimal val = this.unitPrice-tax;
            val = (val == 0 ? 0.01 : val);
            this.margem = setScalePrice(((val - this.cost) / val));
            // System.debug('this.margem: '+this.margem);
            // System.debug('tax: '+tax);
            // System.debug('this.unitPrice: '+this.unitPrice);
            // System.debug('val: '+val);
            // System.debug('this.cost: '+this.cost);
            return margem;
        }
        public Decimal calcListMg(){
            Decimal tax = (this.listPrice * (this.taxPercent/100));
            Decimal val = this.listPrice-tax;
            val = (val == 0 ? 0.01 : val);
            this.margemAlvo = setScalePrice(((val - this.cost) / val));
            // system.debug('this.margemAlvo: ' + this.margemAlvo);
            return this.margemAlvo;
        }        
        public Decimal calcTotal(){
            return this.quantity*this.unitprice;
        }             
        public Decimal calcTotalList(){
            return this.quantity*this.listPrice;
        }        
        public Decimal calcBUMg(){
            Map<String, ScoreBU__C> parameterBU = ScoreBU__c.getAll();
            return (parameterBU.containsKey(this.productBu) ? parameterBU.get(this.productBu).MargemAlvo__c : 1)/100;
        }
        public void getCalcParameter(){
            Map<String, PesoScore__c> parameterScore = PesoScore__c.getAll();
            Map<String, ScoreBU__C> parameterBU = ScoreBU__c.getAll();
            this.calcProd = (parameterScore.containsKey('Produto')  ? parameterScore.get('Produto').Peso__c : 60)/100;//60%
            this.calcMix =  (parameterScore.containsKey('Mix')      ? parameterScore.get('Mix').Peso__c     : 40)/100;//40%
            this.calcBu = (parameterBU.containsKey(this.productBu) ? parameterBU.get(this.productBu).MargemAlvo__c : 1)/100;//8%
        }
        /*
            //formula final simplificada
            x = ( (y + z) / z ) * -1;

            thismargem = x
            thiscost = y
            val = z
            z = -y / (x+1)

            //formula val simplificada
            z = (thisunitPrice * ((thistaxPercent/100))-thisunitPrice))

            thistaxPercent = t
            thisunitPrice = u

            z = (u * ((t/100))-u))
            z = (0.01*tu) - u

            //igualando as formulas
            z = (0.01*tu) - u
            z = -y / (x+1)

            //simplificada
            u = -y / (0.01tx+0.01t−x−1)
            //voltando para os parametros
            this.unitprice = -this.cost / ((0.01*this.taxPercent*this.margem)+(0.01*this.taxPercent)−this.margem−1);

         */
        public void reverseCalc(){

            this.unitPrice = this.margem == 100 ? this.listprice : ((-100*this.cost)/(this.taxPercent-100+this.margem-((this.margem/100)*this.taxPercent))).setScale(6);
            this.newDiscount =  ((1-(this.unitPrice/ this.listPrice))*100).setScale(6);

            this.newDiscount = this.newDiscount < 0 ? 0 : (this.newDiscount > 100 ? 100 : this.newDiscount); 
            this.unitprice = this.newDiscount < 0 ? this.listPrice : (this.newDiscount > 100 ? 0 : this.unitprice);

            this.margemAlvo = setScalePrice(this.calcListMg());
            this.scoreProd = this.margemAlvo == 0 ? 0 : this.margem/this.margemAlvo;
            this.scoreMix = this.calcBUMg() == 0 ? 0 : this.margem/this.calcBUMg();
            this.scoreFinal =  ((this.scoreProd) * this.calcProd) + ((this.scoreMix) * this.calcMix);
        }
                
        public Decimal calcScore(){
            // system.debug(this.calcUnitMg());
            // system.debug(this.calcListMg());
            if (this.calcListMg() < 0) {
                // system.debug('this.calcListMg(): ' + this.calcListMg());
                decimal calcListMgModule = (this.calcListMg() * -1);
                // system.debug('calcListMgModule: ' + calcListMgModule);
                // system.debug('this.calcListMg(): ' + this.calcListMg());
                decimal scoreProd = (this.calcUnitMg() + (calcListMgModule - (this.calcListMg())))/(this.calcListMg() < 0 ? (this.calcListMg() * -1) : this.calcListMg());
                // system.debug('scoreProd: ' + scoreProd);
                this.scoreProd = scoreProd;
            } else {
                this.scoreProd = this.calcListMg() == 0 ? 0 : this.calcUnitMg()/this.calcListMg();
            }
            // system.debug('this.scoreProd: ' + this.scoreProd);
            return this.scoreProd;
        }
                
        public Decimal calcScoreMix(){
            // system.debug(this.calcUnitMg());
            // system.debug(this.calcBUMg());
            // system.debug(this.isContract);
            // system.debug(calcScore());
            this.scoreMix =  this.isContract ? calcScore() :  (this.calcUnitMg()/100) /this.calcBUMg();
            // system.debug('this.scoreMix: ' + this.scoreMix);
            return this.scoreMix;
        }
                
        public Decimal calcScoreFinal(){
            // system.debug('this.calcScore(): ' + this.calcScore());
            // system.debug('this.calcScoreMix(): ' + this.calcScoreMix());
            // system.debug('this.calcProd: ' + this.calcProd);
            // system.debug('this.calcMix: ' + this.calcMix);
            Map<String, PesoScore__c> parameterScore = PesoScore__c.getAll();
            this.calcProd = (parameterScore.containsKey('Produto')  ? parameterScore.get('Produto').Peso__c : 60)/100;//60%
            this.calcMix =  (parameterScore.containsKey('Mix')      ? parameterScore.get('Mix').Peso__c     : 40)/100;//40%
            this.scoreFinal =  (((this.calcScore()) * this.calcProd) + ((this.calcScoreMix()) * this.calcMix)) * 100;
            // system.debug('this.scoreFinal: ' + this.scoreFinal);
            return this.scoreFinal;
        }
    }

    public class CalcDataOrder{
        public Decimal totalAmount {get;set;}
        public Decimal totalAmountList {get;set;}
        public Decimal score {get;set;}
        public Decimal scoreDenominator {get;set;}
        public Decimal scoreNumerador {get;set;}
        public Decimal scoreMix {get;set;}
        public Decimal scoreFinal {get;set;}

        public Decimal calcProd {get;set;}
        public Decimal calcMix {get;set;}
        public CalcDataOrder(){
            this.totalAmount = 0;
            this.totalAmountList = 0;
            Map<String, PesoScore__c> parameterScore = PesoScore__c.getAll();
            this.calcProd = (parameterScore.containsKey('Produto')  ? parameterScore.get('Produto').Peso__c : 60)/100;//60%
            this.calcMix =  (parameterScore.containsKey('Mix')      ? parameterScore.get('Mix').Peso__c     : 40)/100;//40%
        }
        public void putFLD(CalcData cl){
            // system.debug('cl.calcTotal(): ' + cl.calcTotal());
            // system.debug('cl.calcTotalList(): ' + cl.calcTotalList());
            this.totalAmount += cl.calcTotal();
            this.totalAmountList += cl.calcTotalList();
        }
        public void calcScore(CalcData[] clList){
            Decimal denominator = 0;
            Decimal numerator = 0;
            Decimal numeratorBU = 0;
            for(CalcData cl : clList){
                // System.debug('cl.calcTotal(): ' + cl.calcTotal());
                // System.debug('this.totalAmount: ' + this.totalAmount);
                // System.debug('this.totalAmountList: ' + this.totalAmountList);
                // System.debug('cl.calcUnitMg(): ' + cl.calcUnitMg());
                denominator +=((this.totalAmount == 0 ? 0 : (cl.calcTotal() / this.totalAmount)) * (cl.calcUnitMg()));
                // System.debug('denominator: ' + denominator);
                numerator +=((this.totalAmountList == 0 ? 0 : cl.calcTotalList() / (this.totalAmountList)) * (cl.calcListMg()));
                numeratorBU +=((this.totalAmount == 0 ? 0 : (cl.calcTotal() / this.totalAmount)) * (cl.isContract ? (cl.calcListMg() / 100) : cl.calcBUMg()));
            }
            this.scoreDenominator = denominator;
            this.scoreNumerador = numerator;

            numerator = numerator == 0 ? 1 : numerator;

            // system.debug('numerator: ' + numerator);
            // system.debug('numeratorBU: ' + numeratorBU);
            // system.debug('this.scoreDenominator: ' + this.scoreDenominator);
            // system.debug('this.scoreNumerador: ' + this.scoreNumerador);

            if (this.scoreNumerador < 0) {
                decimal scoreNumeratorModule = (this.scoreNumerador * -1);
                decimal score = (this.scoreDenominator + (scoreNumeratorModule - (this.scoreNumerador)))/(this.scoreNumerador < 0 ? scoreNumeratorModule : this.scoreNumerador);
                // system.debug('score: ' + score);
                this.score = (numerator == 0 ? 0 : score) * 100;
            } else {
                this.score = (numerator == 0 ? 0 : (denominator/numerator)) * 100;
            }
            this.scoreMix = numeratorBU == 0 ? 0 : denominator/numeratorBU;

            this.scoreFinal = (this.score * this.calcProd) + (this.scoreMix * this.calcMix);

            // system.debug('this.score: ' + this.score);
            // system.debug('this.scoreMix: ' + this.scoreMix);
            // system.debug('this.scoreFinal: ' + this.scoreFinal);
        }
    }
    public static decimal setScalePrice(Decimal dec){
        return dec == null ? 0 : (dec*100).setScale(6);
    }
    @AuraEnabled(cacheable=false)
    public static String calcProductsScreen(String clListString){
        List<CalcData> listToReturn = new List<CalcData>();
        List<CalcData> clList = (List<CalcData>)JSON.deserialize(clListString, List<CalcData>.class);
        for(CalcData clData : clList){
            clData.getCalcParameter();
            clData.calcScoreFinal();

            // system.debug(clData);

            listToReturn.add(clData);
        }

        // system.debug(listToReturn);
        return JSON.serialize(listToReturn);
    }

    //return unitprice && newDiscount, send me new margem
    @AuraEnabled(cacheable=false)
    public static String reverseCalcScreen(String clListString){
        List<CalcData> listToReturn = new List<CalcData>();
        List<CalcData> clList = (List<CalcData>)JSON.deserialize(clListString, List<CalcData>.class);
        for(CalcData cl : clList){
            cl.getCalcParameter();
            cl.reverseCalc();
            
            // system.debug(cl);

            listToReturn.add(cl);
        }
        // system.debug(listToReturn);
        return JSON.serialize(listToReturn);
    }

    @AuraEnabled(cacheable=false)
    public static String calcProducts(String clListString){
        // system.debug(clListString);
        List<CalcData> clList = (List<CalcData>)JSON.deserialize(clListString, List<CalcData>.class);
        CalcDataReturn clReturn = new CalcDataReturn();
        for(CalcData clData : clList){
            clData.getCalcParameter();
            clReturn.add(clData);
        }
        clReturn.calcScore();
        return JSON.serialize(clReturn);
    }

    public static CalcDataReturn calcProducts(List<CalcData> clList){
        CalcDataReturn clReturn = new CalcDataReturn();
        for(CalcData clData : clList){
            clReturn.add(clData);
        }
        clReturn.calcScore();
        return clReturn;
    }
    public static CalcDataReturn calcSingleOppLineItemProduct(Id oppId){
        return calcSingleProduct([SELECT id, UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OpportunityLineItem WHERE id = :oppId][0]);
    } 
    public static CalcDataReturn calcSingleOrderItemProduct(Id ordItemId){
        return calcSingleProduct([SELECT id  , UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OrderItem WHERE id = :ordItemId][0]);
    } 
    public static CalcDataReturn calcSingleProduct(OpportunityLineItem oppItem){
        return calcSingleProduct(new CalcData(oppItem));
    } 
    public static CalcDataReturn calcSingleProduct(OrderItem ordItem){
        return calcSingleProduct(new CalcData(ordItem));
    }
    public static CalcDataReturn calcOppLineItemProducts(Set<Id> oppLineItemIdSet){
        List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppLineItem : [SELECT id, UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OpportunityLineItem WHERE Id IN :oppLineItemIdSet]){
            oppItemList.add(oppLineItem);
        }
        return calcOppLineItemProducts(oppItemList);
    }
    public static CalcDataReturn calcOrderItemProducts(Set<Id> ordItemIdSet){
        List<OrderItem> ordItemList = new List<OrderItem>();
        for(OrderItem ordItem : [SELECT id  , UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OrderItem WHERE Id IN :ordItemIdSet]){
            ordItemList.add(ordItem);
        }
        return calcOrderItemProducts(ordItemList);
    }
    public static CalcDataReturn calcOrderItemProducts(List<OrderItem> ordItemList){
        List<CalcData> calcDataList = new List<CalcData>();
        for(OrderItem clData : ordItemList){
            calcDataList.add(new CalcData(clData));
        }
        return calcProducts(calcDataList);
    }
    public static CalcDataReturn calcOppLineItemProducts(List<OpportunityLineItem> oppLineList){
        List<CalcData> calcDataList = new List<CalcData>();
        for(OpportunityLineItem clData : oppLineList){
            calcDataList.add(new CalcData(clData));
        }
        return calcProducts(calcDataList);
    }
    public static CalcDataReturn calcSingleProduct(CalcData ordItem){
        return calcProducts(new List<CalcData>{ordItem});
    }
    public static CalcDataReturn calcSingleOrder(Id ordId){
        return calcSingleOrder([SELECT id FROM Order WHERE id = :ordId][0]);
    }
    public static CalcDataReturn calcSingleOpportunity(Id ordId){
        return calcSingleOpportunity([SELECT id FROM Opportunity WHERE id = :ordId][0]);
    }
    public static CalcDataReturn calcSingleOpportunity(Opportunity opp){
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppItem : [SELECT id  , UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OpportunityLineItem WHERE OpportunityId = :opp.id]){
            oppLineList.add(oppItem);
        }
        return calcOppLineItemProducts(oppLineList);
    }
    public static CalcDataReturn calcSingleOrder(Order ord){
        List<OrderItem> ordItemList = new List<OrderItem>();
        for(OrderItem ordItem : [SELECT id  , UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OrderItem WHERE OrderId = :ord.id]){
            ordItemList.add(ordItem);
        }
        return calcOrderItemProducts(ordItemList);
    }
    public static Map<Id, CalcDataReturn> calcOpportunity(Set<Id> oppIdSet){
        List<Opportunity> ordList = new List<Opportunity>();
        for(Opportunity ord : [SELECT id FROM Opportunity WHERE id IN :oppIdSet]){
            ordList.add(ord);
        }
        return calcOpportunitys(ordList);
    }
    public static Map<Id, CalcDataReturn> calcOrders(Set<Id> ordIdSet){
        List<Order> ordList = new List<Order>();
        for(Order ord : [SELECT id FROM Order WHERE id IN :ordIdSet]){
            ordList.add(ord);
        }
        return calcOrders(ordList);
    }
    public static Map<Id, CalcDataReturn> calcOpportunitys(List<Opportunity> ordList){
        Map<Id, OpportunityLineItem[]> ordItemMap = new Map<Id, OpportunityLineItem[]>();
        Map<Id, CalcDataReturn> calcReturnMap = new Map<Id, CalcDataReturn>();

        Set<Id> ordIdSet= new Set<Id>();
        for(Opportunity ord : ordList){
            ordIdSet.add(ord.id);
        }

        for(OpportunityLineItem ordItem : [SELECT id, OpportunityId, UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OpportunityLineItem WHERE OpportunityId IN :ordIdSet]){            
            if(!ordItemMap.containsKey(ordItem.OpportunityId))
                ordItemMap.put(ordItem.OpportunityId, new List<OpportunityLineItem>());
            ordItemMap.get(ordItem.OpportunityId).add(ordItem);
        }

        for(Id ordId : ordItemMap.keySet()){
            calcReturnMap.put(ordId, calcOppLineItemProducts(ordItemMap.get(ordId)));
        }

        return calcReturnMap;
    }
    public static Map<Id, CalcDataReturn> calcOrders(List<Order> ordList){
        Map<Id, OrderItem[]> ordItemMap = new Map<Id, OrderItem[]>();
        Map<Id, CalcDataReturn> calcReturnMap = new Map<Id, CalcDataReturn>();

        Set<Id> ordIdSet= new Set<Id>();
        for(Order ord : ordList){
            ordIdSet.add(ord.id);
        }

        for(OrderItem ordItem : [SELECT id, OrderId, UnitPrice, Product2.CategoriaComercial__c, Product2.ProductCode, ListPrice, Quantity , Custo__c, Imposto__c, ObservacoesComercial__c FROM OrderItem WHERE OrderId IN :ordIdSet]){            
            if(!ordItemMap.containsKey(ordItem.OrderId))
                ordItemMap.put(ordItem.OrderId, new List<OrderItem>());
            ordItemMap.get(ordItem.OrderId).add(ordItem);
        }

        for(Id ordId : ordItemMap.keySet()){
            calcReturnMap.put(ordId, calcOrderItemProducts(ordItemMap.get(ordId)));
        }

        return calcReturnMap;
    }

    public class CalcDataReturn{
        public Map<String, CalcData[]> products {get;set;}
        public Map<String, CalcData[]> cdMap {get;set;}
        public Map<String, CalcData> cdProdMap {get;set;}
        public Map<String, CalcDataOrder> results {get;set;}
        public CalcDataReturn(){
            this.products = new Map<String, CalcData[]>();
            this.results = new Map<String, CalcDataOrder>();
            this.cdMap = new Map<String, CalcData[]>();
            this.cdProdMap = new Map<String, CalcData>();
        }
        public void add(CalcData clData){
            if(!products.containsKey(clData.productBu))
                products.put(clData.productBu, new List<CalcData>());
            products.get(clData.productBu).add(clData);

            
            if(!cdMap.containsKey(clData.cdId))
                cdMap.put(clData.cdId, new List<CalcData>());
            cdMap.get(clData.cdId).add(clData);

            cdProdMap.put(clData.cdId+'_'+clData.productCode, clData);


            
            if(!products.containsKey('Order'))
                products.put('Order', new List<CalcData>());
            products.get('Order').add(clData);
        }
        public void calcScore(){
            for(String bus : products.keySet()){
                this.results.put(bus, this.aggResults(products.get(bus)));
            }
            if(cdMap.isEmpty()) return;

            for(String cdId : cdMap.keySet()){
                this.results.put(cdId, this.aggResults(cdMap.get(cdId)));
            }
        }
        public CalcDataOrder aggResults(CalcData[] clDataList){
            CalcDataOrder cl = new CalcDataOrder();
            for(CalcData clData : clDataList){
                clData.calcScoreFinal();

                cl.putFLD(clData);
            }

            cl.calcScore(clDataList);
            return cl;
        }
    }
}