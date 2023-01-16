trigger OpportunityLineItem on OpportunityLineItem (before update, before insert) {
    new OpportunityLineItemTH().run();
}