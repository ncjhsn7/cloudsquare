@IsTest
private class ApplicationWebhookTest {

    private static void setRestContext(String body) {
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/external/applications';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    private static String buildPayload() {
        return JSON.serialize(new Map<String, Object>{
            'companyName' => 'Acme Corp',
            'federalTaxId' => 'BG123456789',
            'contact' => new Map<String, Object>{
                'firstName' => 'Ivan',
                'lastName' => 'Ivanov',
                'email' => 'ivan@example.com',
                'phone' => '+359888123456'
            },
            'annualRevenue' => 500000
        });
    }

    @IsTest
    static void shouldCreateLeadWithWebhookSource() {
        setRestContext(buildPayload());

        Test.startTest();
        ApplicationWebhook.WebhookResponse response = ApplicationWebhook.handlePost();
        Test.stopTest();

        Assert.isTrue(response.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_LEAD, response.recordType);
        Assert.areEqual(ApplicationConstants.SUCCESS_MESSAGE, response.message);
        Assert.areEqual(
            ApplicationConstants.SOURCE_WEBHOOK,
            [SELECT Application_Source__c FROM Lead WHERE Id = :response.recordId].Application_Source__c
        );
    }

    @IsTest
    static void shouldCreateOpportunityWhenAccountMatches() {
        Account existingAccount = new Account(Name = 'Acme Corp', Federal_Tax_Id__c = 'BG123456789');
        insert existingAccount;
        setRestContext(buildPayload());

        Test.startTest();
        ApplicationWebhook.WebhookResponse response = ApplicationWebhook.handlePost();
        Test.stopTest();

        Assert.isTrue(response.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_OPPORTUNITY, response.recordType);
        Assert.areEqual(
            existingAccount.Id,
            [SELECT AccountId FROM Opportunity WHERE Id = :response.recordId].AccountId
        );
    }

    @IsTest
    static void shouldReturnErrorForMalformedJson() {
        setRestContext('not-a-json');

        Test.startTest();
        ApplicationWebhook.WebhookResponse response = ApplicationWebhook.handlePost();
        Test.stopTest();

        Assert.isFalse(response.success);
        Assert.isNotNull(response.message);
        Assert.areEqual(400, RestContext.response.statusCode);
    }

    @IsTest
    static void shouldReturnErrorWhenRequiredFieldsMissing() {
        setRestContext(JSON.serialize(new Map<String, Object>{ 'companyName' => 'Acme Corp' }));

        Test.startTest();
        ApplicationWebhook.WebhookResponse response = ApplicationWebhook.handlePost();
        Test.stopTest();

        Assert.isFalse(response.success);
        Assert.isTrue(response.message.contains('Missing required fields'));
        Assert.areEqual(400, RestContext.response.statusCode);
    }
}
