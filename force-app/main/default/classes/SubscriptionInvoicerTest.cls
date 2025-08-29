/**
 * Test class for SubscriptionInvoicerSchedulable and SubscriptionInvoicerBatchable
 */
@isTest
private class SubscriptionInvoicerTest {
    
    @testSetup
    static void setup() {
        // Create a permission set with your custom permission
        PermissionSet testPS = new PermissionSet(
            Label = 'Test Bypass Flow',
            Name = 'Test_Bypass_Flow'
        );
        insert testPS;
        
        // Add the custom permission to the permission set
        SetupEntityAccess setupEntity = new SetupEntityAccess(
            ParentId = testPS.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Bypass_Subscription_Flow'].Id
        );
        insert setupEntity;
        
        // Assign permission set to current user
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = testPS.Id
        );
        insert psa;
    }


    static void createTestData() {
        List<SBQQ__Subscription__c> testSubscriptions = new List<SBQQ__Subscription__c>();
        
        testSubscriptions.add(new SBQQ__Subscription__c(
            SBQQ__SubscriptionStartDate__c = Date.today().addDays(-30),
            Return_Date__c = Date.today(),
            Send_Invoice__c = false,
            Quickbooks_Invoice_ID__c = null,
            SBQQ__Quantity__c = 1
        ));
        
        testSubscriptions.add(new SBQQ__Subscription__c(
            SBQQ__SubscriptionStartDate__c = Date.today().addDays(-60),
            Return_Date__c = Date.today().addDays(30),
            Last_Invoice_Date__c = Date.today().addDays(-28),
            Send_Invoice__c = false,
            Quickbooks_Invoice_ID__c = null,
            SBQQ__Quantity__c = 1
        ));
        
        testSubscriptions.add(new SBQQ__Subscription__c(
            SBQQ__SubscriptionStartDate__c = Date.today().addDays(-10),
            Return_Date__c = Date.today().addDays(10),
            Last_Invoice_Date__c = Date.today().addDays(-10),
            Send_Invoice__c = false,
            Quickbooks_Invoice_ID__c = null,
            SBQQ__Quantity__c = 1
        ));
        
        testSubscriptions.add(new SBQQ__Subscription__c(
            SBQQ__SubscriptionStartDate__c = Date.today().addDays(-30),
            Return_Date__c = Date.today(),
            Send_Invoice__c = false,
            Quickbooks_Invoice_ID__c = 'QB-12345',
            SBQQ__Quantity__c = 1
        ));
        
        testSubscriptions.add(new SBQQ__Subscription__c(
            SBQQ__SubscriptionStartDate__c = Date.today().addDays(-60),
            Return_Date__c = Date.today(),
            Last_Invoice_Date__c = Date.today().addDays(-28),
            Send_Invoice__c = false,
            Quickbooks_Invoice_ID__c = '',
            SBQQ__Quantity__c = 1
        ));
        
        insert testSubscriptions;
    }
    
    @isTest
    static void testBatchExecution() {
        createTestData();
        Test.startTest();
        
        SubscriptionInvoicerBatchable batch = new SubscriptionInvoicerBatchable();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        List<SBQQ__Subscription__c> updatedSubs = [
            SELECT Id, Send_Invoice__c, Return_Date__c, Last_Invoice_Date__c, Quickbooks_Invoice_ID__c
            FROM SBQQ__Subscription__c
            ORDER BY CreatedDate
        ];
        
        System.assertEquals(true, updatedSubs[0].Send_Invoice__c, 
            'Subscription with Return Date = today should have Send_Invoice__c = true');
        
        System.assertEquals(true, updatedSubs[1].Send_Invoice__c, 
            'Subscription with Last Invoice + 28 days = today should have Send_Invoice__c = true');
        
        System.assertEquals(false, updatedSubs[2].Send_Invoice__c, 
            'Subscription not meeting conditions should have Send_Invoice__c = false');
        
        System.assertEquals(false, updatedSubs[3].Send_Invoice__c, 
            'Subscription with QB Invoice ID should not be processed');
        
        System.assertEquals(true, updatedSubs[4].Send_Invoice__c, 
            'Subscription with Return Date = today should have Send_Invoice__c = true');
    }
    
    @isTest
    static void testSchedulable() {
        Test.startTest();
        
        String jobId = System.schedule('Test Subscription Invoicer', 
            '0 0 0 15 3 ? 2099',
            new SubscriptionInvoicerSchedulable()
        );
        
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals('0 0 0 15 3 ? 2099', ct.CronExpression, 
            'Cron expression should match');
        System.assertEquals(0, ct.TimesTriggered, 
            'Job should not have been triggered yet');
        
        Test.stopTest();
    }
    
    @isTest
    static void testEmptyBatch() {
        delete [SELECT Id FROM SBQQ__Subscription__c];
        
        Test.startTest();
        
        SubscriptionInvoicerBatchable batch = new SubscriptionInvoicerBatchable();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        System.assert(true, 'Batch should handle empty result set');
    }
}