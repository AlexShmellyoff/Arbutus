@isTest
public with sharing class QuoteTriggerTest {

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
    }
    @isTest
    static void onAfterInsertTest() {
        User adminUser = TestDataFactory.createTestSystemAdminUser();
        Account account = TestDataFactory.createFundamentalTestAccount();
        System.runAs(adminUser) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                RecordTypeId = quoteFundamentalRecTypeId,
                SBQQ__Account__c = account.Id
            );
            insert quote;

            List<Predefined_Qts__c> notes = [SELECT Id, Pre_Defined_Quote_Note__c FROM Predefined_Qts__c WHERE Quote__c = :quote.Id];
            System.assertEquals(2, notes.size(), 'Two predefined notes should be created.');
        }
        

    }

}