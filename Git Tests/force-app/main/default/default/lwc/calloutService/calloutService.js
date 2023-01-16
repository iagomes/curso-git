import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export function doCalloutWithStdResponse(scope, apexMethod, params, ...options){
    // console.log('options:::', options);
    // console.log('doCalloutWithStdResponse');
    if(!options || options.length == 0){
        options = {};
        options.processStandardResponse = true;
    } else {
        options.push({processStandardResponse: true});
    }
    return doCallout(scope, apexMethod, params, options);
}

export function doCallout(scope, apexMethod, params, ...optionsArray){
    let options = {};
    if(optionsArray){
        optionsArray.forEach(opt => {
            options = {...options, ...opt};
        });
    }
    // console.log('options:::', options);
    if(!options || options.length == 0){
        options = {};
    }
    // console.log('options:::', options);

    if(options.skipErrorDialog === undefined) {
        options.skipErrorDialog = false;
    }

    if(options.skipShowSpinner === undefined) {
        options.skipShowSpinner = false;
    }

    if(!options.processStandardResponse){
        return apexMethod(params);
    } else {
        return new Promise((resolve, reject) => {
            let result;
            if(!options.skipShowSpinner) {
                scope.showSpinner = true;
            }
            apexMethod(params).then((response) => {
                // console.log('response:::', response);
                if(!response){ 
                    throw 'Falha na integração';
                }
                else {
                    if(typeof response === 'string'){
                        response = JSON.parse(response);
                    }
                    if(response.messages && response.messages.length > 0){
                        if(response.hasError){
                            throw response.messages.join(' ,');
                        } else if(response.code == '201'){
                            scope.dispatchEvent(
                                new ShowToastEvent({ 
                                    title : 'Aviso', 
                                    message : response.messages.join(' ,'), 
                                    variant : 'warning'
                                })
                            );
                        }
                    }
                }
    
                // // console.log('json response::', response);
                result = response;
                if(!options.skipShowSpinner) {
                    scope.showSpinner = false;
                }
                resolve(result);
            }).catch(error => {
                if(!options.skipErrorDialog){
                    // console.log('error', JSON.stringify(error));
                    if(typeof error === 'string'){
                        addError(scope, error);
                    } else {
                        addError(scope, 'Falha na comunicação com o servidor, por favor entre em contato com o Administrador.');
                    }
                    // addError(scope, 'Por favor, entre em contato com o Administrador.');
                }
                if(!options.skipShowSpinner) {
                    scope.showSpinner = false;
                }
                reject(error);
            });
            // console.log('scope.showSpinner' , scope.showSpinner);
        });
    }
}

export function addError(scope, errorMessage, skipShowSpinner) {
    scope.dispatchEvent(
        new ShowToastEvent({ 
            title : 'Erro', 
            message : errorMessage, 
            variant : 'error', 
            mode: "sticky" 
        })
    );
    scope.hasError_ = true;
    if(!skipShowSpinner) {
        scope.showSpinner = false;
    }
}


export function hasRecords(response){
    return response && (!response.hasError) && response.data && response.data.records && response.data.records.length > 0;
}