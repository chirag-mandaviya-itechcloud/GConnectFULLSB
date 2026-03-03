@isTest
public class ImageUploaderControllerTest {

    @testSetup
    static void setupData() {
        // Create a sample Application__c record to attach documents to
        Application__c app = new Application__c( First_Name__c = 'Test Client');
        insert app;
    }

    @isTest
    static void testSaveCapturedImages() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        List<String> imageList = new List<String>{
            'data:image/png;base64,' + EncodingUtil.base64Encode(Blob.valueOf('FakeImageData1')),
            'data:image/png;base64,' + EncodingUtil.base64Encode(Blob.valueOf('FakeImageData2'))
        };

        Test.startTest();
        ImageUploaderController.saveCapturedImages(app.Id, imageList);
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :app.Id];
        System.assert(!links.isEmpty(), 'Captured images should be linked');
    }

    @isTest
    static void testSaveProfilePhoto() {
        Application__c app = [SELECT Id, Client_Name__c FROM Application__c LIMIT 1];
        String fakeBase64 = EncodingUtil.base64Encode(Blob.valueOf('ProfilePhotoBytes'));

        Test.startTest();
        ImageUploaderController.saveProfilePhoto(app.Id, fakeBase64, 'png');
        Test.stopTest();

        List<ContentVersion> versions = [
            SELECT Id FROM ContentVersion 
            WHERE Is_Profile_Pic__c = true
        ];
        System.assertEquals(1, versions.size(), 'One profile photo should be saved');
    }

    @isTest
    static void testSaveUploadedFiles() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        String fakeBase64 = EncodingUtil.base64Encode(Blob.valueOf('DocumentContent'));

        Test.startTest();
        ImageUploaderController.saveUplodededFiles(app.Id, 'TestDoc', fakeBase64, 'pdf', 'Other');
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :app.Id];
        System.assert(!links.isEmpty(), 'Uploaded file should be linked');
    }

    @isTest
    static void testUploadChunkedFile_New() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('ChunkedFileData'));

        Test.startTest();
        String contentVersionId = ImageUploaderController.uploadChunkedFile(
            app.Id, 'ChunkedFile', base64Data, 'pdf', 'Other', null, true, null
        );
        Test.stopTest();

        System.assertNotEquals(null, contentVersionId, 'ContentVersion ID should be returned');
    }

    @isTest
    static void testInsertContentVersionList_And_Delete() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        Blob blob1 = Blob.valueOf('Some file data');
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            VersionData = blob1,
            PathOnClient = 'TestDoc.pdf',
            Document_Type__c = 'Other'
        );

        Test.startTest();
        List<ContentVersion> inserted = ImageUploaderController.insertContentVersionList(new List<ContentVersion>{ cv }, app.Id);
        
        ImageUploaderController.deleteExistingDocument(app.Id, 'Other');
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :app.Id];
        System.assertEquals(0, links.size(), 'All links should be deleted');
    }
}