public without sharing class PredefinedQuoteNotesController {

    // 1. Get currently linked notes for a quote
    @AuraEnabled(cacheable=true)
    public static List<Object> getQuoteNotes(Id quoteId) {
        List<Predefined_Qts__c> predefinedQts = [
            SELECT Id, Pre_Defined_Quote_Note__c,
                   Pre_Defined_Quote_Note__r.Name,
                   Pre_Defined_Quote_Note__r.NoteDetails__c,
                   Pre_Defined_Quote_Note__r.Category__c
            FROM Predefined_Qts__c
            WHERE Quote__c = :quoteId
        ];

        List<Object> result = new List<Object>();
        for (Predefined_Qts__c qt : predefinedQts) {
            if (qt.Pre_Defined_Quote_Note__c != null) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('Id', qt.Pre_Defined_Quote_Note__c);
                row.put('Name', qt.Pre_Defined_Quote_Note__r.Name);
                row.put('NoteDetails__c', qt.Pre_Defined_Quote_Note__r.NoteDetails__c);
                row.put('Category__c', qt.Pre_Defined_Quote_Note__r.Category__c);
                result.add(row);
            }
        }
        return result;
    }

    // 2. Get all distinct categories
    @AuraEnabled(cacheable=true)
    public static List<String> getAllCategories() {
        Set<String> categories = new Set<String>();
    
        for (Pre_Defined_Quote_Notes__c note : [
            SELECT Category__c FROM Pre_Defined_Quote_Notes__c WHERE Category__c != null
        ]) {
            categories.add(note.Category__c);
        }
    
        return new List<String>(categories);
    }

    // 3. Get notes by category
    @AuraEnabled(cacheable=true)
    public static List<Pre_Defined_Quote_Notes__c> getNotesByCategory(String category) {
        return [
            SELECT Id, Name, NoteDetails__c, Category__c
            FROM Pre_Defined_Quote_Notes__c
            WHERE Category__c = :category
        ];
    }

    // 4. Save current selection
    @AuraEnabled
    public static void saveNoteSelections(List<Id> selectedNoteIds, Id quoteId) {
        delete [SELECT Id FROM Predefined_Qts__c WHERE Quote__c = :quoteId];
        
        if(selectedNoteIds == null || selectedNoteIds.isEmpty()) { return; }

        List<Predefined_Qts__c> inserts = new List<Predefined_Qts__c>();
        for (Id noteId : selectedNoteIds) {
            inserts.add(new Predefined_Qts__c(
                Quote__c = quoteId,
                Pre_Defined_Quote_Note__c = noteId
            ));
        }

        if (!inserts.isEmpty()) {
            insert inserts;
        }
    }
}