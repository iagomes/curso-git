public inherited sharing class EmailMessageHelper {
    
    public static void setCaseNumberInSubject(List<EmailMessage> messages, Set<Id> caseIds) {
        
        Map<Id, String> caseNumbersByIds = new Map<Id, String>();
        
        for (Case cs : [SELECT CaseNumber FROM Case WHERE Id IN: caseIds])
        {
            caseNumbersByIds.put(cs.Id, cs.CaseNumber);
        }
        
        for (EmailMessage message : messages) {
            
            if (caseIds.contains(message.ParentId)) 
            {
                String caseNumber = caseNumbersByIds.get(message.ParentId);
                if (String.isNotBlank(message.Subject) && !message.Subject.contains(caseNumber))
                    message.Subject = String.format('[Caso: {0}] {1}', new String[] { 
                        caseNumber,
                            message.Subject
                            });
            }
        }  
    }
    
}