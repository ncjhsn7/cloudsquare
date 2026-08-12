public without sharing class ApplicationProcessingService {

    public static ApplicationResult processApplication(ApplicationDTO app) {
        return processApplications(new List<ApplicationDTO>{ app })[0];
    }

    public static List<ApplicationResult> processApplications(List<ApplicationDTO> apps) {
        validateAll(apps);
        Map<String, Id> accountIdsByTaxId = new Map<String, Id>();
        Map<String, Id> accountIdsByName = new Map<String, Id>();
        resolveMatchingAccounts(apps, accountIdsByTaxId, accountIdsByName);

        List<Lead> leads = new List<Lead>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<SObject> orderedRecords = new List<SObject>();
        List<String> orderedRecordTypes = new List<String>();

        for (ApplicationDTO app : apps) {
            Id accountId = String.isNotBlank(app.federalTaxId)
                ? accountIdsByTaxId.get(app.federalTaxId)
                : accountIdsByName.get(app.companyName);

            if (accountId == null) {
                Lead newLead = LeadsDomain.buildFromApplication(app);
                leads.add(newLead);
                orderedRecords.add(newLead);
                orderedRecordTypes.add(ApplicationConstants.RECORD_TYPE_LEAD);
            } else {
                Opportunity newOpportunity = OpportunitiesDomain.buildFromApplication(app, accountId);
                opportunities.add(newOpportunity);
                orderedRecords.add(newOpportunity);
                orderedRecordTypes.add(ApplicationConstants.RECORD_TYPE_OPPORTUNITY);
            }
        }

        if (!leads.isEmpty()) {
            insert leads;
        }
        if (!opportunities.isEmpty()) {
            insert opportunities;
        }

        List<ApplicationResult> results = new List<ApplicationResult>();
        for (Integer i = 0; i < orderedRecords.size(); i++) {
            results.add(
                ApplicationResult.ok(
                    orderedRecordTypes[i],
                    orderedRecords[i].Id,
                    ApplicationConstants.SUCCESS_MESSAGE
                )
            );
        }
        return results;
    }

    private static void resolveMatchingAccounts(
        List<ApplicationDTO> apps,
        Map<String, Id> accountIdsByTaxId,
        Map<String, Id> accountIdsByName
    ) {
        Set<String> taxIds = new Set<String>();
        Set<String> names = new Set<String>();
        for (ApplicationDTO app : apps) {
            if (String.isNotBlank(app.federalTaxId)) {
                taxIds.add(app.federalTaxId);
            } else {
                names.add(app.companyName);
            }
        }

        AccountsSelector selector = new AccountsSelector();
        for (Account matched : selector.selectByFederalTaxIds(taxIds)) {
            if (!accountIdsByTaxId.containsKey(matched.Federal_Tax_Id__c)) {
                accountIdsByTaxId.put(matched.Federal_Tax_Id__c, matched.Id);
            }
        }
        for (Account matched : selector.selectByNames(names)) {
            if (!accountIdsByName.containsKey(matched.Name)) {
                accountIdsByName.put(matched.Name, matched.Id);
            }
        }
    }

    private static void validateAll(List<ApplicationDTO> apps) {
        if (apps == null || apps.isEmpty()) {
            throw new ApplicationException('No application data provided');
        }
        for (ApplicationDTO app : apps) {
            validate(app);
        }
    }

    private static void validate(ApplicationDTO app) {
        if (app == null) {
            throw new ApplicationException('No application data provided');
        }
        List<String> missingFields = new List<String>();
        if (String.isBlank(app.companyName)) {
            missingFields.add('companyName');
        }
        if (String.isBlank(app.firstName)) {
            missingFields.add('firstName');
        }
        if (String.isBlank(app.lastName)) {
            missingFields.add('lastName');
        }
        if (String.isBlank(app.email)) {
            missingFields.add('email');
        }
        if (String.isBlank(app.phone)) {
            missingFields.add('phone');
        }
        if (!missingFields.isEmpty()) {
            throw new ApplicationException('Missing required fields: ' + String.join(missingFields, ', '));
        }
        if (!ApplicationConstants.VALID_SOURCES.contains(app.source)) {
            throw new ApplicationException('Invalid application source');
        }
    }
}
