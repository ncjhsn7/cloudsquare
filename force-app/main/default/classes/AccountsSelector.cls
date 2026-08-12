public inherited sharing class AccountsSelector {

    public List<Account> selectByFederalTaxIds(Set<String> federalTaxIds) {
        if (federalTaxIds.isEmpty()) {
            return new List<Account>();
        }
        return [
            SELECT Id, Name, Federal_Tax_Id__c
            FROM Account
            WHERE Federal_Tax_Id__c IN :federalTaxIds
        ];
    }

    public List<Account> selectByNames(Set<String> names) {
        if (names.isEmpty()) {
            return new List<Account>();
        }
        return [
            SELECT Id, Name, Federal_Tax_Id__c
            FROM Account
            WHERE Name IN :names
        ];
    }
}
