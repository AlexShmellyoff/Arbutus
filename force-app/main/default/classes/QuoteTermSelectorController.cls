public class QuoteTermSelectorController {
    public Id quoteId { get; set; }
    public List<TermWrapper> terms { get; set; }

    public QuoteTermSelectorController(ApexPages.StandardController stdCtrl) {
        quoteId = stdCtrl.getId();
        terms = new List<TermWrapper>();

        for (SBQQ__QuoteTerm__c t : [
            SELECT Id, Name, SBQQ__Body__c
            FROM SBQQ__QuoteTerm__c
            WHERE SBQQ__Quote__c = null
        ]) {
            terms.add(new TermWrapper(t));
        }
    }

    public PageReference addSelectedTerms() {
        List<SBQQ__QuoteTerm__c> toUpdate = new List<SBQQ__QuoteTerm__c>();

        for (TermWrapper w : terms) {
            if (w.selected) {
                w.term.SBQQ__Quote__c = quoteId;
                toUpdate.add(w.term);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return new PageReference('/' + quoteId);
    }

    public class TermWrapper {
        public SBQQ__QuoteTerm__c term { get; set; }
        public Boolean selected { get; set; }

        public TermWrapper(SBQQ__QuoteTerm__c t) {
            this.term = t;
            this.selected = false;
        }
    }
}