public class ArbutusQuoteLineRendererController {
    public String quoteId { get; set; }
    public String templateId { get; set; }
    public SBQQ__Quote__c quote { get; set; }
    public List<Map<String, Object>> groupedLines { get; set; }
    public Decimal overallTotal { get; set; }
    public Decimal adderTotal { get; set; }
    public Decimal productTotal { get; set; }

    public ArbutusQuoteLineRendererController(ApexPages.StandardController controller) {
        quoteId = ApexPages.currentPage().getParameters().get('qid');
        templateId = ApexPages.currentPage().getParameters().get('tid');

        if (String.isNotBlank(quoteId)) {
            quote = [SELECT Id, SBQQ__Account__r.Name FROM SBQQ__Quote__c WHERE Id = :quoteId LIMIT 1];
            populateGroupedLines();
        } else {
            groupedLines = new List<Map<String, Object>>();
        }
    }

    public void populateGroupedLines() {
        overallTotal = 0;
        adderTotal = 0;
        productTotal = 0;
        List<SBQQ__QuoteLine__c> allLines = [
            SELECT Id,SBQQ__Group__r.SBQQ__Description__c, SBQQ__ProductName__c, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c,
                   SBQQ__Optional__c, Parent_product__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id

        ];

        groupedLines = new List<Map<String, Object>>();
        Map<String, Object> currentGroup;
        List<Map<String, Object>> subItems = new List<Map<String, Object>>();

        for (SBQQ__QuoteLine__c line : allLines) {
            overallTotal += line.SBQQ__NetTotal__c;
            if (line.SBQQ__Group__r.SBQQ__Description__c != null && line.SBQQ__Group__r.SBQQ__Description__c != '') {
                System.debug('GROUP DESCRIPTION: ' + RemoveHtmlMarkup.stripHtmlTags(line.SBQQ__Group__r.SBQQ__Description__c));
                
            }
            if (line.Parent_product__c) {
                productTotal += line.SBQQ__NetTotal__c;
                if (currentGroup != null) {
                    currentGroup.put('subItems', subItems);
                    groupedLines.add(currentGroup);
                }
                currentGroup = new Map<String, Object>();
                subItems = new List<Map<String, Object>>();

                if(line.SBQQ__Group__r.SBQQ__Description__c != null && line.SBQQ__Group__r.SBQQ__Description__c != '') {
                    currentGroup.put('name', RemoveHtmlMarkup.stripHtmlTags(line.SBQQ__Group__r.SBQQ__Description__c));
                } else {
                    currentGroup.put('name', line.SBQQ__ProductName__c);
                }
                currentGroup.put('qty', line.SBQQ__Quantity__c.intValue());
                currentGroup.put('price', line.SBQQ__ListPrice__c);
                currentGroup.put('total', line.SBQQ__NetTotal__c);
            } else if (currentGroup != null) {
                adderTotal += line.SBQQ__NetTotal__c;
                Map<String, Object> sub = new Map<String, Object>();
                sub.put('name', line.SBQQ__ProductName__c);
                sub.put('qty', line.SBQQ__Quantity__c.intValue());
                sub.put('price', line.SBQQ__ListPrice__c);
                sub.put('total', line.SBQQ__NetTotal__c);
                sub.put('optional', line.SBQQ__Optional__c);
                subItems.add(sub);
            }
        }

        if (currentGroup != null) {
            currentGroup.put('subItems', subItems);
            groupedLines.add(currentGroup);
        }
        System.debug('Grouped Lines: ' + groupedLines);
        System.debug('JSON: ' + JSON.serialize(groupedLines));

    }
}