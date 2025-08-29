@isTest
public with sharing class FundamentalQuoteTemplateHeaderTest {

    public static final String quoteFundamentalRecTypeId = Schema.getGlobalDescribe().get('SBQQ__Quote__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Fundamental_Quotes').getRecordTypeId();

    @TestSetup
    static void makeData(){
        List<Pre_Defined_Quote_Notes__c> predefinedNotes = new List<Pre_Defined_Quote_Notes__c>();
        Pre_Defined_Quote_Notes__c techNotes = new Pre_Defined_Quote_Notes__c(
            Category__c = 'TECH SUPPORT',
            NoteDetails__c = 'Technical Notes'
        );
        predefinedNotes.add(techNotes);
        Pre_defined_Quote_Notes__c equipmentNotes = new Pre_Defined_Quote_Notes__c(
            Category__c = 'EQUIPMENT QUOTED STATEMENT',
            NoteDetails__c = 'Equipment Notes'
        );
        predefinedNotes.add(equipmentNotes);
        insert predefinedNotes;
        Account account = TestDataFactory.createFundamentalTestAccount();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            RecordTypeId = quoteFundamentalRecTypeId,
            SBQQ__Account__c = account.Id,
            SBQQ__Notes__c = 'Initial notes for the quote \r\nwith multiple lines'
        );
        insert quote;

    }

    @isTest
    static void testConstructor() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();
        System.runAs(adminUser) {
            SBQQ__QuoteTemplate__c template = TestDataFactory.createFundamentalQuoteTemplate();
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

            Test.setCurrentPageReference(new PageReference('/apex/FundamentalQuoteTemplateHeader'));
            ApexPages.currentPage().getParameters().put('qid', quote.Id);
            ApexPages.currentPage().getParameters().put('tid', template.Id);
            
            FundamentalQuoteTemplateHeader controller = new FundamentalQuoteTemplateHeader(new ApexPages.StandardController(quote));

            System.assertNotEquals(null, controller.quoteId, 'Quote ID should not be null');
            System.assertNotEquals(null, controller.quote, 'Quote should not be null');
            System.assertNotEquals(null, controller.orderedNoteDescriptions, 'Ordered note descriptions should not be null');
            System.assertEquals(2, controller.orderedNoteDescriptions.size(), 'There should be two ordered note descriptions');
        }
    }
}