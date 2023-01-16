import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getRecords from '@salesforce/apex/BaseLookupController.getRecords';

export default class BaseLookup extends LightningElement {
    // APIs
	@api recordId;
	@api targetObject;
	@api searchFields = [];
	@api moreFields = [];
	@api labelNewRecord = 'Criar novo registro';
	@api newRecordButton = false;
	@api noRepeats = 'Id';
	@api required;
	@api disabled;

	@api parentRecordList; // Valor do WHERE
	@api parentRelationFieldList; // Campo do WHERE
	@api operatorList; // Operador do WHERE

	@api objectIconName = 'standard:custom_notification';
	@api inputLabel = 'Selecione um registro';
	@api placeholder = 'Digite para buscar...';

	@api listItemOptions = {
		title: 'Id',
		description: null
	};

	@api standardFormLayout = false;
	@api recordTypeId;
	@api levelFieldTitle = 0;
	@api fieldTitle = [];

	// TRACKs
	@track delayTimer;
	@track searchFieldsApiNames = null;
	@track moreFieldsApiNames = null;
	@track searchValue = null;
	@track isLoading = true;

	@track records = null;
	@track noRecords = false;
	@track selectedRecord = null;

	@track showCreateRecordForm = false;
	@track allFields;
	@track fieldNameList;
	@track firstRun = true;

	// GETs
	get recordsList() {
		if (!this.records) {
			return null;
		}

		//console.log('recordList =>', JSON.parse(JSON.stringify(this.records)));
		let itemsList = this.records.map(record => {
			var title;
			let description = null;

			//console.log('record =>', JSON.parse(JSON.stringify(record)));
			//console.log('this.listItemOptions =>', JSON.parse(JSON.stringify(this.listItemOptions)));
			//console.log('this.fieldTitle =>', JSON.parse(JSON.stringify(this.fieldTitle)));
			if (this.levelFieldTitle > 0) {
				var fieldValue = record[this.listItemOptions.title];

				for (let level = 0; level < this.levelFieldTitle; level++) {
					fieldValue = fieldValue[this.fieldTitle[level]];
				}

				title = fieldValue;
			}
			else title = record[this.listItemOptions.title] || record['Id'];

			if (this.listItemOptions.description) {
				if (typeof this.listItemOptions.description === 'string') {
					description = record[this.listItemOptions.description] || null;
				}
				else if (this.listItemOptions.description.length > 0) {
					let descriptionValues = [];

					this.listItemOptions.description.forEach(field => {
						if (typeof record[field] != 'undefined' && record[field] != null && record[field] != '') {
							//console.log('typeof record[field] =>', typeof record[field]);
							descriptionValues.push(
								typeof record[field] === 'number' ? record[field].toFixed(2)
								: (
									!this.checkDatetimeAndDate(record[field]) ? record[field]
									: this.convertDatetimeAndDateToString(record[field])
								)
							);
						}
					});

					description = descriptionValues.join(' | ');
				}
			}

			return {
				Id: record.Id,
				title,
				description
			}
		});

		return itemsList;
	}

	// WIREs
	@wire(getRecord, { recordId: '$recordId', fields: '$allFields' })
	wiredGetRecord({ error, data }) {
		this.isLoading = false;

		if (!this.recordId) {
			this.selectedRecord = null;
			return;
		}
		else if (!this.firstRun) return;

		if (error) {
			//console.log(error);
			return;
		}

		if (data) {
			//console.log('data wire =>', JSON.parse(JSON.stringify(data)));
			const { id, fields } = data;

			if (this.levelFieldTitle > 0) {
				var fieldValue = fields[this.listItemOptions.title].value;

				for (let level = 0; level < this.levelFieldTitle; level++) {
					fieldValue = fieldValue.fields[this.fieldTitle[level]].value;
				}

				this.selectedRecord = {
					Id: id,
					title: fieldValue
				};
			} else {
				this.selectedRecord = {
					Id: id,
					title: fields[this.listItemOptions.title].value
				};
			}

			let record = { Id: this.recordId };
			this.allFields.forEach(field => {
				record = {
					...record,
					[field]: fields[field]?.value
				}
			});

			this.dispatchEvent(
				new CustomEvent('selectrecord', {
					detail: {
						record
					}
				})
			);

			this.firstRun = false;
		}
	}

	// METHODs
	connectedCallback() {
		if (this.searchFields) {
			const searchFieldsApiNames = this.searchFields
				.filter(fieldRef => fieldRef.objectApiName === this.targetObject.objectApiName)
				.map(fieldRef => fieldRef);

			this.searchFieldsApiNames = searchFieldsApiNames;

			const moreFieldsApiNames = this.moreFields
				.filter(fieldRef => fieldRef.objectApiName === this.targetObject.objectApiName)
				.map(fieldRef => fieldRef);

			this.moreFieldsApiNames = moreFieldsApiNames;
		}

		this.allFields = [...this.searchFields, ...this.moreFields];
		this.fieldNameList = this.allFields.map(item => {
			return item;
		});
	}

	handleTyping(event) {
		const { value } = event.target;
		this.records = null;

		clearTimeout(this.delayTimer);
		this.delayTimer = setTimeout(() => {

			if (value.length < 0) {
				this.records = null;
				return;
			}

			this.searchValue = value;
			this.isLoading = true;

			this.handleGetRecords();
		}, 1000);
	}

