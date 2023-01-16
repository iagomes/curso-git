({
    navigateToPaymentSlip : function(component, event, helper) {

    var recordId = component.get("v.recordId");
    var isCommunity;
    var action = component.get("c.isCommunity");
        action.setCallback(this, function(response) {
            isCommunity = response.getReturnValue(); // do any operation needed here
            console.log(isCommunity);
            if (isCommunity) {
                if (!recordId) {
                    component.set("v.recordId", document.location.href.substring((document.location.href.length - 18)));
                }
                console.log('recordId');
                console.log(recordId);
                var address = '/visualizar-titulos?id='+recordId;
                console.log(address);
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": address
                });
                urlEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } else {
                var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({ 
                        componentDef : "c:PaymentTitleNameTab",
                        componentAttributes: { recordId : recordId }
                    });
                    evt.fire();
            }
        });
        $A.enqueueAction(action);
    }
})