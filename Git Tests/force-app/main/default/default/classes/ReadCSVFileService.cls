public with sharing class ReadCSVFileService {
    public static String getDocumentData(String documentId) {
        ContentVersion contentVersion = [
            SELECT
                Id,
                VersionData
            FROM ContentVersion
            WHERE ContentDocumentId =: documentId
            LIMIT 1
        ];

        return contentVersion.VersionData.toString();
    }

    public static List<String> getLines(String CSVContent) {
        List<String> lines = CSVContent.split('\n');
        return lines;
    }
}
