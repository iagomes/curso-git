/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 23-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
public class StandardResponse {
    
    @AuraEnabled
    public List<String> messages = new List<String>();

    public transient Set<String> uniqueMessages = new Set<String>();

    @AuraEnabled
    public Object data;

    // 200 = SUCCESS
    @AuraEnabled
    public String code;
    
    @AuraEnabled
    public Boolean hasError = false;

    public StandardResponse(){
        this.code = '200';
    }
    
    public StandardResponse(String code){
        this.code = code;
    }
    
    public StandardResponse(String message, String code){
        this.messages.add(message);
        this.code = code;
    }
    
    public StandardResponse(String message, String code, Object data) {
        this.messages.add(message);
        this.code = code;
        this.data = data;
    }

    public void addUniqueError(String errorMessage){
        if(!this.uniqueMessages.contains(errorMessage)){
            addError(errorMessage);
            this.uniqueMessages.add(errorMessage);
        }
    }

    public StandardResponse addError(String errorMessage){
        addError(errorMessage, '500');
        return this;
    }

    public void addError(Exception ex){
        ExceptionUtils.debug(ex);
        addError(ex.getMessage());
    }

    public StandardResponse addError(String errorMessage, String statusCode){
        this.code = statusCode;
        this.messages.add(errorMessage);
        this.hasError = true;
        return this;
    }

    public StandardResponse setData(Object data){
        this.data = data;
        return this;
    }
    
    public StandardResponse setData(String label, Object value){
        try {
            Map<String, Object> resultData = new Map<String, Object>();
            if(this.data != null && !((Map<String, Object>)this.data).isEmpty()){
                resultData = (Map<String, Object>)this.data;
            }
            resultData.put(label, value);
            this.data = resultData;
        } catch (Exception ex) {
            List<Map<String, Object>> resultData = new List<Map<String, Object>>();
            if(this.data != null && !((List<Map<String, Object>>)this.data).isEmpty()){
                resultData = (List<Map<String, Object>>)this.data;
            }
            resultData.add(new Map<String, Object>{label => value});
            this.data = resultData;
        }
        return this;
    }

    public String toJSON(){
        return JSON.serialize(this);
    }
    
}