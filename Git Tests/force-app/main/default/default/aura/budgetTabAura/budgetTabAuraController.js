({
    onTabFocused : function(component, event, helper) {
        let focusedTabId = event.getParam('currentTabId');
        if(!focusedTabId){
            
            let budgetTabVar = component.find('budgetTab');
            if(budgetTabVar){

                let lastParams = budgetTabVar.getLastParams();
                if(lastParams && Object.keys(lastParams).length > 0){
                   
                    budgetTabVar.doSearch(lastParams);
                    budgetTabVar.getOrders();
                } 
                budgetTabVar.handleSubscripe();
            }
        }
        else{
            let budgetTabVar = component.find('budgetTab');
            if(budgetTabVar){
                budgetTabVar.handleUnsubscribe();
            }
        }
    },
    handleOrderClick: function(component, event) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__component",
                "attributes": {
                    "componentName": "c__orderListWonWrapper"
                },
                "state":{
                    "uid":"1"
                }
                
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.setTabLabel({tabId:response, label:'Pedidos Ganhos'})
            workspaceAPI.setTabIcon({tabId:response, icon:'standard:drafts',iconAlt:'Meus pedidos ganhos'})            
        }).catch(function(error) {
            console.log('tabiderror: '+error)
            console.log(error);
        });
    }
})