/**
    MIT License

    Copyright (c) 2018 Alex

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

@IsTest
public with sharing class QueryBuilderTest {

    @TestSetup
    public static void init() {
        // createAccount(1);
        
        // result.Name = 'Account-' + i;
        // result.NumberOfEmployees = 0;
        Account acc = TestUtility.createAccPJ();
        acc.Name = 'Account-1';
        acc.NumberOfEmployees = 0;
        acc.DescontoCliente__c = 2;
        acc.CNPJ__c = '47782743000124';
        acc.ExternalId__c = '47782743000124';
        insert acc;

        Account acc3 = TestUtility.createAccPJ();
        acc3.Name = 'Account-2';
        acc3.NumberOfEmployees = 0;
        acc3.ParentId = acc.Id;
        acc3.DescontoCliente__c = 2;
        acc.CNPJ__c = '34349677000151';
        acc.ExternalId__c = '34349677000151';
        insert acc3;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;
        
        Contact contact3 = TestUtility.createContact(acc3.Id);
        contact3.Email = 'teste'+Integer.valueof((Math.random() * 100)) +'@test.com';
        insert contact3;
    }

    @IsTest
    public static void testFrom1() {
        List<Account> accounts = (List<Account>) new QueryBuilder('Account')
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(new Account())
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom4() {
        List<Account> accounts = (List<Account>) new QueryBuilder(new Account().getSObjectType())
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom5() {
        List<Account> accounts = (List<Account>) new QueryBuilder()
                .addFrom('Account')
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom6() {
        List<Account> accounts = (List<Account>) new QueryBuilder()
                .addFrom(Account.class)
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom7() {
        List<Account> accounts = (List<Account>) new QueryBuilder()
                .addFrom(new Account())
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testFrom8() {
        List<Account> accounts = (List<Account>) new QueryBuilder()
                .addFrom(new Account().getSObjectType())
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testField1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields(new List<String>{'Name', 'Parent.Name'})
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
        for(Account acc: accounts){
            if(acc.Name == 'Account-2'){
                System.assertEquals(acc.Parent.Name, 'Account-1');
            }
        }
    }

    @IsTest
    public static void testField2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addField(Account.Name)
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testField3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addField('Id, Name')
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields(new Account(Name = 'test'))
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields21() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields('Name')
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields22() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields('Id, Name')
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields23() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields('Name, Name')
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields31() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields(new List<String>{
                        'Name'
                })
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields32() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields(new List<String>{
                        'Id', 'Name'
                })
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields33() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields(new List<String>{
                        'Name', 'Name'
                })
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields4() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFields(new Set<String>{
                        'Name'
                })
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields5() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFieldsAll()
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields6() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFieldsAll('Account')
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testFields7() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addFieldsAllCreatable()
                .toList();
        System.assertEquals(2, accounts.size());
        System.assertNotEquals(null, accounts[0].Name);
    }

    @IsTest
    public static void testConditionManager() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.SimpleCondition())
                .preview()
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testSimpleCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.SimpleCondition('Name = \'Account-1\''))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testSimpleCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.SimpleCondition())
                .add(new QueryBuilder.SimpleCondition().ignoreConditionsForNullValues())
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testNullCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.NullCondition('Name').isNull())
                .endConditions()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testNullCondition12() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.NullCondition(Account.Name).isNull())
                .endConditions()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testNullCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.NullCondition(Account.Name).notNull())
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testCompareCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
                .add(new QueryBuilder.CompareCondition('Name').eq(System.today()))
                .add(new QueryBuilder.CompareCondition('Name').eq(true))
                .add(new QueryBuilder.CompareCondition('Name').ne(true))
                .add(new QueryBuilder.CompareCondition('Name').lt(DateTime.newInstance(2007, 6, 23, 3, 3, 3)))
                .add(new QueryBuilder.CompareCondition('Name').gt(DateTime.newInstance(2007, 6, 23, 3, 3, 3)))
                .add(new QueryBuilder.CompareCondition('Name').lte(DateTime.newInstance(2007, 6, 23, 3, 3, 3)))
                .add(new QueryBuilder.CompareCondition('Name').lte(System.today()))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testCompareCondition12() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition(Account.Name).eq('Account-1'))
                .add(new QueryBuilder.CompareCondition(Account.CreatedDate).lte('Account-1','CreatedDate','Account'))
                .add(new QueryBuilder.CompareCondition(Account.CreatedDate).lte(System.today(),'CreatedDate','Account'))
                .add(new QueryBuilder.CompareCondition(Account.CreatedDate).gte(System.today(),'CreatedDate','Account'))
                .add(new QueryBuilder.CompareCondition(Account.Name).gte('Account-1','Name','Account'))
                .add(new QueryBuilder.CompareCondition(Account.Name).lt('Account-1'))
                .add(new QueryBuilder.CompareCondition(Account.Name).gt('Account-1'))
                .add(new QueryBuilder.CompareCondition(Account.Name).lte('Account-1'))
                .add(new QueryBuilder.CompareCondition(Account.Name).gte('Account-1'))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testCompareCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('Name').ne('Account-1'))
                .endConditions()
                .toList();
        List<Id> accountIds = new List<Id>();
        System.assertEquals(false, accounts.isEmpty());

        for(Account iAccount : accounts) {
            accountIds.add(iAccount.Id);
        }

        delete [Select Id, AccountId from Entitlement WHERE AccountId in: accountIds];

        delete accounts;
        
        accounts = (List<Account>) new QueryBuilder(Account.class)
        .addConditions()
        .add(new QueryBuilder.CompareCondition('Name').ne('Account-1'))
        .endConditions()
        .toList();
        System.assertEquals(true, accounts.isEmpty());
    }

    @IsTest
    public static void testCompareCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').eq(1))
                .endConditions()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testCompareCondition31() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').ne(0))
                .endConditions()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testCompareCondition32() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gt(0))
                .endConditions()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testCompareCondition33() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gte(1))
                .endConditions()
                .preview()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testCompareCondition34() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').lt(0))
                .endConditions()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testCompareCondition35() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').lte(-1))
                .endConditions()
                .preview()
                .toList();
        System.assert(accounts.isEmpty());
    }

    @IsTest
    public static void testLikeCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('ccount-'))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testLikeCondition12() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.LikeCondition(Account.Name).likeAnyBoth('ccount-'))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testLikeCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.LikeCondition('Name').likeAnyLeft('ccount-1'))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testLikeCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.LikeCondition('Name').likeAnyRight('Account-'))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    // @IsTest
    // public static void testInCondition01() {
    //     List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
    //             .addConditions()
    //             .add(new QueryBuilder.InCondition('Id').inCollection(new Set<Id>()))
    //             .endConditions()
    //             .toList();
    //     System.assert(accounts.isEmpty());
    // }

    // @IsTest
    // public static void testInCondition02() {
    //     List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
    //             .addConditions()
    //             .add(new QueryBuilder.InCondition('Id').inCollection(new List<Id>()))
    //             .endConditions()
    //             .toList();
    //     System.assert(accounts.isEmpty());
    // }

    @IsTest
    public static void testInCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Name').inCollection(new List<String>{
                        'Account-1'
                }))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testInCondition12() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition(Account.Name).inCollection(new List<String>{
                        'Account-1'
                }))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testInCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Name').inCollection(new Set<String>{
                        'Account-1'
                }))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testInCondition3() {
        Set<Id> accIds = new QueryBuilder('Account').toIdSet();
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Id').inCollection(accIds))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testInCondition31() {
        List<String> accIds = new List<Id>(new QueryBuilder('Account').toIdSet());
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Id').inCollection(accIds))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testInCondition32() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Id').inCollection(new QueryBuilder('Contact').addFields('AccountId')))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testInCondition33() {
        Map<String,List<Contact>> mapContactByAccountId = (Map<String,List<Contact>>) new QueryBuilder('Contact').addFields('AccountId').toMap('AccountId');
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Id').inCollection(mapContactByAccountId.keySet()))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    // @IsTest
    // public static void testInCondition34() {
    //     Map<Id,List<Contact>> mapContactByAccountId = (Map<Id,List<Contact>>) new QueryBuilder('Contact').addFields('AccountId').toMap('AccountId');
    //     List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
    //             .addConditions()
    //             .add(new QueryBuilder.InCondition('Id').inCollection(new QueryBuilder('Contact').addFields('AccountId').toList()))
    //             .endConditions()
    //             .toList();
    //     System.assertEquals(2, accounts.size());
    // }

    @IsTest
    public static void testInCondition41() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('DescontoCliente__c').inCollection(new Set<Decimal>{2.0}))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testInCondition42() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('DescontoCliente__c').inCollection(new List<Decimal>{2.0}))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testNotInCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Id').notIn(new QueryBuilder('Account').toList()))
                .endConditions()
                .toList();
        System.assertEquals(0, accounts.size());
    }

    // @IsTest
    // public static void testNotInCondition2() {
    //     List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
    //             .addConditions()
    //             .add(new QueryBuilder.InCondition('Id').notIn(new QueryBuilder('Contact').addFields('AccountId').toMap()))
    //             .endConditions()
    //             .toList();
    //     System.assertEquals(0, accounts.size());
    // }

    @IsTest
    public static void testNotInCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.InCondition('Id').notIn(new QueryBuilder('Contact').addFields('AccountId')))
                .endConditions()
                .toList();
    }

    @IsTest
    public static void testComplexCondition0() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        System.assertEquals('', complex.toString());
    }

    @IsTest
    public static void testComplexCondition1() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.startCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(complex)
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testComplexCondition2() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(complex)
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testComplexCondition3() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.orCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(complex)
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testComplexCondition4() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.NullCondition('Name').notNull())
                .add(complex)
                .setConditionOrder('1' + complex.addOrderIfNotEmpty('AND 2'))
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testComplexCondition5() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.NullCondition('Name').notNull())
                .add(complex)
                .setConditionOrder('1' + complex.addOrderIfNotEmpty('AND 2'))
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testComplexCondition6() {
        Id accId = new QueryBuilder('Account').toSObject().Id;
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(
                    new QueryBuilder.ComplexCondition()
                        .andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
                        .andCondition(new QueryBuilder.CompareCondition('Id').eq(accId))
                )
                .endConditions()
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testComplexCondition7() {
        Id accId = new QueryBuilder('Account').toSObject().Id;
        //createAccount(2);

        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-2'));
        complex.orCondition(new QueryBuilder.CompareCondition('Id').eq(accId));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addConditions()
                .add(complex)
                .endConditions()
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testLimit1() {
        //createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .setLimit(-1)
                .toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testLimit2() {
        //createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .setLimit(1)
                .toList();
        System.assertEquals(1, accounts.size());
    }

    @IsTest
    public static void testOrder1() {
        //createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addField('Name')
                .addOrderAsc('Name')
                .toList();
        System.assertEquals('Account-1', accounts[0].Name);
    }

    @IsTest
    public static void testOrder2() {
        //createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addField('Name')
                .addOrderDesc('Name')
                .toList();
        System.assertEquals('Account-2', accounts[0].Name);
    }

    @IsTest
    public static void testOrder3() {
        //createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addField('Name')
                .addOrderAsc('Name')
                .addOrderAsc('Id')
                .toList();
        System.assertEquals('Account-1', accounts[0].Name);
    }

    @IsTest
    public static void testOrder4() {
        //createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
                .addField('Name')
                .addOrderDesc('Name')
                .addOrderDesc('Id')
                .toList();
        System.assertEquals('Account-2', accounts[0].Name);
    }

    @IsTest
    public static void testPreview() {
        new QueryBuilder(Account.class)
                .preview();
    }

    @IsTest
    public static void testPreviewCount() {
        new QueryBuilder(Account.class)
                .previewCount();
    }

    @IsTest
    public static void testToString() {
        String queryString = new QueryBuilder(Account.class)
                .toString();
        System.assertEquals('SELECT Id FROM Account', queryString);
    }

    @IsTest
    public static void testToCountString() {
        String queryString = new QueryBuilder(Account.class)
                .toStringCount();
        System.assertEquals('SELECT count() FROM Account', queryString);
    }

    @IsTest
    public static void testToCountString2() {
        String queryString = new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
                .endConditions()
                .toStringCount();
        System.assertEquals('SELECT count() FROM Account WHERE Name = \'Account-1\'', queryString);
    }

    @IsTest
    public static void testResetResult() {
        QueryBuilder accountQueryBuilder = new QueryBuilder('Account');
        List<Account> accounts = (List<Account>) accountQueryBuilder
                .toList();
        System.assertEquals(2, accounts.size());

        //createAccount(2);
        accounts = (List<Account>) accountQueryBuilder.toList();
        System.assertEquals(2, accounts.size());

        accountQueryBuilder.resetResult();
        accounts = (List<Account>) accountQueryBuilder.toList();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testToMap1() {
        Map<Id, SObject> accounts = new QueryBuilder('Account')
                .addField('Name')
                .toMap();
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testToMap2() {
        Map<Id, Account> accounts = new Map<Id, Account>();
        new QueryBuilder('Account')
                .addField('Name')
                .toMap(accounts);
        System.assertEquals(2, accounts.size());
    }

    @IsTest
    public static void testToSobject() {
        Account account = (Account) new QueryBuilder('Account')
                .toSObject();
        System.assertNotEquals(null, account);
    }

    @IsTest
    public static void testToSobject2() {
        SObject account = (Account) new QueryBuilder('Account')
                .addConditions()
                .add(new QueryBuilder.NullCondition('Name').isNull())
                .endConditions()
                .toSObject();
        System.assertEquals(null, account);
    }

    @IsTest
    public static void testToIdSet() {
        Set<Id> accountIds = new QueryBuilder('Account')
                .toIdSet();
        System.assertEquals(2, accountIds.size());
    }

    @IsTest
    public static void testExtractIds() {
        final Id ACCOUNT_ID = new QueryBuilder('Account').toSObject().Id;
        createContact(ACCOUNT_ID);
        Set<Id> extractedIds = new QueryBuilder('Contact')
                .addField('AccountId')
                .extractIds('AccountId');
        System.assertEquals(2, extractedIds.size());
        System.assert(extractedIds.contains(ACCOUNT_ID));
    }

    @IsTest
    public static void testClone1() {
        QueryBuilder qb1 = new QueryBuilder('Account');
        System.assertEquals('SELECT Id FROM Account', qb1.toString());

        QueryBuilder qb2 = qb1.cloneQueryBuilder();
        qb2.addField('Name');

        qb1.resetResult();
        System.assertEquals('SELECT Id FROM Account', qb1.toString());
        System.assertEquals('SELECT Id, Name FROM Account', qb2.toString());
    }

    @IsTest
    public static void testClone2() {
        QueryBuilder qb1 = new QueryBuilder('Account');
        qb1.toList();

        QueryBuilder qb2 = qb1.cloneQueryBuilder(true);
        //createAccount(2);

        System.assertEquals(qb1.toList(), qb2.toList());
    }

    @IsTest
    public static void testStub1() {
        final String EXPECTED_SOQL = 'SELECT Name FROM Account';

        QueryBuilder stubbedQueryBuilder = new QueryBuilder(Account.class)
                .buildStub()
                .addStubToString(EXPECTED_SOQL)
                .applyStub();

        System.assertEquals(EXPECTED_SOQL, stubbedQueryBuilder.toString());
    }

    @IsTest
    public static void testStub2() {
        QueryBuilder stubbedQueryBuilder = new QueryBuilder(Account.class)
                .buildStub()
                .addStubToList(new List<Account>{
                        new Account(Name = 'Stubbed-Account')
                })
                .applyStub();

        List<Account> accounts = (List<Account>) stubbedQueryBuilder.toList();
        System.assertEquals(1, accounts.size());
        System.assertEquals('Stubbed-Account', accounts[0].Name);
    }

    @IsTest
    public static void test_setCheckCRUDAndFLS() {
        String queryString = new QueryBuilder(Account.class)
                .addConditions()
                .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
                .endConditions()
                .toStringCount();
                
        new QueryBuilder(Account.class);
        new QueryBuilder('Account');
        new QueryBuilder(Account.getSobjectType());
        new QueryBuilder(new Account());
        
        new QueryBuilder().addFrom(Account.class);
        new QueryBuilder().addFrom('Account');
        new QueryBuilder().addFrom(Account.getSobjectType());
        new QueryBuilder().addFrom(new Account());

        new QueryBuilder(Account.class).addField(Account.Name);
        new QueryBuilder(Account.class).addField('Name');
        new QueryBuilder(Account.class).addField('Name, Id');
        new QueryBuilder(Account.class).addFields('Name, Id');
        new QueryBuilder(Account.class).addFields(new List<String>{'Name'});
        new QueryBuilder(Account.class).addFields(new Set<String>{'Name'});

        new QueryBuilder(Account.class).addFieldsAll();
        new QueryBuilder(Account.class).addFieldsAllCreatable();
        new QueryBuilder(Account.class).addFieldsAllUpdatable();

        // new QueryBuilder(Account.class).addFieldSet('Field_Set_Name');
    
        // FieldSet retrievedFieldSet = ...//get fieldSet
        // new QueryBuilder(Account.class).addFieldSet(retrievedFieldSet);

        QueryBuilder qBuilder = new QueryBuilder(Account.class)
            .addSubQuery(
                new QueryBuilder('ChildAccounts').addField(Account.Name)
            )
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
            .endConditions()
            .addFieldsAllAcessibleFields()
            .setLimit(1)
            .setOffset(0)
            .addOrderAsc('Id')
            .addOrderDesc(Account.Name);

        new QueryBuilder(Account.class)
            .addSubQuery(
                new QueryBuilder('ChildAccounts').addField(Account.Name)
            )
            .addFieldsAllUpdatable(new Account())
            .addFieldsAll(Account.class)
            .addFieldSet('test')
            .newQuery();

            
        new QueryBuilder(Account.class).addFieldsAll((Type) Account.class);
        new QueryBuilder(Account.class).addFieldsAllUpdatable((Type) Account.class);
        new QueryBuilder(Account.class).addFieldsAllUpdatable(Account.class);
        new QueryBuilder(Account.class).addFieldsAllCreatable(new Account());
        new QueryBuilder(Account.class).addFieldsAllCreatable(Account.class);
            
        new QueryBuilder(Account.class) 
            .setUpdateViewstat()
            .setUpdateTracking()
            .setForReference()
            .setForView();
            
        List<Account> accounts = (List<Account>) qBuilder
            .setCheckFLS()
            .setCheckCRUD()
            .setCheckCRUDAndFLS()
            .setWithSecurityEnforced()
            .toList();

        System.assertEquals(1, accounts.size());
        System.assertEquals(1, accounts[0].ChildAccounts.size());
        System.assertEquals('Account-2', accounts[0].ChildAccounts[0].Name);
        qBuilder.toStringCount();
        qBuilder.toCount();
        qBuilder.toList();
        qBuilder.toMap();
        qBuilder.toSObject();
        qBuilder.toIdSet();
        qBuilder.extractIds('Id');
        qBuilder.extractField('Name');
        qBuilder.extractField(Account.Name);

    }

    //Utility methods
    private static Account createAccount(Integer i) {
        Account result = new Account();
        result.Name = 'Account-' + i;
        result.NumberOfEmployees = 0;
        // insert result;
        return result;
    }

    @IsTest
    public static void testsetStandardFieldTokens() {
        
        QueryBuilder queryB = new QueryBuilder()
                .setStandardFieldTokens(new Set<String>{
                        'Name'
                });
       
    }

    @IsTest
    public static void testgetById() {
        QueryBuilder accountQueryBuilder = new QueryBuilder('Account');
        List<Account> accounts = (List<Account>) accountQueryBuilder
                .toList();
        QueryBuilder queryB = new QueryBuilder()
                .getById(
                    accounts[0].Id
                );
       
    }
    @IsTest
    public static void testgetByName() {
        QueryBuilder accountQueryBuilder = new QueryBuilder().getByName('Account-1');
        accountQueryBuilder = new QueryBuilder()
        .getByName(new Set<String>{
                'Account-1'
        });

        accountQueryBuilder = new QueryBuilder()
        .addFieldsAll(Account.getSObjectType());

        accountQueryBuilder = new QueryBuilder()
        .addFieldsAll(new Account());
       
    }

    @IsTest
    public static void testaddFieldSet() {

        Schema.DescribeFieldResult describeField = Account.Industry.getDescribe();
        Schema.sObjectField field = describeField.getSObjectField();    

    QueryBuilder accountQueryBuilder = new QueryBuilder('Account');
    List<Account> accounts = (List<Account>) accountQueryBuilder
            .addField(Account.Name)
            .toList();

    QueryBuilder queryBuilder =  new QueryBuilder()
         .addConditionsWithOrder('1 and (2 or 3) and 4')
          .endConditions();


          queryBuilder = new QueryBuilder(Account.class)
          .addOrder(
               new QueryBuilder.Order(Account.Id)
                   .setSortingOrderAsc()
                   .setNullsOrderLast()
           );

           queryBuilder = new QueryBuilder(Account.class)
          .addOrderAsc(accounts[0].Name);

           queryBuilder = new QueryBuilder(Account.class)
                .addGroupBy('Name')
                .addGroupBy('Id, ParentId');

           queryBuilder = new QueryBuilder(Account.class)
                .addGroupBy(accounts[0].Name);

           queryBuilder = new QueryBuilder(Account.class)
                .addGroupBy(new List<String> {'Name'});

        //    queryBuilder =  new QueryBuilder(Account.class)
        //         .setScope(queryBuilder.FilterScope.Mine);

           queryBuilder =  new QueryBuilder(Account.class)
                .setForView(true);
      

           queryBuilder =  new QueryBuilder(Account.class)
                .setForReference(true);
            // Database.QueryLocator  dt = new QueryBuilder()
            // .toQueryLocator();

            // List<Object> sobjList = new QueryBuilder()
            // .extractField(field);
      
    }

    private static Contact createContact(Id accId) {
        Contact result = new Contact();
        result.FirstName = 'Contact';
        result.LastName = 'Contact-' + accId;
        result.AccountId = accId;
        result.Email = 'email' + accId + '@example.com';
        result.Description = accId;
        result.Phone = '1936106059';
        result.MobilePhone = '19992868239';
        insert result;
        return result;
    }
}