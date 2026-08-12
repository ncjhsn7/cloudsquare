public inherited sharing class OpportunitiesDomain {

    public static Opportunity buildFromApplication(ApplicationDTO app, Id accountId) {
        return new Opportunity(
            Name = app.companyName + ApplicationConstants.OPPORTUNITY_NAME_SUFFIX,
            StageName = ApplicationConstants.OPPORTUNITY_STAGE,
            CloseDate = Date.today().addDays(ApplicationConstants.OPPORTUNITY_CLOSE_DAYS),
            AccountId = accountId,
            Amount = app.annualRevenue,
            Application_Source__c = app.source
        );
    }
}
