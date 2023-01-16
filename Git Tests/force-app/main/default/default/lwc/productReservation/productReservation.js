import { LightningElement, track, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
// import getBaseData from '@salesforce/apex/ReservationManagement.getBaseData';
import getProducts from '@salesforce/apex/ReservationManagement.getProducts';
import upsertReserveProduct from '@salesforce/apex/ReservationManagement.upsertReserveProduct';
import transferProducts from '@salesforce/apex/ReservationManagement.transferProducts';
import getReserveInformation from '@salesforce/apex/ReservationManagement.getReserveInformation';
import deleteProductReservation from '@salesforce/apex/ReservationManagement.deleteProductReservation';
import deleteReservationHeader from '@salesforce/apex/ReservationManagement.deleteReservationHeader';
import getReservedProducts from '@salesforce/apex/ReservationManagement.getReservedProducts';
import getUnlimitedReservedProducts from '@salesforce/apex/ReservationManagement.getUnlimitedReservedProducts';
import checkHaveSomeReserveWithTheSameCD from '@salesforce/apex/ReservationManagement.checkHaveSomeReserveWithTheSameCD';
import validateApprovers from '@salesforce/apex/ReservationManagement.validateApprovers';
import createProductsReservationByCSVFile from '@salesforce/apex/ReservationManagement.createProductsReservationByCSVFile';
import getTotalProductsReservation from '@salesforce/apex/ReservationManagement.getTotalProductsReservation';
import AllJsFilesSweetAlert from '@salesforce/resourceUrl/AllJsFilesSweetAlert';
import { NavigationMixin } from 'lightning/navigation';

import refreshProductReservationChannel from '@salesforce/messageChannel/refreshProductReservationChannel__c';
import {MessageContext, createMessageContext, releaseMessageContext, publish, subscribe, unsubscribe} from 'lightning/messageService';
import closeConsoleTab from "@salesforce/messageChannel/CloseConsoleTab__c";
import refreshProducts from '@salesforce/apex/CampaignManagementController.refreshProducts';
import refreshProductsApex from '@salesforce/apex/ReservationManagement.refreshProductsApex';
import getTotalValueReserved from '@salesforce/apex/ReservationManagement.getTotalValueReserved';
export default class ProductReservation extends NavigationMixin(LightningElement) {
	lengthReservedProductLastSearch = 0;
	lengthNotReservedProductLastSearch = 0;
	isConnectedCallBack = false;
	productFilterListNaoReservados = [];
	productFilterListReservados = [];
	ultimaAtualizacao;
	totalProducts;
	showGetAllProducts = true;
	isByCSV = false;

	getAllProducts = false;
	@track isLoadingScreen = false;
	isLoadingProductsTransfer = false;
	@track reserve;
	@track reserveToTransfer = {"Id": "", "DistributionCenterCode": ""};

	@track resetScroll = false;

	@track transferProductsMode = undefined;
	disableContinue = true;
	// @track transferProduct = false;

	//radioGroupVariables
	get options() {
        return [
			{ label: 'Não reservados', value: '1' },
            { label: 'Reservados', value: '2' }
        ];
    }

	@track radioButtonValue = '1';
	//end

	//messageChannel 
	context = createMessageContext();
	subscription = null;

	@track tabTodos = false;
	@track tabAdicionados = false;

	@api recordId;

	@track prodList = [];
	// @track prodListSort = [];
	@track prodFilterList = [];
	@track reservedProdList = [];
	@track searchGenericValue = '';
	@track searchFabricanteValue = '';
	@track saldoFinanceiro;
	@track valorTotalReservado = 0;
	@track valorTotalReservadoTela = this.getCurrencyFormat(0);
	@track valorTotalDif = 0;
	@track valorTotalDifTela = this.getCurrencyFormat(0);

	@track wantAddProduct = false;
	@track insertCSV = false;
	@track isValidCSV = false;

	// @track saldoLiberado = 5000;
	// @track saldoConsumido = 2000;
	// @track disableSaldoFinanceiro = false;
	@track cliente;
	@track grupoCliente;
	@track vigenciaInicial;
	@track vigenciaFinal;
	@track offSetValue = 0;
	@track offSetValueReservados = 0;
	@track offSetValueNaoReservados = 0;
	@track isLoadingProducts = false;
	@track hasMoreProducts = false;
	@track disableAllButtons = false;
	@track hasProducts = false;
	@track hasProductsAdd = false;

	get tipoReserva() {
		return [
			{ label: 'Key Account' , value: 'Key Account' },
			{ label: 'Regional', value: 'Regional'}
		]
	}

	get centDistribuicao() {
		return [
			{ label: 'Matriz Goiania' , value: 'Matriz Goiania' },
			{ label: 'Matriz Ribeirão Preto', value: 'Matriz Ribeirão Preto'}
		]
	}

	get storage() {
		return [
			{ label: 'Matriz Goiania' , value: 'Matriz Goiania' },
			{ label: 'Matriz Ribeirão Preto', value: 'Matriz Ribeirão Preto'}
		]
	}

	@wire(MessageContext)
	messageContext;

	handlePublishCloseTab() {
		publish(this.messageContext, closeConsoleTab);
	}

	handleChange() {
		console.log('Alterou');
	}

	handleAddProduct(event) {
		this.searchGenericValue = '';
		this.wantAddProduct = !this.wantAddProduct;
	}

	handleAddProductAdicionados(event) {
		this.searchGenericValue = '';
		this.wantAddProduct = !this.wantAddProduct;
		console.log('this.wantAddProduct ' + this.wantAddProduct);
		// this.researchProduct();
		if(!this.wantAddProduct) {
			this.prodFilterList = this.cloneObj(this.productFilterListReservados);
			this.checkHasMoreProduct(this.productFilterListReservados);
			console.log('this.productFilterListReservados.length ' + this.productFilterListReservados.length);
		} else if(this.radioButtonValue == '1') {
			this.prodFilterList = this.cloneObj(this.productFilterListNaoReservados);
			this.checkHasMoreProduct(this.productFilterListNaoReservados);
			console.log('this.productFilterListNaoReservados.length ' + this.productFilterListNaoReservados.length);
		} else {
			this.checkHasMoreProduct(this.productFilterListReservados);
			console.log('this.productFilterListReservados.length ' + this.productFilterListReservados.length);
		}
		console.log('this.hasMoreProducts handleAddProductAdicionados: ' + this.hasMoreProducts);
	}

	researchProduct() {
		this.valorTotalDif = 0;
		this.valorTotalDifTela = this.getCurrencyFormat(0);
		this.prodList = [];
		// this.prodListSort = [];
		this.prodFilterList = [];
		if (this.wantAddProduct && this.radioButtonValue == '1') {
			this.searchProducts();
			this.tabTodos = true;
			this.tabAdicionados = true;
		} else {
		// 	this.prodList = [];
		// 	this.prodListSort = [];
		// 	this.prodFilterList = [];
			this.offSetValue = 0;
			this.searchReservedProducts();
			this.tabTodos = false;
			this.tabAdicionados = true;
		}
	}

	renderedCallback(){
		console.log('rendered callback');
	}

	getFormattedDate() {
		var date = new Date();
		var str = date.getDate() + "/" + (date.getMonth() + 1) + "/" + date.getFullYear() + " " +  date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds();
	
		return str;
	}

	async connectedCallback() {
		getTotalProductsReservation({reserveId: this.recordId}).then(totalProducts => {
			this.totalProducts = totalProducts;
		}).catch(error => {
			console.log('error ==> ' + error);
		});
		this.ultimaAtualizacao = this.getFormattedDate();
		this.isConnectedCallBack = true;
		Promise.all([loadScript(this, AllJsFilesSweetAlert + '/sweetalert-master/sweetalert.min.js')]).then(() => { console.log('Files loaded.'); }).catch(error => { console.log('error: ' + JSON.stringify(error)); });
		console.log('Entrou no connected callback do produtReservation');
		console.log(this.recordId);

		this.tabTodos = false;
		this.tabAdicionados = true;
		this.reserve = await getReserveInformation({recordId: this.recordId});
		console.log('this.reserve ==> ' + this.reserve);

		this.disableAllButtons = !await validateApprovers({reservationCurrentId: this.recordId});
		if(!this.disableAllButtons) {
			console.log('this.disableAllButtons ==> ' + this.disableAllButtons);
			if(this.reserve.IsReservedExpired) {
				this.disableAllButtons = true;
			}
			console.log('this.reserve ==> ' + JSON.stringify(this.reserve));

			this.researchProduct();
	
			this.subscription = subscribe(this.context, refreshProductReservationChannel, (message) => {
				console.log('message ==> ' + JSON.stringify(message));
				this.researchProduct();
			});
		} else {
			swal('Reserva bloqueada!', 'Não foram encontrados os aprovadores desta reserva.', 'warning');
		}
	}

	handleChangeRadioButton(event) {
		this.radioButtonValue = event.target.value;
		console.log('this.radioButtonValue ==> ' + this.radioButtonValue);
		if(this.wantAddProduct && (this.productFilterListNaoReservados == undefined || this.productFilterListNaoReservados.length == 0) && this.radioButtonValue == '1') {
			console.log('this.radioButtonValue ==> ' + this.radioButtonValue);
			this.offSetValue = 0;
			this.researchProduct();
		} else if(this.radioButtonValue == '2') {
			this.offSetValue = this.offSetValueReservados;
			this.prodFilterList = this.cloneObj(this.productFilterListReservados);
			this.checkHasMoreProductByNum(this.lengthReservedProductLastSearch);
		} else if (this.radioButtonValue == '1') {
			this.checkHasMoreProductByNum(this.lengthNotReservedProductLastSearch);
			this.offSetValue = this.offSetValueNaoReservados;
			this.prodFilterList = this.cloneObj(this.productFilterListNaoReservados);
		} else {
			this.offSetValue = this.offSetValueReservados;
			this.prodFilterList = this.cloneObj(this.productFilterListReservados);
			this.checkHasMoreProductByNum(this.lengthReservedProductLastSearch);
		}
	}

	searchProducts() {
		this.isLoadingProducts = true;
		console.log('this.offSetValue ==> ' + this.offSetValue);
		getProducts({ 
				reserveId: this.recordId,
				offSetValue: this.offSetValue, 
				searchGenericValue: this.searchGenericValue, 
				searchFabricanteValue: this.searchFabricanteValue, 
				radioButtonValue: this.radioButtonValue})
			.then(result => {
				console.log('getProducts: entrou certo!');
				this.isLoadingProducts = false;
				let hasError = result == null ? true : false;
				if (!hasError) {
					console.log('result ==> ' + JSON.stringify(result));
					console.log('result.length ==> ' + JSON.stringify(result.length));
					if(!result.length == 0) {
						this.checkHasMoreProduct(result);
						this.prodList = [];
						result.forEach(prod => {
							let valorTotal = 0;
							if (prod.reservedQuantity) {
								valorTotal = Number(prod.priceAverage) * Number(prod.reservedQuantity)
							}
							this.prodList.push({
								...prod,
								quantidade: prod.reservedQuantity,
								selected: true,
								valorTotal: valorTotal,
								valorTotalTela: this.getCurrencyFormat(valorTotal),
								priceAverageTela: this.getCurrencyFormat(prod.priceAverage)
							});
							console.log('prod ==> ' + JSON.stringify(prod));
							this.saldoFinanceiro = prod.reservedFinancialBalance;
						});
						console.log(this.saldoFinanceiro);
						this.lengthNotReservedProductLastSearch = this.prodList.length;
						// this.prodList = this.prodListSort.sort((a, b) => Number(b.alreadyReserved) - Number(a.alreadyReserved));
						this.prodList.forEach(element => {
							this.prodFilterList.push(this.cloneObj(element));
						});
						console.log(this.prodFilterList);
	
						this.refreshReservedProdList();
						this.hasProducts = true;
					} else {
						this.hasProducts = false;
						swal('Aviso!', 'Nenhum produto encontrado.', 'warning');
						this.saldoFinanceiro = prod.reservedFinancialBalance;
					}
					
				} else {
					let url = window.location.href;
					console.log('url ==> ' + JSON.stringify(url));
					if(url.toString().includes('DestinatarioReserva__c')) {
						return;
					} else {
						//swal('Atenção!', 'Não existe nenhum produto para esta reserva no momento!', 'warning');
						return;
					}
				}
				if(this.wantAddProduct && this.radioButtonValue == '1') {
					this.productFilterListNaoReservados = this.cloneObj(this.prodFilterList);
				}
			}).catch(error => {
				this.isLoadingProducts = false;
				console.log('getProducts: entrou no erro!');
				console.log(error);
			});
	}

	async searchReservedProducts() {
		this.isLoadingProducts = true;
		console.log('this.recordId ' + this.recordId);
		console.log('this.offSetValue ==> ' + this.offSetValue);
		getReservedProducts({ reserveId: this.recordId, offSetValue: this.offSetValue, getAllProducts: this.getAllProducts})
			.then(result => {
				console.log('getReservedProducts: entrou certo!');
				console.log(result);
				this.isLoadingProducts = false;
				let hasError = result == null ? true : false;
				if (!hasError) {
					if (result.length == 0) {
						let url = window.location.href;
						console.log('url ==> ' + JSON.stringify(url));
						if(url.toString().includes('DestinatarioReserva__c')) {
							return;
						} else {
							if((this.prodFilterList.length == 0)) {
								this.hasProductsAdd = false;
							}
							return;
						}
					}else{
						this.hasProductsAdd = true;
					}
					this.checkHasMoreProduct(result);
					this.prodList = [];
					result.forEach(prod => {
						let valorTotal = Number(prod.priceAverage) * Number(prod.reservedQuantity);
						let canSelect = Number(prod.reservedQuantity) > Number(prod.consumedQuantity);
						// this.prodList = [];
						this.prodList.push({
							...prod,
							selected: false,
							canSelect: canSelect,
							valorTotal: valorTotal,
							valorTotalTela: this.getCurrencyFormat(valorTotal),
							priceAverageTela: this.getCurrencyFormat(prod.priceAverage),
							quantidade: prod.reservedQuantity,
							quantityTransfer: 0
						});
						console.log('prod ==> ' + JSON.stringify(prod));
						this.saldoFinanceiro = prod.reservedFinancialBalance;
					});

					this.lengthReservedProductLastSearch = this.prodList.length;
					
					this.prodList.forEach(element => {
						this.prodFilterList.push(this.cloneObj(element));
					});
					// this.refreshReservedProdList();
				}
				if(!this.wantAddProduct || (this.wantAddProduct && this.radioButtonValue == '2')) {
					this.productFilterListReservados = this.cloneObj(this.prodFilterList);
					this.checkShowGetAllProductsButton(this.productFilterListReservados);
					// this.calcReservedItensTotalPrice();
				}
			}).catch(error => {
				console.log('getReservedProducts: entrou no erro!');
				console.log(error);
			});
			console.log('getTotalValueReserved => ' + await getTotalValueReserved({reserveId: this.recordId}));
			this.valorTotalReservado = this.getCurrencyFormat(await getTotalValueReserved({reserveId: this.recordId}));
			this.valorTotalReservadoTela = this.getCurrencyFormat(await getTotalValueReserved({reserveId: this.recordId}));
			this.valorTotalDif = 0;
			this.valorTotalDifTela = this.getCurrencyFormat(0);
	}

	async refreshReservedProdList() {
		this.reservedProdList = [];
		await getUnlimitedReservedProducts({ reserveId: this.recordId })
			.then(result => {
				console.log('getUnlimitedReservedProducts: entrou certo!');
				console.log('result ' + JSON.stringify(result));
				let hasError = result == null ? true : false;
				if (!hasError) {
					console.log('this.reservedProdList => ' + JSON.stringify(this.reservedProdList));
					result.forEach(prod => {
						let valorTotal = Number(prod.priceAverage) * Number(prod.reservedQuantity);
						console.log('valorTotal => ' + JSON.stringify(valorTotal));
						prod.valorTotal = valorTotal
						prod.valorTotalTela = this.getCurrencyFormat(valorTotal);
						prod.priceAverageTela = this.getCurrencyFormat(prod.priceAverage);
						this.reservedProdList.push(JSON.parse(JSON.stringify(prod)));
						// this.reservedProdList.push({
						// 	...prod,
						// 	valorTotal: valorTotal,
						// 	valorTotalTela: this.getCurrencyFormat(valorTotal),
						// 	priceAverageTela: this.getCurrencyFormat(prod.priceAverage)
						// });
					});
					console.log('this.reservedProdList => ' + JSON.stringify(this.reservedProdList));
					// this.calcReservedItensTotalPrice();
					// this.sortByBooleanAlreadyReserved();
				}
			}).catch(error => {
				console.log('getUnlimitedReservedProducts: entrou no erro!');
				console.log(error);
			});
	}

	// sortByBooleanAlreadyReserved() {
	// 	this.prodList = this.prodList.sort((a, b) => Number(b.alreadyReserved) - Number(a.alreadyReserved));
	// }

	async removeReservedProduct(event) {
		console.log('Remover produto da reserva');
		console.log(event.target.value);
		let prodResId = event.target.value;

		
		// this.prodFilterList.forEach(element => {
		// 	if(element.id == prodResId) {
		// 		element.isLoading = true;
		// 	}
		// });

		swal({
			title: "Remover produto da reserva?",
			icon: "warning",
			buttons: ["Cancelar", "Remover"],
			dangerMode: true,
		})
			.then((willDelete) => {
				if (willDelete) {
					this.isLoadingProducts = true;
					console.log('excluir');
					console.log(JSON.stringify(this.recordId));

					deleteProductReservation({
						reservationId: this.recordId,
						productReservationId: prodResId.toString()
					})
						.then(result => {
							console.log('deleteProductReservation: '+ result);
							this.isLoadingProducts = false;
							const apexResult = JSON.parse(result);

							if (apexResult.isSuccess) {
								let objIndex = this.prodFilterList.findIndex((obj => obj.id == prodResId));
								let productName = this.prodFilterList[objIndex].name;
								this.prodFilterList.splice(objIndex, 1);
								this.productFilterListReservados = this.cloneObj(this.prodFilterList);
								console.log(result);
								getTotalValueReserved({reserveId: this.recordId}).then(valorTotalReservado => {
									this.valorTotalReservado = this.getCurrencyFormat(valorTotalReservado);
									this.valorTotalReservadoTela = this.getCurrencyFormat(valorTotalReservado);
									this.valorTotalDif = 0;
									this.valorTotalDifTela = this.getCurrencyFormat(0);
								}).catch(error => {

								});
								getTotalProductsReservation({reserveId: this.recordId}).then(totalProducts => {
									this.totalProducts = totalProducts;
									this.checkShowGetAllProductsButton(this.productFilterListReservados);
								}).catch(error => {
									console.log('error ==> ' + error);
								});
								swal('Show!', 'Produto ' + productName + ' removido com sucesso.', 'success');
								// this.calcReservedItensTotalPrice();
								eval("$A.get('e.force:refreshView').fire();");
								
							} else {
								if (!!apexResult.errorCode) {
									switch(apexResult.errorCode) {
										case 'reservation-has-only-one-product': {
											// swal(
											// 	'Atenção!', 
											// 	'A reserva não poderá ficar sem produtos, é necesário excluir o cabeçalho da reserva.',
											// 	'warning'
											// );
											this.handleDeleteReservationHeader();
											return;
										}

										case 'delete-product-erp-error': {
											swal(
												'Atenção!', 
												apexResult.message,
												'warning'
											);
											return;
										}

										default: {
											swal(
												'Erro', 
												'Erro ao deletar produto, entre em contato com o Administrador', 
												'error'
											);
											console.log(result);
											return;
										}
									}
								}

							}
						})
						.catch(error => {
							this.isLoadingProducts = false;
							console.log(error);
						})
				}
			});
	}

	handleDeleteReservationHeader() {
		swal({
			title: "Remover reserva por completo?",
			text: 'A reserva não poderá ficar sem produtos, é necesário excluir o cabeçalho da reserva.',
			icon: "warning",
			buttons: ["Cancelar", "Excluir reserva"],
			dangerMode: true,
		})
			.then((willDeleteHeader) => {
				if (willDeleteHeader) {
					this.isLoadingScreen = true;

					deleteReservationHeader({ reservationId: this.recordId })
						.then((result) => {
							const apexResponse = JSON.parse(result);
							if (apexResponse.isSuccess) {
								this.handlePublishCloseTab();
							} else {
								this.isLoadingScreen = false;
								if (!!apexResponse.errorCode) {
									switch(apexResponse.errorCode) {
										case 'reservation-has-consummed-products': {
											swal(
												'Erro', 
												'Não é possível deletar a reserva que possui itens que foram consumidos', 
												'error'
											);
											return;
										}

										case 'delete-reservation-header-erp-error': {
											swal(
												'Erro', 
												apexResponse.errorCode.message, 
												'error'
											);
											return;
										}

										default: {
											swal(
												'Erro', 
												'Erro ao deletar a reserva, entre em contato com o Administrador', 
												'error'
											);
										}
									}
								}
							}
						})
						.catch((error) => {
							swal(
								'Erro', 
								'Erro ao deletar a reserva, entre em contato com o Administrador', 
								'error'
							);
							console.log(error);
							this.isLoadingScreen = false;
						})
				}
			});
	}

	checkHasMoreProduct(result) {
		console.log('result.length ===> ' + result.length);
		if (result.length == 20) {
			this.hasMoreProducts = true;
		} else {
			this.hasMoreProducts = false;
		}
	}

	checkHasMoreProductByNum(value) {
		console.log('value ===> ' + value);
		if (value == 20) {
			this.hasMoreProducts = true;
		} else {
			this.hasMoreProducts = false;
		}
	}

	onChangeSearchProductNome(event) {
		this.searchGenericValue = event.target.value;
		console.log(event.target.value);
		if((event.target.value == '' && this.searchGenericValue == '')) {
			if (this.searchFabricanteValue == '' && this.searchGenericValue == '') {
				this.handleFilterSearchProd();
			}
		}
	}
	
	onChangeSearchProductByFabricator(event) {
		this.searchFabricanteValue = event.target.value == '' ? '' : this.searchFabricanteValue;
		console.log(event.target.value + 'ewfewf');
		if((event.target.value == '' && this.searchGenericValue == '')) {
			if (this.searchFabricanteValue == '' && this.searchGenericValue == '') {
				this.handleFilterSearchProd();
			}
		}
	}
	
	onKeyUpSearchProductNome(event) {
		this.searchGenericValue = event.target.value;
		console.log(event.target.value);
		if (event.key === 'Enter' || (this.searchFabricanteValue == '' && this.searchGenericValue == '')) {
			this.handleFilterSearchProd();
		}
	}

	onKeyUpSearchProductByFabricator(event) {
		this.searchFabricanteValue = event.target.value;
		console.log(event.target.value + 'ewfewf');
		if (event.key === 'Enter' || (this.searchFabricanteValue == '' && this.searchGenericValue == '')) {
			this.handleFilterSearchProd();
		}
	}

	handleFilterSearchProd() {
		console.log('this.lengthNotReservedProductLastSearch ==> ' + this.lengthNotReservedProductLastSearch);
		console.log('this.searchGenericValue ==> ' + this.searchGenericValue);
		console.log('this.searchFabricanteValue ==> ' + this.searchFabricanteValue);
		if(this.searchGenericValue == '' && this.searchFabricanteValue == '') {
			if(this.radioButtonValue == '1') {
				this.isLoadingProducts = true;
				setTimeout(() => {
					this.prodFilterList = this.cloneObj(this.productFilterListNaoReservados);
					this.offSetValue = this.offSetValueNaoReservados;
					this.checkHasMoreProductByNum(this.lengthNotReservedProductLastSearch);
					console.log('this.hasMoreProducts ==> ' + this.hasMoreProducts);
					this.isLoadingProducts = false;
				}, 0);
			} else {
				this.isLoadingProducts = true;
				setTimeout(() => {
					this.offSetValue = this.offSetValueReservados;
					this.prodFilterList = this.cloneObj(this.productFilterListReservados);
					this.checkHasMoreProductByNum(this.lengthReservedProductLastSearch);
					this.isLoadingProducts = false;
				}, 0);
			}
		} else {
			this.isLoadingProducts = true;
			this.prodFilterList = [];
			this.offSetValue = 0;
			this.getProductsRecursive();
			
		}
	}

	async getProductsRecursive() {
		await getProducts({
			reserveId: this.recordId, 
			offSetValue: this.offSetValue, 
			searchGenericValue: this.searchGenericValue, 
			searchFabricanteValue: this.searchFabricanteValue, 
			radioButtonValue: this.radioButtonValue})
		.then(result => {
			this.checkHasMoreProduct(result);
			let hasError = (result == null || result.length == 0)? true : false;
			
			if(!hasError) {
				result.forEach(prod => {
					let valorTotal = 0;
					if (prod.reservedQuantity) {
						valorTotal = Number(prod.priceAverage) * Number(prod.reservedQuantity)
					}
					this.prodFilterList.push({
						...prod,
						quantidade: prod.reservedQuantity,
						selected: true,
						valorTotal: valorTotal,
						valorTotalTela: this.getCurrencyFormat(valorTotal),
						priceAverageTela: this.getCurrencyFormat(prod.priceAverage)
					});
					this.saldoFinanceiro = prod.reservedFinancialBalance;
					console.log('this.prodFilterList ==> ' + JSON.stringify(this.prodFilterList));
				});
			} else {
				if(this.offSetValue == 0) {
					swal('Aviso!', 'Não foi encontrado nenhum produto para está busca.', 'warning');
				}
			}

			if(result.length != 0) {
				this.offSetValue = this.offSetValue + 20;
				this.getProductsRecursive();
			} else {
				this.offSetValue = this.offSetValueNaoReservados;
				this.isLoadingProducts = false;
			}
		}).catch(error => {
			this.isLoadingProducts = false;
			console.log('getProducts: entrou no erro!');
			console.log(error);
		});
	}

	handleGetMoreProducts() {
		this.offSetValue += 20;
		if (this.wantAddProduct) {
			this.searchProducts();
		} else {
			this.searchReservedProducts();
		}
	}

	handleGroupSelection(event){
		this.grupoCliente = event.target.value;
		alert("The selected Accout id is"+this.grupoCliente);
	}
	
	normalizeData(eventData, list) {
		return list ? JSON.parse(JSON.stringify(eventData))[0] : JSON.parse(JSON.stringify(eventData));
	}

	onChangeQuantity(event) {
		console.log(event.target.value);
		let prodId = event.currentTarget.dataset.productid;
		let armazem = event.currentTarget.dataset.armazem;
		console.log('armazem => ' + JSON.stringify(armazem));
		let quantity = Number(event.target.value);
		let obj = this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem));
		if (event.target.value) {
			let valorTotal = Number(quantity) * Number(obj.priceAverage);
			let prod = this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem));
			this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantidade = quantity;
			this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal = valorTotal;
			this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotalTela = this.getCurrencyFormat(valorTotal);
			console.log('prod => ' + JSON.stringify(prod));
			if (prod.alreadyReserved) {
				this.valorTotalDif = valorTotal - this.reservedProdList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal;
				this.valorTotalDifTela = this.getCurrencyFormat(this.valorTotalDif);
			}
			this.checkTotalReservedValue();
			this.getProductUpdated();
		} else {
			if (obj.reservedQuantity) {
				let valorTotal = Number(obj.reservedQuantity) * Number(obj.priceAverage);
				this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal = valorTotal;
				this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotalTela = this.getCurrencyFormat(valorTotal);
				this.reservedProdList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantidade = undefined;
			} else {
				this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal = 0;
				this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotalTela = this.getCurrencyFormat(0);
			}
			this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantidade = undefined;
			this.valorTotalDif = 0;
			this.valorTotalDifTela = this.getCurrencyFormat(0);
			this.checkTotalReservedValue();
		}
	}

	async onChangeQuantityTransfer(event) {
		console.log(event.target.value);
		let prodId = event.currentTarget.dataset.productid;
		let armazem = event.currentTarget.dataset.armazem;
		console.log('armazem => ' + JSON.stringify(armazem));
		let quantityTransfer = Number(event.target.value);
		let obj = this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem));
		if (event.target.value) {
			// let valorTotal = Number(quantityTransfer) * Number(obj.priceAverage);
			let prod = this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem));
			// let quantityTransferProd = prod.quantityTransfer;
			if(Number(quantityTransfer) <= (Number(prod.reservedQuantity - prod.consumedQuantity))) {
				this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = quantityTransfer;
			} else {
				await swal('Aviso!', 'Não é possível inserir uma quantidade à transferir maior do que ' + Number(prod.reservedQuantity - prod.consumedQuantity).toString() + '.', 'warning').then((ok) => {
					if(ok) {
							this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = 0;
							this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = prod.quantityTransfer;
						} else {
							this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = 0;
							this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = prod.quantityTransfer;
						}
					});
				// await swal('Aviso!', 'Não é possível inserir uma quantidade de transferência maior do que a quantidade reservada menos a qunatidade consumida.', 'warning').then();
			}
			// this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal = valorTotal;
			// this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotalTela = this.getCurrencyFormat(valorTotal);
			console.log('prod => ' + JSON.stringify(prod));
			// if (prod.alreadyReserved) {
			// 	this.valorTotalDif = valorTotal - this.reservedProdList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal;
			// 	this.valorTotalDifTela = this.getCurrencyFormat(this.valorTotalDif);
			// }
			// this.checkTotalReservedValue();
			// this.getProductUpdated();
		} else {
			if (obj.reservedQuantity) {
				// let valorTotal = Number(obj.reservedQuantity) * Number(obj.priceAverage);
				// this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal = valorTotal;
				// this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotalTela = this.getCurrencyFormat(valorTotal);
				this.reservedProdList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = undefined;
			} else {
				// this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotal = 0;
				// this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).valorTotalTela = this.getCurrencyFormat(0);
			}
			this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem)).quantityTransfer = undefined;
			// this.valorTotalDif = 0;
			// this.valorTotalDifTela = this.getCurrencyFormat(0);
			// this.checkTotalReservedValue();
		}
	}

	calcReservedItensTotalPrice() {
		console.log('this.reservedProdList => ' + JSON.stringify(this.reservedProdList));
		this.valorTotalReservado = 0;
		this.valorTotalReservadoTela = 0;
		console.log('this.reservedProdList.length => ' + JSON.stringify(this.reservedProdList.length));
		if (this.reservedProdList.length > 0) {
			this.reservedProdList.forEach(prod => {
				let valorTotal = Number(prod.priceAverage) * (prod.quantidade ? Number(prod.quantidade) : Number(prod.reservedQuantity));
				if(isNaN(valorTotal)) {
					valorTotal = 0;
				}
				console.log('valorTotal ==> ' + valorTotal);
				this.valorTotalReservado += valorTotal;
			});
		}
		console.log('this.valorTotalReservado ==> ' + this.valorTotalReservado);
		this.valorTotalReservadoTela = this.getCurrencyFormat(this.valorTotalReservado);
		console.log(this.valorTotalReservado);
	}

	getCurrencyFormat(price) {
		console.log('price ==> ' + price);
		console.log('price ==> JSON.stringify' + JSON.stringify(price));
		if(price == undefined || price == null || price == 'NaN' || isNaN(price)) {
			return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(0);
		} else {
			console.log('entrou aqui price ==> ' + price);
			return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(price);
		}
	}

	getProductUpdated() {        
		console.log('produto atualizado');
		console.log(this.normalizeData(this.prodFilterList, false));
	}

	async handleAddAllSelectedProducts(event) {
		console.log(event);
		let lprod = [];

		this.checkTotalReservedValue();

		let hasBalanceError = false;
		let hasFinancialError = false;

		this.prodFilterList.forEach(prod => {
			if (prod.quantidade > prod.balance) {
				hasBalanceError = true;
			}

			console.log('Valor total reservado: ');
			console.log((this.valorTotalReservado + this.valorTotalDif));
			if (this.saldoFinanceiro < (this.valorTotalReservado + this.valorTotalDif)) {
				hasFinancialError = true;
			}
			
			if (prod.selected) {
				lprod.push(prod);
			}
		})

		if (hasBalanceError) {			
			swal('Aviso!', 'Não é possível inserir/alterar reserva de produto para quantidade acima do saldo disponível.', 'warning');
			return;
		}
		if (hasFinancialError) {
			swal('Aviso!', 'Valor total da reserva não pode ultrapassar o valor máximo disponível.', 'warning');
			return;
		}

		this.isLoadingProducts = true;

		console.log(this.normalizeData(lprod, false));

		if (lprod.length > 0) {
			if(lprod.length > 20) {
				let prodNameUpserted = [];
				let lastIndex = lprod.length - 1;
				let divideFor = Math.ceil(lastIndex / 20);
				console.log('divideFor => ' + divideFor); 
				for(let i = 0; i < divideFor; i++) {
					let indexToFind = (i+1) * 20;
					let indexToStart = i * 20;
					console.log('i => ' + i);
					console.log('(divideFor - 1) => ' + (divideFor - 1));
					if(i == (divideFor - 1)) {
						console.log('lprod.slice(indexToStart, indexToFind) ==> ' + lprod.slice(indexToStart, indexToFind));
						console.log('entrou 2 ==> ');
						this.getUpsertReserveProduct(lprod.slice(indexToStart, indexToFind));
						this.isByCSV = true;
					} else {
						console.log('entrou 1 ==> ');
						await upsertReserveProduct({ reserveId: this.recordId, productJson: JSON.stringify(lprod.slice(indexToStart, indexToFind))}).then(result => {

						}).catch(error => {
							
						});
					}
				}
			} else {
				this.getUpsertReserveProduct(lprod);
			}
			this.insertCSV = false;
			this.wantAddProduct = false;
		} else {
			this.isLoadingProducts = false;
			swal('Aviso!', 'Nenhum produto selecionado.', 'warning');
		}
	}

	checkTotalReservedValue() {
		let totalToReserve = 0;
		this.prodFilterList.forEach(prod => {
			let valorDiferenca = 0;
			console.log('this.reservedProdList ==> ' + JSON.stringify(this.reservedProdList));
			console.log('prod ==> ' + JSON.stringify(prod));
			this.reservedProdList.forEach(resProd => {
				if (resProd.productId == prod.productId && resProd.storage == prod.storage) {
					prod.checked = true;
					totalToReserve += (prod.valorTotal - resProd.valorTotal);					
					prod.valorDiferenca = (prod.valorTotal - resProd.valorTotal);
				}
			});
			
			if (prod.selected && !prod.checked) {
				valorDiferenca = prod.valorTotal;
				totalToReserve += prod.valorTotal;
				prod.valorDiferenca = valorDiferenca;
			}
		})
		console.log(totalToReserve);

		this.valorTotalDif = totalToReserve;
		this.valorTotalDifTela = this.getCurrencyFormat(this.valorTotalDif);
	}

	async handleAddProductToReservation(event) {
		let prodId = event.currentTarget.dataset.productid;
		let armazem = event.currentTarget.dataset.armazem;
		let prodAdd = event.currentTarget.dataset.productadd == 'true';
		console.log(prodId);
		
		let prodObj = this.validReserveFields(prodId, armazem);
		console.log(prodObj);

		if (prodObj) {
			let lprod = [];
			lprod.push(prodObj);
			console.log('quantidade: ' + prodObj.quantidade);
			console.log('balance: ' + prodObj.balance);
			// if (prodObj.quantidade > prodObj.balance) {
			// 	swal('Aviso!', 'Não é possível inserir/alterar produto da reserva com quantidade acima do saldo disponível.', 'warning');
			// 	return;
			// }
			if (this.saldoFinanceiro < (this.valorTotalReservado + (prodObj.valorDiferenca))) {
				swal('Aviso!', 'Valor total da reserva não pode ultrapassar o limite financeiro.', 'warning');
				return;
			}

			let prodObjKey = prodObj.reserveId + '_' + prodObj.productId + '_' + prodObj.storage;
			// this.isLoadingProducts = true;
			let boolean = await this.getUpsertReserveProduct(lprod);
			console.log('boolean => ' + boolean);
			if(boolean.status) {
				console.log('entrou aqui!! ');
				this.prodFilterList.find(prod => ((prod.reserveId + '_' + prod.productId + '_' + prod.storage) == prodObjKey)).alreadyReserved = true;
			} else {
				swal('Erro!', boolean.message, 'warning');
			}
		} else {
			swal('Aviso!', 'Campo de quantidade inválido!', 'warning');
		}

	}

	cloneObj(value) {
		return JSON.parse(JSON.stringify(value));
	}

	async getUpsertReserveProduct(lprod) {
		let response = undefined;

		await upsertReserveProduct({ reserveId: this.recordId, productJson: JSON.stringify(lprod) })
		.then(productReservation => {
			let productReservationParse = JSON.parse(productReservation);
			if(productReservationParse.length > 1 || (productReservationParse.length == 1 && this.isByCSV)) {
				this.isByCSV = false;
				this.researchProduct();
				console.log('entrou 3 ==> ');
				getTotalValueReserved({reserveId: this.recordId}).then(valorTotalReservado => {
					this.valorTotalReservado = this.getCurrencyFormat(valorTotalReservado);
					this.valorTotalReservadoTela = this.getCurrencyFormat(valorTotalReservado);
					this.valorTotalDif = 0;
					this.valorTotalDifTela = this.getCurrencyFormat(0);
				}).catch(error => {

				});

				getTotalProductsReservation({reserveId: this.recordId}).then(totalProducts => {
					this.totalProducts = totalProducts;
					this.checkShowGetAllProductsButton(this.productFilterListReservados);
				}).catch(error => {
					console.log('error ==> ' + error);
				});
			} else {
				if(this.wantAddProduct && this.radioButtonValue == '1') {
					let productParsed = JSON.parse(productReservation);
					productParsed.quantidade = productParsed.reservedQuantity;
					productParsed.alreadyReserved = true;
					let valorTotal = Number(productParsed.priceAverage) * Number(productParsed.quantidade);
					productParsed.valorTotalTela = this.getCurrencyFormat(valorTotal);
					productParsed.priceAverageTela = this.getCurrencyFormat(productParsed.priceAverage);
					let objIndex = this.prodFilterList.findIndex((obj => (obj.productId == productParsed.productId && obj.storage == productParsed.storage)));
					this.prodFilterList.splice(objIndex, 1);
					let objIndex2 = this.productFilterListNaoReservados.findIndex((obj => (obj.productId == productParsed.productId && obj.storage == productParsed.storage)));
					this.productFilterListNaoReservados.splice(objIndex2, 1);
					console.log('productParsed ==> ' + JSON.stringify(productParsed));
					this.productFilterListReservados.push(this.cloneObj(productParsed));
					swal('Show!', 'Produto ' + productParsed.name + ' adicionado com sucesso.', 'success');
					eval("$A.get('e.force:refreshView').fire();");
					this.hasProductsAdd = true;
					response = true;
					// this.calcReservedItensTotalPrice();
					getTotalValueReserved({reserveId: this.recordId}).then(valorTotalReservado => {
						this.valorTotalReservado = this.getCurrencyFormat(valorTotalReservado);
						this.valorTotalReservadoTela = this.getCurrencyFormat(valorTotalReservado);
						this.valorTotalDif = 0;
						this.valorTotalDifTela = this.getCurrencyFormat(0);
					}).catch(error => {
	
					});
	
					getTotalProductsReservation({reserveId: this.recordId}).then(totalProducts => {
						this.totalProducts = totalProducts;
						this.checkShowGetAllProductsButton(this.productFilterListReservados);
					}).catch(error => {
						console.log('error ==> ' + error);
					});
				} else {
					let productParsed = JSON.parse(productReservation);
					let valorTotal = Number(productParsed.priceAverage) * Number(productParsed.quantidade);
					productParsed.valorTotalTela = this.getCurrencyFormat(valorTotal);
					productParsed.priceAverageTela = this.getCurrencyFormat(productParsed.priceAverage);
					let objIndex = this.prodFilterList.findIndex((obj => obj.id == productParsed.id));
					this.prodFilterList[objIndex] = this.cloneObj(productParsed);
					this.productFilterListReservados = this.cloneObj(this.prodFilterList);
					swal('Show!', 'Produto ' + productParsed.name + ' atualizado com sucesso.', 'success');
					eval("$A.get('e.force:refreshView').fire();");
					response = true;
					// this.calcReservedItensTotalPrice();
					getTotalValueReserved({reserveId: this.recordId}).then(valorTotalReservado => {
						this.valorTotalReservado = this.getCurrencyFormat(valorTotalReservado);
						this.valorTotalReservadoTela = this.getCurrencyFormat(valorTotalReservado);
						this.valorTotalDif = 0;
						this.valorTotalDifTela = this.getCurrencyFormat(0);
					}).catch(error => {
	
					});
				}
			}
		}).catch(error => {
			this.isLoadingProducts = false;
			console.log('upsertReserveProduct: entrou no erro!');
			console.log(error);
			if(error?.body?.exceptionType?.includes("CustomException")) {
				response = {status: false, message: error.body.message};
			} else {
				response = {status: false, message: 'Erro na inserção deste produto, entre em contato com o administrador do sistema!'};
			}
			this.prodFilterList.forEach(prod => {
				prod.isLoading = false;
			});
		});

		// this.valorTotalReservado = this.getCurrencyFormat(await getTotalValueReserved({reserveId: this.recordId}));
		// this.valorTotalReservadoTela = this.getCurrencyFormat(await getTotalValueReserved({reserveId: this.recordId}));
		// console.log('await getTotalValueReserved({reserveId: this.recordId}) => ' + await getTotalValueReserved({reserveId: this.recordId}));
		return response;
		// eval("$A.get('e.force:refreshView').fire();");
	}

	validReserveFields(prodId, armazem) {
		let allFieldsFilled = false;
		console.log('this.prodFilterList ==> ' + JSON.stringify(this.prodFilterList));
		let prodObj = this.prodFilterList.find(prod => (prod.productId == prodId && prod.storage == armazem));
		console.log('prodObj ==> ' + JSON.stringify(prodObj));
		this.prodFilterList.forEach(prod => {
			if ((prod.productId == prodId && prod.storage == armazem)) {
				if (prod.quantidade != undefined && prod.quantidade != '') {
					allFieldsFilled = true;
					prod.isLoading = true;
					console.log('prodIsLoading ==> ' + JSON.stringify(prod));
				}
			}
		});

		if (!allFieldsFilled) {
			return undefined;
		} else if (prodObj) {
			return prodObj;
		}
	}

	handleCSVImport() {
		console.log('IMPORT CSV');
		this.insertCSV = !this.insertCSV;

		if (this.insertCSV) {
			this.isValidCSV = false;
			this.valorTotalDif = 0;
			this.valorTotalDifTela = this.getCurrencyFormat(0);
			this.prodList = [];
			this.prodFilterList = [];
			this.wantAddProduct = true;
		} else {
			this.wantAddProduct = false;
			this.researchProduct();
		}
	}

	get acceptedFormats() {
        return ['.csv'];
    }

	handleAllCheckbox(event) {
		let checked = event.target.checked;
		this.prodFilterList.forEach(prod =>{
            prod.selected = checked;
        });
		this.checkTotalReservedValue();
	}

	handleProdCheckbox(event) {
		let checked = event.target.checked;
		let prodId = event.currentTarget.dataset.productid;
		let armazemProd = event.currentTarget.dataset.armazem;
		this.prodFilterList.forEach(prod => {
			if (prod.productId == prodId && prod.storage == armazemProd) {
				prod.selected = checked;
			}
        });
		this.checkTotalReservedValue();
	}

	handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
		console.log(uploadedFiles);
		this.isLoadingProducts = true;
		createProductsReservationByCSVFile({ reserveId: this.recordId, documentId: uploadedFiles[0].documentId })
			.then(result => {
				console.log('createProductsReservationByCSVFile: entrou certo!');
				console.log(result);
				this.isLoadingProducts = false;
				if (result != null) {
					this.prodList = [];
					this.isValidCSV = true;
					this.valorTotalDif = 0;
					result.forEach(prod => {
						let valorTotal = Number(prod.priceAverage) * Number(prod.quantidade)
						this.prodList.push({
							...prod,
							selected: prod.haveInventory,
							valorTotal: valorTotal,
							valorTotalTela: this.getCurrencyFormat(valorTotal),
							priceAverageTela: this.getCurrencyFormat(prod.priceAverage)
						});
					});
	
					this.prodFilterList = this.prodList;
					this.checkTotalReservedValue();
				}
			}).catch(error => {
				console.log('createProductsReservationByCSVFile: entrou no erro!');
				console.log(error);
				this.isLoadingProducts = false;
				swal('Aviso!', error.body.message, 'warning');
			});
    }

	handleClickProductName(event) {
		let prodId = event.currentTarget.dataset.productid;

		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: prodId,
				actionName: 'view'
			}
		});
	}

	handleNotification(evt) { 
		var maxScroll = Number(evt.target.scrollHeight - evt.target.clientHeight);
		var scroll = Number(evt.target.scrollTop);
		var percentScroll = ((100 * evt.target.scrollTop) / maxScroll);
		console.log('maxScroll: ' + maxScroll);
		console.log('evt.target.scrollTop: ' + evt.target.scrollTop);
		console.log('percentScroll: ' + percentScroll);
		if(percentScroll < 80) {
			this.resetScroll = false;
		}
		console.log('this.hasMoreProducts handleNotification: ' + this.hasMoreProducts);
		if(!this.resetScroll) {
			if(this.hasMoreProducts && (percentScroll > 80)) {
				this.resetScroll = true;
				this.offSetValue += 20;
				if (this.wantAddProduct && this.radioButtonValue == '1') {
					this.offSetValueNaoReservados = this.offSetValue;
					this.searchProducts();
				} else {
					this.offSetValueReservados = this.offSetValue;
					console.log('searchReservedProducts');
					if(Number(this.totalProducts) != Number(this.prodFilterList.length)) {
						this.searchReservedProducts();
					}
				}
			}
		}
	}

	async handleTransferProducts(event) {
		this.isLoadingProducts = true;
		if(await checkHaveSomeReserveWithTheSameCD({recordId: this.recordId, distributionCenterCode: this.reserve.DistributionCenterCode})) {
			this.isLoadingProducts = false;
			if(this.transferProductsMode == undefined) {
				this.transferProductsMode = true;
			} else {
				this.transferProductsMode = !this.transferProductsMode;
			}
		} else {
			this.isLoadingProducts = false;
			swal('Aviso!', 'Nenhuma reserva para o mesmo centro de distribuição foi encontrada!' , 'warning');
		}
	}

	handleTransferProductsModal(event) {
		let prodListToCheckTransferPossible = [];

		this.prodFilterList.forEach(prod => {
			if(prod.quantityTransfer != null && prod.quantityTransfer != undefined && prod.quantityTransfer != 0 && prod.checked) {
				prodListToCheckTransferPossible.push(prod);
			}
		});

		if(prodListToCheckTransferPossible.length > 0) {
			///apex
		} else {
			swal('Aviso!', 'Nenhum produto encontrado!', 'warning');
		}
	}

	handleSelectedTransferReserve(event) {
		this.reserveToTransfer = event.detail.record;
		console.log('event ==> ' + JSON.stringify(event));
		console.log('this.reserveToTransfer ==> ' + JSON.stringify(this.reserveToTransfer));
		if(this.reserveToTransfer != undefined && this.reserveToTransfer != null) {
			this.disableContinue = false;
		}
	}

	handleSelectedClearTransferReserve(event) {
		this.reserveToTransfer = null;
		this.disableContinue = true;
	}

	async handleTransferProductToUpdate(event) {
		let reservationProductsList = event.detail.reservationProductToTransfer;
		let updated = await transferProducts({reservationProductsList: JSON.stringify(reservationProductsList), reservationCurrentId: this.recordId, reservationToTransfer: this.reserveToTransfer.Id});

		if(updated) {
			this.template.querySelector('c-product-reservation-modal').transferLoadingChange();
			await swal("Show!", "Reserva de produtos transferidos com sucesso!", "success");
			this.template.querySelector('c-product-reservation-modal').closeAll();
		} else {
			this.template.querySelector('c-product-reservation-modal').transferLoadingChange();
			swal("Erro!", "Houve algum erro no processo de transferência de reserva de produtos, entre com contato com um administrador do sistema!", "error");
		}
	}

	async handleRefreshProducts() {
		if(!this.wantAddProduct || (this.wantAddProduct && this.radioButtonValue == '2')) {
			this.isLoadingProducts = true;
			for(let i = 0; i < this.prodFilterList.length; i++) {
				// this.prodFilterList[i].isLoading = true;
				this.prodFilterList[i] = this.cloneObj(JSON.parse(await refreshProductsApex({reserveId: this.recordId, productJson: JSON.stringify(this.prodFilterList[i])})));
				this.prodFilterList[i].alreadyReserved = true;
				let valorTotal = Number(this.prodFilterList[i].priceAverage) * Number(this.prodFilterList[i].quantidade);
				this.prodFilterList[i].valorTotalTela = this.getCurrencyFormat(valorTotal);
				this.prodFilterList[i].priceAverageTela = this.getCurrencyFormat(this.prodFilterList[i].priceAverage);
			}
			eval("$A.get('e.force:refreshView').fire();");
			this.productFilterListReservados = this.cloneObj(this.prodFilterList);
			this.isLoadingProducts = false;
			this.ultimaAtualizacao = this.getFormattedDate();
			swal('Produtos atualizados com sucesso!', '', 'success');
		} else {
			this.researchProduct();
		}
	}

	handleGetAllProductsReservation(event) {
		if(this.prodFilterList.length != this.totalProducts) {
			this.getAllProducts = true;
			this.prodFilterList = [];
			this.showGetAllProducts = false;
			this.searchReservedProducts();
		} else {
			this.showGetAllProducts = false;
		}
	}

	checkShowGetAllProductsButton(value) {
		if(value.length == 20) {
			this.showGetAllProducts = true;
		} else {
			this.showGetAllProducts = false;
		}
	}
}