const statusFilterConst = () => {
    return [
        {label: 'Aguardado sua resposta', value: 'awaitYourResp'},
        {label: 'Parcialmente respondidos', value: 'partResp'},
        {label: 'Nenhuma resposta', value: 'noneResp'},
        {label: 'Totalmente respondidos', value: 'allResp'},
        {label: 'Todas solicitações', value: 'all'},
        {label: 'Cotado', value: 'quoted'},
        {label: 'Não cotado', value: 'tabulatedNotOffered'},
    ];
} 

const itemsTableConst = () => {
    return [
        { 
            label: 'Sequência', 
            fieldName: 'sequencia', 
            initialWidth: 50,
            cellAttributes: {class:{fieldName: 'style2Class'}, 
                alignment: 'left' 
            } 
        },
        // { 
        //     label: 'Código',
        //     initialWidth: 150,
        //     fieldName: 'quoteitemUrl',
        //     cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left' },
        //     type: "url",
        //     typeAttributes: { 
        //         label: { fieldName: 'idCustomer' }
        //     }
        // },
        { 
            label: 'Descrição do Produto', 
            fieldName: 'customerDescription',
            cellAttributes: {class:{fieldName: 'style2Class'}, 
                alignment: 'left' 
            } 
        },
        { label: 'Quantidade', fieldName: 'quantidadeSolicitada', cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left' }, initialWidth: 90, type: 'number' },
        { label: 'Unidade medida', fieldName: 'customerMeasurementUnit', initialWidth: 150, cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left' } },
        { 
            label: 'Marcas favoritas',
            fieldName: 'favoriteBrands',
            cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left' },
            type: "text"
        },
        { 
            label: 'Categoria',
            fieldName: 'categoriaCliente',
            cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left' },
            type: "text"
        },
        { label: 'Estoque', fieldName: 'estoqueStr', initialWidth: 150, cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left' } },
        { label: 'Status do item', fieldName: 'statusItem', initialWidth: 230, cellAttributes: {class:{fieldName: 'styleStatus2Class'}, alignment: 'left' } },
        {
            label: '',
            fieldName: '',
            type: 'CustomIcon',
            cellAttributes: {class:{fieldName: 'style2Class'}, alignment: 'left'},
            initialWidth: 50,
            typeAttributes:{
                iconName: { fieldName: 'dynamicIcon' },
                size: 'small',
                tooltip: 'Item Cotado'
            }
        },
        { 
            label: '', 
            fieldName: 'idPortal', 
            type: 'CustomButtons',
            cellAttributes: {class:{fieldName: 'style2Class'}},
            initialWidth: 80,
            typeAttributes: { 
                isEntrega: {fieldName:'isEntrega'},
                indexB: {fieldName: 'indexB'}
            }
        },
    ];
}

export {statusFilterConst, itemsTableConst};