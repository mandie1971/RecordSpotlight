@IsTest
private class RecordSpotlightController_Test {

    private static final String OBJECT_API_NAME =
        'Contact';

    private static final String CURRENT_FIELD =
        'Agency_Package_Test_Current__c';

    private static final String FIELD_SET =
        'Agency_Package_Test';

    @IsTest
    static void testReturnsCurrentRecord() {
        Contact contact =
            new Contact(
                LastName = 'Current Contact',
                Agency_Package_Test_Current__c = true
            );

        insert contact;

        Test.startTest();

        RecordSpotlightController.HighlightResult result =
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                null,
                null
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            result
        );

        System.assertEquals(
            contact.Id,
            result.recordId
        );

        System.assertEquals(
            OBJECT_API_NAME,
            result.objectApiName
        );

        System.assertNotEquals(
            null,
            result.fields
        );
    }

    @IsTest
    static void testReturnsNullWhenNoCurrentRecord() {
        Contact contact =
            new Contact(
                LastName = 'Not Current',
                Agency_Package_Test_Current__c = false
            );

        insert contact;

        Test.startTest();

        RecordSpotlightController.HighlightResult result =
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                null,
                null
            );

        Test.stopTest();

        System.assertEquals(
            null,
            result
        );
    }

    @IsTest
    static void testInvalidObjectThrowsError() {
        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                'Not_A_Real_Object__c',
                CURRENT_FIELD,
                FIELD_SET,
                null,
                null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException for an invalid object.'
        );
    }

    @IsTest
    static void testInvalidCurrentFieldThrowsError() {
        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                'Not_A_Field__c',
                FIELD_SET,
                null,
                null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException for an invalid current-record field.'
        );
    }

    @IsTest
    static void testNonCheckboxCurrentFieldThrowsError() {
        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                'LastName',
                FIELD_SET,
                null,
                null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException when the current-record field is not a checkbox.'
        );
    }

    @IsTest
    static void testInvalidFieldSetThrowsError() {
        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                'Not_A_Field_Set',
                null,
                null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException for an invalid Field Set.'
        );
    }

    @IsTest
    static void testMultipleCurrentRecordsThrowsError() {
        insert new List<Contact>{
            new Contact(
                LastName = 'Current One',
                Agency_Package_Test_Current__c = true
            ),
            new Contact(
                LastName = 'Current Two',
                Agency_Package_Test_Current__c = true
            )
        };

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                null,
                null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException when multiple current records exist.'
        );
    }

    @IsTest
    static void testParentFilteringReturnsCorrectRecord() {
        Account accountOne =
            new Account(
                Name = 'Account One'
            );

        Account accountTwo =
            new Account(
                Name = 'Account Two'
            );

        insert new List<Account>{
            accountOne,
            accountTwo
        };

        Contact contactOne =
            new Contact(
                LastName = 'Contact One',
                AccountId = accountOne.Id,
                Agency_Package_Test_Current__c = true
            );

        Contact contactTwo =
            new Contact(
                LastName = 'Contact Two',
                AccountId = accountTwo.Id,
                Agency_Package_Test_Current__c = true
            );

        insert new List<Contact>{
            contactOne,
            contactTwo
        };

        Test.startTest();

        RecordSpotlightController.HighlightResult result =
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                'AccountId',
                accountOne.Id
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            result
        );

        System.assertEquals(
            contactOne.Id,
            result.recordId
        );
    }

    @IsTest
    static void testParentFilteringReturnsNullWhenNoMatch() {
        Account account =
            new Account(
                Name = 'Account'
            );

        insert account;

        insert new Contact(
            LastName = 'Not Current',
            AccountId = account.Id,
            Agency_Package_Test_Current__c = false
        );

        Test.startTest();

        RecordSpotlightController.HighlightResult result =
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                'AccountId',
                account.Id
            );

        Test.stopTest();

        System.assertEquals(
            null,
            result
        );
    }

    @IsTest
    static void testInvalidParentLookupThrowsError() {
        Account account =
            new Account(
                Name = 'Account'
            );

        insert account;

        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                'Not_A_Field__c',
                account.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException for an invalid parent lookup field.'
        );
    }

    @IsTest
    static void testParentFieldMustBeReference() {
        Account account =
            new Account(
                Name = 'Account'
            );

        insert account;

        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                'LastName',
                account.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException when the parent field is not a reference field.'
        );
    }

    @IsTest
    static void testParentRecordIdRequired() {
        Boolean exceptionThrown = false;

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                'AccountId',
                null
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException when Parent Lookup Field is configured without a parent record Id.'
        );
    }

    @IsTest
    static void testMultipleCurrentRecordsForSameParentThrowsError() {
        Account account =
            new Account(
                Name = 'Account'
            );

        insert account;

        insert new List<Contact>{
            new Contact(
                LastName = 'Current One',
                AccountId = account.Id,
                Agency_Package_Test_Current__c = true
            ),
            new Contact(
                LastName = 'Current Two',
                AccountId = account.Id,
                Agency_Package_Test_Current__c = true
            )
        };

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            RecordSpotlightController.getCurrentRecord(
                OBJECT_API_NAME,
                CURRENT_FIELD,
                FIELD_SET,
                'AccountId',
                account.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected an AuraHandledException when multiple current records exist for the same parent.'
        );
    }
}