public class OrganizationQueryForUser {
    Id recordId;

    public List<Organization__c> Orgs {get;set;}

    public OrganizationQueryForUser(ApexPages.StandardController controller) {
        recordId = ApexPages.CurrentPage().getParameters().get('id');
        Orgs = [SELECT Id, Name, Type__c FROM Organization__c WHERE Id IN (
            SELECT Organization__c FROM UserToOrganization__c WHERE UserToOrganization__c.User__r.Id = :recordId
        )];
    }
}