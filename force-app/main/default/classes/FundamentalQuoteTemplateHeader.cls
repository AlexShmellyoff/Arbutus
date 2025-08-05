public class FundamentalQuoteTemplateHeader {
    public String quoteId { get; set; }
    public String templateId { get; set; }
    public String notesHeader { get; set; }
    public String discountHeader { get; set; }
    public List<String> noteList { get; set; }
    public SBQQ__Quote__c quote { get; set; }
    public List<String> orderedNoteDescriptions { get; set; }

    public FundamentalQuoteTemplateHeader(ApexPages.StandardController controller) {

        quoteId = ApexPages.currentPage().getParameters().get('qid');
        templateId = ApexPages.currentPage().getParameters().get('tid');
        noteList = new List<String>{''};
        discountHeader = '';

        if (String.isBlank(quoteId) || String.isBlank(templateId)) { return; }
        // Get the quote
        quote = [
            SELECT Id, SBQQ__Notes__c, SBQQ__AdditionalDiscountAmount__c, 
            SBQQ__PaymentTerms__c, REF__c, SBQQ__PrimaryContact__r.Name
            FROM SBQQ__Quote__c 
            WHERE Id = :quoteId 
            LIMIT 1
        ];

        setupTemplateDependentFields();

        // Get and sort all notes by Category__c, then Quote_Order_Number__c
        List<Predefined_Qts__c> predefinedQts = [
            SELECT Id, Pre_Defined_Quote_Note__c,
                Pre_Defined_Quote_Note__r.Name,
                Pre_Defined_Quote_Note__r.NoteDetails__c,
                Category__c,
                Quote_Order_Number__c
            FROM Predefined_Qts__c
            WHERE Quote__c = :quoteId
            ORDER BY Category__c ASC, Quote_Order_Number__c ASC
        ];
        // initialize noteList with '' just in case there are no notes
        if (quote.SBQQ__Notes__c != null) {
            String cleanedNotes = quote.SBQQ__Notes__c.replace('\r', '&#160;');
            noteList = cleanedNotes.split('\n');
        }
        
        // Flatten into List<String>
        orderedNoteDescriptions = new List<String>();
        for (Predefined_Qts__c note : predefinedQts) {
            if (note.Pre_Defined_Quote_Note__r != null &&
                String.isNotBlank(note.Pre_Defined_Quote_Note__r.NoteDetails__c)) {
                orderedNoteDescriptions.add(note.Pre_Defined_Quote_Note__r.NoteDetails__c);
            }
        }
    }

    private void setupTemplateDependentFields() {
        SBQQ__QuoteTemplate__c templateRec = null;
        List<SBQQ__QuoteTemplate__c> results = [
            SELECT Id, Name 
            FROM SBQQ__QuoteTemplate__c 
            WHERE Id = :templateId 
            LIMIT 1
        ];

        if (!results.isEmpty()) {
            templateRec = results[0];
        }
        
        if (templateRec == null) {
            System.debug('No template found for the given templateId: ' + templateId);
            return;
        }
        // SBQQ__AdditionalDiscountAmount__c
        notesHeader = 'CONTRACT NOTES:';
        

        if (templateRec.Name.contains('Quote')) {
            notesHeader = 'QUOTATION NOTES:';
        }
        if(quote.SBQQ__AdditionalDiscountAmount__c != null && quote.SBQQ__AdditionalDiscountAmount__c > 0) {
            
            if(!templateRec.Name.contains('BOL')) {
                discountHeader = 'DISCOUNT GIVEN: $CAD ' + quote.SBQQ__AdditionalDiscountAmount__c;
            }

        }
        


    }
}