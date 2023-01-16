public without sharing class ContactHelper {
    public ContactHelper() {}

    public static String formatMobilePhone(String str) {
        return String.format('({0}) {1}-{2}', new List<String>{
            str.substring(0, 2),
            str.substring(2, 7),
            str.substring(7, 11)
        });
    }

    public static String formatPhone(String str) {
        if (str.length() == 10) {
            return String.format('({0}) {1}-{2}', new List<String>{
                str.substring(0, 2),
                str.substring(2, 6),
                str.substring(6, 10)
            });
        }
        else {
            return String.format('({0}) {1}-{2}', new List<String>{
                str.substring(0, 2),
                str.substring(2, 7),
                str.substring(7, 11)
            });
        }
    }
    
    public static void formatNumber(List<Contact> newList) {
        for (Contact contact : newList) {
            String str;
            if (contact.MobilePhone != null && contact.MobilePhone != '') {
                str = contact.MobilePhone.replaceAll('\\D', '');
                
                if (contact.MobilePhone.length() != 11) {
                    contact.MobilePhone.addError('Formato do celular inválido.\nEx: 99123456789.');
                }
                else {
                    if (str.length() != 11) {
                        contact.MobilePhone.addError('Formato do celular inválido.\nEx: 99123456789.');
                    }
                    else {
                        contact.MobilePhone = formatMobilePhone(str);
                    }
                }
            }
            if (contact.Phone != null && contact.Phone != '') {
                str = contact.Phone.replaceAll('\\D', '');

                if ( (contact.Phone.length() == 10 || contact.Phone.length() == 11) && (contact.Phone.length() == str.length()) ) {
                    if (str.length() == 10 || str.length() == 11) {
                        contact.Phone = formatPhone(str);
                    }
                    else {
                        contact.Phone.addError('Formato do telefone inválido, digite apenas números.');
                    }
                }
                else {
                    if (contact.Phone.length() == str.length()) {
                        contact.Phone.addError('Telefone deve conter 10 ou 11 digitos com DDD incluso.');
                    }
                    else {
                        contact.Phone.addError('Formato do telefone inválido, digite apenas números.');
                    }
                }
            }
        }
    }

    public static void updateNumber(List<Contact> newList) {
        for (Contact contact : newList) {
            String str;
            if (contact.MobilePhone != null && contact.MobilePhone != '') {
                str = contact.MobilePhone.replaceAll('\\D', '');
                
                if (str.length() != 11) {
                    contact.MobilePhone.addError('Formato do celular inválido.\nEx: 99123456789.');
                }
                else {
                    contact.MobilePhone = formatMobilePhone(str);
                }
            }
            if (contact.Phone != null && contact.Phone != '') {
                str = contact.Phone.replaceAll('\\D', '');
                
                if (str.length() == 10 || str.length() == 11) {
                    contact.Phone = formatPhone(str);
                }
                else {
                    contact.Phone.addError('Formato do telefone inválido.');
                }
            }
        }
    }

    public static void changePriorityContactInsert(List<Contact> newList) {
        List<Contact> contactUpdate = new List<Contact>();
        Set<Id> contactIdSet        = new Set<Id>();
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact newContact : newList) {
            if (newContact.Padrao__c == true) {
                contactIdSet.add(newContact.AccountId);
                accountIdToContact.put(newContact.AccountId, newContact);
            }
        }

        List<Contact> contactList = [SELECT Id, AccountId, Padrao__c, Email, Phone
                                     FROM Contact 
                                     WHERE AccountId IN: contactIdSet AND Padrao__c = true];
        System.debug('contactList: ' + contactList);

        for (Contact oldContact : contactList) {
            if ((oldContact.Email == null || oldContact.Email == '') || (oldContact.Phone == null || oldContact.Phone == '')) {
                accountIdToContact.get(oldContact.AccountId).addError('E-mail ou telefone do contato padrão antigo errados.\nPor favor arrume antes de prosseguir.');
            }
            else {
                oldContact.Padrao__c = false;
                contactUpdate.add(oldContact);
            }
        }

        if (!contactUpdate.isEmpty()){
            System.debug('Update contacts: ' + contactUpdate);
            ContactHandler.disableTrigger();
            update contactUpdate;
            ContactHandler.enableTrigger();
        }
    }

    public static void changePriorityContactUpdate(List<Contact> newList, Map<Id, Contact> newMap) {
        List<Contact> contactUpdate = new List<Contact>();
        Set<Id> contactIdSet        = new Set<Id>();
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact newContact : newList) {
            if (newContact.Padrao__c == true) {
                contactIdSet.add(newContact.AccountId);
                accountIdToContact.put(newContact.AccountId, newContact);
            }
        }

        List<Contact> contactList = [SELECT Id, AccountId, Padrao__c, Email, MobilePhone
                                     FROM Contact 
                                     WHERE AccountId IN: contactIdSet AND Padrao__c = true];
        System.debug('contactList: ' + contactList);

        for (Contact oldContact : contactList) {
            if (!newMap.containsKey(oldContact.Id)) {
                if ((oldContact.Email == null || oldContact.Email == '') || (oldContact.MobilePhone == null || oldContact.MobilePhone == '')) {
                    accountIdToContact.get(oldContact.AccountId).addError('Email ou celular do contato padrão antigo errados.\nPor favor arrume antes de prosseguir.');
                }
                else {
                    oldContact.Padrao__c = false;
                    contactUpdate.add(oldContact);
                }
            }
        }

        if (!contactUpdate.isEmpty()){
            System.debug('Update: ' + contactUpdate);
            ContactHandler.disableTrigger();
            update contactUpdate;
            ContactHandler.enableTrigger();
        }
    }
}
