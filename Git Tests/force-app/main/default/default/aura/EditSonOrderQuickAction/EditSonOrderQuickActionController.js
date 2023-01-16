({
    init: function (component, event, helper) {
        console.log('Entrou no INIT');
        console.log(component);
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:CreateOrderAuraComponent",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                isEdit: true,
                isBudget: false,
                isSonOrder: true
            }
        });
        evt.fire();
    }
})