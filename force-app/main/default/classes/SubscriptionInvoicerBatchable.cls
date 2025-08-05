/**
 * Batch class to process subscriptions and set Send_Invoice__c flag
 * based on Return Date and Last Invoice Date logic
 */
public class SubscriptionInvoicerBatchable implements Database.Batchable<sObject>, Database.Stateful {
    
    private List<String> errors = new List<String>();
    private Integer successCount = 0;
    private Integer errorCount = 0;
    
    /**
     * Start method - Query subscriptions where Quickbooks_Invoice_ID__c is null or empty
     * @param bc BatchableContext
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        SubscriptionSelector selector = new SubscriptionSelector();
        return selector.getSubscriptionsForInvoicing();
    }
    
    /**
     * Execute method - Process each batch of subscriptions
     * @param bc BatchableContext
     * @param scope List of subscriptions to process
     */
    public void execute(Database.BatchableContext bc, List<SBQQ__Subscription__c> scope) {
        List<SBQQ__Subscription__c> subscriptionsToUpdate = new List<SBQQ__Subscription__c>();
        Date today = Date.today();
        
        for (SBQQ__Subscription__c subscription : scope) {
            try {
                Boolean shouldUpdateInvoice = false;
                
                if (subscription.Return_Date__c == today) {
                    shouldUpdateInvoice = true;
                }
                else if (subscription.Last_Invoice_Date__c != null) {
                    Date lastInvoicePlus28 = subscription.Last_Invoice_Date__c.addDays(28);
                    if (lastInvoicePlus28 == today) {
                        shouldUpdateInvoice = true;
                    }
                }
                else if (subscription.Last_Invoice_Date__c == null && subscription.SBQQ__SubscriptionStartDate__c != null) {
                    Date createdDatePlus28 = subscription.SBQQ__SubscriptionStartDate__c.addDays(28);
                    if (createdDatePlus28 == today) {
                        shouldUpdateInvoice = true;
                    }
                }
                
                if (shouldUpdateInvoice && !subscription.Send_Invoice__c) {
                    subscription.Send_Invoice__c = true;
                    subscriptionsToUpdate.add(subscription);
                } 
                
            } catch (Exception e) {
                errorCount++;
                errors.add('Error processing Subscription Id: ' + subscription.Id + 
                          ' - Error: ' + e.getMessage() + ' - StackTrace: ' + e.getStackTraceString());
            }
        }
        
        if (!subscriptionsToUpdate.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(subscriptionsToUpdate, false);
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    Database.Error[] dbErrors = saveResults[i].getErrors();
                    String errorMsg = 'Failed to update Subscription Id: ' + subscriptionsToUpdate[i].Id + ' - Errors: ';
                    for (Database.Error err : dbErrors) {
                        errorMsg += err.getMessage() + '; ';
                    }
                    errors.add(errorMsg);
                }
            }
        }
    }
    
    /**
     * Finish method - Log results
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        String logMessage = 'SubscriptionInvoicerBatchable completed.\n' +
                           'Success Count: ' + successCount + '\n' +
                           'Error Count: ' + errorCount;
        
        if (!errors.isEmpty()) {
            logMessage += '\n\nErrors:\n';
            for (String error : errors) {
                logMessage += error + '\n';
            }
        }
        
        System.debug(logMessage);
    }
}