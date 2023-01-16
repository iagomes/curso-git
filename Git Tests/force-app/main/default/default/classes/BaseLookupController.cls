public with sharing class BaseLookupController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String data) {
		System.debug('data => ' + data);
		Map<String, Object> requestDataMap = (Map<String, Object>)JSON.deserializeUntyped(data);
        RequestDTO requestData = new RequestDTO(requestDataMap);

        System.debug(requestData);

        String query = getQueryBase(requestData);

        System.debug(query);
        query += ' LIMIT 5';
        return Database.query(query);
    }

    public static String getQueryBase(RequestDTO requestData) {
    	String query = 'SELECT Id, #SEARCH_FIELDS# FROM #OBJECT_API# WHERE Id != NULL ';
        query = query.replace('#OBJECT_API#', requestData.targetObject);

        Set<String> fieldsSet = getQueryFieldsSet(requestData);
        String fields = String.join((Iterable<String>)fieldsSet, ', ');
        query = query.replace('#SEARCH_FIELDS#', fields);

        if (requestData.searchValue != null) {
            query += 'AND ( #SEARCH_BASE# )';
        }

        String searchBase = parseSearchFields(requestData.searchFields);

        query = query.replaceAll('#SEARCH_BASE#', searchBase);

        if (requestData.searchValue != null) {
            query = query.replaceAll('#SEARCH_VALUE#', String.escapeSingleQuotes(requestData.searchValue));
        }

        if (requestData.relations != null && requestData.relations.size() > 0) {
            query += parseRelationFields(requestData.relations);
        }

        return query;
    }

    public static Set<String> getQueryFieldsSet(RequestDTO requestData) {
        Set<String> fieldsSet = new Set<String>();

        fieldsSet.addAll(convertObjectListToStringList(requestData.searchFields));

        if (requestData.moreFields != null) {
            fieldsSet.addAll(convertObjectListToStringList(requestData.moreFields));
        }

        return fieldsSet;
    }

    public static String parseSearchFields(List<Object> searchFields) {
        String searchBase = '';

        for (Integer i = 0; i < searchFields.size(); i++) {
            if (i > 0) {
                searchBase += ' OR ' + searchFields[i];
            } else {
                searchBase +=  searchFields[i];
            }

            searchBase += ' LIKE \'%#SEARCH_VALUE#%\' ';
        }

        return searchBase;
    }

    public static String parseRelationFields(List<RelationDTO> relations) {
        String relationsBase = '';

        for (RelationDTO relation : relations) {
			Object parentRecord = relation.parentRecord;

			if (relation.operator == 'IN' || relation.operator == 'NOT IN') {
				String value = '';

				for (String record : convertObjectListToStringList(relation.parentRecordList)) {
					if (value == '') value = '\'' + record + '\'';
					else value += ', \'' + record + '\'';
				}
                if (value == '') value = '\'\'';

				parentRecord = '(' + value + ')';
			}
			else if (relation.operator == 'LIKE') {
				if (relation.parentRecord == '') parentRecord = '\'%%\'';
                else parentRecord = '\'' + relation.parentRecord + '\'';
			}
			else if (relation.parentRecord instanceof String) {
				if (!checkDatetimeAndDate((String)relation.parentRecord)) parentRecord = '\'' + relation.parentRecord + '\'';
			}
            //parentRecord = relation.parentRecord instanceof Boolean ? relation.parentRecord : '\'' + relation.parentRecord + '\'';

            relationsBase += ' AND ' + relation.parentRelationField + ' ' + relation.operator + ' ' + parentRecord;
        }

        return relationsBase;
    }

	public static Boolean checkDateTimeAndDate(String stringToCheck) {
		String regexDatetime = '[0-9]{4}-[0-9]{0,2}-[0-9]{0,2}T[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}.[0-9]{0,3}-[0-9]{0,2}:[0-9]{0,2}';
		String regexDate = '[0-9]{4}-[0-9]{0,2}-[0-9]{0,2}';
		Pattern datetimePattern = Pattern.compile(regexDatetime);
		Pattern datePattern = Pattern.compile(regexDate);

		Matcher matchDatetime = datetimePattern.matcher(stringToCheck);
		Matcher matchDate = datePattern.matcher(stringToCheck);

		//System.debug('matchDatetime.matches() => ' + matchDatetime.matches());
		//System.debug('matchDate.matches() => ' + matchDate.matches());
		return (matchDatetime.matches() || matchDate.matches());
	}

	public static List<String> convertObjectListToStringList(List<Object> objectList) {
		if (objectList == null) return new List<String>();

		List<String> searchFields = new List<String>();
		for (Object field : objectList) {
			if (field != null) searchFields.add((String)field);
		}

		return searchFields;
	}

    public class RequestDTO {
        public String targetObject;
        public String searchValue;
        public List<Object> searchFields;
        public List<Object> moreFields;

        public List<RelationDTO> relations;

		public RequestDTO(Map<String, Object> requestDataMap) {
			this.targetObject = (String)requestDataMap.get('targetObject');
			this.searchValue = (String)requestDataMap.get('searchValue');
			this.searchFields = (List<Object>)requestDataMap.get('searchFields');
			this.moreFields = (List<Object>)requestDataMap.get('moreFields');

			List<RelationDTO> relationDTOList = new List<RelationDTO>();

			for (Object relation : (List<Object>)requestDataMap.get('relations')) {
				relationDTOList.add(new RelationDTO((Map<String, Object>)relation));
			}

			this.relations = relationDTOList;
		}
    }

    public class RelationDTO {
        public String parentRelationField;
        public Object parentRecord;
        public List<String> parentRecordList;
        public String operator;

		public RelationDTO(Map<String, Object> objectMap) {
			this.parentRelationField = (String)objectMap.get('parentRelationField');
			this.parentRecord = objectMap.get('parentRecord');
			this.parentRecordList = objectMap.get('parentRecord') == null ? (
										objectMap.get('parentRecordList') == null ? null
										: convertObjectListToStringList((List<Object>)objectMap.get('parentRecordList'))
									) : null;
			this.operator = (String)objectMap.get('operator');
		}
    }
}