/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_SBQQ_QuoteLineTrigger on SBQQ__QuoteLine__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(SBQQ__QuoteLine__c.SObjectType);
}