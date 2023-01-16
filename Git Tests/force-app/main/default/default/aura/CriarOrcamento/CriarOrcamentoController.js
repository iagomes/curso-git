({
    init : function(component, event, helper) {
        console.log("init 2");
        console.log(component.get("v.recordId"));
        console.log(component.get("v.isEdit"));
        var recordId = component.get("v.recordId");
        if (!recordId) {
            component.set("v.recordId", document.location.href.substring((document.location.href.length - 18)));
            if (document.location.href.includes('criar')) {
                component.set("v.isEdit", false);
            } else {
                component.set("v.isEdit", true);
            }
        }
        var isEdit = component.get("v.isEdit");
        window.setTimeout(function(){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: isEdit ? "Editar orçamento" : "Criar orçamento"
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
    },
    handleFilterChange: function(component, event) {
        try{
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectnumOrcamento", (data.attributes.numOrcamento));
            component.set("v.headerObjectvalorTotal", (data.attributes.valorTotal));
            component.set("v.headerObjectscore", (data.attributes.score));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissor", data.attributes.clienteEmissor);
            component.set("v.headerObjectclienteEmissorCGC", data.attributes.clienteEmissorCGC);
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", data.attributes.tabelaPrecoNome);
            component.set("v.headerObjectcanalEntrada", (data.attributes.canalEntrada));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", data.attributes.condicaoPagamentoNome);
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectprazoValidade", (data.attributes.prazoValidade));
            component.set("v.headerObjectdtValidade", (data.attributes.dtValidade));
            component.set("v.headerObjectobservacaoCliente", (data.attributes.observacaoCliente));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectisCoordenador", (data.attributes.isCoordenador));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjecthasPermissionERB", data.attributes.hasPermissionERB);
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectrecordId", data.attributes.recordId);
            component.set("v.headerObjectorderListReturned", data.attributes.orderListReturned);
            component.set("v.headerObjectIdportalcotacoes", data.attributes.Idportalcotacoes);
            component.set("v.headerObjectrecomendacaoRespondida", data.attributes.recomendacaoRespondida);
            component.set("v.headerLayout", false);
            component.set("v.filtroPDF", data.attributes.filtroPDF);    
        }catch(e){
            debugger;
            console.log(e);
        }
        // component.set('v.message', filters.length > 0 ? 'Your selection: ' + filters.join() : 'No selection');
    },
    handleNavigateToCheckout: function (component, event) {
        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectnumOrcamento", (data.attributes.numOrcamento));
            component.set("v.headerObjectvalorTotal", (data.attributes.valorTotal));
            component.set("v.headerObjectscore", (data.attributes.score));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissor", data.attributes.clienteEmissor);
            component.set("v.headerObjectclienteEmissorCGC", data.attributes.clienteEmissorCGC);
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", data.attributes.tabelaPrecoNome);
            component.set("v.headerObjectcanalEntrada", (data.attributes.canalEntrada));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", data.attributes.condicaoPagamentoNome);
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectprazoValidade", (data.attributes.prazoValidade));
            component.set("v.headerObjectdtValidade", (data.attributes.dtValidade));
            component.set("v.headerObjectobservacaoCliente", (data.attributes.observacaoCliente));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectisCoordenador", (data.attributes.isCoordenador));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjecthasPermissionERB", data.attributes.hasPermissionERB);
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectrecordId", data.attributes.recordId);
            component.set("v.headerObjectorderList", data.attributes.orderList);
            component.set("v.headerObjectIdportalcotacoes", data.attributes.Idportalcotacoes);
            component.set("v.headerObjectrecomendacaoRespondida", data.attributes.recomendacaoRespondida);
            component.set("v.navigateCheckout", false);
            component.set("v.navigateInsertOrder", true);
            component.set("v.filtroPDF", data.attributes.filtroPDF);
        } catch (e) {
            debugger;
            console.log(e);
        }
        // component.set('v.message', filters.length > 0 ? 'Your selection: ' + filters.join() : 'No selection');
    },
    handleNavigateToOrderProduct: function (component, event) {
        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectnumOrcamento", (data.attributes.numOrcamento));
            component.set("v.headerObjectvalorTotal", (data.attributes.valorTotal));
            component.set("v.headerObjectscore", (data.attributes.score));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissor", data.attributes.clienteEmissor);
            component.set("v.headerObjectclienteEmissorCGC", data.attributes.clienteEmissorCGC);
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", data.attributes.tabelaPrecoNome);
            component.set("v.headerObjectcanalEntrada", (data.attributes.canalEntrada));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", data.attributes.condicaoPagamentoNome);
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectprazoValidade", (data.attributes.prazoValidade));
            component.set("v.headerObjectdtValidade", (data.attributes.dtValidade));
            component.set("v.headerObjectobservacaoCliente", (data.attributes.observacaoCliente));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectisCoordenador", (data.attributes.isCoordenador));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjecthasPermissionERB", data.attributes.hasPermissionERB);
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectrecordId", data.attributes.recordId);
            component.set("v.headerObjectorderListReturned", data.attributes.orderListReturned);
            component.set("v.headerObjectrecomendacaoRespondida", data.attributes.recomendacaoRespondida);
            component.set("v.headerObjectselectedProd", (data.attributes.selectedProd));
            component.set("v.headerObjectgetRecommendation", (data.attributes.getRecommendation));
            component.set("v.headerObjectIdportalcotacoes", data.attributes.Idportalcotacoes);
            component.set("v.headerLayout", false);
            component.set("v.navigateCheckout", true);
            component.set("v.filtroPDF", data.attributes.filtroPDF);
        } catch (error) {
            debugger;
            console.log(error);
        }
    },
    handleNavigateToInsertOrder: function (component, event) {
        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectnumOrcamento", (data.attributes.numOrcamento));
            component.set("v.headerObjectvalorTotal", (data.attributes.valorTotal));
            component.set("v.headerObjectscore", (data.attributes.score));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissor", data.attributes.clienteEmissor);
            component.set("v.headerObjectclienteEmissorCGC", data.attributes.clienteEmissorCGC);
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", data.attributes.tabelaPrecoNome);
            component.set("v.headerObjectcanalEntrada", (data.attributes.canalEntrada));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", data.attributes.condicaoPagamentoNome);
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectprazoValidade", (data.attributes.prazoValidade));
            component.set("v.headerObjectdtValidade", (data.attributes.dtValidade));
            component.set("v.headerObjectobservacaoCliente", (data.attributes.observacaoCliente));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjecthasPermissionERB", data.attributes.hasPermissionERB);
            component.set("v.headerObjectisCoordenador", (data.attributes.isCoordenador));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectrecomendacaoRespondida", data.attributes.recomendacaoRespondida);
            component.set("v.headerObjectrecordId", data.attributes.recordId);
            component.set("v.headerObjectisFromBudgetScreen", data.attributes.isFromBudgetScreen);
            component.set("v.headerObjectorderListReturned", data.attributes.orderListReturned);
            component.set("v.headerInfoData", data.attributes.headerInfoData);
            component.set("v.navigateInsertOrder", false);
        } catch (error) {
            debugger;
            console.log(error);
        }
    },
    handleNavigateToInsertOrderInOrder: function (component, event) {
        console.log('InsertOrderInOrder entrou');
        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectnumOrcamento", (data.attributes.numOrcamento));
            component.set("v.headerObjectvalorTotal", (data.attributes.valorTotal));
            component.set("v.headerObjectscore", (data.attributes.score));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissor", data.attributes.clienteEmissor);
            component.set("v.headerObjectclienteEmissorCGC", data.attributes.clienteEmissorCGC);
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", data.attributes.tabelaPrecoNome);
            component.set("v.headerObjectcanalEntrada", (data.attributes.canalEntrada));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", data.attributes.condicaoPagamentoNome);
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectprazoValidade", (data.attributes.prazoValidade));
            component.set("v.headerObjectdtValidade", (data.attributes.dtValidade));
            component.set("v.headerObjectobservacaoCliente", (data.attributes.observacaoCliente));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjecthasPermissionERB", data.attributes.hasPermissionERB);
            component.set("v.headerObjectisCoordenador", (data.attributes.isCoordenador));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectrecomendacaoRespondida", data.attributes.recomendacaoRespondida);
            component.set("v.recordId", data.attributes.recordId);
            component.set("v.headerObjectorderListReturned", data.attributes.orderListReturned);
            component.set("v.isReturn", true);
            component.set("v.headerLayout", true);
        } catch (error) {
            debugger;
            console.log(error);
        }
    },
    handleCloseClicked: function(component, event) {
        console.log('Fechando orçamento!');
        component.set('v.message', 'Close Clicked');

        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({ tabId: focusedTabId });
        })
            .catch(function (error) {
                console.log(error);
            });
    }

})