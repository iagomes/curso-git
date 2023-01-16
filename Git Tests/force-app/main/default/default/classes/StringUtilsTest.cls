@isTest
public class StringUtilsTest {   

    @isTest
    public static void StringUtilsTest() {

        User u = TestUtility.createUser();
        insert u;

        Account acc = TestUtility.createAccount();
        insert acc;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;

        Opportunity opp = TestUtility.createOpportunity(u);
        insert opp;

        Map<String, String> mapNewValues = new Map<String, String>{
            '\\\\' => '',
            '\\\'' => '\\\\\\\''
        };

        Test.startTest();
            String removeNonNumericCharacters = StringUtils.removeNonNumericCharacters('(68) 2872-3377');
            String replaceSpecialCharacters = StringUtils.replaceSpecialCharacters(acc.Name, mapNewValues);
            String getSiglaEstado = StringUtils.getSiglaEstado('Alagoas');
        Test.stopTest();
    }
}