import { LightningElement, track, api } from 'lwc';
import getLotes from '@salesforce/apex/ProductShelfLifeController.getLotes';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';

const BORDER_DEFAULT = 'borderCard borderDefault';
const BORDER_ERROR = 'borderCard borderError';
export default class ProductShelfLife extends LightningElement {

    @track isModalOpen;
    @track openSelected = false;
	@track isLoadingLotes;
	@track infoList;
	@track allValues;

	@api orderList;
	@api cd;
    @api prodCode;
    @api primaryId;
    @api cdId;
    @api cdCnpj;
    @api prodName;
    @api centroDistribuicao;
    @api unidadeMedida;
    @api shelfLife;
    @api shelfPriceCnpj;
    @api shelfPriceProd;
    @api disableButton = false;
    @api addButton;
    @api loteSelecionado;

	connectedCallback() {
		console.log('ProductShelfLife Screen');
		console.log(this.orderList);
		console.log(this.prodCode);
		console.log(this.primaryId);
		console.log(this.cdId);
		console.log(this.cdCnpj);
		console.log(this.prodName);
		console.log(this.centroDistribuicao);
		console.log(this.unidadeMedida);
		console.log(this.shelfPriceCnpj);
		console.log(this.shelfPriceProd);
		console.log(this.disableButton);
		this.addButton = this.addButton == "true" ? true : false;
	}

    closeModal(event) {
        console.log(event);
        this.isModalOpen = false;
    }

    openModal(event) {
        // to open modal set openModal tarck value as true
        this.isModalOpen = true;
		this.handleSelectedInfo(event);
    }

	checkQuantityWithSaldo() {
		let haveSomeItemWithError = false;
		this.infoList.forEach(item => {
			if(item.isShelflife) {
				if(item.quantidade >= 0) {
					if(Number(item.quantidade) > Number(item.saldo)) {
						haveSomeItemWithError = true;
						item.borderCard = BORDER_ERROR;
						console.log('item.quantidade => ' + item.quantidade);
						console.log('item.saldo => ' + item.saldo);
					} else {
						item.borderCard = BORDER_DEFAULT;
					}
				} else {
					haveSomeItemWithError = true;
					item.borderCard = BORDER_ERROR;
					console.log('item.quantidade => ' + item.quantidade);
					console.log('item.saldo => ' + item.saldo);
				}
			}
		});

		if(haveSomeItemWithError) {
			swal('Divergência', 'Não é possível adicionar uma quantidade maior do que a quantidade do saldo. \n Ajuste os itens com divergência e tente novamente!', 'error');
		}

		return haveSomeItemWithError;
	}

	checkPriceWithMinimumOrMaximum() {
		let haveSomeItemWithError = false;

		let minimumPrice = 0.0;
		let maximumPrice = 0.0;

		let findError = false;

		this.infoList.forEach(item => {
			if(item.isShelflife  && !findError) {
				console.log('parseFloat(item.preco) => ' + parseFloat(item.preco));
				console.log('parseFloat(item.minimumPrice) => ' + parseFloat(item.minimumPrice));
				console.log('parseFloat(item.maximumPrice) => ' + parseFloat(item.maximumPrice));
				if(parseFloat(item.preco) >= parseFloat(item.minimumPrice)) {
					item.borderCard = BORDER_DEFAULT;
				} else {
					item.borderCard = BORDER_DEFAULT;
					haveSomeItemWithError = true;
					item.borderCard = BORDER_ERROR;
					minimumPrice = item.minimumPrice;
					maximumPrice = item.maximumPrice;
				}
			}
		});

		if(haveSomeItemWithError) {
			swal({
				title: 'Aviso!', 
				text: 'Só é possível inserir valores acima do preço mínimo. \nPreço mínimo: ' + minimumPrice.toString(),
				closeOnClickOutside: false,
				closeOnEsc: false,
				icon: 'info'}).then(ok => {
				if(ok) {
					this.infoList.find(item => item.id == loteId).preco = lastValue;
				}
			});
		}

		return haveSomeItemWithError;
	}

