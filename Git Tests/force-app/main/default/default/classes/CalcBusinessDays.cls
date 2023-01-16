public without sharing class CalcBusinessDays {
    
    @InvocableMethod(label='Calc Business Days' 
                    description='Sum more business days to Opportunity')
    public static List<String> flowCalcDays(List<String> oppIdSet) {
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp : [SELECT id, QuantidadeProrrogamentos__c, PrazoValidade__C FROM Opportunity WHERE ID IN :oppIdSet]){
            oppList.add(new Opportunity(Id = opp.id, 
                                        QuantidadeProrrogamentos__c = (opp.QuantidadeProrrogamentos__c == null ? 1 : opp.QuantidadeProrrogamentos__c + 1),
                                        CloseDate = calcDays(Date.today(), (opp.PrazoValidade__C == null ? 0 : opp.PrazoValidade__C))
                                        ));
        }

        if(!oppList.isEmpty())
            update oppList;
        return new list<String>{'Sucesso!!'};
    }
    public static Boolean IsWeekend(Date myDate){
    	String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return myDateString.equals('Sat') || myDateString.equals('Sun');
    }
    public static Date calcDays(Date startDate, Decimal qtdDays){
        Date finalDate = startDate;
        Integer direction = qtdDays < 0 ? -1 : 1;
        while(qtdDays != 0){
            finalDate = finalDate.addDays(direction);
            if (!IsWeekend(finalDate)){
                qtdDays -= direction;
            }
        }
        return finalDate;
    }
}