	async handleGetRecords() {
		let requestData = {
			targetObject: this.targetObject,
			searchFields: this.searchFieldsApiNames,
			searchValue: this.searchValue,
			moreFields: this.moreFieldsApiNames || null
		};

		//console.log('this.parentRelationFieldList =>', this.parentRelationFieldList ? JSON.parse(JSON.stringify(this.parentRelationFieldList)) : this.parentRelationFieldList);
		//console.log('this.parentRecordList =>', this.parentRecordList ? JSON.parse(JSON.stringify(this.parentRecordList)) : this.parentRecordList);
		if (this.parentRelationFieldList && this.parentRecordList && this.operatorList) {
			var relationList = [];
			var cont = 0;

			this.parentRelationFieldList.forEach(field => {
				var value = this.parentRecordList[cont];
				var operator = this.operatorList[cont];

				relationList = [
					...relationList,
					{
						parentRelationField: field,
						parentRecord: Array.isArray(value) ? null : value, // (typeof value === 'string') ? value : null,
						parentRecordList: value,
						operator: operator
					}
				];

				cont++;
			});
			//console.log('relationList =>', JSON.parse(JSON.stringify(relationList)));

			requestData = {
				...requestData,
				relations: relationList
			}
		}

		try {
			//console.log('requestData =>', JSON.parse(JSON.stringify(requestData)));
			const data = await getRecords({ data: JSON.stringify(requestData) });
			//console.log('data lookup fon =>', JSON.parse(JSON.stringify(data)));

			var dataResult = [];
			if (data) {
				data.forEach(element => {
					if (this.noRepeats == 'Id') {
						dataResult = [
							...dataResult,
							element
						];
					}
					else {
						if (dataResult.length > 0) {
							if (!(dataResult.find(item => item[this.noRepeats] == element[this.noRepeats]))) {
								dataResult = [
									...dataResult,
									element
								];
							}
						}
						else {
							dataResult = [
								...dataResult,
								element
							];
						}
					}
				});
			}

			if (dataResult) {
				this.records = dataResult.map(item => {
					var record = { ...item };
					this.fieldNameList.forEach(field => {
						if (record[field] == null || record[field] == undefined) {
							record = {
								...record,
								[field]: item[field] ? item[field] : null
							};
						}
					});

					return record;
				});
				//this.records = dataResult.map(item => ({ ...item }));
				this.noRecords = (dataResult.length == 0);
			}
			else this.records = null;
		}
		catch (error) {
			console.log('Erro na busca de registro =>',error);
		}
		finally {
			this.isLoading = false;
		}
	}

	handleOnFocus() {
		this.handleGetRecords();
	}

	handleCloseList() {
		this.records = null;
	}

	handleSelectRecord(event) {
		const { value } = event.target.dataset;
		this.firstRun = false;
		var record = this.records.find(item => item.Id === value);

		var recordTitle;
		if (this.levelFieldTitle > 0) {
			recordTitle = record[this.listItemOptions.title];
			this.fieldTitle.forEach(field => {
				recordTitle = recordTitle[field];
			});
		}
		else recordTitle = record[this.listItemOptions.title];

		this.selectedRecord = {
			Id: record.Id,
			title: recordTitle
		};

		this.dispatchEvent(
			new CustomEvent('selectrecord', {
				detail: {
					record
				}
			})
		);
	}

	@api handleClearSelected() {
		this.selectedRecord = null;
		this.recordId = null;
    console.log('entrou aqui');
		this.dispatchEvent(
			new CustomEvent('clearselectedrecord')
		);
	}

	@api clearAll() {
		this.selectedRecord = null;
		this.recordId = null;
		this.searchValue = null;
		this.records = null;
	}

	handleToggleCreateRecord() {
		this.showCreateRecordForm = !this.showCreateRecordForm;
		this.scrollToTop();
		//this.handleGetRecords();
		//this.isLoading = false;
	}

	scrollToTop() {
		if (!this.desktop) {
			const scrollOptions = {
				left: 0,
				top: 0
			}

			parent.scrollTo(scrollOptions);
		}
	}

	async handleSuccessCreate(event) {
		const { id: recordId } = event.detail;

		this.isLoading = true;
		this.recordId = recordId;

		this.handleToggleCreateRecord();
	}

	checkDatetimeAndDate(stringDate) {
		const regexDatetime = /[0-9]{4}-[0-9]{0,2}-[0-9]{0,2}T[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}.[0-9]{0,3}Z/;
		const regexDate = /[0-9]{4}-[0-9]{0,2}-[0-9]{0,2}/;

		return (regexDatetime.test(stringDate) || regexDate.test(stringDate));
	}

	convertDatetimeAndDateToString(stringDate) {
		var formatDate = '',
			gmtDate = new Date(stringDate),
			utcDate = gmtDate.getUTCDate() < 10 ? ('0' + gmtDate.getUTCDate()) : gmtDate.getUTCDate(),
			utcMonth = (gmtDate.getUTCMonth() + 1) < 10 ? '0' + (gmtDate.getUTCMonth() + 1) : (gmtDate.getUTCMonth() + 1),
			utcYear = gmtDate.getUTCFullYear();

		formatDate = `${utcDate}/${utcMonth}/${utcYear}`;

		return formatDate;
	}
}