	handleAddLotes() {		
		if(this.checkQuantityWithSaldo()) return;
		if(this.checkPriceWithMinimumOrMaximum()) return;
        this.isModalOpen = false;
		let sendList = [];

		this.infoList.forEach(item => {
			if (item.quantidade > 0) {
				console.log(item.id);
				item.loteSelecionado = true;
				sendList.push(item);

			}
		});
		
		console.log('sendList ==> ' + JSON.stringify(sendList));
        this.dispatchEvent(
            new CustomEvent('closeshelflife', {
                detail: {
                    record: 'fechou',
					shelfLifeList: JSON.stringify(sendList)
                }
            })
        );
	}

	async onChangeQuantity(event) {
		// console.log(event.currentTarget.dataset.loteId);
		// console.log(event.target.value);
		let loteId = event.currentTarget.dataset.loteId;
		this.infoList.find(item => item.id == loteId).quantidade = event.target.value;
	// 	let saldo = this.infoList.find(item => item.id == loteId).saldo;
	// 	console.log('saldo => ' + saldo);
	// 	let lastQuantity = this.infoList.find(item => item.id == loteId).quantidade;
	// 	console.log('lastQuantity => ' + lastQuantity);
	// 	let quantidade = event.target.value;
	// 	console.log('quantidade => ' + quantidade);
	// 	if(Number(quantidade) > Number(saldo)) {
	// 		await swal('Atenção', 'A quantidade informada não pode ser maior do o saldo.', 'error').then(result => {
	// 			if(result) {
	// 				this.infoList.find(item => item.id == loteId).quantidade = lastQuantity;
	// 			} else {
	// 				this.infoList.find(item => item.id == loteId).quantidade = lastQuantity;
	// 			}
	// 		});
	// 	} else {
	// 		this.infoList.find(item => item.id == loteId).quantidade = event.target.value;
	// 	}
	}

	async onChangePrice(event) {
		let loteId = event.currentTarget.dataset.loteId;
		let price = parseFloat(event.target.value);
		this.infoList.find(item => item.id == loteId).preco = price;
		this.infoList.find(item => item.id == loteId).precoScreen = this.getCurrencyFormat(price);

		// let minimumPrice = parseFloat(this.infoList.find(item => item.id == loteId).minimumPrice);
		// let maximumPrice = parseFloat(this.infoList.find(item => item.id == loteId).maximumPrice);
		// let lastValue = parseFloat(this.infoList.find(item => item.id == loteId).preco);

		// this.infoList.find(item => item.id == loteId).preco = price;
		// this.infoList.find(item => item.id == loteId).precoScreen = this.getCurrencyFormat(price);
		
		// if((price >= minimumPrice && price <= maximumPrice) || isNaN(price)) {
		// 	this.infoList.find(item => item.id == loteId).preco = price;
		// 	this.infoList.find(item => item.id == loteId).precoScreen = this.getCurrencyFormat(price);
		// } else {
		// 	this.infoList.find(item => item.id == loteId).preco = undefined;

		// 	await swal({
		// 		title: 'Aviso!', 
		// 		text: 'Só é possível inserir valores dentro deste intervalo. \nPreço mínimo: ' + minimumPrice.toString() + '\n Preço máximo: ' + maximumPrice.toString(),
		// 		closeOnClickOutside: false,
		// 		closeOnEsc: false,
		// 		icon: 'info'}).then(ok => {
		// 		if(ok) {
		// 			this.infoList.find(item => item.id == loteId).preco = lastValue;
		// 		}
		// 	});
		// }
	}

