@IsTest
private class ApplicationFormControllerTest {

    private static ApplicationDTO buildInput() {
        ApplicationDTO input = new ApplicationDTO();
        input.companyName = 'Acme Corp';
        input.federalTaxId = 'BG123456789';
        input.firstName = 'Ivan';
        input.lastName = 'Ivanov';
        input.email = 'ivan@example.com';
        input.phone = '+359888123456';
        input.annualRevenue = 500000;
        return input;
    }

    @IsTest
    static void shouldCreateLeadWithCommunitySource() {
        Test.startTest();
        ApplicationResult result = ApplicationFormController.submitApplication(buildInput());
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual(ApplicationConstants.RECORD_TYPE_LEAD, result.recordType);
        Assert.areEqual(
            ApplicationConstants.SOURCE_COMMUNITY,
            [SELECT Application_Source__c FROM Lead WHERE Id = :result.recordId].Application_Source__c
        );
    }

    @IsTest
    static void shouldReturnFailureWhenInputIsNull() {
        Test.startTest();
        ApplicationResult result = ApplicationFormController.submitApplication(null);
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.isNotNull(result.message);
    }

    @IsTest
    static void shouldReturnFailureWhenValidationFails() {
        ApplicationDTO input = buildInput();
        input.lastName = null;

        Test.startTest();
        ApplicationResult result = ApplicationFormController.submitApplication(input);
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.isTrue(result.message.contains('lastName'));
    }
}
