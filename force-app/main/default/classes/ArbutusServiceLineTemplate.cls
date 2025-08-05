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
                 Services_Included__c
          FROM SBQQ__Quote__c 
          WHERE Id = :quoteId 
          LIMIT 1];
            populateInstalledSite();
            populateProposalOverview();
            populateServiceIncluded();
            populateArbutusNotes();
            populateGroupedLines();
        } 
    }

    public void populateGroupedLines() {
        List<Map<String, Object>> groupedLines = new List<Map<String, Object>>();
        Date startDate = null;
        Date endDate = null;
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
                SBQQ__Number__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
        ];

        // Group quote lines by group id
        Map<Id, List<SBQQ__QuoteLine__c>> groupedLinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c line : allLines) {
            if (!groupedLinesMap.containsKey(line.SBQQ__Group__c)) {
                groupedLinesMap.put(line.SBQQ__Group__c, new List<SBQQ__QuoteLine__c>());
            }
            groupedLinesMap.get(line.SBQQ__Group__c).add(line);
        }

        Decimal durationYears = null;
        if (allLines[0] != null && allLines[0].SBQQ__Group__r.SBQQ__StartDate__c != null && allLines[0].SBQQ__Group__r.SBQQ__EndDate__c != null) {
            startDate = allLines[0].SBQQ__Group__r.SBQQ__StartDate__c;
            endDate = allLines[0].SBQQ__Group__r.SBQQ__EndDate__c;
            Integer totalDays = startDate.daysBetween(endDate);
            durationYears = (Decimal.valueOf(totalDays) / 365).round();
        }
        Decimal groupedLinesSubTotalAmount = 0;
        for (String key : groupedLinesMap.keySet()) {
            Map<String, Object> currentGroup = new Map<String, Object>();
            SBQQ__QuoteLine__c parentLine = null;
            String groupDescription = null;
            List<SBQQ__QuoteLine__c> subItems = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> lines = groupedLinesMap.get(key);
            List<String> groupDescriptionList = new List<String>();

            for (SBQQ__QuoteLine__c qt : lines) {
                if (qt.Parent_product__c) {
                    parentLine = qt;
                    groupDescription = parentLine.SBQQ__Group__r.SBQQ__Description__c.replaceAll('<div>', '');
                    if(groupDescription.contains('</div>')) {
                        groupDescriptionList = groupDescription.replaceAll('-','&#160;').split('</div>');
                    }

                } else {
                    subItems.add(qt);
                }
                groupedLinesSubTotalAmount += qt.SBQQ__ListPrice__c * qt.SBQQ__Quantity__c;
            }
            
            

            System.debug('[VDO] Yearly Duration: ' + durationYears);
            currentGroup.put('parentProduct', parentLine);
            currentGroup.put('subItems', subItems);
            currentGroup.put('parrentProductDescription', groupDescriptionList);
            

            groupedLines.add(currentGroup);
        }

        // make for using durationYears and year++
        groupedLinesByYears = new Map<String, Map<String, Object>>();
        groupedLinesByYearsKeys = new List<String>();
        overallTotal = 0;

        Date currentStart = startDate;
        for (Integer year = 1; year <= durationYears.intValue(); year++) {
            // Create a deep copy of groupedLines for this year
            List<Map<String, Object>> currentGroupedLines = new List<Map<String, Object>>();
            for (Map<String, Object> groupL : groupedLines) {
                Map<String, Object> clonedGroup = new Map<String, Object>();
                clonedGroup.putAll(groupL);
                currentGroupedLines.add(clonedGroup);
            }
            

            Date calculatedEnd = currentStart.addYears(1).addDays(-1); // 1 year span

            // If last year and calculated end exceeds actual endDate
            Date actualEnd = (calculatedEnd > endDate) ? endDate : calculatedEnd;

            // Use DateTime to format the Date as MM/dd/yyyy
            String formattedStart = DateTime.newInstance(currentStart, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
            String formattedEnd = DateTime.newInstance(actualEnd, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');

            String yearKey = 'year ' + year + ' - ' + formattedStart + ' - ' + formattedEnd;

            overallTotal += groupedLinesSubTotalAmount;
            groupedLinesByYears.put(yearKey, new Map<String, Object>{
                'quoteLines' => currentGroupedLines,
                'periodInfo' => new Map<String, Object>{
                    'startDate' => formattedStart,
                    'endDate' => formattedEnd,
                    'duration' => String.valueOf(year)
                },
                'subTotal' => groupedLinesSubTotalAmount
            } ); // Replace with filtered groupedLines if needed
            groupedLinesByYearsKeys.add(yearKey);

            System.debug('[VDO] Group Key: ' + yearKey);

            currentStart = currentStart.addYears(1);
            if(year == 1 ){
                quoteStartAndEndDate = formattedStart;
            } else if (year == durationYears.intValue()) {
                quoteStartAndEndDate += ' - ' + formattedEnd;
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
    
}