trigger QuoteItem on QuoteItem__c (before update, before insert, after insert, after update, after delete) {
    new QuoteItemTH().run();
}