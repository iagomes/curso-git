import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getTemplate from '@salesforce/apex/ContractUploadController.getTemplate';
import getDataFields from '@salesforce/apex/ContractUploadController.getDataFields';
import insertContract from '@salesforce/apex/ContractUploadController.insertContract';

const CONTRACT_TEMPLATE_NAME = 'contractTemplate.csv';
const VALIDATION_MESSAGE_FILE_INVALID = 'Selecione um arquivo CSV válido para upload.';
const VALIDATION_MESSAGE_FILE_LARGE = 'Tamanho do arquivo é muito grande.';
const INSERT_DATA = 'Inserir registros';
const MAX_FILE_SIZE = 1500000;
export default class ContractUploadCsv extends LightningElement {
    @track columns = [];
    @track data = [];
    @track dataRecords = [];
    @track fileName = '';
    @track UploadFile = INSERT_DATA;
    @track showLoadingSpinner = false;
    @track isTrue = false;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    schema = [];
    headerList = [];

    get isData(){
        return this.data.length > 0;
    }
    
    get isSelectedFile(){
        return this.fileName != '';
    }
    connectedCallback(){
        getDataFields({})
        .then(response => {
            this.headerList = response;
            let schema = new Map();
            let camp = [];
            console.log('getDataFields response',response);
            response.forEach((record) => {
                let tempConRec = Object.assign({}, record);
                let item = {label : tempConRec.MasterLabel, type : tempConRec.Data_type__c, fieldName : tempConRec.MasterLabel, value : ''};
                schema.set(tempConRec.MasterLabel, item);
                camp.push(item);
            });
            console.log('getDataFields schema',schema);
            this.schema = schema;
            this.columns = camp;
            
        })
        .catch(error => {
            console.log('getDataFields error',error);
            this.showToast(error, 'error');
        });
    }

    handleFilesChange(event){
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;
        }
    }

    handleSave(){
        if(this.filesUploaded.length > 0) {
            this.uploadHelper();
        }else {
            this.fileName = VALIDATION_MESSAGE_FILE_INVALID;
            this.showToast(VALIDATION_MESSAGE_FILE_INVALID, 'error');
        }
    }

    async uploadHelper(){
        this.file = this.filesUploaded[0];
        if (this.file.size > MAX_FILE_SIZE) {
            this.showToast(VALIDATION_MESSAGE_FILE_LARGE, 'error');
            return ;
        }
        this.showLoadingSpinner = true;
        this.fileReader= new FileReader();
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;
            try{
                this.showData();
            }catch(error){
                console.log('showData error',error);
                this.showLoadingSpinner = false;
                this.showToast('Erro na estrutura do CSV, baixe o template e verifique se todos os campos estão preenchidos. Também veja se o campo data está com o formato correto DD/MM/YYYY.','error');
            }
        });
        this.fileReader.readAsText(this.file);
    }
 
    showData(){
        this.data = [];
        this.dataRecords = [];
        let rows = this.fileContents.split('\n');
        let headers = rows[0].split(';').map( header => {return header.trim().replace(/"/g, '')});
        console.log('showData headers',headers);
        rows.shift();
        console.log('rows', rows);
        let msg = '';
        console.log('showData rows',rows);
        console.log('showData this.schema',this.schema);

        rows.forEach(row => {
            let fields = row.split(';');
            if(fields.length > 1){
                let line = [];
                fields.forEach( (value, index) => {
                    console.log('showData headers[index]',headers[index]);

                    let field = this.schema.get(headers[index]);
                    field.value = value.replace(/['"]+/g, '');
                    if(field.value === '' || field.value === 0 || field.value === null){
                        msg = 'O campo '+field.fieldName+' não pode ser nulo ou zero. |';
                    }
                    if(field.fieldName === 'Nome Do Produto' && field.value.length < 7){
                        field.value = field.value.padStart(7, '0')
                    }
                    if(field.fieldName === 'Número do Contrato' && field.value.length < 8){
                        field.value = field.value.padStart(8, '0')
                    }
                    line[headers[index]] = field.value;
                    console.log('showData line[headers[index]] ',line[headers[index]] );
                });
                this.dataRecords.push({...line});
                this.data.push(line);
                console.log('showData this.data',this.data);
            }
        });
        console.log('dataRecords', this.dataRecords);
        this.showLoadingSpinner = false;
        if(msg != ''){
            this.data = [];
            this.dataRecords = [];
            this.showToast(msg+' Ajuste os campos no csv e tente novamente.', 'error');
        }
    }

    downloadTemplate(){
        getTemplate({})
        .then(csv => {
            let universalBOM = "\uFEFF";
            let a = document.createElement('a');
            a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(universalBOM+csv);
            a.target = '_self';
            a.download = CONTRACT_TEMPLATE_NAME;
            document.body.appendChild(a);
            a.click();
            this.showToast( 'Atenção! Não atere o cabeçalho do template.', 'success');
        })
        .catch(error => {
            this.showToast(JSON.stringify(error), 'error');
        });
    }
    
    showToast(message, variant){
        let title = variant == 'error' ? 'Erro' : 'Sucesso';
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    confirmUpload(){
        try{
            this.dataRecords = [];
            //Adjust data
            let rows = this.fileContents.split('\n');
            let headers = rows[0].split(';').map( header => {return header.trim().replace(/"/g, '')});
            rows.shift();
            rows.forEach(row => {
                let fields = row.split(';');
                let line = [];
                fields.forEach( (value, index) => {
                    let field = this.schema.get(headers[index]);
                    field.value = value.replace(/['"]+/g, '');
                    if(field.type === 'DATE'){
                        const [day, month, year] = field.value.split('/');
                        field.value = String(year).trim()+'-'+String(month).padStart(2, '0').trim()+'-'+String(day).padStart(2, '0').trim();
                        console.log('field.value date', field.value);
                        console.log('field.fieldName date', field.fieldName);
                    }
                    if(field.fieldName === 'Nome Do Produto' && field.value.length < 7){
                        field.value = field.value.padStart(7, '0')
                    }
                    if(field.fieldName === 'Número do Contrato' && field.value.length < 8){
                        field.value = field.value.padStart(8, '0')
                    }
                    line[headers[index]] = field.value.replace('\r' ,'' );
                    line[headers[index]] = field.value.replace(',' ,'.' );
                });
                this.dataRecords.push({...line});
            });
            console.log('dataRecords', this.dataRecords);
    
            let mapReqParams= {
                'json' :JSON.stringify(this.dataRecords)
                ,'headerList' : JSON.stringify(this.headerList)
            };
            insertContract({'dataMap' : mapReqParams})
            .then(response => {
                console.log('confirmUpload response', response);
                if(response && response.isSuccess){
                    this.showToast('O arquivo foi processado com sucesso.','sucess');
                }else{
                    if(response.msg && response.msg!= null && response.msg != ''){
                        this.showToast(response.msg,'error');
                    }
                }
            })
            .catch(error =>{
                console.log('confirmUpload error', error);
                this.showToast(error, 'error');
            });
        }catch(error){
            console.log('confirmUpload error',error);
        }
        
        
    }
}
