public inherited sharing class LeadsDomain {

    public static Lead buildFromApplication(ApplicationDTO app) {
        return new Lead(
            FirstName = app.firstName,
            LastName = app.lastName,
            Company = app.companyName,
            Email = app.email,
            Phone = app.phone,
            AnnualRevenue = app.annualRevenue,
            Federal_Tax_Id__c = app.federalTaxId,
            Application_Source__c = app.source
        );
    }
}
