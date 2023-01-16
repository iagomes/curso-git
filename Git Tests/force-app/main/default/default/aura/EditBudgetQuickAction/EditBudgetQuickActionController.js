({
    init : function (component, event, helper) {
        console.log('Entrou no INIT');
        console.log(component);
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
                var address = '/editar-orcamento?id='+recordId;
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
                    componentDef: "c:CriarOrcamento",
                    componentAttributes: {
                        recordId: component.get("v.recordId"),
                        isEdit: true,
                        isBudget: true
                    }
                });
                evt.fire();
            }
        });
        $A.enqueueAction(action);
    }
})