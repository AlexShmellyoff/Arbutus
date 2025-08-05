trigger QuoteTrigger on SBQQ__Quote__c (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            QuoteTriggerHandler.onAfterInsert(Trigger.newMap);
                }
        }
    }