public with sharing class ESignLiveRESTAPIHelper
{
    @TestVisible
    private e_SignLive_Connection_Settings__c connectionSettings{get;set;}

    /**
     * Constructor - sets the connection settings used for connecting to eSignLive
     */
    public ESignLiveRESTAPIHelper()
    {
        setSettings();
    }

    /**
     * Method to get the sessionId
     */
    public String getSessionId()
    {
        String sessionId;
        HttpResponse response = doPost('/authenticationTokens', '');

        // Check response
        if(response.getStatusCode() == 200)
        {
            try
            {
                ESignLiveAPIObjects.Authentication authentication = (ESignLiveAPIObjects.Authentication)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Authentication.class);
                sessionId = authentication.value;
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error authenticating to eSignLive: ' + e.getMessage());
            }
        } 
        else 
        {
            throw new ESignLiveRestAPIHelperException('Error authenticating to eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return sessionId;
    }

    /**
     * Method to create a template or a document package from an existing document package.
     */
    public ESignLiveAPIObjects.Package_x createPackageFromTemplate(ESignLiveAPIObjects.Package_x packageSettings, String packageIdToClone)
    {
        String requestBody = JSON.serialize(packageSettings);
        HttpResponse response = doPost('/packages/' + packageIdToClone + '/clone', requestBody);

        // Check response
        ESignLiveAPIObjects.Package_x packageResponse = new ESignLiveAPIObjects.Package_x();
        if(response.getStatusCode() == 200)
        {
            try
            {
                packageResponse = (ESignLiveAPIObjects.Package_x)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Package_x.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error cloning template or package with eSignLive: ' + e.getMessage());
            }
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error cloning template or package with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return packageResponse;
    }

    /**
     * Method to update the information of a document package
     */
    public void updatePackage(ESignLiveAPIObjects.Package_x packageSettings, String packageId)
    {
        String requestBody = JSON.serialize(packageSettings);
        HttpResponse response = doPut('/packages/' + packageId, requestBody);

        // Check response
        if(response.getStatusCode() == 200)
        {
            // No action
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error updating package with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());   
        }
    }

    /**
     * Method to get the package signing status
     */
    public String getPackageSigningStatus(String packageId)
    {
        // Send Request
        String resourceUrl = '/packages/' + packageId + '/signingStatus';
        HttpResponse response = doGet(resourceUrl);

        // Check response
        ESignLiveAPIObjects.Package_x packageStatus;
        if(response.getStatusCode() == 200)
        {   
            try
            {
                packageStatus = (ESignLiveAPIObjects.Package_x)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Package_x.class);
            }
            catch(Exception e)
            {
                System.debug(e.getStackTraceString());
                throw new ESignLiveRestAPIHelperException('Error getting eSignLive package signing status: ' + response.getStatusCode() + ' - ' + response.getStatus());
            }
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error getting eSignLive package signing status: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        return packageStatus.status.name();
    }

    /**
     * Method to delete a package
     */
    public String deletePackage(String packageId)
    {
        HttpResponse response = doDelete('/packages/' + packageId);

        // Check response
        if(response.getStatusCode() == 200)
        {
            // No action
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error deleting package with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());   
        }
        return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * Method to get the signing Url of a package
     */
    public ESignLiveAPIObjects.SigningUrl getSigningUrl(String packageId, String signerId)
    {
        // Send Request
        String resourceUrl = '/packages/' + packageId + '/roles/' + signerId + '/signingUrl';
        HttpResponse response = doGet(resourceUrl);

        // Check response
        ESignLiveAPIObjects.SigningUrl signingUrl;
        if(response.getStatusCode() == 200)
        {
            try
            {
                signingUrl = (ESignLiveAPIObjects.SigningUrl)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.SigningUrl.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error obtaining eSignLive signing Url: ' + e.getMessage());
            }
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error obtaining eSignLive signing Url: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        
        return signingUrl;
    }

    /**
     * Method to get the Document Blob for the Package Id and Document Id passed.
     */
    public Blob getSignedDocument(String packageId, String docId)
    {
        // Send Request
        String resourceUrl = '/packages/' + packageId + '/documents/' + docId + '/pdf';
        HttpResponse response = doGet(resourceUrl);

        // Check response
        Blob signedDocument;
        if(response.getStatusCode() == 200)
        {
            try
            {
                signedDocument = response.getBodyAsBlob();
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error obtaining signed eSignLive document: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error obtaining signed eSignLive document: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return signedDocument;
    }

    /**
     * Method that adds the Signature for the Package Id, Document Id, and Approval passed.
     */
    public ESignLiveAPIObjects.Approval createApproval(String packageId, String documentId, ESignLiveAPIObjects.Approval approval)
    {
        String requestBody = JSON.serialize(approval);
        System.debug('=> requestBody for createApproval:'+requestBody);

        // Send Request
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId + '/approvals';
        HttpResponse response = doPost(resourceUrl, requestBody);

        // Check response
        ESignLiveAPIObjects.Approval approvalResponse;
        if(response.getStatusCode() == 200)
        {
            try
            {
                approvalResponse = (ESignLiveAPIObjects.Approval)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Approval.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating eSignLive signer: ' + e.getMessage());
            }
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating eSignLive signer: ' + response.getStatusCode() + ' - ' + response.getStatus());  
        }

        return approvalResponse;
    }

    /**
     * Method that adds the Signature for the Package Id, Document Id, and Approval passed.
     */
    public ESignLiveAPIObjects.Approval getApproval(String packageId, String documentId, String approvalId)
    {
        // Send Request
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId;
        HttpResponse response = doGet(resourceUrl);

        // Check response
        ESignLiveAPIObjects.Approval approvalResponse;
        if(response.getStatusCode() == 200)
        {
            try
            {
                approvalResponse = (ESignLiveAPIObjects.Approval)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Approval.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating eSignLive signer: ' + e.getMessage());
            }
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating eSignLive signer: ' + response.getStatusCode() + ' - ' + response.getStatus());  
        }

        return approvalResponse;
    }

    /**
     * Method that adds the Signature for the Package Id, Document Id, and Approval passed.
     */
    public String updateApproval(String packageId, String documentId, String approvalId, ESignLiveAPIObjects.Approval approval)
    {   
        String requestBody = JSON.serialize(approval);
        // Send Request
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId;
        HttpResponse response = doPut(resourceUrl, requestBody);

        // Check response
        ESignLiveAPIObjects.Approval approvalResponse;
        if(response.getStatusCode() == 200)
        {
            try
            {
                approvalResponse = (ESignLiveAPIObjects.Approval)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Approval.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating eSignLive signer: ' + e.getMessage());
            }
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating eSignLive signer: ' + response.getStatusCode() + ' - ' + response.getStatus());  
        }

         return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * Method to delete a package
     */
    public String deleteApproval(String packageId, String documentId, String approvalId)
    {
        HttpResponse response = doDelete('/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId);

        // Check response
        if(response.getStatusCode() == 200)
        {
            // No action
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error deleting package with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());   
        }
        return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * This method gets the Audit Trail of the package.  The Audit Trail will be empty
     * for packages not sent yet.
     */
    public String getAuditTrail(String packageId)
    {
        String resourceUrl = '/packages/' + packageId + '/evidence/summary';
        String evidenceSummary;

        HttpResponse response = doGet(resourceUrl);

        if(response.getStatusCode() == 200)
        {
            try
            {
                evidenceSummary = EncodingUtil.base64Encode(response.getBodyAsBlob());
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error obtaining the Audit Trail: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error obtaining the Audit Trail: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        return evidenceSummary;
    }

    /**
     * Method to get the zip file of the signer attachments for a particular signer. 
     */
    public String getSignerAttachments(String packageId, String roleId)
    {
        // Send Request
        String resourceUrl = '/packages/' + packageId + '/attachment/zip/'+roleId;
        HttpResponse response = doGet(resourceUrl);

        // Check response
        String signerAttachmentZip;
        if(response.getStatusCode() == 200)
        {
            try
            {
                if(response.getBodyAsBlob() != null)
                {
                    signerAttachmentZip = EncodingUtil.base64Encode(response.getBodyAsBlob());
                }
                else
                {
                    throw new ESignLiveRestAPIHelperException('No attachments found for the role.');       
                }
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error obtaining the Attachments for the role: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error obtaining the Attachments for the role: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return signerAttachmentZip;
    }


    /**
     * Method to create a role. 
     */
    public String createRole(String packageId, ESignLiveAPIObjects.Role signer)
    {
        ESignLiveAPIObjects.Role role;
        String resourceUrl = '/packages/' + packageId + '/roles/';

        //Serialize the Role object
        String reqBody = JSON.serialize(signer); 

        HttpResponse response = doPost(resourceUrl,reqBody);

        if(response.getStatusCode() == 200)
        {
            try
            {
                role = (ESignLiveAPIObjects.Role)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Role.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating the Role: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating the Role: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        return JSON.serialize(role);
    }

    /**
     * Method to reassign a role. 
     */
    public String reassignRole(String packageId, String roleId, ESignLiveAPIObjects.Role signer)
    {
        ESignLiveAPIObjects.Role role;
        String resourceUrl = '/packages/' + packageId + '/roles/' + roleId + '/reassign';

        //Serialize the Role object
        String reqBody = JSON.serialize(signer); 

        HttpResponse response = doPost(resourceUrl,reqBody);

        if(response.getStatusCode() == 200)
        {
            try
            {
                role = (ESignLiveAPIObjects.Role)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Role.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error reassigning the Role: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error reassigning the Role: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return JSON.serialize(role);
    }


    /**
     * Method to get a role 
     */
    public ESignLiveAPIObjects.Role getRole(String packageId, String roleId)
    {
        ESignLiveAPIObjects.Role role;
        String resourceUrl = '/packages/' + packageId + '/roles/' + roleId;

        HttpResponse response = doGet(resourceUrl);

        if(response.getStatusCode() == 200)
        {
            try
            {
                role = (ESignLiveAPIObjects.Role)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Role.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error getting the Role: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error getting the Role: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return role;
    }

    /**
     * This method sets the signer/role authentication mechanism to Email(NONE), Q/A(CHALLENGE) and SMS(SMS) 
     * based on the inputs provided.
     */
    public String updateRole(String packageId, String roleId, ESignLiveAPIObjects.Role signer)
    {
        String resourceUrl = '/packages/' + packageId + '/roles/' + roleId;
        HttpResponse res = new HttpResponse();
        try
        {
            String reqBody = JSON.serialize(signer); 

            // Put the new Role object
            res = doPut(resourceUrl, reqBody);
        }
        catch(Exception e)
        {
            throw new ESignLiveRestAPIHelperException('Error updating the Role: ' + e.getMessage());
        }

        return res.getStatusCode() + ' - ' + res.getStatus();
    }

    /**
     * This method sets the signer/role authentication mechanism to Email(NONE), Q/A(CHALLENGE) and SMS(SMS) 
     * based on the inputs provided.
     */
    public String deleteRole(String packageId, String roleId)
    {
        HttpResponse response = doDelete('/packages/' + packageId + '/roles/' + roleId);

        // Check response
        if(response.getStatusCode() == 200)
        {
            // No action
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error deleting Role with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());   
        }
        return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * Method to create a Field. 
     */
    public String createField(String packageId, String documentId, String approvalId, ESignLiveAPIObjects.Field fieldToCreate)
    {
        ESignLiveAPIObjects.Field field;
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId + '/fields';

        //Serialize the Role object
        String reqBody = JSON.serialize(fieldToCreate); 

        HttpResponse response = doPost(resourceUrl,reqBody);

        if(response.getStatusCode() == 200)
        {
            try
            {
                field = (ESignLiveAPIObjects.Field)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Field.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating the Field: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating the Field: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        return JSON.serialize(field);
    }

    /**
     * Method to get a Field 
     */
    public ESignLiveAPIObjects.Field getField(String packageId, String documentId, String approvalId, String fieldId)
    {
        ESignLiveAPIObjects.Field field;
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId + '/fields/' + fieldId;

        HttpResponse response = doGet(resourceUrl);

        if(response.getStatusCode() == 200)
        {
            try
            {
                field = (ESignLiveAPIObjects.Field)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Field.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error getting the Field: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error getting the Field: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return field;
    }

    /**
     * Method to update a field
     */
    public String updateField(String packageId, String documentId, String approvalId, String fieldId, ESignLiveAPIObjects.Field fieldToUpdate)
    {
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId + '/fields/' + fieldId;
        HttpResponse res = new HttpResponse();
        try
        {
            String reqBody = JSON.serialize(fieldToUpdate); 

            // Put the new Role object
            res = doPut(resourceUrl, reqBody);
        }
        catch(Exception e)
        {
            throw new ESignLiveRestAPIHelperException('Error updating the Field: ' + e.getMessage());
        }

        return res.getStatusCode() + ' - ' + res.getStatus();
    }

    /**
     * Method to delete a field
     */
    public String deleteField(String packageId, String documentId, String approvalId, String fieldId)
    {
        HttpResponse response = doDelete('/packages/' + packageId + '/documents/' + documentId + '/approvals/' + approvalId + '/fields/' + fieldId);

        // Check response
        if(response.getStatusCode() == 200)
        {
            // No action
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error deleting Field with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());   
        }
        return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * This method sets the signer/field authentication mechanism to Email(NONE), Q/A(CHALLENGE) and SMS(SMS) 
     * based on the inputs provided.
     */
    public String updateDocument(String packageId, String documentId, ESignLiveAPIObjects.Document doc)
    {
        String resourceUrl = '/packages/' + packageId + '/documents/' + documentId;
        HttpResponse res = new HttpResponse();
        try
        {
            String reqBody = JSON.serialize(doc); 

            // Put the new Role object
            res = doPut(resourceUrl, reqBody);
        }
        catch(Exception e)
        {
            throw new ESignLiveRestAPIHelperException('Error updating the Role: ' + e.getMessage());
        }

        return res.getStatusCode() + ' - ' + res.getStatus();
    }

    /**
     * Method to delete a package
     */
    public String deleteDocument(String packageId, String documentId)
    {
        HttpResponse response = doDelete('/packages/' + packageId + '/documents/' + documentId);

        // Check response
        if(response.getStatusCode() == 200)
        {
            // No action
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error deleting package with eSignLive: ' + response.getStatusCode() + ' - ' + response.getStatus());   
        }
        return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * Method to create a package with document binaries     
     */
    public String createPackageWithBinaries(Blob multipartFormData)
    {
        String resourceUrl = '/packages/' ;
        String packageId;

        HttpResponse response = doPost(resourceUrl, multipartFormData);

        if(response.getStatusCode() == 200)
        {
            try
            {
                ESignLiveAPIObjects.Package_x packageResponse = (ESignLiveAPIObjects.Package_x)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Package_x.class);
                packageId = packageResponse.id;
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating eSignLive package with documents: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating eSignLive package with documents: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return packageId;
    }

    /**
     * Method to create documents for an existing package.
     */
    public String createDocumentsWithBinaries(String packageId, Blob multipartFormData)
    {
        String resourceUrl = '/packages/'+packageId+'/documents' ;
        HttpResponse response = doPost(resourceUrl, multipartFormData);

        List<ESignLiveAPIObjects.Document> documentResponse = new List<ESignLiveAPIObjects.Document>();

        if(response.getStatusCode() == 200)
        {
            try
            {
                documentResponse = (List<ESignLiveAPIObjects.Document>)JSON.deserialize(response.getBody(), List<ESignLiveAPIObjects.Document>.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating eSignLive package with documents: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating eSignLive package with documents: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return JSON.serialize(documentResponse);
    }

    /**
     * Method to create a package with the information provided. 
     */
    public String createPackage(ESignLiveAPIObjects.Package_x pkg)
    {
        String requestBody = JSON.serialize(pkg);
        String resourceUrl = '/packages/' ;
        String packageId;

        HttpResponse response = doPost(resourceUrl, requestBody);

        if(response.getStatusCode() == 200)
        {
            try
            {
                ESignLiveAPIObjects.Package_x packageResponse = (ESignLiveAPIObjects.Package_x)JSON.deserialize(response.getBody(), ESignLiveAPIObjects.Package_x.class);
                packageId = packageResponse.id;
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error creating eSignLive package: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error creating eSignLive package: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return packageId;
    }

    /**
     * This method gets the Package for the given package id. 
     */
    public ESignLiveAPIObjects.Package_x getPackage(String packageId)
    {
        ESignLiveAPIObjects.Package_x pkg;

        String resourceUrl = '/packages/' + packageId;

        HttpResponse response = doGet(resourceUrl);

        if(response.getStatusCode() == 200)
        {            
            String inboundResponseBody = ESignLiveJSONHelper.prepareInboundJSON(response.getBody());            

            try
            {
                pkg = (ESignLiveAPIObjects.Package_x)JSON.deserialize(inboundResponseBody, ESignLiveAPIObjects.Package_x.class);
            }
            catch(Exception e)
            {
                throw new ESignLiveRestAPIHelperException('Error getting the Package: ' + e.getMessage());
            }
        }   
        else
        {
            throw new ESignLiveRestAPIHelperException('Error getting the Package: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return pkg;
    }

    /**
     * Method to update a package status.
     */
    public String updatePackageStatus(String packageId, ESignLiveAPIObjects.PackageStatus status)
    {
        ESignLiveAPIObjects.Package_x pkg = new ESignLiveAPIObjects.Package_x();
        String resourceUrl = '/packages/' + packageId;

        pkg.status = status;

        String requestBody = JSON.serialize(pkg);

        HttpResponse response = doPut(resourceUrl, requestBody);

        if(response.getStatusCode() == 200)
        {
            //do nothing
        }
        else
        {
            throw new ESignLiveRestAPIHelperException('Error updating eSignLive package status: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }

        return response.getStatusCode() + ' - ' + response.getStatus();
    }

    /**
     * Utility method to handle POST callouts
     */
    private HttpResponse doPost(String resourceUrl, String requestBody)
    {
        //Cleanup requestBody string before sending it out
        String outboundRequestBody = ESignLiveJSONHelper.prepareOutboundJSON(requestBody);
        System.debug('=> outboundRequestBody:'+outboundRequestBody);

        // Build Request
        HttpRequest request = new HttpRequest();

        request.setEndpoint(connectionSettings.Endpoint__c + resourceUrl);
        request.setBody(outboundRequestBody);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Basic ' + connectionSettings.API_Key__c);
        request.setHeader('Content-type', 'application/json');
        request.setHeader('Accept', 'application/json');

        // Send Request
        HttpResponse response = (new Http()).send(request);

        return response;
    }

    /**
     * Utility method to handle POST callouts for blobs
     */
    private HttpResponse doPost(String resourceUrl, Blob requestBody)
    {
        // Build Request
        HttpRequest req = new HttpRequest();

        req.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundary1bNO60n7FqP5WO4t');
        req.setMethod('POST');
        req.setEndpoint(connectionSettings.Endpoint__c + resourceUrl);
        req.setBodyAsBlob(requestBody);
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Basic ' + connectionSettings.API_Key__c);
        req.setHeader('Content-Length',String.valueof(req.getBodyAsBlob().size()));

        Http http = new Http();
        HTTPResponse res;

        // Send Request
        res = http.send(req);

        return res;
    }

    /**
     * Utility method to handle PUT callouts
     */
    private HttpResponse doPut(String resourceUrl, String requestBody)
    {
        String outboundRequestBody = ESignLiveJSONHelper.prepareOutboundJSON(requestBody);
        System.debug('=> Put Request Body after cleanup: ' + outboundRequestBody);

        // Build Request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(connectionSettings.Endpoint__c + resourceUrl);
        request.setBody(outboundRequestBody);
        request.setMethod('PUT');
        request.setHeader('Authorization', 'Basic ' + connectionSettings.API_Key__c);
        request.setHeader('Content-type', 'application/json');
        request.setHeader('Accept', 'application/json');

        // Send Request
        HttpResponse response = (new Http()).send(request);
        
        return response;
    }

    /**
     * Utility method to handle GET callouts
     */
    private HttpResponse doGet(String resourceUrl)
    {
        // Build Request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(connectionSettings.Endpoint__c + resourceUrl);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Basic ' + connectionSettings.API_Key__c);
        request.setHeader('Content-type', 'application/json');

        // Send Request
        HttpResponse response = (new Http()).send(request);

        if(response != null && (response.getHeader('Content-Type')).contains('json'))
        {
            System.debug('=> Formating for JSON response');
            // Format responseBody string before returning
            String inboundResponseBody = ESignLiveJSONHelper.prepareInboundJSON(response.getBody());
            response.setBody(inboundResponseBody);
        }

        return response;
    }

    /**
     * Utility method to handle DELETE callouts
     */
    private HttpResponse doDelete(String resourceUrl)
    {
        // Build Request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(connectionSettings.Endpoint__c + resourceUrl);
        request.setMethod('DELETE');
        request.setHeader('Authorization', 'Basic ' + connectionSettings.API_Key__c);
        request.setHeader('Content-type', 'application/json');

        // Send Request
        HttpResponse response = (new Http()).send(request);

        //Format responseBody string before returning
        String inboundResponseBody = ESignLiveJSONHelper.prepareInboundJSON(response.getBody());
        response.setBody(inboundResponseBody);
       
        return response;
    }

    /**
     * Method to set connection settings to memory
     */
    private void setSettings()
    {
        try
        {
            connectionSettings = e_SignLive_Connection_Settings__c.getInstance('Main');    
        }
        catch(Exception e)
        {            
            throw new ESignLiveRestAPIHelperException(
                    'Error in retrieving the eSignLive Custom Settings. Please verify you have the below set up:\n '
                +   'Custom Setting API Name: e_SignLive_Connection_Settings__c, Custom Setting Record Name: Main');
        }
    }

    public class ESignLiveRestAPIHelperException extends Exception{}
}