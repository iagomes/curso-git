({
    init: function (component, event, helper) {
        console.log('Entrou no INIT');
        console.log(component);
        console.log("Method Entry: CreateQuoteQuickActionController.js");
        var evt = $A.get("e.force:navigateToComponent");

        var recordId = component.get("v.recordId");

        var action = component.get("c.isCommunity");
        var isCommunity;
        action.setCallback(this, function(response) {
            isCommunity = response.getReturnValue(); // do any operation needed here
            console.log(isCommunity);
            if (isCommunity) {
                if (!recordId) {
                    component.set("v.recordId", document.location.href.substring((document.location.href.length - 18)));
                }
                console.log('recordId');
                console.log(recordId);
                var address = '/criar-pedido?id='+recordId;
                console.log(address);
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": address,
                "isredirect" :false,
                "isEdit" : true
                });
                urlEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } else {
                evt.setParams({
                    componentDef: "c:CreateOrderAuraComponent",
                    componentAttributes: {
                        recordId: component.get("v.recordId"),
                        isEdit: false,
                        isBudget: false
                    }
                });
                evt.fire();
            }
        });
        $A.enqueueAction(action);

    }
})