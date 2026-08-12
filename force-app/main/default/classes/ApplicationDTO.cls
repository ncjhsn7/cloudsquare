public with sharing class ApplicationDTO {

    @AuraEnabled public String companyName { get; set; }
    @AuraEnabled public String federalTaxId { get; set; }
    @AuraEnabled public String firstName { get; set; }
    @AuraEnabled public String lastName { get; set; }
    @AuraEnabled public String email { get; set; }
    @AuraEnabled public String phone { get; set; }
    @AuraEnabled public Decimal annualRevenue { get; set; }
    @AuraEnabled public String source { get; set; }
}