    handleSelectedInfo(event) {
		console.log('this.orderList ==> ' + JSON.stringify(this.orderList));
		console.log('this.prodCode ==> ' + JSON.stringify(this.prodCode));
		console.log('this.primaryId ==> ' + JSON.stringify(this.primaryId));
		console.log('this.cdId ==> ' + JSON.stringify(this.cdId));
		console.log('this.cdCnpj ==> ' + JSON.stringify(this.cdCnpj));
		console.log('this.prodName ==> ' + JSON.stringify(this.prodName));
		console.log('this.centroDistribuicao ==> ' + JSON.stringify(this.centroDistribuicao));
		console.log('this.unidadeMedida ==> ' + JSON.stringify(this.unidadeMedida));
		console.log('this.shelfPriceCnpj ==> ' + JSON.stringify(this.shelfPriceCnpj));
		console.log('this.shelfPriceProd ==> ' + JSON.stringify(this.shelfPriceProd));
		console.log('this.disableButton ==> ' + JSON.stringify(this.disableButton));
		console.log('this.cd: ' + JSON.stringify(this.cd));

		let productCode = event.currentTarget.dataset.productCode;
		let savedCdCnpj = event.currentTarget.dataset.cdCnpj;
		event.stopPropagation();
		this.infoList = [];
		console.log(this.shelfPriceCnpj);
		this.allValues = [];
		try {
			if (this.shelfPriceCnpj) {			
				if (this.shelfPriceCnpj.includes(';')) {
					this.allValues = this.shelfPriceCnpj.split(';');
				} else {
					this.allValues.push(this.shelfPriceCnpj);
				}
			}
		} catch (error) {
			console.log(error);
		}
		this.isLoadingLotes = true;
		getLotes({ clienteCGC: savedCdCnpj, productCode: productCode })
			.then(result => {
				this.isLoadingLotes = false;
				console.log('getLotes: entrou certo!');
				console.log('result: => ' + JSON.stringify(result));

				let currentInfo = [];
				if (result != null) {
					currentInfo = result;
					console.log('currentInfo: ' + JSON.stringify(currentInfo));
					for (var i = 0; i < currentInfo.length; i++) {
						let shelfLifePrice = 0;
						if (this.shelfPriceCnpj) {
							this.allValues.forEach(val => {
								if (val.includes(currentInfo[i].lote) && val.includes(savedCdCnpj)) {
									shelfLifePrice = val.split('_')[2];
								}
							});
						}
						let qtd = 0;
						if (this.orderList) {
							let orderItem = this.orderList.find(item => ((item.id.includes(this.primaryId + '_' + currentInfo[i].lote) || item.id == this.primaryId)) && item.lote == currentInfo[i].lote);
							if (orderItem) {
								qtd = orderItem.quantidadeCx;
							}
						}
						console.log('shelfLifePrice: ' + shelfLifePrice);
						console.log('qtd: ' + qtd);
						console.log('shelfPriceProd: ' + this.shelfPriceProd);
						console.log('this.orderList: ' + JSON.stringify(this.orderList));
						console.log('this.centroDistribuicao: ' + JSON.stringify(this.centroDistribuicao));
						console.log('this.cd: ' + JSON.stringify(this.cd));
						if(parseInt(currentInfo[i].estoque).toString() != '0') {
							console.log('currentInfo[i]: ' + JSON.stringify(currentInfo[i]));
							if(this.orderList.length != 0) {
								let key = this.cdId + '_' + currentInfo[i].lote;
								console.log('key: ' + JSON.stringify(key));
								let orderItem = this.orderList.filter(orderItem => orderItem.cdId == key);
								console.log('orderItem: ' + JSON.stringify(orderItem));
								if(orderItem) {
									console.log('orderItem.caixa: ' + JSON.stringify(orderItem.caixa));
									this.infoList.push({
										id: i+1,
										idFromCdList: this.primaryId,
										prodCode: this.prodCode,
										cdId: this.cdId,
										cdCnpj: this.cdCnpj,
										lote: currentInfo[i].lote,
										validade: this.getFormatDate(currentInfo[i].validade),
										saldo: parseInt(currentInfo[i].estoque).toString(),
										precoScreen: currentInfo[i].is_shelflife ? this.getCurrencyFormat(Number(orderItem[0].caixa)) : this.getCurrencyFormat(Number(shelfLifePrice)),
										preco: Number(currentInfo[i].is_shelflife ? orderItem[0].caixa : shelfLifePrice),
										quantidade: qtd,
										borderCard: BORDER_DEFAULT,
										isShelflife: currentInfo[i].is_shelflife,
										minimumPrice: currentInfo[i].minimum_price,
										maximumPrice: currentInfo[i].maximum_price,
										infoPrice: 'Preço mínimo: ' + currentInfo[i].minimum_price.toString() + ' | Preço máximo: ' + currentInfo[i].maximum_price.toString(),
										diasProduto: this.getProductQuantityDays(currentInfo[i].validade)
									});
								} else {
									this.infoList.push({
										id: i+1,
										idFromCdList: this.primaryId,
										prodCode: this.prodCode,
										cdId: this.cdId,
										cdCnpj: this.cdCnpj,
										lote: currentInfo[i].lote,
										validade: this.getFormatDate(currentInfo[i].validade),
										saldo: parseInt(currentInfo[i].estoque).toString(),
										precoScreen: currentInfo[i].is_shelflife ? this.getCurrencyFormat(Number(this.cd.caixa)) : this.getCurrencyFormat(Number(shelfLifePrice)),
										preco: Number(currentInfo[i].is_shelflife ? this.cd.caixa : shelfLifePrice),
										quantidade: qtd,
										borderCard: BORDER_DEFAULT,
										isShelflife: currentInfo[i].is_shelflife,
										minimumPrice: currentInfo[i].minimum_price,
										maximumPrice: currentInfo[i].maximum_price,
										infoPrice: 'Preço mínimo: ' + currentInfo[i].minimum_price.toString() + ' | Preço máximo: ' + currentInfo[i].maximum_price.toString(),
										diasProduto: this.getProductQuantityDays(currentInfo[i].validade)
									});
								}
							} else {
								this.infoList.push({
									id: i+1,
									idFromCdList: this.primaryId,
									prodCode: this.prodCode,
									cdId: this.cdId,
									cdCnpj: this.cdCnpj,
									lote: currentInfo[i].lote,
									validade: this.getFormatDate(currentInfo[i].validade),
									saldo: parseInt(currentInfo[i].estoque).toString(),
									precoScreen: currentInfo[i].is_shelflife ? this.getCurrencyFormat(Number(this.cd.caixa)) : this.getCurrencyFormat(Number(shelfLifePrice)),
									preco: Number(currentInfo[i].is_shelflife ? this.cd.caixa : shelfLifePrice),
									quantidade: qtd,
									borderCard: BORDER_DEFAULT,
									isShelflife: currentInfo[i].is_shelflife,
									minimumPrice: currentInfo[i].minimum_price,
									maximumPrice: currentInfo[i].maximum_price,
									infoPrice: 'Preço mínimo: ' + currentInfo[i].minimum_price.toString() + ' | Preço máximo: ' + currentInfo[i].maximum_price.toString(),
									diasProduto: this.getProductQuantityDays(currentInfo[i].validade)
								});
							}
						}
					}
					console.log('this.infoList ==> ' + JSON.stringify(this.infoList));
				} else {
					swal({
						title: 'Erro!', 
						text: 'Consulta de lotes indiponível.\n Tente novamente ou entre em contato com o administrador do sistema!',
						closeOnClickOutside: false,
						closeOnEsc: false,
						icon: 'error'});
				}
			}).catch(error => {
				this.isLoadingLotes = false;
				console.log('getLote: entrou no erro!');
				console.log(error);
			});
	}

