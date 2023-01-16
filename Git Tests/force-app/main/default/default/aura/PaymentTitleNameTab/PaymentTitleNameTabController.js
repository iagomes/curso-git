({
    init : function(component, event, helper) {
        console.log("init 2");
        console.log(component.get("v.recordId"));
        var recordId = component.get("v.recordId");
        if (!recordId) {
            var accId = '';
            var url = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
            for (var i = 0; i < url.length; i++) {
                var params = url[i].split("=");
                if (params[0] == 'id') {
                    accId = params[1];
                }
            }
    
            // component.set("v.recordId", document.location.href.substring((document.location.href.length - 18)));
            component.set("v.recordId", accId);
            console.log('2 ' + component.get("v.recordId"));
        }

        window.setTimeout(function(){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: "Títulos"
                });            
                workspaceAPI.setTabIcon({
                    tabId: focusedTabId,
                    icon: "action:adjust_value",
                    iconAlt: "Tela Especial"
                });
            })
            .catch(function(error) {
                console.log(error);
            });
        }, 1000);
    }
    // },
    // handleFilterChange: function(component, event) {
        
    //         try{
    //             var data = JSON.parse(event.getParam('data'));
    //             component.set("v.headerObjectrecordId", data.attributes.recordId);  
    //             component.set("v.headerObjectclienteEmissor", data.attributes.clienteEmissor);  
    //             component.set("v.headerObjectclienteEmissorCGC", data.attributes.clienteEmissorCGC);  
    //             component.set("v.headerObjectcondicaoPagamentoNome", data.attributes.condicaoPagamentoNome);  
    //             component.set("v.headerObjecttabelaPrecoNome", data.attributes.tabelaPrecoNome);  
    //              component.set("v.headerLayout", false);
    //         }catch(e){
    //             debugger;
    //             console.log(e);

    //         }
    //     // component.set('v.message', filters.length > 0 ? 'Your selection: ' + filters.join() : 'No selection');
    // },
    // handleCloseClicked: function(component, event) {
    //     console.log('Fechando orçamento!');
    //     component.set('v.message', 'Close Clicked');

    //     var workspaceAPI = component.find("workspace");
    //     workspaceAPI.getFocusedTabInfo().then(function (response) {
    //         var focusedTabId = response.tabId;
    //         workspaceAPI.closeTab({ tabId: focusedTabId });
    //     })
    //         .catch(function (error) {
    //             console.log(error);
    //         });
    // }

})