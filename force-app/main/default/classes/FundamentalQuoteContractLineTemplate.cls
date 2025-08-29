public class FundamentalQuoteContractLineTemplate {

    public String quoteId { get; set; }
    public SBQQ__Quote__c quote { get; set; }
    public List<SBQQ__QuoteLine__c> rentalQuoteLines { get; set; }
    public List<SBQQ__QuoteLine__c> serviceQuoteLines { get; set; }
    public Decimal rentalTotal { get; set; }
    public Decimal serviceTotal { get; set; }
    public Map<String, List<String>> serviceQuoteLinesDescription { get; set; }
    public Decimal total { get; set; }

    public FundamentalQuoteContractLineTemplate(ApexPages.StandardController controller) {
        quoteId = ApexPages.currentPage().getParameters().get('qid');
        rentalQuoteLines = new List<SBQQ__QuoteLine__c>();
        serviceQuoteLines = new List<SBQQ__QuoteLine__c>();
        serviceQuoteLinesDescription = new Map<String, List<String>>();
        rentalTotal = 0;
        serviceTotal = 0;
        total = 0;

        quote = [
            SELECT Id, Tax_Code_1GC__c, Tax_Code_2GC__c, SBQQ__NetAmount__c, Tax_Amount__c, Net_Amount_Tax__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
        ];

        List<SBQQ__QuoteLine__c> quoteLinesRaw = [
            SELECT Id, SBQQ__Number__c, SBQQ__Quantity__c, SBQQ__Description__c, SBQQ__ProductCode__c,
                   Note__c, Notes_Auto_Fill__c, Duration__c, SBQQ__StartDate__c,
                   Expected_End_Date__c, Daily__c, Week_7_DAY__c, Month_28_DAY__c,
                   SBQQ__TotalDiscountAmount__c, SBQQ__NetTotal__c, SBQQ__ProductFamily__c,
                   SBQQ__NetPrice__c, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            ORDER BY SBQQ__Number__c
        ];

        for (SBQQ__QuoteLine__c qLine : quoteLinesRaw) {
            SBQQ__QuoteLine__c qLineCopy = qLine;

            if (qLineCopy.SBQQ__ProductFamily__c.contains('Rental')) {
                qLineCopy.SBQQ__Description__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.SBQQ__Description__c);
                qLineCopy.Note__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Note__c);
                qLineCopy.Notes_Auto_Fill__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Notes_Auto_Fill__c);
                rentalTotal += qLineCopy.SBQQ__NetTotal__c;
                rentalQuoteLines.add(qLineCopy);
            }

            if (qLineCopy.SBQQ__ProductFamily__c.contains('Service')) {
                if (qLine.SBQQ__Description__c != null) {
                    // Use the new splitHtmlByClosingTags method here
                    List<String> descriptionSegments = splitHtmlByClosingTags(qLineCopy.SBQQ__Description__c);
                    serviceQuoteLinesDescription.put(qLineCopy.Id, descriptionSegments);

                    // Also store a stripped version in SBQQ__Description__c if needed for display elsewhere
                    qLineCopy.SBQQ__Description__c = String.join(descriptionSegments, ' ');
                }

                qLineCopy.Note__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Note__c);
                qLineCopy.Notes_Auto_Fill__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Notes_Auto_Fill__c);
                serviceTotal += qLineCopy.SBQQ__NetTotal__c;
                serviceQuoteLines.add(qLineCopy);
            }
        }

        total = rentalTotal + serviceTotal;

        System.debug('rentalQuoteLines: ' + JSON.serialize(rentalQuoteLines));
        System.debug('serviceQuoteLines: ' + JSON.serialize(serviceQuoteLines));
        System.debug('serviceQuoteLinesDescription: ' + JSON.serialize(serviceQuoteLinesDescription));
        System.debug('rentalTotal: ' + rentalTotal);
        System.debug('serviceTotal: ' + serviceTotal);
        System.debug('total: ' + total);
        System.debug('quote: ' + JSON.serialize(quote));
        System.debug('quoteId: ' + quoteId);
    }

    private static List<String> splitHtmlByClosingTags(String html) {
        List<String> segments = new List<String>();
        if (String.isBlank(html)) {
            return segments;
        }
        for (String part : html.split('</[^>]+>')) {
            String cleaned = part.replaceAll('<[^>]+>', '').trim();
            if (!String.isEmpty(cleaned)) {
                segments.add(cleaned);
            }
        }
        return segments;
    }
}