({
    init : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");

        if (!workspaceAPI) {
            return null;
        }
        
        workspaceAPI.getFocusedTabInfo()
            .then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: "Adicionar itens"
                });     

                workspaceAPI.setTabIcon({
                    tabId: focusedTabId,
                    icon: "utility:advertising",
                    iconAlt: "Adicionar itens"
                });
            })
            .catch(function(error) {
                console.log(error);
            });
    }
})
