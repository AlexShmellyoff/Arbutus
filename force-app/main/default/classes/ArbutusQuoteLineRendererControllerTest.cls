@isTest
private class ArbutusQuoteLineRendererControllerTest {
    @isTest
    static void testControllerWithQuoteLines() {
        // Create test user
        User adminUser = TestDataFactory.createTestSystemAdminUser();
        System.runAs(adminUser) {
            // Create test Account
            Account acc = TestDataFactory.createFundamentalTestAccount();
            
            // Create test Quote
            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Account__c = acc.Id);
            insert quote;
            
            // Create a Quote Line Group with description
            SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Description__c = '<b>Group 1</b>'
            );
            insert quoteGroup;
            // Create Product
            Product2 prod = new Product2(Name = 'Main Product', IsActive = true);
            insert prod;

            // Query Standard Price Book (usually exists, even if not active)
            Id stdPbId = Test.getStandardPricebookId();

            // Insert Standard PricebookEntry
            PricebookEntry standardEntry = new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            insert standardEntry;

            // Now insert custom Price Book
            Pricebook2 customPb = new Pricebook2(Name = 'Test Price Book', IsActive = true);
            insert customPb;

            // Insert custom PricebookEntry
            PricebookEntry customEntry = new PricebookEntry(
                Pricebook2Id = customPb.Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert customEntry;

            // Parent Quote Line (Product Line)
            SBQQ__QuoteLine__c parentLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = quoteGroup.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ListPrice__c = 100,
                SBQQ__CustomerPrice__c = 100,
                SBQQ__NetPrice__c = 100,
                Parent_product__c = true
            );
            insert parentLine;

            // Child Quote Line (Adder)
            SBQQ__QuoteLine__c childLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Group__c = quoteGroup.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__Quantity__c = 2,
                SBQQ__ListPrice__c = 25,
                SBQQ__CustomerPrice__c = 25,
                SBQQ__NetPrice__c = 25,
                SBQQ__Optional__c = true,
                Parent_product__c = false
            );
            insert childLine;

            // Set test page parameters
            Test.setCurrentPageReference(new PageReference('/apex/ArbutusRenderer'));
            ApexPages.currentPage().getParameters().put('qid', quote.Id);
            ApexPages.currentPage().getParameters().put('tid', 'fakeTemplateId');

            ArbutusQuoteLineRendererController controller = new ArbutusQuoteLineRendererController(new ApexPages.StandardController(quote));
        }

    }
}