	getFormatDate(input) {
		var datePart = input.match(/\d+/g),
			year     = datePart[0],
			month    = datePart[1],
			day      = datePart[2];

		return day + '/' + month + '/' + year;
	}

	getCurrencyFormat(price) {
		return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(price);
	}

	getProductQuantityDays(input) {
		const oneDay = 1000 * 60 * 60 * 24;
	
		var datePart = input.match(/\d+/g);
	
		// const firstDate = new Date(datePart[0],datePart[1],datePart[2]);
		// const today = new Date();
		// const secondDate = new Date(today.getFullYear(),String(today.getMonth() + 1).padStart(2, '0'),String(today.getDate()).padStart(2, '0'));
		// const productDays = Math.round((firstDate - secondDate) / oneDay);
	
		// let dayMilliSeconds = 1000 * 60 * 60 * 24;
		//  // finding difference between current date and other date
		//  let todaySDate = new Date(new Date().toISOString().slice(0, 10));
		//  let currentDiff = new Date(datePart) - todaySDate;
		//  let totalDays = Math.abs(currentDiff / dayMilliSeconds);
		//  console.log(Math.floor(totalDays));
	
		//  console.log(input);
		//  console.log(datePart);
		//  console.log(datePart[1],datePart[2],datePart[0]);
	
		 let today = new Date().toISOString().slice(0, 10);
	
		 const startDate  = datePart[0]+'-'+datePart[1]+'-'+datePart[2];
		 const endDate    = today;
		 
		 const diffInMs   =  new Date(startDate) -new Date(endDate) 
		 const diffInDays = diffInMs / (1000 * 60 * 60 * 24);
	
		return diffInDays.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
	}
}