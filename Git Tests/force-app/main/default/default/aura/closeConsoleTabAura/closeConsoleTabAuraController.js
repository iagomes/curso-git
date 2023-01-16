({
    handleInit: function(component) {
      var workspaceAPI = component.find("workspace");

      workspaceAPI.getFocusedTabInfo()
        .then(function(response) {
          var focusedTabId = response.tabId;
          component.set("v.focusedTabId", focusedTabId);

          console.log("getFocusedTabInfo => response.tabId:", JSON.stringify(response.tabId));

          workspaceAPI.isSubtab({ tabId: response.tabId })
            .then(function(isSubtabResponse) {
              // console.log("isSubtab() =>", JSON.stringify(isSubtabResponse));
               if (!isSubtabResponse) {
                workspaceAPI.getTabInfo({ tabId: response.tabId })
                  .then(function(tabInfoResponse) {
                    var subtabs = tabInfoResponse.subtabs;

                    for (var i=0; i<subtabs.length; i++) {
                      if (subtabs[i].focused) {
                        // console.log("subtab in focus: ", subtabs[i].tabId);
                        component.set("v.focusedTabId", subtabs[i].tabId);
                        break;
                      }
                    }
                  })
                  .catch(function(error) {
                    console.log(error);
                    component.set("v.focusedTabId", "");
                  });
              }
            })
            .catch(function(error) {
              console.log(error);
              component.set("v.focusedTabId", "");
            });
        })
        .catch(function(error) {
          console.log(error);
          component.set("v.focusedTabId", "");
        });
    },

    handleMessage: function(component, event, helper) {
      var focusedTabId = component.get("v.focusedTabId");

      if (event != null && !!focusedTabId) {
        var workspaceAPI = component.find("workspace");
        var focusedTabId = component.get("v.focusedTabId");

        if (event.getParams() && !!event.getParams()) {
          var params = event.getParams();

          if (!!params.recordId) {
            // console.log("Open tab:", params.recordId);
            workspaceAPI.openTab({
              url: '#/sObject/'+ params.recordId +'/view',
              focus: true
            });
          }
        }

        // console.log("focusedTabId:", focusedTabId);
        workspaceAPI.closeTab({ tabId: focusedTabId });
      } else {
        var workspaceAPI = component.find("workspace");
        
        if (event.getParams() && !!event.getParams()) {
          var params = event.getParams();
          if (!!params.recordId) {
            
            workspaceAPI.openTab({
              url: '#/sObject/'+ params.recordId +'/view',
              focus: true
            });
          }
        }
      }
    }
})
