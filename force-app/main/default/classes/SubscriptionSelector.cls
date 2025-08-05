/**
 * Selector class for SBQQ__Subscription__c object
 * Centralizes all subscription queries
 */
public with sharing class SubscriptionSelector {
    
    /**
     * Get subscriptions that need invoice processing
     * @return Database.QueryLocator for batch processing
     */
    public Database.QueryLocator getSubscriptionsForInvoicing() {
        String query = buildInvoicingQuery();
        return Database.getQueryLocator(query);
    }
    
    /**
     * Get subscriptions that need invoice processing - List version
     * @param recordLimit Maximum number of records to return
     * @return List of subscriptions
     */
    public List<SBQQ__Subscription__c> getSubscriptionsForInvoicingList(Integer recordLimit) {
        String query = buildInvoicingQuery();
        query += ' LIMIT :recordLimit';
        return Database.query(query);
    }
    
    /**
     * Build the query string for invoice processing
     * @return Query string
     */
    private String buildInvoicingQuery() {
        return 'SELECT Id, Quickbooks_Invoice_ID__c, Send_Invoice__c, ' +
               'Last_Invoice_Date__c,SBQQ__SubscriptionStartDate__c, SBQQ__StartDate__c, Return_Date__c ' +
               'FROM SBQQ__Subscription__c ' +
               'WHERE (Quickbooks_Invoice_ID__c = null OR Quickbooks_Invoice_ID__c = \'\') ';
    }
    
    /**
     * Get subscription by Id with invoice fields
     * @param subscriptionId The subscription Id
     * @return Subscription record or null
     */
    public SBQQ__Subscription__c getSubscriptionById(Id subscriptionId) {
        List<SBQQ__Subscription__c> subscriptions = [
            SELECT Id, Quickbooks_Invoice_ID__c, Send_Invoice__c,
                   Last_Invoice_Date__c, SBQQ__StartDate__c, Return_Date__c
            FROM SBQQ__Subscription__c
            WHERE Id = :subscriptionId
            LIMIT 1
        ];
        
        return subscriptions.isEmpty() ? null : subscriptions[0];
    }
    
    /**
     * Get subscriptions by Ids with invoice fields
     * @param subscriptionIds Set of subscription Ids
     * @return List of subscription records
     */
    public List<SBQQ__Subscription__c> getSubscriptionsByIds(Set<Id> subscriptionIds) {
        return [
            SELECT Id, Quickbooks_Invoice_ID__c, Send_Invoice__c,
                   Last_Invoice_Date__c, SBQQ__StartDate__c, Return_Date__c
            FROM SBQQ__Subscription__c
            WHERE Id IN :subscriptionIds
        ];
    }
    
    /**
     * Get subscriptions pending invoice generation
     * @param recordLimit Maximum number of records to return
     * @return List of subscriptions with Send_Invoice__c = true
     */
    public List<SBQQ__Subscription__c> getPendingInvoiceSubscriptions(Integer recordLimit) {
        return [
            SELECT Id, Quickbooks_Invoice_ID__c, Send_Invoice__c,
                   Last_Invoice_Date__c, SBQQ__StartDate__c, Return_Date__c
            FROM SBQQ__Subscription__c
            WHERE Send_Invoice__c = true
            AND (Quickbooks_Invoice_ID__c = null OR Quickbooks_Invoice_ID__c = '')
            LIMIT :recordLimit
        ];
    }
}