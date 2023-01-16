({
    init : function(component, event, helper) {
        console.log("init 2");
        console.log("recordId", component.get("v.recordId"));
        var recordId = component.get("v.recordId");
        if (!recordId) {
            component.set("v.recordId", document.location.href.substring((document.location.href.length - 18)));
            if (document.location.href.includes('criar')) {
                component.set("v.isEdit", false);
            } else if (document.location.href.includes('gerar')) {
                component.set("v.isCreateOrderFromBudget", true);
            } else {
                component.set("v.isEdit", true);
            }
        }
        console.log(component.get("v.isEdit"));
        var isEdit = component.get("v.isEdit");
        var isBudget = component.get("v.isBudget");
        component.set("v.isReturn", false);
        window.setTimeout(function(){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: isEdit ? "Editar pedido" : "Criar pedido"
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
        debugger;
        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectclienteEmissor", (data.attributes.clienteEmissor));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissorCGC", (data.attributes.clienteEmissorCGC));
            component.set("v.headerObjectmedico", (data.attributes.medico));
            component.set("v.headerObjectmedicoId", (data.attributes.medicoId));
            component.set("v.headerObjectmedicoCRM", (data.attributes.medicoCRM));
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", (data.attributes.tabelaPrecoNome));
            component.set("v.headerObjecttipoFrete", (data.attributes.tipoFrete));
            component.set("v.headerObjectvalorFrete", (data.attributes.valorFrete));
            component.set("v.headerObjectnumeroPedidoCliente", (data.attributes.numeroPedidoCliente));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", (data.attributes.condicaoPagamentoNome));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectcanalVendas", (data.attributes.canalVendas));
            component.set("v.headerObjecttipoOrdem", (data.attributes.tipoOrdem));
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectdtPrevistaEntrega", (data.attributes.dtPrevistaEntrega));
            component.set("v.headerObjectclienteRecebedor", (data.attributes.clienteRecebedor));
            component.set("v.headerObjectclienteRecebedorCGC", (data.attributes.clienteRecebedorCGC));
            component.set("v.headerObjectenderecoEntrega", (data.attributes.enderecoEntrega));
            component.set("v.headerObjectenderecoEntregaId", (data.attributes.enderecoEntregaId));
            component.set("v.headerObjectenderecoEntregaContaOrdem", (data.attributes.enderecoEntregaContaOrdem));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectobservacaoNF", (data.attributes.observacaoNF));
            component.set("v.headerObjectobservacaoPedido", (data.attributes.observacaoPedido));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectpedidoComplementar", (data.attributes.pedidoComplementar));
            component.set("v.headerObjectorderListReturned", (data.attributes.orderListReturned));
            component.set("v.headerObjecthasPermissionERB", (data.attributes.hasPermissionERB));
            component.set("v.headerObjectgoToCheckout", (data.attributes.goToCheckout));
            component.set("v.headerObjectenderecoAdicional", (data.attributes.utilizarEnderecoAdicional));
            component.set("v.headerObjectIdportalcotacoes", (data.attributes.Idportalcotacoes));
            component.set("v.headerObjectrecomendacaoRespondida", (data.attributes.recomendacaoRespondida));
            component.set("v.headerObjectcreateOrderDt", (data.attributes.createOrderDt));
            component.set("v.headerLayout", false);
        } catch (e) {
            debugger;
            console.log(e);
        }
    },
    handleRetorno: function(component, event) {
         debugger;
        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.recordId", (data.attributes.recordId));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.headerObjectclienteEmissor", (data.attributes.clienteEmissor));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissorCGC", (data.attributes.clienteEmissorCGC));
            component.set("v.headerObjectmedico", (data.attributes.medico));
            component.set("v.headerObjectmedicoId", (data.attributes.medicoId));
            component.set("v.headerObjectmedicoCRM", (data.attributes.medicoCRM));
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", (data.attributes.tabelaPrecoNome));
            component.set("v.headerObjecttipoFrete", (data.attributes.tipoFrete));
            component.set("v.headerObjectvalorFrete", (data.attributes.valorFrete));
            component.set("v.headerObjectnumeroPedidoCliente", (data.attributes.numeroPedidoCliente));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", (data.attributes.condicaoPagamentoNome));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectcanalVendas", (data.attributes.canalVendas));
            component.set("v.headerObjecttipoOrdem", (data.attributes.tipoOrdem));
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectdtPrevistaEntrega", (data.attributes.dtPrevistaEntrega));
            component.set("v.headerObjectclienteRecebedor", (data.attributes.clienteRecebedor));
            component.set("v.headerObjectclienteRecebedorCGC", (data.attributes.clienteRecebedorCGC));
            component.set("v.headerObjectenderecoEntrega", (data.attributes.enderecoEntrega));
            component.set("v.headerObjectenderecoEntregaId", (data.attributes.enderecoEntregaId));
            component.set("v.headerObjectenderecoEntregaContaOrdem", (data.attributes.enderecoEntregaContaOrdem));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectobservacaoNF", (data.attributes.observacaoNF));
            component.set("v.headerObjectobservacaoPedido", (data.attributes.observacaoPedido));
            component.set("v.headerObjecthasPermissionERB", (data.attributes.hasPermissionERB));
            component.set("v.headerObjectgoToCheckout", (data.attributes.goToCheckout));
            component.set("v.headerObjectorderListReturned", (data.attributes.orderListReturned));
            component.set("v.headerObjectenderecoAdicional", (data.attributes.utilizarEnderecoAdicional));
            component.set("v.headerObjectIdportalcotacoes", (data.attributes.Idportalcotacoes));
            component.set("v.headerObjectcreateOrderDt", (data.attributes.createOrderDt));
            console.log('headerObjectIdportalcotacoes ' + data.attributes.Idportalcotacoes);
            component.set("v.headerObjectrecomendacaoRespondida", (data.attributes.recomendacaoRespondida));
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.isReturn", true);
            
            
            component.set("v.headerLayout", true);

        } catch (e) {
            debugger;
            console.log(e);
        }
    },
    handleNavigateToCheckout: function (component, event) {
        console.log("seiji 2");

        try {
            var data = JSON.parse(event.getParam('data'));
            component.set("v.newRecordId", (data.attributes.newRecordId));
            component.set("v.isEdit", (data.attributes.isEdit));
            component.set("v.headerObjectisBudget", (data.attributes.isBudget));
            component.set("v.headerObjectclienteEmissor", (data.attributes.clienteEmissor));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissorCGC", (data.attributes.clienteEmissorCGC));
            component.set("v.headerObjectmedico", (data.attributes.medico));
            component.set("v.headerObjectmedicoId", (data.attributes.medicoId));
            component.set("v.headerObjectmedicoCRM", (data.attributes.medicoCRM));
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", (data.attributes.tabelaPrecoNome));
            component.set("v.headerObjecttipoFrete", (data.attributes.tipoFrete));
            component.set("v.headerObjectvalorFrete", (data.attributes.valorFrete));
            component.set("v.headerObjectnumeroPedidoCliente", (data.attributes.numeroPedidoCliente));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", (data.attributes.condicaoPagamentoNome));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectcanalVendas", (data.attributes.canalVendas));
            component.set("v.headerObjecttipoOrdem", (data.attributes.tipoOrdem));
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectdtPrevistaEntrega", (data.attributes.dtPrevistaEntrega));
            component.set("v.headerObjectclienteRecebedor", (data.attributes.clienteRecebedor));
            component.set("v.headerObjectclienteRecebedorCGC", (data.attributes.clienteRecebedorCGC));
            component.set("v.headerObjectenderecoEntregaId", (data.attributes.enderecoEntregaId));
            component.set("v.headerObjectenderecoEntrega", (data.attributes.enderecoEntrega));
            component.set("v.headerObjectenderecoEntregaContaOrdem", (data.attributes.enderecoEntregaContaOrdem));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectobservacaoNF", (data.attributes.observacaoNF));
            component.set("v.headerObjectobservacaoPedido", (data.attributes.observacaoPedido));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectpedidoComplementar", (data.attributes.pedidoComplementar));
            component.set("v.headerObjectcnpjCd", (data.attributes.cnpjCd));
            component.set("v.headerObjecthasPermissionERB", (data.attributes.hasPermissionERB));
            component.set("v.headerObjectgoToCheckout", (data.attributes.goToCheckout));
            component.set("v.headerObjectorderList", data.attributes.orderList);
            component.set("v.headerObjectenderecoAdicional", (data.attributes.utilizarEnderecoAdicional));
            component.set("v.headerObjectIdportalcotacoes", (data.attributes.Idportalcotacoes));
            component.set("v.headerObjectrecomendacaoRespondida", (data.attributes.recomendacaoRespondida));
            component.set("v.headerObjectcreateOrderDt", (data.attributes.createOrderDt));
            component.set("v.navigateCheckout", false);
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
            component.set("v.headerObjectclienteEmissor", (data.attributes.clienteEmissor));
            component.set("v.headerObjectclienteEmissorId", (data.attributes.clienteEmissorId));
            component.set("v.headerObjectclienteEmissorCGC", (data.attributes.clienteEmissorCGC));
            component.set("v.headerObjectmedico", (data.attributes.medico));
            component.set("v.headerObjectmedicoId", (data.attributes.medicoId));
            component.set("v.headerObjectmedicoCRM", (data.attributes.medicoCRM));
            component.set("v.headerObjecttabelaPreco", (data.attributes.tabelaPreco));
            component.set("v.headerObjecttabelaPrecoNome", (data.attributes.tabelaPrecoNome));
            component.set("v.headerObjecttipoFrete", (data.attributes.tipoFrete));
            component.set("v.headerObjectvalorFrete", (data.attributes.valorFrete));
            component.set("v.headerObjectnumeroPedidoCliente", (data.attributes.numeroPedidoCliente));
            component.set("v.headerObjectcondicaoPagamento", (data.attributes.condicaoPagamento));
            component.set("v.headerObjectcondicaoPagamentoNome", (data.attributes.condicaoPagamentoNome));
            component.set("v.headerObjectcontatoOrcamento", (data.attributes.contatoOrcamento));
            component.set("v.headerObjectcanalVendas", (data.attributes.canalVendas));
            component.set("v.headerObjecttipoOrdem", (data.attributes.tipoOrdem));
            component.set("v.headerObjectformaPagamento", (data.attributes.formaPagamento));
            component.set("v.headerObjectdtPrevistaEntrega", (data.attributes.dtPrevistaEntrega));
            component.set("v.headerObjectclienteRecebedor", (data.attributes.clienteRecebedor));
            component.set("v.headerObjectclienteRecebedorCGC", (data.attributes.clienteRecebedorCGC));
            component.set("v.headerObjectenderecoEntregaId", (data.attributes.enderecoEntregaId));
            component.set("v.headerObjectenderecoEntrega", (data.attributes.enderecoEntrega));
            component.set("v.headerObjectenderecoEntregaContaOrdem", (data.attributes.enderecoEntregaContaOrdem));
            component.set("v.headerObjectobservacao", (data.attributes.observacao));
            component.set("v.headerObjectobservacaoNF", (data.attributes.observacaoNF));
            component.set("v.headerObjectobservacaoPedido", (data.attributes.observacaoPedido));
            component.set("v.headerObjectdtParcelas", (data.attributes.dtParcelas));
            component.set("v.headerObjectfretesPorCd", (data.attributes.fretesPorCd));
            component.set("v.headerObjectselectedProd", (data.attributes.selectedProd));
            component.set("v.headerObjectgetRecommendation", (data.attributes.getRecommendation));
            component.set("v.headerObjectalreadySaved", (data.attributes.alreadySaved));
            component.set("v.headerObjectsavingStrData", (data.attributes.savingStrData));
            component.set("v.headerObjectpedidoComplementar", (data.attributes.pedidoComplementar));
            component.set("v.headerObjecthasPermissionERB", (data.attributes.hasPermissionERB));
            component.set("v.headerObjectgoToCheckout", (data.attributes.goToCheckout));
            component.set("v.headerObjectorderListReturned", data.attributes.orderListReturned);
            component.set("v.headerObjectenderecoAdicional", (data.attributes.utilizarEnderecoAdicional));
            component.set("v.headerObjectIdportalcotacoes", (data.attributes.Idportalcotacoes));
            component.set("v.headerObjectrecomendacaoRespondida", (data.attributes.recomendacaoRespondida));
            component.set("v.headerObjectcreateOrderDt", (data.attributes.createOrderDt));
            component.set("v.headerLayout", false);
            component.set("v.navigateCheckout", true);
        } catch (error) {
            debugger;
            console.log(error);
        }
    },
    handleCloseClicked: function (component, event) {
        console.log('Fechando pedido!');
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