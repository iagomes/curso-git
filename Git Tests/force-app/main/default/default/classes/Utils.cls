/********************************************************************************************
* Name   : Utils
* Purpose: Standardize and accelerate developments
* Author : Gabriel Teixeira
* Date   : 29/09/2020

* Change Log
-------------------------------------------------------------------------------------------
29/09/2020           Gabriel Teixeira         Implementing Class with projects Methods
********************************************************************************************/
public class Utils {

    public static final Date MAX_DATE = Date.newInstance(4000, 12, 31);
    public static final Date MIN_DATE = Date.newInstance(1700, 01, 01);

    // @PRIMIVITE CONVERT VARIABLES METHODS
    public static Boolean stringIsEmpty(String str){
        return ((String.isBlank(str) || str.toLowerCase() == 'null' || str == null || str == '') ? true : false); 
    }
    public static Boolean decimalIsEmpty(Decimal decs){
        String str = String.valueOf(decs);
        return ((String.isBlank(str) || str.toLowerCase() == 'null' || str == null || str == '') ? true : false); 
    }
    public static void requiredString(String value) {
        if(stringIsEmpty(value)) {
            throw new NullPointerException();
        }        
    }   
    public static String clearNonDigits(String data){
        if (data == null) return null;

        return data.replaceAll('\\D', '');
    } 
    public static Decimal stringToDecimal(String data){
        if (String.isBlank(data)) return null;
        return Decimal.valueOf(data);
    }
    public static Integer stringToInteger(String data){
        return (data != null && String.isNotBlank(data) ? Integer.valueOf(data) : null);
    }    
    public static Double stringToDouble(String data){
        return (data != null && String.isNotBlank(data) ? Double.valueOf(data) : null);
    }    
    public static Long stringToLong(String data){
        return (data != null && String.isNotBlank(data) ? Long.valueOf(data) : null);
    }
    public static Date stringToDate(String data) {
        if (String.isBlank(data) || data.containsOnly('0')) return null;

        if (data.length() == 10) {
            if ((data.substring(4, 5) != '-' || data.substring(7, 8) != '-') && data.replace('-', '').length() != 8) {
                throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
            } else {
                data = data.replace('-', '');
            }
        }

        if (!data.isNumeric() || data.length() != 8){
            throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
        }

        // if (data.length() == 8 && data.isNumeric()) {
            try {
                Date dt = Date.newInstance(
                    Integer.valueOf(data.substring(0,4)),
                    Integer.valueOf(data.substring(4,6)),
                    Integer.valueOf(data.substring(6,8))
                );
                return ((dt > MAX_DATE) ? MAX_DATE : (dt < MIN_DATE ? MIN_DATE : dt));
            } catch(Exception e) {
                throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
            }
        // } else {
        //     throw new ConversionException('Invalid value for Date conversion: "'+data+'"');
        // }
    }
    public static Time stringToTime(String str){
        if (String.isBlank(str)) return null;
        
        if (str.length() == 8){
            if (str.substring(2, 3) != ':' || str.substring(5, 6) != ':') {
                throw new ConversionException('Invalid value for Time conversion: "'+str+'"');
            } else {
                str = str.replace(':', '');
            }
        }

        if (str.length() != 6 || !str.isNumeric()){
            throw new ConversionException('Invalid value for Time conversion: "'+str+'"');
        }

        return Time.newInstance(
            Integer.valueOf(str.substring(0, 2)),
            Integer.valueOf(str.substring(2, 4)),
            Integer.valueOf(str.substring(4, 6)),
            0
        );
    }
    // @END PRIMIVITE CONVERT VARIABLES METHODS

