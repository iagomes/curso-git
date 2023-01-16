public without sharing class OrderHandler extends TriggerHandler{

    public OrderHandler(System.TriggerOperation operation, List<Order> newRecordList, List<Order> oldRecordList, Map<Id, Order> newMap, Map<Id, Order> oldMap) {
        super(operation, newRecordList, oldRecordList, newMap, oldMap);
    }

    // @TRIGGER METHODS
    private static Boolean runTrigger;

    static {
        runTrigger = true;
    }

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static Boolean enableTrigger(){
        return runTrigger = true;
    }

    public static Boolean disableTrigger(){
        return runTrigger = false;
    }
    // @END TRIGGER METHODS

    // @TRIGGER HANDLERS

    /*
    * Purpose: BEFORE_INSERT handler method
    */
    public override void beforeInsert() {
        
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
        OrderHelper.fillOrderCode((Order[]) this.newRecordList);
        OrderHelper.dispatchOrderCountEvent((Map<Id, Order>) this.newMap);//Portal-979
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        // OrderHelper.checkError( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.fillProtheusCode( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.updateOrderSon((Order[]) this.newRecordList, (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.updateOrderStatusIntegration((Map<Id, Order>) this.oldMap, (Order[]) this.newRecordList);
        OrderHelper.createManualLaboratoryOrder( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap, (Order[])this.newRecordList);
        // OrderHelper.automaticOrderApproval( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.recallApprovalProcess( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.splitOrder( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap, this.newRecordList);
        //OrderHelper.checkStatusUpdate( (List<Order>) this.newRecordList, (List<Order>) this.oldRecordList );
        OrderHelper.cancelRelatedNF((Order[]) this.newRecordList);
        // troca do status do pedido pai ai atualiza o pedido pai e muda o status do pedido pai
        //OrderHelper.atualizaStatusPedidoPai( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        // criar metodo para criar pdf
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
        OrderHelper.updateParentLabOrder( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.validaAprovacao( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap, this.newRecordList);
        OrderHelper.automaticOrderApproval( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.sendOrderToERP( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.sendApprovalOrderToERP( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.sendApprovalOrderIntegradoraToERP( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.returningApprovalToERP( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        // OrderHelper.checkLabApproval( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.sendPedidoIntegradora( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.checkVansOrder( (Map<Id, Order>) this.newMap);
        OrderHelper.deletSplitOrder( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.removeSendApproval( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.checkStatusOrder( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.updateCancelledLaboratoryOrder( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.updateLaboratoryChildOrders( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.checkBilledStatus( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.sendCancelledOrderEmail( (Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);
        OrderHelper.dispatchOrderCountEvent((Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);//Portal-979
        OrderHelper.updateLabOrderStatusWhenParentOrderWasApproved((Map<Id, Order>) this.oldMap, (Map<Id, Order>) this.newMap);//Portal-979
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
        system.debug(this.oldRecordList);
        
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS
}
