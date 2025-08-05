public without sharing class QuoteTriggerHandler {
	private static final String fundamentalRecTypeId = Schema.getGlobalDescribe().get('SBQQ__Quote__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Fundamental_Quotes').getRecordTypeId();

    private static  List<Fundamenta_Predefined_Notes__mdt> predefinedNotesCategory = Fundamenta_Predefined_Notes__mdt.getAll().values();

    public static void onAfterInsert(Map<Id,SBQQ__Quote__c> newQuotes) {
        insertNotes(newQuotes);
        
    }
    private static void insertNotes(Map<Id,SBQQ__Quote__c> newQuotes){
        List<Predefined_Qts__c> predefinedNotesForInsert = new List<Predefined_Qts__c>();
        List<String> notesCategories = new List<String>();

        for(Fundamenta_Predefined_Notes__mdt mdtNote : predefinedNotesCategory) {
            notesCategories.add(mdtNote.Label);
        }

        Map<Id,Pre_Defined_Quote_Notes__c> predefinedNotes = new Map<Id, Pre_Defined_Quote_Notes__c>([SELECT Id, Category__c 
                                                        FROM Pre_Defined_Quote_Notes__c  
                                                        WHERE Category__c IN :notesCategories]);
    
        for(SBQQ__Quote__c quote : newQuotes.values()) {
            if(quote.RecordTypeId != fundamentalRecTypeId){ continue; }
            
            predefinedNotesForInsert.addAll(createNotes(quote.Id, predefinedNotes.keySet()));
            
        }

        if(!predefinedNotesForInsert.isEmpty()){
            try {
                insert predefinedNotesForInsert;
            } catch (DmlException e) {
                System.debug('Error inserting predefined notes: ' + e.getMessage());
            }
        }
    }

    public static List<Predefined_Qts__c> createNotes(Id quoteId, Set<Id> notesId){
        List<Predefined_Qts__c> predefinedNotes = new List<Predefined_Qts__c>();
        for(Id noteId : notesId){
            Predefined_Qts__c predefinedNote = new Predefined_Qts__c();
            predefinedNote.Quote__c = quoteId;
            predefinedNote.Pre_Defined_Quote_Note__c = noteId;
            predefinedNotes.add(predefinedNote);
        }
        return predefinedNotes;
    }

}