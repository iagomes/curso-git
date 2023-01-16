global class BatchOpportunity implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, CloseDate, Name, OwnerId, Owner.Name, Owner.Email FROM Opportunity WHERE CloseDate = TODAY order by OwnerId]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope ) {        

        List<Opportunity> listOpp = (List<Opportunity>) scope;

        String NomeOrcamento = '';
        map<Id,Opportunity> mapUsuario = new map<Id, Opportunity>();
        map<Id,String> mapOppVenceHoje = new map<Id, String>();
        EmailTemplate emailOrcExpiraAmanha = new EmailTemplate();
        emailOrcExpiraAmanha = [SELECT Body,Description,DeveloperName,Id,IsActive,Name,OwnerId,Subject 
                                    FROM EmailTemplate 
                                    WHERE developerName = 'OrcamentoExpiraAmanha'];

        EmailTemplate emailOrcExpira = new EmailTemplate();
        emailOrcExpira = [SELECT Body,Description,DeveloperName,Id,IsActive,Name,OwnerId,Subject 
                            FROM EmailTemplate 
                            WHERE developerName = 'OrcamentoExpirada'];


        for (Opportunity opp : listOpp) {
            if(mapOppVenceHoje.containsKey(opp.OwnerId)){
                NomeOrcamento =  mapOppVenceHoje.get(opp.OwnerId);
            }else{
                NomeOrcamento = '';
            }
            NomeOrcamento += opp.Name + ' </br> ';
            mapOppVenceHoje.put(opp.OwnerId, NomeOrcamento);
            mapUsuario.put(opp.OwnerId, opp);
        }

        map<Id,String> mapOppVenceAmanha = new map<Id, String>();
        Date checkDate = Test.isRunningTest() ? Date.today().addDays(1) : Date.today().addDays(1);
        List<Opportunity> scope1 =[SELECT Id, CloseDate, Name, OwnerId, Owner.Name, Owner.Email  FROM Opportunity WHERE CloseDate =: checkDate order by OwnerId ];

        for (Opportunity opp : scope1) {
            if(mapOppVenceAmanha.containsKey(opp.OwnerId)){
                NomeOrcamento =  mapOppVenceAmanha.get(opp.OwnerId);
            }else{
                NomeOrcamento = '';

            }
            NomeOrcamento += opp.Name + ' </br> ';
            mapOppVenceAmanha.put(opp.OwnerId, NomeOrcamento);
            mapUsuario.put(opp.OwnerId, opp);
        }
        List<Messaging.SingleEmailMessage> lLstSingleEmailMessage = new list<Messaging.SingleEmailMessage>();

        for(String usuario : mapOppVenceHoje.keySet()){
            Messaging.SingleEmailMessage lEmail = new Messaging.SingleEmailMessage();
            lEmail.setTargetObjectId(usuario);
            lEmail.setSaveAsActivity(false);
            lEmail.setHtmlBody(emailOrcExpira.Body + mapOppVenceHoje.get(usuario));
            Opportunity opp = mapUsuario.get(usuario);
            String[] toAddresses = new String[] {opp.Owner.Email};
            lEmail.setToAddresses(toAddresses);
            lLstSingleEmailMessage.add(lEmail);
        }

        for(String usuario : mapOppVenceAmanha.keySet()){
            Messaging.SingleEmailMessage lEmail = new Messaging.SingleEmailMessage();
            lEmail.setTargetObjectId(usuario);
            lEmail.setSaveAsActivity(false);
            lEmail.setHtmlBody(emailOrcExpiraAmanha.Body + mapOppVenceAmanha.get(usuario));
            Opportunity opp = mapUsuario.get(usuario);
            String[] toAddresses = new String[] {opp.Owner.Email};
            lEmail.setToAddresses(toAddresses);
            lLstSingleEmailMessage.add(lEmail);
        }
        if(!lLstSingleEmailMessage.isEmpty() ){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lLstSingleEmailMessage, false);
        } 

    }

    global void finish(Database.BatchableContext BC) {}
}
