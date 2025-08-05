@isTest
public with sharing class FundamentalQuoteContractLineTemplateTest {
    
    @isTest
    static void testControllerWithQuoteLines() {
        // Create test user
        User adminUser = TestDataFactory.createTestSystemAdminUser();
        System.runAs(adminUser) {
            SBQQ__QuoteTemplate__c template = TestDataFactory.createFundamentalQuoteTemplate();
            // Create test Account
            Account acc = TestDataFactory.createFundamentalTestAccount();
            
            // Create test Quote
            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = acc.Id, RecordTypeId = TestDataFactory.quoteFundamentalRecTypeId);
            insert quote;
            
            // Create a Quote Line Group with description
            SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Description__c = '<b>Group 1</b>'
            );
            insert quoteGroup;
            // Create Products
            List<Product2> products = new List<Product2>();
            products.add(new Product2(Name = 'Rental Product', IsActive = true,Family = 'Rental'));
            products.add(new Product2(Name = 'Service Product', IsActive = true,Family = 'Service'));
            insert products;

            // Query Standard Price Book (usually exists, even if not active)
            Id stdPbId = Test.getStandardPricebookId();

            // Insert Standard PricebookEntrys
            List<PricebookEntry> standardEntries = new List<PricebookEntry>();
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = products[0].Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            ));
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = products[1].Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            ));
            insert standardEntries;

            // Now insert custom Price Book
            Pricebook2 customPb = new Pricebook2(Name = 'Test Price Book', IsActive = true);
            insert customPb;

            // Insert custom PricebookEntry
            List<PricebookEntry> customEntries = new List<PricebookEntry>();
            customEntries.add(new PricebookEntry(
                Pricebook2Id = customPb.Id,
                Product2Id = products[0].Id,
                UnitPrice = 100,
                IsActive = true
            ));
            customEntries.add(new PricebookEntry(
                Pricebook2Id = customPb.Id,
                Product2Id = products[1].Id,
                UnitPrice = 100,
                IsActive = true
            ));
            insert customEntries;

            // Create a Quote line
            List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

            quoteLines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = quoteGroup.Id,
                SBQQ__Product__c = products[0].Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ListPrice__c = 100,
                SBQQ__CustomerPrice__c = 100,
                SBQQ__NetPrice__c = 100,
                Parent_product__c = true,
                SBQQ__Description__c = '<div>Rental Product Description</div> <div>Additional Info</div>'
            ));
            quoteLines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = quoteGroup.Id,
                SBQQ__Product__c = products[1].Id,
                SBQQ__Quantity__c = 2,
                SBQQ__ListPrice__c = 25,
                SBQQ__CustomerPrice__c = 25,
                SBQQ__NetPrice__c = 25,
                SBQQ__Optional__c = true,
                Parent_product__c = false,
                SBQQ__Description__c = '<div>Rental Product Description</div> <div>Additional Info</div>'
            ));
            insert quoteLines;

            // Set test page parameters
            Test.setCurrentPageReference(new PageReference('/apex/FundamentalRenderer'));
            ApexPages.currentPage().getParameters().put('qid', quote.Id);
            ApexPages.currentPage().getParameters().put('tid', template.Id);

            FundamentalQuoteContractLineTemplate controller = new FundamentalQuoteContractLineTemplate(new ApexPages.StandardController(quote));
        }

    }
}