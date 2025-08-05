@isTest
public class ArbutusServiceLineTemplateTest {
    @isTest
    public static void testArbutusServiceLineTemplate() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();
        System.runAs(adminUser) {
            // Setup: Template and Account
            SBQQ__QuoteTemplate__c template = TestDataFactory.createArbutusServiceLineTemplate();
            Account acc = TestDataFactory.createFundamentalTestAccount();

            // Quote
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                RecordTypeId = TestDataFactory.quoteArbutusRecTypeId
            );
            insert quote;

            // Group (renamed from "group" to "quoteGroup")
            SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Description__c = '<div>Parent Product Description</div><div>Extra Info</div>',
                SBQQ__StartDate__c = Date.newInstance(2026, 1, 1),
                SBQQ__EndDate__c = Date.newInstance(2028, 12, 31),
                SBQQ__SubscriptionTerm__c = 36
            );
            insert quoteGroup;

            // Products
            Product2 parentProduct = new Product2(Name = 'Parent Product', IsActive = true, Family = 'Service');
            Product2 subProduct = new Product2(Name = 'Sub Product', IsActive = true, Family = 'Service');
            insert new List<Product2>{ parentProduct, subProduct };

            // Standard Pricebook Entries
            Id stdPbId = Test.getStandardPricebookId();
            insert new List<PricebookEntry>{
                new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = parentProduct.Id, UnitPrice = 500, IsActive = true),
                new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = subProduct.Id, UnitPrice = 250, IsActive = true)
            };

            // Quote Lines (note: NetTotal and ProductName are calculated by CPQ)
            insert new List<SBQQ__QuoteLine__c>{
                new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Group__c = quoteGroup.Id,
                    SBQQ__Product__c = parentProduct.Id,
                    SBQQ__Quantity__c = 1,
                    SBQQ__ListPrice__c = 500,
                    Parent_product__c = true,
                    SBQQ__Optional__c = false
                ),
                new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Group__c = quoteGroup.Id,
                    SBQQ__Product__c = subProduct.Id,
                    SBQQ__Quantity__c = 2,
                    SBQQ__ListPrice__c = 250,
                    Parent_product__c = false,
                    SBQQ__Optional__c = true
                )
            };

            // Simulate page call
            Test.setCurrentPageReference(new PageReference('/apex/ArbutusRenderer'));
            ApexPages.currentPage().getParameters().put('qid', quote.Id);
            ApexPages.currentPage().getParameters().put('tid', template.Id);

            // Instantiate and assert
            ArbutusServiceLineTemplate controller = new ArbutusServiceLineTemplate(new ApexPages.StandardController(quote));
            System.assertNotEquals(null, controller.groupedLinesByYears);
            System.assert(controller.groupedLinesByYears.size() > 0, 'Expected groupedLinesByYears to be populated');
            System.assert(controller.overallTotal > 0, 'Expected overallTotal to be greater than 0');
        }
    }
}