public without sharing class QueueRevalidateUserApprovalAssociations implements Queueable {
    public void execute(QueueableContext context) {
        Set<Id> responsibleUsersIds = new Set<Id>();
        
        List<ResponsabilidadeAprovacao__c> responsibleApprovalsList = [
            SELECT 
                Id,
                UsuarioAprovador__c
            FROM ResponsabilidadeAprovacao__c
        ];

        for (ResponsabilidadeAprovacao__c currResponsibleUser : responsibleApprovalsList) {
            responsibleUsersIds.add(currResponsibleUser.UsuarioAprovador__c);
        }
        
        ResponsabilidadeAprovacaoHelper.revalidateAssociationsAsync(responsibleUsersIds);        
    }
}
