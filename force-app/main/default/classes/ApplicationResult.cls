public with sharing class ApplicationResult {

    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String recordType { get; set; }
    @AuraEnabled public Id recordId { get; set; }
    @AuraEnabled public String message { get; set; }

    public static ApplicationResult ok(String recordType, Id recordId, String message) {
        ApplicationResult result = new ApplicationResult();
        result.success = true;
        result.recordType = recordType;
        result.recordId = recordId;
        result.message = message;
        return result;
    }

    public static ApplicationResult fail(String message) {
        ApplicationResult result = new ApplicationResult();
        result.success = false;
        result.message = message;
        return result;
    }
}
