public without sharing class ImageUploaderController {
    
    // Method for create the ContentVersion Record of Captured Images \
    @AuraEnabled
    public static void saveCapturedImages(String recordId, List<String> imageDataList) {
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        
        for (String imageData : imageDataList) {
            String base64EncodedData = imageData.substring(imageData.indexOf(',') + 1);
            Blob imageBlob = EncodingUtil.base64Decode(base64EncodedData);
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Captured Image';
            contentVersion.PathOnClient = 'CapturedImage.png';
            contentVersion.VersionData = imageBlob;
            contentVersion.FirstPublishLocationId = recordId;
            contentVersionList.add(contentVersion);
        }
        if(!contentVersionList.isEmpty()){
            insertContentVersionList(contentVersionList,recordId);
        }
    }
    
    @AuraEnabled
    public static String uploadChunkedFile(String parentId, String fileName, String base64Data,
                                           String contentType, String docType,
                                           String uploadSessionId, Boolean isLastChunk, String contentVersionId) 
    {
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        ContentVersion contentVersion = new ContentVersion();
        if (docType == null || docType == '') {
            docType = 'Other';
        }
        
        if (contentVersionId == null) {
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            
            contentVersion.Title = fileName;
            contentVersion.Document_Type__c = docType;
            contentVersion.VersionData = fileBlob;
            contentVersion.PathOnClient = fileName + '.' + contentType;
            contentVersion = insertContentVersionList(new List<ContentVersion>{ contentVersion }, parentId)[0];
        } else {
            ContentVersion existingContentVersion = [SELECT Id,VersionData,ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
            
            Blob fileBlob = EncodingUtil.base64Decode(EncodingUtil.base64Encode(existingContentVersion.VersionData) + base64Data);
            
            contentVersion.Title = fileName;
            contentVersion.Document_Type__c = docType;
            contentVersion.VersionData = fileBlob;
            contentVersion.PathOnClient = fileName + '.' + contentType;
            contentVersion.ContentDocumentId = existingContentVersion.ContentDocumentId;
            
            insert contentVersion;
        }
        return contentVersion.Id;
    }
    
    
    // Method for create the ContentVersion Record for uploded files 
    @AuraEnabled
    public static void saveUplodededFiles(String parentId, String fileName, 
                                          String base64Data, String contentType, String docType)
    {
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        if(docType!= 'DSP Upload' && docType!= 'Incident' && docType!= 'Deduction'){
            deleteExistingDocument(parentId, docType);
        }
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        if(docType == null || docType == ''){
            docType = 'Other';
        }
        if (fileBlob != null) {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName; 
            contentVersion.Document_Type__c = docType; 
            contentVersion.VersionData = fileBlob;
            contentVersion.PathOnClient = fileName+'.'+contentType; 
            contentVersionList.add(contentVersion);
        }
        if(!contentVersionList.isEmpty()){
            insertContentVersionList(contentVersionList,parentId);
        }
        
    }
    
    // Method for create the ContentVersion Record for Profile Photo 
    @AuraEnabled
    public static void saveProfilePhoto(String recordId, String base64Data, String contentType) {
        
        deleteExistingDocument(recordId, null);
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<Application__c> appDetails = [SELECT Id, Name, Client_Name__c FROM Application__c WHERE Id =:recordId LIMIT 1 ];
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        if (fileBlob != null) {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = appDetails[0].Client_Name__c+'_Profile_Photo'; 
            contentVersion.VersionData = fileBlob;
            contentVersion.PathOnClient = appDetails[0].Client_Name__c+'_Profile_Photo.'+ contentType; 
            contentVersion.Document_Type__c = 'Profile Picture';
            contentVersion.Is_Profile_Pic__c = true;
            contentVersionList.add(contentVersion);
        }
        if(!contentVersionList.isEmpty()){
            insertContentVersionList(contentVersionList,recordId);
        }
        
    }
    
    @AuraEnabled
    public static void deleteExistingDocument(String recordId, String docType) {
        // 1. Fetch linked ContentDocumentIds
        List<ContentDocumentLink> docLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
        
        if (docLinks.isEmpty()) return;
        
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            contentDocIds.add(link.ContentDocumentId);
        }
        List<ContentVersion> matchedVersions = new List<ContentVersion>();
        if(docType != null){
            matchedVersions = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocIds
                AND Document_Type__c = :docType
            ];
        }else{
            matchedVersions = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocIds
                AND Is_Profile_Pic__c = true
            ];
        }
        
        System.debug('matchedVersions: ' + matchedVersions);
        if (matchedVersions.isEmpty()) return;
        
        Set<Id> targetDocIds = new Set<Id>();
        for (ContentVersion v : matchedVersions) {
            targetDocIds.add(v.ContentDocumentId);
        }
        
        // 3. Delete matching ContentDocumentLinks
        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
        for (ContentDocumentLink link : docLinks) {
            if (targetDocIds.contains(link.ContentDocumentId)) {
                linksToDelete.add(link);
            }
        }
        if (!linksToDelete.isEmpty()) {
            delete linksToDelete;
        }
        
        // 4. Delete ContentDocuments (which deletes all their versions)
        List<ContentDocument> docsToDelete = [
            SELECT Id FROM ContentDocument WHERE Id IN :targetDocIds
        ];
        if (!docsToDelete.isEmpty()) {
            List<Delete_Document_On_Verification__e> events = new List<Delete_Document_On_Verification__e>();
            
            for (ContentDocument doc : docsToDelete) {
                events.add(new Delete_Document_On_Verification__e(Content_Document_ID__c = doc.Id ));
            }

            if (!events.isEmpty()) {
                EventBus.publish(events);
            }
            //delete docsToDelete;
        }
    }
    
    // Insert ContentVersion Records and based on that get the CDI and create the CDL data
    public static List<ContentVersion> insertContentVersionList(List<ContentVersion> contentVersionList , String recordId){
        
        List<ContentVersion> insertedContentVersionList = new List<ContentVersion>();
        List<String> errorMessages = new List<String>();
        Set<Id> contentDocIdSet = new Set<Id>();
        if(!contentVersionList.isEmpty()){
            Database.SaveResult[] saveResults = Database.insert(contentVersionList, false);
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    insertedContentVersionList.add(contentVersionList[i]);
                    System.debug('Successfully inserted ContentVersion with ID: ' + saveResults[i].getId());
                } else {
                    System.debug('Failed to insert ContentVersion.');
                }
            }
        }
        if(!insertedContentVersionList.isEmpty()){
            contentDocIdSet = getContentDocumentIds(insertedContentVersionList);
        }
        if(!contentDocIdSet.isEmpty()){
            createContentDocumentLinkRecords(contentDocIdSet, recordId);
        }
        
        return insertedContentVersionList;
    }
    
    //Get the newly created ContentDocumentId records
    public static Set<Id> getContentDocumentIds(List<ContentVersion> insertedContentVersionList){
        Set<Id> newSetContentDocIds = new Set<Id>();
        Set<Id> setInsertedCV = new Set<Id>();
        List<ContentVersion> insertedCVList = new List<ContentVersion>();
        if(!insertedContentVersionList.isEmpty()){
            for (ContentVersion cvRec : insertedContentVersionList) {
                setInsertedCV.add(cvRec.Id);
            }
            if(!setInsertedCV.isEmpty()){
                insertedCVList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :setInsertedCV];
                if(!insertedCVList.isEmpty()){
                    for(ContentVersion cv: insertedCVList){
                        newSetContentDocIds.add(cv.ContentDocumentId);
                    }
                }
            }
        }
        return newSetContentDocIds;
    }
    
    //Create ContentDocumentLink Records
    public static void createContentDocumentLinkRecords(Set<Id> setContentDocumentIds, String recordId){
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        
        List<ContentDocumentLink> existingLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId AND ContentDocumentId IN :setContentDocumentIds];
        Set<Id> existingContentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : existingLinks) {
            existingContentDocumentIds.add(cdl.ContentDocumentId);
        }
        
        
        if(!setContentDocumentIds.isEmpty()){
            for (Id contentDocumentId : setContentDocumentIds) {
                if (!existingContentDocumentIds.contains(contentDocumentId)) {
                    ContentDocumentLink cDocRec = new ContentDocumentLink();
                    cDocRec.ContentDocumentId = contentDocumentId;
                    cDocRec.LinkedEntityId = recordId;
                    cDocRec.ShareType = 'V';
                    cDocRec.Visibility = 'AllUsers';
                    contentDocumentLinkList.add(cDocRec);
                }
            }
            if (!contentDocumentLinkList.isEmpty()) {
                insert contentDocumentLinkList;
            }           
        }
    }
    
}