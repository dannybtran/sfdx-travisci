@RestResource(urlMapping='/UserAuthorization/*')
global with sharing class UserAuthorizationRestResource {
  @HttpGet
  global static void doGet() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    String fedId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
    Map<String, Object> result = new Map<String, Object>();

    /* get user data and permissions */
    User user = [SELECT Id, Name, Email, FederationIdentifier FROM User WHERE FederationIdentifier = :fedId];
    List<PermissionSetAssignment> psets = [SELECT PermissionSet.Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :user.Id];
    List<String> permissions = new List<String>();
    for(PermissionSetAssignment pset : psets) {
      permissions.add(pset.PermissionSet.Name);
    }

    Map<String, Object> organizations = new Map<String, Object>();

    /* get blanket delegate orgs */

    List<Org_To_Org_Relationship__c> dorgs = [
        SELECT Delegator__r.Id,
               Delegator__r.Name,
               Delegator__r.Organization_ID__c,
               Delegator__r.Type__c
        FROM Org_To_Org_Relationship__c
        WHERE Org_To_Org_Relationship__c.Delegate__c IN (
			SELECT Organization__c FROM UserToOrganization__c
            WHERE User__r.Id = :user.Id
        ) AND Delegate_To_All_Users__c = true
    ];
    for(Org_To_Org_Relationship__c dorg : dorgs) {
      Map<String, Object> orgDto = new Map<String, Object>();
      orgDto.put('salesforceId', dorg.Delegator__r.Id);
      orgDto.put('organizationId', dorg.Delegator__r.Organization_ID__c);
      orgDto.put('type', dorg.Delegator__r.Type__c);
      orgDto.put('affiliationType', 'delegate');
      orgDto.put('name', dorg.Delegator__r.Name);
      organizations.put(String.valueOf(dorg.Delegator__r.Id), orgDto);
    }
      
    /* get specific delegate orgs */

    List<Org_To_Org_Relationship__c> sdorgs = [
        SELECT Delegator__r.Id,
               Delegator__r.Name,
               Delegator__r.Organization_ID__c,
               Delegator__r.Type__c
        FROM Org_To_Org_Relationship__c
        WHERE Id IN (
			SELECT Org_To_Org_Relationship__c FROM O2O_Relationship_To_Delegate_User__c
            WHERE User__r.Id = :user.Id
        )
    ];
    for(Org_To_Org_Relationship__c dorg : sdorgs) {
      Map<String, Object> orgDto = new Map<String, Object>();
      orgDto.put('salesforceId', dorg.Delegator__r.Id);
      orgDto.put('organizationId', dorg.Delegator__r.Organization_ID__c);
      orgDto.put('type', dorg.Delegator__r.Type__c);
      orgDto.put('affiliationType', 'delegate');
      orgDto.put('name', dorg.Delegator__r.Name);
      organizations.put(String.valueOf(dorg.Delegator__r.Id), orgDto);
    }      

    /* get direct orgs */

    List<Organization__c> orgs = [
        SELECT Id, Name, Organization_ID__c, Type__c FROM Organization__c WHERE Id IN (
            SELECT Organization__c FROM UserToOrganization__c WHERE UserToOrganization__c.User__r.Id = :user.Id
        )
    ];
    for(Organization__c org : orgs) {
      Map<String, Object> orgDto = new Map<String, Object>();
      orgDto.put('salesforceId', org.Id);
      orgDto.put('organizationId', org.Organization_ID__c);
      orgDto.put('type', org.Type__c);
      orgDto.put('affiliationType', 'direct');
      orgDto.put('name', org.Name);
      organizations.put(String.valueOf(org.Id), orgDto);
    }
   
    result.put('salesforceId', user.Id);
    result.put('federationId', user.FederationIdentifier);
    result.put('name', user.Name);
    result.put('email', user.Email);
    result.put('permissions', permissions);
    result.put('organizations', organizations);

    res.responseBody = Blob.valueOf(JSON.serialize(result));
    res.statusCode = 200;
  }
}