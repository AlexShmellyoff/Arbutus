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

        quote = [SELECT Id, Tax_Code_1__c, Tax_Code_2__c, SBQQ__NetAmount__c, Tax_Amount__c,Net_Amount_Tax__c FROM SBQQ__Quote__c WHERE Id = :quoteId];

        List<SBQQ__QuoteLine__c> quoteLinesRaw = [
            SELECT Id, SBQQ__Number__c, SBQQ__Quantity__c, SBQQ__Description__c, SBQQ__ProductCode__c,
                   Note__c, Notes_Auto_Fill__c, Duration__c, SBQQ__StartDate__c,
                   Expected_End_Date__c, Daily__c, Week_7_DAY__c, Month_28_DAY__c,
                   SBQQ__TotalDiscountAmount__c, SBQQ__NetTotal__c, SBQQ__ProductFamily__c,
                   SBQQ__NetPrice__c,SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId 
            ORDER BY SBQQ__Number__c
        ];

        for (SBQQ__QuoteLine__c qLine : quoteLinesRaw) {
            SBQQ__QuoteLine__c qLineCopy = qLine;
            if(qLineCopy.SBQQ__ProductFamily__c.contains('Rental')){
                qLineCopy.SBQQ__Description__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.SBQQ__Description__c);
                qLineCopy.Note__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Note__c);
                qLineCopy.Notes_Auto_Fill__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Notes_Auto_Fill__c);
                System.debug('JSON quoteLine: ' + JSON.serialize(qLineCopy));
                rentalTotal += qLineCopy.SBQQ__NetTotal__c;
                rentalQuoteLines.add(qLineCopy);
            }

            // groupDescription = parentLine.SBQQ__Group__r.SBQQ__Description__c.replaceAll('<div>', '');
            // if(groupDescription.contains('</div>')) {
            //     groupDescriptionList = groupDescription.replaceAll('-','&#160;').split('</div>');
            // }
            if(qLineCopy.SBQQ__ProductFamily__c.contains('Service')){

                if(qLine.SBQQ__Description__c != null){
                    String descriptionCopy = qLineCopy.SBQQ__Description__c;
                    descriptionCopy = descriptionCopy.replaceAll('<div>', '');
                    if(descriptionCopy.contains('</div>')){
                        serviceQuoteLinesDescription.put(qLineCopy.Id, descriptionCopy.split('</div>'));
                    }else{
                        List<String> descriptionList = new List<String>();
                        descriptionList.add(descriptionCopy);
                        serviceQuoteLinesDescription.put(qLineCopy.Id, descriptionList);
                    }


                    qLineCopy.SBQQ__Description__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.SBQQ__Description__c);
                }
                
                qLineCopy.Note__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Note__c);
                qLineCopy.Notes_Auto_Fill__c = RemoveHtmlMarkup.stripHtmlTags(qLineCopy.Notes_Auto_Fill__c);
                System.debug('JSON quoteLine: ' + JSON.serialize(qLineCopy));
                serviceTotal += qLineCopy.SBQQ__NetTotal__c;
                serviceQuoteLines.add(qLineCopy);
            }
        }
        total = rentalTotal + serviceTotal;
        // debug all the values
        System.debug('rentalQuoteLines: ' + JSON.serialize(rentalQuoteLines));
        System.debug('serviceQuoteLines: ' + JSON.serialize(serviceQuoteLines));
        System.debug('rentalTotal: ' + rentalTotal);
        System.debug('serviceTotal: ' + serviceTotal);
        System.debug('total: ' + total);
        System.debug('quote: ' + JSON.serialize(quote));
        System.debug('quoteId: ' + quoteId);
    }
}