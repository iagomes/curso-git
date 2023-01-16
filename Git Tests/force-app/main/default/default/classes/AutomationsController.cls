public class AutomationsController {
    
    private static Map<String, Integer> mapStopedAutomations = new Map<String, Integer>();

    
    public static void stop(String automationName, Id recordId) {
        stop(automationName, new Set<Id>{recordId});
    }

    
    public static void stop(String automationName, Set<Id> recordIds) {
        if(recordIds != null){
            for(Id recordId: recordIds){
                if(recordId != null){
                    stop(automationName + recordId);
                } else {
                    System.debug('Warning:Exception::: Trying to stop an automation without recordId.');
                }
            }
        }
    }

    public static void stop(String automationName) {
        Integer automationStopCount = mapStopedAutomations.get(automationName);
        if(automationStopCount == null){
            automationStopCount = 0;
        }
        automationStopCount++;
        System.debug('AutomationsController:::stop:::' + automationName + ':' + automationStopCount);
        mapStopedAutomations.put(automationName, automationStopCount);
    }

    public static void restart(String automationName) {
        Integer automationStopCount = mapStopedAutomations.get(automationName);
        if(automationStopCount == null){
            automationStopCount = 1;
        }
        automationStopCount--;
        System.debug('AutomationsController:::restart:::' + automationName + ':' + automationStopCount);
        mapStopedAutomations.put(automationName, automationStopCount);
    }
    
    public static void restart(String automationName, Set<Id> recordIds) {
        for(Id recordId: recordIds){
            restart(automationName + (recordId != null? recordId : ''));
        }
    }

    public static void restartAll(String automationName) {
        System.debug('AutomationsController:::restartAll:::' + automationName);
        mapStopedAutomations.put(automationName, 0);
    }
    
    public static void restartAll(String automationName, Set<Id> recordIds) {
        for(Id recordId: recordIds){
            restartAll(automationName + (recordId != null? recordId : ''));
        }
    }

    public static Boolean isRunning(String automationName, Id recordId){
        return isRunning(automationName, new Set<Id>{recordId}).contains(recordId);
    }

    public static Set<Id> isRunning(String automationName, Set<Id> recordIds){
        Set<Id> runningIds = new Set<Id>();
        if(!isRunning(automationName)){
            return runningIds;
        }
        for(Id recordId: recordIds){
            if(recordId != null && isRunning(automationName + recordId)){
                runningIds.add(recordId); 
            }
        }
        return runningIds;
    }

    public static Boolean isRunning(String automationName){
        Integer automationStopCount = mapStopedAutomations.get(automationName);
        Boolean running = (automationStopCount == null || automationStopCount == 0);
        System.debug('AutomationsController:::' + automationName + '.isRunning::: ' + running + ':' + automationStopCount);
        return running;
    }

    public static Boolean executeOnce(String automationName){
        Boolean result = isRunning(automationName);
        if(result){
            stop(automationName);
        }
        return result;
    }

    public static Boolean executeOnce(String automationName, Id recordId){
        return executeOnce(automationName, new Set<Id>{recordId}).size() > 0;
    }

    public static Set<Id> executeOnce(String automationName, Set<Id> recordIds){
        if((recordIds == null || recordIds.isEmpty())){
            return new Set<Id>();
        }
        Set<Id> result = isRunning(automationName, recordIds);
        if(result.size() > 0){
            stop(automationName, result);
        }
        return result;
    }


}