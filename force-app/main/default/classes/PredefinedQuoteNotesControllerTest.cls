@isTest
public with sharing class PredefinedQuoteNotesControllerTest {

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
            RecordTypeId = TestDataFactory.quoteFundamentalRecTypeId,
            SBQQ__Account__c = account.Id
        );
        insert quote;

    }

    @isTest
    static void getQuoteNotesTest() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();

        System.runAs(adminUser) {
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            List<Object> notes = PredefinedQuoteNotesController.getQuoteNotes(quote.Id);
            System.assertNotEquals(null, notes, 'Notes should not be null');
            System.assertEquals(2, notes.size(), 'There should be two notes');
        }
    }

    @isTest
    static void getAllCategoriesTest() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();

        System.runAs(adminUser) {
            List<String> categories = PredefinedQuoteNotesController.getAllCategories();
            System.assertNotEquals(null, categories, 'Categories should not be null');
            System.assertEquals(2, categories.size(), 'There should be two categories');
        }
    }

    @isTest
    static void getNotesByCategoryTest() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();

        System.runAs(adminUser) {
            List<Pre_Defined_Quote_Notes__c> notes = PredefinedQuoteNotesController.getNotesByCategory('TECH SUPPORT');
            System.assertNotEquals(null, notes, 'Notes should not be null');
            System.assertEquals(1, notes.size(), 'There should be one note in this category');
        }
    }

    @isTest
    static void saveNoteSelectionsTest() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();

        System.runAs(adminUser) {
            SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            List<Id> selectedNoteIds = new List<Id>();
            List<Pre_Defined_Quote_Notes__c> notes = [SELECT Id FROM Pre_Defined_Quote_Notes__c LIMIT 1];
            selectedNoteIds.add(notes[0].Id);

            Test.startTest();
            PredefinedQuoteNotesController.saveNoteSelections(selectedNoteIds, quote.Id);
            Test.stopTest();

            List<Predefined_Qts__c> savedNotes = [SELECT Id FROM Predefined_Qts__c WHERE Quote__c = :quote.Id];
            System.assertEquals(1, savedNotes.size(), 'One note should be saved');
        }
    }
    
}