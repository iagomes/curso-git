({
    onTabFocused : function(component, event, helper) {
        let focusedTabId = event.getParam('currentTabId');
        let workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo({tabId:focusedTabId})
        .then(response=>{
            if(response['customTitle']==='Pedidos Ganhos'){
                let orderListWon = component.find('orderListWon');
                orderListWon.getOrdersListWon();
            }
        });
    }
})
