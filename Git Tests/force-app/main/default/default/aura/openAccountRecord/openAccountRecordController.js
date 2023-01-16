({    invoke : function(component, event, helper) {
    // Get the record ID attribute
    var record = component.get("v.recordId");
    
    // Get the Lightning event that opens a record in a new tab
    sforce.one.navigateToSObject(record, "detail");
 }})