@isTest
public with sharing class TestDataFactory {
    public static final String quoteFundamentalRecTypeId = Schema.getGlobalDescribe().get('SBQQ__Quote__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Fundamental_Quotes').getRecordTypeId();
    public static final String quoteArbutusRecTypeId = Schema.getGlobalDescribe().get('SBQQ__Quote__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Arbutus_Quotes').getRecordTypeId();
    
    public static User createTestSystemAdminUser() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User adminUser = new User(
            ProfileId = adminProfile.Id,
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'admin@arbutus.com',
            Alias = 'adTaw',
            Username = 'admin@arbutus.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Business_Unit__c = 'Arbutus West'
        );
        insert adminUser;

        return adminUser;
    }

    public static Account createFundamentalTestAccount() {
        Account account = new Account(
            Name = 'Test Account',
            Will_Call__c = false,
            Fundamental_Account__c = true,
            Tax_Code_1__c = 'GST',
            Tax_Code_2__c = 'PST',
            BillingState = 'Ontario',
            BillingCountry = 'Canada',
            ShippingState = 'Ontario',
            ShippingCountry = 'Canada'
        );
        insert account;

        return account;
    }

    public static SBQQ__QuoteTemplate__c createFundamentalQuoteTemplate() {
        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c(
            Name = 'Test Quote Template BOL'
        );
        insert template;

        return template;
    }

    public static SBQQ__QuoteTemplate__c createArbutusServiceLineTemplate() {
        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c(
            Name = 'Arbutus Service Line Template'
        );
        insert template;

        return template;
    }

}