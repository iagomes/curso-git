import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export class MultiOption {

    selected;
    value;
    data;

    constructor(selected, value, label ) {
        this.selected = selected;
        this.label = label;
        this.value = value;
        this.data = value;
        if(value && typeof value === 'object'){
            if(this.data.Id){
                this.data.id = this.data.Id;
            }
            if(this.data.Name){
                this.data.name = this.data.Name;
            }
            if(this.data.id){
                this.value = this.data.id;
            }
            if(!label && this.data.name){
                this.label = this.data.name;
            }
        }
    }
    
    get className() {
        return 'slds-dropdown__item slds-media slds-listbox__option slds-media_center slds-media_small slds-listbox__option_plain' + ( this.selected ? ' slds-is-selected': '');
    };

    get isSelected() {
        return this.selected;
    }

    onclick() {
        this.selected = (!this.selected);
    }
}

export function splitString(value, separators){
    if(value && separators){
        separators.forEach( ( separator, index ) => {
            value = value.split(separator).join(';');
        });
        value = value.split(';');
    }
    return value;
}

export function objectContainsValue(obj, searchValue){
    // console.log('objectContainsValue obj:::', obj, 'searchValue:::' , searchValue, ' type:::' , typeof searchValue);
    let result = false;
    let values = Object.values(obj);
    for(let i = 0; i < values.length; i++){
        let value = values[i];
        // console.log('searchValue::', searchValue, 'value:::', value, 'type:::' , typeof value);
        if(!value){
            // console.log('searchValue::', searchValue, 'a result:::', false);
            continue;
        }
        if(value == searchValue || (typeof value === "string" && value.indexOf(searchValue) >= 0)){
            // console.log('searchValue::', searchValue, 'b result:::', true);
            result = true;
            break;
        }
        try {
            if(typeof value === 'object'){
                result = objectContainsValue(value, searchValue);
                // console.log('searchValue::', searchValue, 'c result:::', true);
                if(result){
                    break;
                }
            } else if(typeof value === 'array'){
                let bValues = Object.values(value);
                for(let j = 0; j < values.length; j++){
                    let bValue = bValues[j];
                    if(objectContainsValue(bValue, searchValue)){
                        // console.log('searchValue::', searchValue, 'd result:::', true);
                        result = true;
                        break;
                    }
                }
            } else {
                // console.log('searchValue::', searchValue, 'e result:::', value.indexOf(searchValue) >= 0);
                result = value.indexOf(searchValue) >= 0;
                if(result){
                    break;
                }
            }
        } catch (ex){
            // console.log('searchValue::', searchValue, 'f result:::', false);
        }
    }
    return result;
}

export function getResource(resourceUrl) {
    return new Promise((resolve, reject) => {
        fetch(resourceUrl).then( (response) => {
            if(response.status >= 200 && response.status < 300){
                response.json().then(json => {
                    resolve(json);
                });
            } else {
                reject(response); 
            }
        });
    });
}

export function getSecondsBetweenTwoDates(date1, date2){
    return Math.abs((date1-date2) / 1000);
}

export function waitMiliseconds(time){
    return new Promise((resolve, reject) => {
        window.setTimeout(() => {
            resolve();
        }
        , time);
    });
}

export function compareObjectsBy_name( a, b ) {
    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
}

export function compareObjectsByField( a, b ) {
    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
}

export function sortObjectsArrayByField( objectArray, fieldName ) {
    return objectArray.sort((a, b) => {
        return a[fieldName].toLowerCase().localeCompare(b[fieldName].toLowerCase());
    });
}

export function showToast(title, message, variant, mode){
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: mode }));
}

/**
 * Simple object check.
 * @param item
 * @returns {boolean}
 */
export function isObject(item) {
    return (item && typeof item === 'object' && !Array.isArray(item));
}

/**
 * Deep merge two objects.
 * @param target
 * @param ...sources
 */
export function mergeDeep(target, ...sources) {
    // export function mergeDeep(maxDepth, target, ...sources) {
    // if(maxDepth === null || maxDepth === undefined){
    //     maxDepth = 5;
    // }
    // maxDepth--;
    // if (!sources.length || maxDepth < 0){
    if (!sources.length){
        return target;
    }
    
    let source = sources.shift();

    if (isObject(target) && isObject(source)) {
        for (let key in source) {
            if (isObject(source[key])) {
                if (!target[key]){
                    Object.assign(target, { [key]: {} });
                }
                mergeDeep(target[key], source[key]);
                // mergeDeep(maxDepth, target[key], source[key]);
            } else {
                Object.assign(target, { [key]: source[key] });
            }
        }
    }

    // return mergeDeep(maxDepth, target, ...sources);
    return mergeDeep(target, ...sources);
}


export function getParentElementByClassName(scope, element, className){
    if(element == null){
        return scope.template.querySelector("." + className);
    } else {
        for(let i = 0; i < 12; i++){
            if(element.classList && element.classList.value.indexOf(className) >= 0){
                return element;
            } else {
                element = element.parentElement;
            }
        }
        return null;
    }
}

export function formatarData(data){
    if(data){
        if(typeof data === "string"){
            data = new Date(data.replace('.000', '').replace(' ','T'));
        }
        let dia  = data.getDate().toString(),
        diaF = (dia.length == 1) ? '0'+dia : dia,
        mes  = (data.getMonth()+1).toString(), //+1 pois no getMonth Janeiro começa com zero.
        mesF = (mes.length == 1) ? '0'+mes : mes,
        anoF = data.getFullYear(),
        hora  = data.getHours().toString(),
        horaF = hora.length == 1 ? '0' + hora : hora,
        minuto  = data.getMinutes().toString(),
        minutoF = minuto.length == 1 ? '0' + minuto : minuto;
        return diaF + '/' + mesF + '/' + anoF + ' ' + horaF + ':' + minutoF;
    }
    return null;
}

export function stringToDate(data){
    return data && typeof data === "string" ? new Date(data.replace('.000', '').replace(' ','T')) : null;
}

export function stringToNumber(value, toFixed){
    if(!value){
        value = 0;
    }
    if(typeof value === "string"){
        value = Number(value);
    }
    
    if(toFixed && typeof value == "number"){
        value = value.toFixed(toFixed);
    }
    return value;
}

export function isEmpty(value, isJson){
    if(typeof value == "string"){
        value = value.trim();
        if(isJson && value){
            return isEmpty(JSON.parse(value), false);
        }
    }
    if(!value){
        return true;
    }
    if(value instanceof Date){
        return false;
    }
    if(typeof value == "object" && Object.keys(value).length == 0){
        return true;
    }
    if(value.hasOwnProperty("length") && value.length == 0 && typeof value != "function"){
        return true;
    }
    return false;
}

export function isNotEmpty(value){
    return !isEmpty(value);
}

export function getChangedProperties(oldParams, newParams){
    
    if(isEmpty(newParams)){
        return [];
    }
    
    if(isEmpty(oldParams)){
        return Object.keys(newParams);
    } 
    else {
        let changedParams = [];
        Object.keys(newParams).forEach(newKey => {
            if(!oldParams[newKey] || oldParams[newKey] != newParams[newKey]){
                changedParams.push(newKey);
            }
        });
        return changedParams;
    }
}