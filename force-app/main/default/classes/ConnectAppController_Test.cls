@isTest
public class ConnectAppController_Test {
    
    @isTest
    Public static void verifyAccount(){
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Include_in_vat__c = true;
        acc.EncryptedKey__c = 'testEncryptedKey';
        acc.GDPR_Statement__c = true;
        acc.Sign_Offers_News__c = true;
        insert acc;
        
        
        Contact con = new Contact(LastName = 'Test Contact ' );
        insert con;
        
        Test.startTest();
        
        String result = ConnectAppController.verifyAccount(acc.EncryptedKey__c);
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        
        Test.stopTest();
    }
    
    @isTest
    Public static void getSubContractorDetails(){
        
        RecordType clientRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Client' AND IsActive = true LIMIT 1];
        RecordType mcRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Main_Contractor' AND IsActive = true LIMIT 1];
        RecordType euRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'End_User' AND IsActive = true LIMIT 1];
        
        aed0n7__Tax_Legislation__c   taxleg = new aed0n7__Tax_Legislation__c();
        taxleg.Name = 'test tax';
        taxleg.aed0n7__Short_Code__c = 'test';
        
        insert taxleg;
        
        Account mcAccount = new Account();
        mcAccount.Name = 'mc test';
        mcAccount.RecordTypeId = mcRecordType.Id;
        insert mcAccount;
        
        // Create an End User Account
        Account endUserAccount = new Account();
        endUserAccount.Name = 'End User 1 test';
        endUserAccount.RecordTypeId = euRecordType.Id;
        insert endUserAccount;
        
        Account clientAcc = new Account();
        clientAcc.Name = 'test testing';
        clientAcc.Email__c = 'test@gmail.com';
        clientAcc.Last_Confirmed_Stage__c = 'Sign Up';
        clientAcc.First_Name__c = 'test';
        clientAcc.Last_Name__c = 'testing';
        clientAcc.Phone = '+442345643245';
        clientAcc.Email__c = 'test@gmail.com';
        clientAcc.RecordTypeId = clientRecordType.Id;
        clientAcc.Main_Contractor__c = mcAccount.Id;
        insert clientAcc;
        
