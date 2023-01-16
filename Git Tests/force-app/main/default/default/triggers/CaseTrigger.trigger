/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 09-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
trigger CaseTrigger on Case (before insert, after insert, before update, after update, before delete, after delete) {
    CaseTH handler = new CaseTH(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (CaseTH.isTriggerEnabled())
        handler.execute();
}