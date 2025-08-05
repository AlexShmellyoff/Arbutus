/**
 * Schedulable class to run SubscriptionInvoicerBatchable daily
 * Schedule using: System.schedule('Subscription Invoicer Daily', '0 0 0 * * ?', new SubscriptionInvoicerSchedulable());
 */
public class SubscriptionInvoicerSchedulable implements Schedulable {
    
    /**
     * Execute method called by the scheduler
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        // Create and execute the batch job
        SubscriptionInvoicerBatchable batch = new SubscriptionInvoicerBatchable();
        
        // Execute with default batch size of 200
        // Adjust batch size if needed based on your org's limits
        Database.executeBatch(batch, 200);
    }
}