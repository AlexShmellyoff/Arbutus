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
                   SBQQ__Optional__c, Parent_product__c,SBQQ__Description__c,SBQQ__Number__c,SBQQ__CustomerPrice__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            Order By SBQQ__Number__c


        ];
        System.debug('All Quote line JSON: '+ JSON.serialize(allLines));
        groupedLines = new List<Map<String, Object>>();
        Map<String, Object> currentGroup;
        List<Map<String, Object>> subItems = new List<Map<String, Object>>();

        for (SBQQ__QuoteLine__c line : allLines) {
            System.debug('Line number is: '+ line.SBQQ__Number__c);
            String groupDescription = null;
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
                    // System.debug('Description Original: '+ JSON.serialize(line.SBQQ__Group__r.SBQQ__Description__c));
                    // System.debug('Description: ' + JSON.serialize(RemoveHtmlMarkup.stripHtmlTags(line.SBQQ__Group__r.SBQQ__Description__c)));
                    // System.debug('Description final: '+ JSON.serialize(RemoveHtmlMarkup.stripHtmlTags(line.SBQQ__Group__r.SBQQ__Description__c).split('\\n')));
                    // List<String> groupDescriptionList = RemoveHtmlMarkup.stripHtmlTags(line.SBQQ__Group__r.SBQQ__Description__c).split('\\n');
                    // List<String> groupDescriptionList = line.SBQQ__Group__r.SBQQ__Description__c.replaceAll('<div>', '').split('</div>');
                    // currentGroup.put('name', groupDescriptionList);
                    List<String> groupDescriptionList = splitHtmlByClosingTags(line.SBQQ__Group__r.SBQQ__Description__c);
                    currentGroup.put('name', groupDescriptionList);
                } else {
                    currentGroup.put('name', 
                        new List<String>{ line.SBQQ__ProductName__c }
                    );
                }
                currentGroup.put('qty', line.SBQQ__Quantity__c.intValue());
                currentGroup.put('price', line.SBQQ__CustomerPrice__c);
                currentGroup.put('total', line.SBQQ__NetTotal__c);
            } else if (currentGroup != null) {
                adderTotal += line.SBQQ__NetTotal__c;
                Map<String, Object> sub = new Map<String, Object>();
                String subItemName = subItemName(line);
                sub.put('name', subItemName);
                // sub.put('name', line.SBQQ__ProductName__c);
                sub.put('qty', line.SBQQ__Quantity__c.intValue());
                sub.put('price', line.SBQQ__CustomerPrice__c);
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

    public String subItemName(SBQQ__QuoteLine__c line){
        String name = line.SBQQ__ProductName__c;
        if(line.SBQQ__Description__c != null && line.SBQQ__Description__c != '') {
            name += ' - ' + line.SBQQ__Description__c.replaceAll('<div>', '').replaceAll('</div>', '');
        }
        name = RemoveHtmlMarkup.stripHtmlTags(name);
        return name;
    }

    private static List<String> splitHtmlByClosingTags(String html) {
        List<String> segments = new List<String>();
        if (String.isBlank(html)) {
            return segments;
        }
        // 1) Split on any closing-tag pattern like </something>
        for (String part : html.split('</[^>]+>')) {
            // 2) Remove any leftover opening tags (or attributes) e.g. <div class="…">
            String cleaned = part.replaceAll('<[^>]+>', '').trim();
            if (!String.isEmpty(cleaned)) {
                segments.add(cleaned);
            }
        }
        return segments;
    }
}