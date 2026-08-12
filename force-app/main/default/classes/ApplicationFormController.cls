public with sharing class ApplicationFormController {

    @AuraEnabled
    public static ApplicationResult submitApplication(ApplicationDTO input) {
        try {
            if (input == null) {
                return ApplicationResult.fail('No application data provided');
            }
            input.source = ApplicationConstants.SOURCE_COMMUNITY;
            return ApplicationProcessingService.processApplication(input);
        } catch (Exception e) {
            return ApplicationResult.fail(e.getMessage());
        }
    }
}
