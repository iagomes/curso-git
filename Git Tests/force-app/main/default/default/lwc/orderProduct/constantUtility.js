const optionsRefuseUtils = () => {
    return [
        { label: 'Sem interesse por ainda ter estoque', value: 'Recusada sem interesse por ainda ter estoque' },
        { label: 'Não trabalha com este produto', value: 'Recusada não trabalha com este produto' },
        { label: 'Sem interesse por ser laboratório/marca não padronizada', value: 'Recusada sem interesse por ser laboratório/marca não padronizada' },
        { label: 'Sem interesse por prazo de entrega', value: 'Recusada sem interesse por prazo de entrega' },
        { label: 'Sem interesse pelo preço', value: 'Recusada sem interesse pelo preço' },
        { label: 'Outros', value: 'Recusada (Outros Justificar)' }
    ];
}

const radioOptionsUtils = () => {
    return [
        { label: "Com saldo", value: "Com saldo" },
        { label: "Todos os itens",  value: "Todos os itens" }
    ];
}

const orderOptionsUtils = () => {
    return [
        { label: "Maior Preço", value: "Maior Preço" },
        { label: "Menor Preço",  value: "Menor Preço" },
        { label: "Maior Saldo", value: "Maior Saldo" },
        { label: "Menor Saldo",  value: "Menor Saldo" }
      ];
}

const validityOptionsUtils = () => {
    return [
        { label: "7 dias", value: "168" },
        { label: "30 dias", value: "720" },
        { label: "60 dias",  value: "1440" },
        { label: "90 dias", value: "2160" },
        { label: "180 dias",  value: "4320" },
        { label: "1 ano",  value: "8760" },
        { label: "18 meses",  value: "13140" },
        { label: "24 meses",  value: "17520" },
        { label: "Shelf Life",  value: "Shelf Life" },
        { label: "Vazio",  value: "Vazio" }
      ];
}

export {optionsRefuseUtils, radioOptionsUtils, orderOptionsUtils, validityOptionsUtils};