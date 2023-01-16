({
   navigateToPaymentSlip : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({ 
            componentDef : "c:paymentSlipPreview",
            componentAttributes: { recordId : component.get("v.recordId") }
        });
        evt.fire();
    }

})