    // @MASK FORMAT METHODS
	public static Boolean emailAddressIsValid(String emailTxt) {
		if (String.isEmpty(emailTxt)) 
			return true;
		Boolean isValid = true;
		
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
		Pattern MyPattern = Pattern.compile(emailRegex);
		Matcher MyMatcher = MyPattern.matcher(emailTxt);
	
		if (!MyMatcher.matches()) 
		    isValid = false;
		return isValid;	
	}
	public static String replaceSpecialCaracter(String value){
		Map<String,String> mapaAcentosHex = new Map<String, String>{
			'a' => '[à-æ]',
			'A' => '[À-Æ]',
			'e' => '[è-ë]',
			'E' => '[È-Ë]',
			'o' => '[ò-ö]',
			'O' => '[Ò-Ö]',
			'u' => '[ù-ü]',
			'U' => '[Ù-Ü]',
			'i' => '[ì-ï]',
			'c' => '[ç]',
			'C' => '[Ç]',
			'n' => '[ñ]',
			'N' => '[Ñ]',
			'I' => '[Ì-̈Ï]'};

		for (String letra : mapaAcentosHex.keySet()) {
			value = value.replaceAll(mapaAcentosHex.get(letra), letra);
		}
		return value;
	}
    public static String formatCNPJ(String str){
        if (str == null) return null;

        // Clear anything that's not a number
        str = str.replaceAll('\\D', '');
        if (str.length() != 14){
            return null;
        }

        return String.format('{0}.{1}.{2}/{3}-{4}', new List<String>{
            str.substring(0, 2),
            str.substring(2, 5),
            str.substring(5, 8),
            str.substring(8, 12),
            str.substring(12)
        });
    }
    public static String formatCPF(String str, boolean returnFormatted) {
        if (str == null) return null;

        // Clear anything that's not a number
        str = str.replaceAll('\\D', '');
        if (str.length() != 11){
            return null;
        }
        if(returnFormatted){
            return String.format('{0}.{1}.{2}-{3}', new List<String>{
                str.substring(0, 2),
                str.substring(2, 5),
                str.substring(5, 8),
                str.substring(8, 10)
            });
        }
        return str;
    }
    public static String formatCEP(Integer cep) {
        return formatCEP(String.valueOf(cep));
    }
    public static String formatCEP(String cep) {
        String convertedCep = String.valueOf(cep);
        if (convertedCep != null && String.isNotBlank(convertedCep) && convertedCep.length() == 8) {
            try {
                return convertedCep.substring(0, 5) + '-' + convertedCep.substring(5, 8);
            } catch(Exception e) {
                throw new ConversionException('Invalid value for CEP conversion: "' + convertedCep + '"');
            }
        } else {
            throw new ConversionException('Invalid value for CEP conversion: "' + convertedCep + '"');
        }
    }
    public static String leftZeroesTrim(String str){
        Integer index = str.indexOfAnyBut('0');
        if (index == -1 || index == null){
            return str;
        }else{
            return str.substring(index);
        }
    }    
    public static String leftZeroesFix(Long it, Integer zeroesToTheLeft){
        String num = String.valueOf(it);
		Integer size = num.length() + zeroesToTheLeft;
        while (num.length() < size){
            num = '0'+num;
        }

        return num;
    }    
    public static String leftZeroesFill(Long it, Integer numberLength){
        String num = String.valueOf(it);
        while (num.length() < numberLength){
            num = '0'+num;
        }

        return num;
    }
    // @END MASK FORMAT METHODS
    
    public static Set<String> getPicklistValues(SObjectField field) {
        Set<String> options = new Set<String>();
        for(Schema.PicklistEntry picklist : field.getDescribe().getPicklistValues()) {
            options.add(picklist.getValue());
        }
        return options;
    }
    public static Map<String, String> getPicklistApi(SObjectField field) {
        Map<String, String> options = new Map<String, String>();
        for(Schema.PicklistEntry picklist : field.getDescribe().getPicklistValues()) {
            options.put(picklist.getValue(), picklist.getLabel());
        }
        return options;
    }
    public static String fileSizeToString(Long value){
    	/* Converts integer bytes into KB, MB or GB metric */
        if (value < 1024){
          return string.valueOf(value) + ' Bytes';
        }else{
        	if (value >= 1024 && value < (1024*1024)){
		        //KB
		        Decimal kb = Decimal.valueOf(value);
		        kb = kb.divide(1024,2);
		        return string.valueOf(kb) + ' KB';
        	}else{
        		if (value >= (1024*1024) && value < (1024*1024*1024)){
		        	//MB
		        	Decimal mb = Decimal.valueOf(value);
		        	mb = mb.divide((1024*1024),2);
		        	return string.valueOf(mb) + ' MB';
		        }else{
			        //GB
			        Decimal gb = Decimal.valueOf(value);
			        gb = gb.divide((1024*1024*1024),2);
			        return string.valueOf(gb) + ' GB';
		        }
    		}
    	}
    }
    public static String beautifyJSON(String data) {
        try {
            return JSON.serializePretty(JSON.deserializeUntyped(data));
        } catch (Exception e) {
            System.debug('Could not beautify due to malformed JSON');
            return data;
        }
    }
    public static String formatExceptionMessage(Exception e) {
        return 'Exception: ' + e.getMessage() + ' - Stack Trace: ' + e.getStackTraceString();
    }
    
    public static List<String> getAllFieldsFromObject(String obj) {

        List<String> fieldList = new List<String>();

        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(obj).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.values())
        {
            Schema.Describefieldresult dfield = sfield.getDescribe();
            fieldList.add(dfield.getName());
        }
        
        return fieldList;

    }

    public class NullPointerException extends Exception {}
    public class ConversionException extends Exception{}
}
