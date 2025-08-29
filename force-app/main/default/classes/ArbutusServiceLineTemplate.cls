public class ArbutusServiceLineTemplate {
    public String quoteId { get; set; }
    public String templateId { get; set; }
    public SBQQ__Quote__c quote { get; set; }
    public Map<String, Map<String, Object>> groupedLinesByYears { get; set; }
    public List<String> groupedLinesByYearsKeys { get; set; }
    public Decimal overallTotal { get; set; }
    public List<String> installedSite { get; set; }
    public List<String> proposalOverview { get; set; }
    public List<String> serviceIncluded { get; set; }
    public List<String> arbutusNotes { get; set; }
    public List<String> notesForScopeOfWork { get; set; }
    public String quoteStartAndEndDate { get; set; }
    public String logoDocId { get; set; }

    public String getLogoUrl() {
        String base = URL.getOrgDomainUrl().toExternalForm();
        return base
            + '/servlet/servlet.ImageServer'
            + '?id='    + logoDocId
            + '&oid='   + UserInfo.getOrganizationId();
    }

    public ArbutusServiceLineTemplate(ApexPages.StandardController controller) {
        quoteId = ApexPages.currentPage().getParameters().get('qid');
        templateId = ApexPages.currentPage().getParameters().get('tid');
        if(!Test.isRunningTest()){
            logoDocId = [SELECT Id,DeveloperName FROM Document where DeveloperName = 'Arbutus_Cover_Page' LIMIT 1].Id;
        }
        System.debug('[VDO]Logo Doc Id: ' + logoDocId);
        System.debug('[VDO]Constructor ArbutusServiceLineTemplate');

        if (String.isNotBlank(quoteId)) {
            try {
                quote = [
                    SELECT Id,
                     SBQQ__Account__r.Name,
                     Arbutus_Notes__c,
                     SBQQ__ShippingName__c,
                     SBQQ__ShippingStreet__c,
                     SBQQ__ShippingCity__c,
                     SBQQ__ShippingState__c,
                     SBQQ__ShippingPostalCode__c,
                     SBQQ__ShippingCountry__c,
                     Proposal_Overview__c,
                     Services_Included__c,
                     Notes_for_Scope_of_Work_Bill_of_Material__c
              FROM SBQQ__Quote__c 
              WHERE Id = :quoteId 
              LIMIT 1];
                populateInstalledSite();
                populateProposalOverview();
                populateServiceIncluded();
                populateArbutusNotes();
                populateNotesForScopeOfWork();
                populateGroupedLines();
            } catch (Exception ex) {
                System.debug('[ArbutusServiceLineTemplate ERROR] ' + ex.getMessage() + '\n' + ex.getStackTraceString());
                
                ex.setMessage('An error occurred while loading the quote details.');
            }
        } 
    }

    public void populateGroupedLines() {
        groupedLinesByYears = new Map<String, Map<String, Object>>();
        groupedLinesByYearsKeys = new List<String>();
        overallTotal = 0;
        
        List<SBQQ__QuoteLine__c> allLines = [
            SELECT Id, SBQQ__Group__r.SBQQ__Description__c, 
                SBQQ__Group__c, SBQQ__Group__r.Name,
                SBQQ__Group__r.SBQQ__SubscriptionTerm__c,
                SBQQ__Group__r.SBQQ__StartDate__c,
                SBQQ__Product__r.Part_Number__c,
                SBQQ__Product__r.Manufacturer__c,
                SBQQ__Group__r.SBQQ__EndDate__c,
                SBQQ__ProductName__c, SBQQ__Quantity__c, 
                SBQQ__ListPrice__c, SBQQ__NetTotal__c,
                SBQQ__Optional__c, Parent_product__c,
                SBQQ__Number__c, SBQQ__Description__c,
                Year__c,SBQQ__NetPrice__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            Order By Year__c
        ];

        // Group quote lines by group id
        Map<Id, List<SBQQ__QuoteLine__c>> groupedLinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c line : allLines) {
            if (!groupedLinesMap.containsKey(line.SBQQ__Group__c)) {
                groupedLinesMap.put(line.SBQQ__Group__c, new List<SBQQ__QuoteLine__c>());
            }
            groupedLinesMap.get(line.SBQQ__Group__c).add(line);

        }

        Decimal groupedLinesSubTotalAmount = 0;
        Integer qliYear = 0;
        for (String key : groupedLinesMap.keySet()) {
            List<Map<String, Object>> groupedLines = new List<Map<String, Object>>();
            Date startDate = null;
            Date endDate = null;
            
            Boolean isNewYear = false;
            Map<String, Object> currentGroup = new Map<String, Object>();
            SBQQ__QuoteLine__c parentLine = null;
            String groupDescription = null;
            List<Map<String, Object>> subItems = new List<Map<String, Object>>();
            List<SBQQ__QuoteLine__c> lines = groupedLinesMap.get(key);
            List<String> groupDescriptionList = new List<String>();

            for (SBQQ__QuoteLine__c qt : lines) {
                Integer yearOfQLI = Integer.valueOf(qt.Year__c);

                if(yearOfQLI > qliYear) {
                    qliYear = yearOfQLI;
                    isNewYear = true;
                    startDate = qt.SBQQ__Group__r.SBQQ__StartDate__c;
                    endDate = qt.SBQQ__Group__r.SBQQ__EndDate__c;
                    groupedLinesSubTotalAmount = 0;
                    System.debug('[VDO] ENTER IN NEW YEAR');
                }


                if (qt.Parent_product__c) {
                    parentLine = qt;
                    //List<String> groupDescriptionList = splitHtmlByClosingTags(line.SBQQ__Group__r.SBQQ__Description__c);
                        // String description = parentLine.SBQQ__Group__r.SBQQ__Description__c.replaceAll('<p>', '').replaceAll('</p>', '');
                        // if(description == null && description == '') {
                        //     groupDescriptionList.add(parentLine.SBQQ__ProductName__c);
                        //     continue;
                        // }

                        // groupDescription = description.replaceAll('<div>', '');
                        // if(groupDescription.contains('</div>')) {
                        //     groupDescriptionList = groupDescription.replaceAll('-','&#160;').split('</div>');
                        // }

                    groupDescriptionList = splitHtmlByClosingTags(parentLine.SBQQ__Group__r.SBQQ__Description__c);

                } else {
                    Map<String, Object> subItem = new Map<String, Object>();
                    subItem = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(qt));
                    subItem.put('name', subItemName(qt));
                    if(qt.SBQQ__Product__r.Part_Number__c != null && qt.SBQQ__Product__r.Part_Number__c != '') {
                        subItem.put('partNumber', qt.SBQQ__Product__r.Part_Number__c);
                    } else {
                        subItem.put('partNumber', '');
                    }

                    subItems.add(subItem);
                }
                groupedLinesSubTotalAmount += qt.SBQQ__NetPrice__c * qt.SBQQ__Quantity__c;
                overallTotal += qt.SBQQ__NetPrice__c * qt.SBQQ__Quantity__c;
                System.debug('[VDO] subtotal: '+ groupedLinesSubTotalAmount);
            }
            
            

            // System.debug('[VDO] Yearly Duration: ' + durationYears);
            currentGroup.put('parentProduct', parentLine);
            currentGroup.put('subItems', subItems);
            currentGroup.put('parrentProductDescription', groupDescriptionList);
            
            
            groupedLines.add(currentGroup);

            

            String yearKey = 'year ' + qliYear ;
            System.debug('[VDO] Group Key: ' + yearKey);
            
            if(isNewYear){
                String formattedStart = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
                String formattedEnd = DateTime.newInstance(endDate, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
                

                groupedLinesByYears.put(yearKey, new Map<String, Object>{
                    'quoteLines' => groupedLines,
                    'periodInfo' => new Map<String, Object>{
                        'startDate' => formattedStart,
                        'endDate' => formattedEnd,
                        'duration' => String.valueOf(qliYear)
                    },
                    'subTotal' => groupedLinesSubTotalAmount
                } ); // Replace with filtered groupedLines if needed
                groupedLinesByYearsKeys.add(yearKey);

            } else {
                // fetch the year’s data
                Map<String, Object> yearData = groupedLinesByYears.get(yearKey);
                // grab the list
                List<Map<String, Object>> quoteLines =
                    (List<Map<String, Object>>) yearData.get('quoteLines');
                // add your new groups
                quoteLines.addAll(groupedLines);
                yearData.put('subTotal', groupedLinesSubTotalAmount);
            }
        }



        System.debug('[VDO] Grouped Lines: ' + JSON.serialize(groupedLinesByYears));
        
    } 

    public void populateInstalledSite() {
        installedSite = new List<String>();

        if (quote.SBQQ__ShippingName__c != null && quote.SBQQ__ShippingName__c != '') {
            installedSite.add(quote.SBQQ__ShippingName__c);
        }
        if (quote.SBQQ__ShippingStreet__c != null && quote.SBQQ__ShippingStreet__c != '') {
            installedSite.add(quote.SBQQ__ShippingStreet__c);
        }
        if ((quote.SBQQ__ShippingPostalCode__c != null && quote.SBQQ__ShippingPostalCode__c != '') || 
            (quote.SBQQ__ShippingCity__c != null && quote.SBQQ__ShippingCity__c != '') || 
            (quote.SBQQ__ShippingState__c != null && quote.SBQQ__ShippingState__c != '')) {

            String postalCode = quote.SBQQ__ShippingPostalCode__c != null ? quote.SBQQ__ShippingPostalCode__c : '';
            String city = quote.SBQQ__ShippingCity__c != null ? quote.SBQQ__ShippingCity__c : '';
            String state = quote.SBQQ__ShippingState__c != null ? ', ' + quote.SBQQ__ShippingState__c : '';
            installedSite.add(postalCode + ' ' + city + state);
        }
        if (quote.SBQQ__ShippingCountry__c != null) {
            installedSite.add(quote.SBQQ__ShippingCountry__c);
        }
        System.debug('[VDO] Installed Site: ' + installedSite);
    }

    public void populateProposalOverview() {
        proposalOverview = new List<String>();
        
        if (quote.Proposal_Overview__c != null && quote.Proposal_Overview__c != '') {
            proposalOverview = quote.Proposal_Overview__c.replaceAll(' ', '&#160;').split('\n');
        } 
        System.debug('[VDO] Proposal Overview: ' + proposalOverview);
        
    }

    public void populateServiceIncluded() {
        serviceIncluded = new List<String>();
        
        if (quote.Services_Included__c != null && quote.Services_Included__c != '') {
            serviceIncluded = quote.Services_Included__c.replaceAll(' ', '&#160;').split('\n');
        } 
        System.debug('[VDO] Services Included: ' + serviceIncluded);
        
    }

    public void populateArbutusNotes() {
        arbutusNotes = new List<String>();
        
        if (quote.Arbutus_Notes__c != null && quote.Arbutus_Notes__c != '') {
            arbutusNotes = quote.Arbutus_Notes__c.replaceAll(' ', '&#160;').split('\n');
        }
        System.debug('[VDO] Arbutus Notes: ' + arbutusNotes);
        
    }

    public void populateNotesForScopeOfWork() {
        notesForScopeOfWork = new List<String>();
        
        if (quote.Notes_for_Scope_of_Work_Bill_of_Material__c != null && quote.Notes_for_Scope_of_Work_Bill_of_Material__c != '') {
            notesForScopeOfWork = quote.Notes_for_Scope_of_Work_Bill_of_Material__c.replaceAll(' ', '&#160;').split('\n');
        }
        System.debug('[VDO] Notes for Scope of Work: ' + notesForScopeOfWork);
        
    }

    public String subItemName(SBQQ__QuoteLine__c line){
        String name = line.SBQQ__ProductName__c;
        if(line.SBQQ__Description__c != null && line.SBQQ__Description__c != '') {
            name += ' - ' + line.SBQQ__Description__c.replaceAll('<div>', '').replaceAll('</div>', '');
        }
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