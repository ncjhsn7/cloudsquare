@IsTest
private class ApplicationProcessingServiceTest {

    private static final String TAX_ID = 'BG123456789';
    private static final String COMPANY_NAME = 'Acme Corp';

    private static ApplicationDTO buildApplication(String source) {
        ApplicationDTO app = new ApplicationDTO();
        app.companyName = COMPANY_NAME;
        app.federalTaxId = TAX_ID;
        app.firstName = 'Ivan';
        app.lastName = 'Ivanov';
        app.email = 'ivan@example.com';
        app.phone = '+359888123456';
        app.annualRevenue = 500000;
        app.source = source;
        return app;
    }

    @IsTest
    static void shouldCreateLeadWhenNoAccountMatches() {
        ApplicationDTO app = buildApplication(ApplicationConstants.SOURCE_COMMUNITY);

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(app);
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_LEAD, result.recordType);
        Assert.isNotNull(result.recordId);

        Lead createdLead = [
            SELECT FirstName, LastName, Company, Email, Phone, AnnualRevenue, Federal_Tax_Id__c, Application_Source__c
            FROM Lead
            WHERE Id = :result.recordId
        ];
        Assert.areEqual('Ivan', createdLead.FirstName);
        Assert.areEqual('Ivanov', createdLead.LastName);
        Assert.areEqual(COMPANY_NAME, createdLead.Company);
        Assert.areEqual('ivan@example.com', createdLead.Email);
        Assert.areEqual('+359888123456', createdLead.Phone);
        Assert.areEqual(500000, createdLead.AnnualRevenue);
        Assert.areEqual(TAX_ID, createdLead.Federal_Tax_Id__c);
        Assert.areEqual(ApplicationConstants.SOURCE_COMMUNITY, createdLead.Application_Source__c);
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity]);
    }

    @IsTest
    static void shouldCreateOpportunityWhenFederalTaxIdMatches() {
        Account existingAccount = new Account(Name = 'Existing Company', Federal_Tax_Id__c = TAX_ID);
        insert existingAccount;
        ApplicationDTO app = buildApplication(ApplicationConstants.SOURCE_COMMUNITY);

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(app);
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_OPPORTUNITY, result.recordType);

        Opportunity createdOpportunity = [
            SELECT Name, StageName, CloseDate, AccountId, Amount, Application_Source__c
            FROM Opportunity
            WHERE Id = :result.recordId
        ];
        Assert.areEqual(COMPANY_NAME + ApplicationConstants.OPPORTUNITY_NAME_SUFFIX, createdOpportunity.Name);
        Assert.areEqual(ApplicationConstants.OPPORTUNITY_STAGE, createdOpportunity.StageName);
        Assert.areEqual(Date.today().addDays(ApplicationConstants.OPPORTUNITY_CLOSE_DAYS), createdOpportunity.CloseDate);
        Assert.areEqual(existingAccount.Id, createdOpportunity.AccountId);
        Assert.areEqual(500000, createdOpportunity.Amount);
        Assert.areEqual(ApplicationConstants.SOURCE_COMMUNITY, createdOpportunity.Application_Source__c);
        Assert.areEqual(0, [SELECT COUNT() FROM Lead]);
    }

    @IsTest
    static void shouldCreateOpportunityWhenNameMatchesAndTaxIdIsBlank() {
        Account existingAccount = new Account(Name = COMPANY_NAME);
        insert existingAccount;
        ApplicationDTO app = buildApplication(ApplicationConstants.SOURCE_COMMUNITY);
        app.federalTaxId = null;

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(app);
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_OPPORTUNITY, result.recordType);
        Assert.areEqual(
            existingAccount.Id,
            [SELECT AccountId FROM Opportunity WHERE Id = :result.recordId].AccountId
        );
    }

    @IsTest
    static void shouldCreateLeadWhenTaxIdDoesNotMatchEvenIfNameMatches() {
        insert new Account(Name = COMPANY_NAME, Federal_Tax_Id__c = 'OTHER123');
        ApplicationDTO app = buildApplication(ApplicationConstants.SOURCE_COMMUNITY);

        Test.startTest();
        ApplicationResult result = ApplicationProcessingService.processApplication(app);
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_LEAD, result.recordType);
    }

    @IsTest
    static void shouldSetApplicationSourceFromInput() {
        List<ApplicationDTO> apps = new List<ApplicationDTO>{
            buildApplication(ApplicationConstants.SOURCE_COMMUNITY),
            buildApplication(ApplicationConstants.SOURCE_WEBHOOK)
        };
        apps[1].email = 'webhook@example.com';

        Test.startTest();
        List<ApplicationResult> results = ApplicationProcessingService.processApplications(apps);
        Test.stopTest();

        Assert.areEqual(2, results.size());
        Assert.areEqual(
            ApplicationConstants.SOURCE_COMMUNITY,
            [SELECT Application_Source__c FROM Lead WHERE Id = :results[0].recordId].Application_Source__c
        );
        Assert.areEqual(
            ApplicationConstants.SOURCE_WEBHOOK,
            [SELECT Application_Source__c FROM Lead WHERE Id = :results[1].recordId].Application_Source__c
        );
    }

    @IsTest
    static void shouldThrowWhenRequiredFieldsAreMissing() {
        ApplicationDTO app = buildApplication(ApplicationConstants.SOURCE_COMMUNITY);
        app.companyName = null;
        app.email = '';

        Test.startTest();
        try {
            ApplicationProcessingService.processApplication(app);
            Assert.fail('Expected ApplicationException');
        } catch (ApplicationException e) {
            Assert.isTrue(e.getMessage().contains('companyName'));
            Assert.isTrue(e.getMessage().contains('email'));
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenSourceIsInvalid() {
        ApplicationDTO app = buildApplication('Other');

        Test.startTest();
        try {
            ApplicationProcessingService.processApplication(app);
            Assert.fail('Expected ApplicationException');
        } catch (ApplicationException e) {
            Assert.isTrue(e.getMessage().contains('Invalid application source'));
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenInputIsNull() {
        Test.startTest();
        try {
            ApplicationProcessingService.processApplications(null);
            Assert.fail('Expected ApplicationException');
        } catch (ApplicationException e) {
            Assert.isTrue(e.getMessage().contains('No application data provided'));
        }
        Test.stopTest();
    }
}