        // Create Contact linked to Account
        Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = mcAccount.Id, Email = 'test@example.com');
        insert con;
        
        
        aed0n7__Company__c   company = new aed0n7__Company__c  ();
            company.Name = 'test company';
            company.aed0n7__Financial_Year_Start_Date__c = Date.today();
            company.aed0n7__Financial_Year_End_Date__c = Date.today().addDays(10);
            company.aed0n7__VAT_Registration_Number__c = 'test111';
            company.aed0n7__VAT_Period_covered_by_the_return__c = 'Monthly';
            company.aed0n7__Tax_Legislation__c = taxleg.Id;
            insert company;
            
            // Create a depot record
            aed0n7__Analysis_1__c depot = new aed0n7__Analysis_1__c(Name = 'Depot 1', Main_Contractor__c = mcAccount.Id,aed0n7__Company__c = company.Id);
            insert depot;
            
            Application__c app = new Application__c();
            app.Last_Confirmed_Stage__c = 'Sign Up';
            app.First_Name__c = 'test';
            app.Last_Name__c = 'testing';
            app.Phone__c = '+442345643245';
            app.Email__c = 'test@gmail.com';
            app.SC_Status__c = 'Engaged';
        	app.EncryptedKey__c = 'dgdfgbfgbfcbhfgb';
            app.Main_Contractor__c = mcAccount.Id;
            app.Gconnect_Account__c = clientAcc.Id;
            insert app;
            
            Associate__c acc = new Associate__c();
            acc.Application__c = app.Id;
            acc.Depot__c = depot.Id;
            acc.End_User__c = endUserAccount.Id;
            insert acc;

        String jsonString = '{"GDPRStatement":true,"signOffersNews":true,"signUpEmail":"test@gmail.com","lastConfirmStage": "Service Plan","encryptedKey":"dgdfgbfgbfcbhfgb","confirmBasicDetails":{},"confirmAddressDetails":{"nationalInsNumber":"AA654661A","dateOfBirth":"2003-04-17","addressLine1":"Sapna society","town":"Andalusia","country":"United States","addressLine2":"343","postCode":"456789","dateSCMoved":"2024-05-09","previousAddressLine1":"Sapna society","previousAddressLine2":"101","previousTown":"Andalusia","previousCountry":"jij","previousPostCode":"457896"},"confirmGovtGatewayDetails":{"uniqueTaxRefNumber":"Yes","VATNumber":"Yes","KnowGovtGatewayDetails":"Yes","govtGatewayUsername":"jkh","URTNumberEntry":"klok","VATNumberEntry":"klklo","govtGatewayPassword":"soha@101"},"selectedProduct":"","selectedAddOnProduct":"","confirmBankDetails":{"bankAccountName":"iuhy","bankAccountNo":"788","sortCode":"789"} '
           + ',"confirmRightToWorkDetails":{"Citizenship_Immigration_status__c":"Rest Of The World","Biometric_Evidence__c":"No","Access_Code__c":"123456","Date_of_Entry__c":"27/07/2024","Settled_Status__c":"Settled Status","Right_to_work_document__c":"Other"}'
            + ',"confirmEmergancyContactDetails":{"Emergency_Contact_Name__c":"Cn","Emergency_Contact_Relationship__c":"aa","Emergency_Contract_Telephone_Number__c":"+44999999999"}'
          + ',"confirmDrivingLicenseDetails":{"Driving_Licence_Number__c":"TN99 2019 00 00 999","Points_on_Licence__c":"Lorem","Driving_Licence_Expiry_Date__c":"11/07/2024","Type_of_licence__c":"Full UK Licence – Additional Categories","Additional_licence_categories__c":"D"}}';

        
        Test.startTest();
        String result = ConnectAppController.getSubContractorDetails(app.Email__c, app.EncryptedKey__c);
        ConnectAppController.updateDetails(jsonString);
        Test.stopTest();
    }
       
     @isTest
     static void PrefferLanguage() {
        
		Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Preffered_Language__c = 'English';
        acc.Nationality1__c = 'India';
        insert acc;
         
         
        Contact con = new Contact(LastName = 'Test Contact ' );
        insert con;
        
        Test.startTest();
        String prefferedLanguagesJson = ConnectAppController.prefferLanguage();
        String nationalityJson = ConnectAppController.nationality();
        // Map<String, Object> resultMap = ConnectAppController.getAutoSettingFlags(); 
        Test.stopTest();
        
        List<String> prefferedLanguagesList = (List<String>) JSON.deserialize(prefferedLanguagesJson, List<String>.class);
        List<String> nationalityList = (List<String>) JSON.deserialize(nationalityJson, List<String>.class);
      
    }
    
    @isTest
    static void testUpdateDetails() {
        ConnectAppController.ConfirmDetailsWrapper detailsWrapper = new ConnectAppController.ConfirmDetailsWrapper();
        
        String outputMap = JSON.serialize(detailsWrapper);

        Account acc = new Account(
            Name = 'Test Account',
            SC_Status__c = 'Onboarding',
            EncryptedKey__c = 'MDAxMjYwMDAwMkdqajJRQUFSXzIwMjQtMDMtMTkgMTE6MTg6MDU=',
            Email__c = 'jay121@yopmail.com'
        );
        insert acc;
        
        
        Contact con = new Contact(LastName = 'Test Contact ' );
        insert con;
        
        String jsonString = '{"GDPRStatement":true,"signOffersNews":true,"signUpEmail":"jay121@yopmail.com","lastConfirmStage": "Service Plan","encryptedKey":"MDAxMjYwMDAwMkdqajJRQUFSXzIwMjQtMDMtMTkgMTE6MTg6MDU=","confirmBasicDetails":{},"confirmAddressDetails":{"nationalInsNumber":"AA654661A","dateOfBirth":"2003-04-17","addressLine1":"Sapna society","town":"Andalusia","country":"United States","addressLine2":"343","postCode":"456789","dateSCMoved":"2024-05-09","previousAddressLine1":"Sapna society","previousAddressLine2":"101","previousTown":"Andalusia","previousCountry":"jij","previousPostCode":"457896"},"confirmGovtGatewayDetails":{"uniqueTaxRefNumber":"Yes","VATNumber":"Yes","KnowGovtGatewayDetails":"Yes","govtGatewayUsername":"jkh","URTNumberEntry":"klok","VATNumberEntry":"klklo","govtGatewayPassword":"soha@101"},"selectedProduct":"","selectedAddOnProduct":"","confirmBankDetails":{"bankAccountName":"iuhy","bankAccountNo":"788","sortCode":"789"} '
           + ',"confirmRightToWorkDetails":{"Citizenship_Immigration_status__c":"Rest Of The World","Biometric_Evidence__c":"No","Access_Code__c":"123456","Date_of_Entry__c":"27/07/2024","Settled_Status__c":"Settled Status","Right_to_work_document__c":"Other"}'
            + ',"confirmEmergancyContactDetails":{"Emergency_Contact_Name__c":"Cn","Emergency_Contact_Relationship__c":"aa","Emergency_Contract_Telephone_Number__c":"+44999999999"}'
          + ',"confirmDrivingLicenseDetails":{"Driving_Licence_Number__c":"TN99 2019 00 00 999","Points_on_Licence__c":"Lorem","Driving_Licence_Expiry_Date__c":"11/07/2024","Type_of_licence__c":"Full UK Licence – Additional Categories","Additional_licence_categories__c":"D"}}';

        
        Test.startTest();
        ConnectAppController.updateDetails(jsonString);
        Test.stopTest();

        //Account updatedAccount = [SELECT Id, Last_Confirmed_Stage__c, GDPR_Statement__c, Sign_Offers_News__c /* Add more fields as needed */
                                  //FROM Account WHERE Id = :acc.Id];
        
    }
    
    @isTest
    public static void getMultiplePicklistValues_Test(){
        
         // Set up test data
        String objectName = 'Account'; // Using standard object 'Account'
        List<String> fieldNames = new List<String>{'Driving_Licence_Expired_Status__c', 'Citizenship_Immigration_status__c'};
		
        Test.startTest();
			Map<String, List<String>> resultMap = ConnectAppController.getMultiplePicklistValues(objectName, fieldNames);
        Test.stopTest();
        
        //Assertion 
		System.assert(resultMap.get('Driving_Licence_Expired_Status__c').size() > 0, 'Industry picklist should have values');
        System.assert(resultMap.get('Citizenship_Immigration_status__c').size() > 0, 'Type picklist should have values');
         
    }
}