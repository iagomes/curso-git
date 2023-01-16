global class StringUtils {
    
    global static String cutByFieldLength(Schema.SObjectField theField, String value) {
        return cutByFieldLength(theField.getDescribe(), value);
    }

    global static String cutByFieldLength(Schema.DescribeFieldResult dfr, String value) {
        // Schema.DescribeFieldResult dfr = Account.Description.getDescribe();
        if(String.isEmpty(value) || value.length() <= dfr.getLength()){
            return value;
        } else {
            return value.left(dfr.getLength());
        }
    }

    global static String removeNonNumericCharacters(String value){
        return removeCharacters(value, '[^0-9]');
    }

    global static String removeCharacters(String value, String filter){
        return replaceCharacters(value, filter, '');
    }

    global static String replaceCharacters(String value, String filter, String newValue){
        // filter example '[^a-zA-Z0-9]'
        if(String.isEmpty(value)){
            return value;
        } else {
            return Pattern.compile(filter).matcher(value).replaceAll(newValue);
        }
    }

    global static String replaceSpecialCharacters(String value, Map<String,String> mapNewValues){
        return replaceSpecialCharacters(new List<String>{value}, mapNewValues)[0];
    }

    global static List<String> replaceSpecialCharacters(List<String> values, Map<String,String> mapNewValues){
        List<String> response = new List<String>();
        if(values != null && mapNewValues != null && !values.isEmpty() && !mapNewValues.isEmpty()){
            for(String value: values){
                if(!String.isEmpty(value)){
                    for(String filter: mapNewValues.keySet()){
                        value = replaceCharacters(value, filter, mapNewValues.get(filter));
                    }
                }
                response.add(value);
            }
        } else {
            response = values;
        }
        return response;
    }

    global static String getSiglaEstado(String estado){
        return getSiglaEstado(new List<String>{estado})[0];
    }

    global static List<String> getSiglaEstado(List<String> estados){
        List<String> response = new List<String>();
        if(estados == null || estados.isEmpty()){
            return estados;
        }

        Map<String,String> mapSiglasEstados = new Map<String, String>{
            'Acre' => 'AC',
            'Alagoas' => 'AL',
            'Amapá' => 'AP',
            'Amazonas' => 'AM',
            'Bahia' => 'BA',
            'Ceará' => 'CE',
            'Distrito Federal' => 'DF',
            'Espírito Santo' => 'ES',
            'Goiás' => 'GO',
            'Maranhão' => 'MA',
            'Mato Grosso' => 'MT',
            'Mato Grosso do Sul' => 'MS',
            'Minas Gerais' => 'MG',
            'Pará' => 'PA',
            'Paraíba' => 'PB',
            'Paraná' => 'PR',
            'Pernambuco' => 'PE',
            'Piauí' => 'PI',
            'Rio de Janeiro' => 'RJ',
            'Rio Grande do Norte' => 'RN',
            'Rio Grande do Sul' => 'RS',
            'Rondônia' => 'RO',
            'Roraima' => 'RR',
            'Santa Catarina' => 'SC',
            'São Paulo' => 'SP',
            'Sergipe' => 'SE',
            'Tocantins' => 'TO'
        };

        for(String nomeEstado: estados){
            response.add((String.isEmpty(nomeEstado) || !mapSiglasEstados.containsKey(nomeEstado) ? nomeEstado : mapSiglasEstados.get(nomeEstado)));
        }

        return response;
    }

    global static Set<String> convertListToSet(List<String> lstStr){
        Set<String> result = new Set<String>();
        result.addAll(lstStr);
        return result;
    }
    
    global static String dateToString(Date value){
        String sMonth = String.valueof(value.month());
        String sDay = String.valueof(value.day());
        if(sMonth.length()==1){
        sMonth = '0' + sMonth;
        }
        if(sDay.length()==1){
        sDay = '0' + sDay;
        }
        return String.valueof(value.year()) + '-' + sMonth + '-' + sDay;
    }
    
    //return true if value is format:"dd/MM/yy"
    global static Boolean isDateDDMMYY(String value){
        if(String.isNotBlank(value)){
            Pattern SearchTextDate = Pattern.compile('([0-3])(\\d)/([0-1])(\\d)/(\\d+)');
            Matcher isDateSearch = SearchTextDate.matcher(value);
            return isDateSearch.matches();
        }
        return false;
    }

    //return true if value is format:"dd/MM/yy hh"
    global static Boolean isDateTimeDDMMYYhh(String value){

        if(String.isNotBlank(value)){
            Pattern SearchTextHour = Pattern.compile('([0-3])(\\d)/([0-1])(\\d)/(\\d+)(\\s)([0-6])(\\d)');
            Matcher isHourSearch = SearchTextHour.matcher(value);
            return ishourSearch.matches();
        }
        return false;
    }

    //return true if value is format:"dd/MM/yy hh:mm"
    global static Boolean isDateTimeDDMMYYhhmm(String value){

        if(String.isNotBlank(value)){
            Pattern SearchTextMinute = Pattern.compile('([0-3])(\\d)/([0-1])(\\d)/(\\d+)(\\s)([0-6])(\\d):([0-6])(\\d)');
            Matcher isMinuteSearch = SearchTextMinute.matcher(value);
            return isMinuteSearch.matches();
        }
        return false;
    }

    global static Decimal transformToNumber(String value){

        if(String.isNotBlank(value) && value.containsOnly('0123456789.,')){
            List<String> toList = value.split(',|\\.');
            toList[toList.size()-1] = '.'+toList[toList.size()-1];
            String toString = String.join(toList, '');
            return Decimal.valueOf(toString);
        }
        return null;
    }
}