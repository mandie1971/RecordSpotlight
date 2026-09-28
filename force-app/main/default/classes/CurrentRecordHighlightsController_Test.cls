@IsTest
private class CurrentRecordHighlightsController_Test {

    /*
     * TEST CONFIGURATION
     *
     * This controller is intentionally generic, so the test avoids relying on
     * Essie-specific objects or fields.
     *
     * Contact is used as a standard Salesforce object.
     * DoNotCall is used only as a portable, writable standard Boolean field.
     * Its business meaning is irrelevant to this test; the controller treats
     * any configured Boolean field as the current-record indicator.
     *
     * Record_Comparison_Test is a small Contact Field Set included with the
     * project specifically as stable metadata for testing reusable components
     * that consume a configured Field Set. Using it keeps this test independent
     * of the production Field Sets used by any particular implementation of
     * Current Record Highlights.
     *
     * AccountId is used as the standard reference field for testing the optional
     * parent-record filtering behavior.
     */

    @IsTest
    static void getCurrentRecordReturnsConfiguredContact() {

        Contact currentContact = new Contact(
            FirstName = 'Current',
            LastName = 'Record Test',
            Email = 'current.record@example.com',
            DoNotCall = true
        );

        Contact otherContact = new Contact(
            FirstName = 'Not Current',
            LastName = 'Record Test',
            Email = 'not.current@example.com',
            DoNotCall = false
        );

        insert new List<Contact>{
            currentContact,
            otherContact
        };

        Test.startTest();

        CurrentRecordHighlightsController.HighlightResult result =
            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'DoNotCall',
                'Record_Comparison_Test',
                null,
                null
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'A current Contact should have been returned.'
        );

        System.assertEquals(
            currentContact.Id,
            result.recordId,
            'The Contact with DoNotCall = true should be returned.'
        );

        System.assertEquals(
            'Current Record Test',
            result.recordName,
            'The Contact Name should be returned as the record name.'
        );

        System.assertEquals(
            'Contact',
            result.objectApiName,
            'The configured object API name should be returned.'
        );

        System.assertNotEquals(
            null,
            result.fields,
            'Field Set fields should be returned.'
        );

        System.assert(
            result.fields.size() > 0,
            'The Record_Comparison_Test Field Set should contain fields.'
        );
    }

    @IsTest
    static void getCurrentRecordReturnsNullWhenNoRecordIsCurrent() {

        insert new Contact(
            FirstName = 'Not Current',
            LastName = 'Record Test',
            Email = 'not.current@example.com',
            DoNotCall = false
        );

        Test.startTest();

        CurrentRecordHighlightsController.HighlightResult result =
            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'DoNotCall',
                'Record_Comparison_Test',
                null,
                null
            );

        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'No record should be returned when no Contact has DoNotCall = true.'
        );
    }

    @IsTest
    static void getCurrentRecordRejectsInvalidObject() {

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                'Definitely_Not_An_Object__c',
                'DoNotCall',
                'Record_Comparison_Test',
                null,
                null
            );

            System.assert(
                false,
                'An invalid object should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }

    @IsTest
    static void getCurrentRecordRejectsInvalidCurrentField() {

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'Definitely_Not_A_Field__c',
                'Record_Comparison_Test',
                null,
                null
            );

            System.assert(
                false,
                'An invalid current-record field should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }

    @IsTest
    static void getCurrentRecordRejectsNonCheckboxCurrentField() {

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'LastName',
                'Record_Comparison_Test',
                null,
                null
            );

            System.assert(
                false,
                'A non-checkbox current-record field should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }

    @IsTest
    static void getCurrentRecordRejectsInvalidFieldSet() {

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'DoNotCall',
                'Definitely_Not_A_Field_Set',
                null,
                null
            );

            System.assert(
                false,
                'An invalid Field Set should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }

    @IsTest
    static void getCurrentRecordRequiresConfiguration() {

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                null,
                null,
                null,
                null,
                null
            );

            System.assert(
                false,
                'Missing configuration should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }

    @IsTest
    static void getCurrentRecordFiltersByParentRecord() {

        Account firstAccount = new Account(
            Name = 'First Parent'
        );

        Account secondAccount = new Account(
            Name = 'Second Parent'
        );

        insert new List<Account>{
            firstAccount,
            secondAccount
        };

        Contact firstContact = new Contact(
            FirstName = 'First',
            LastName = 'Current Contact',
            Email = 'first.current@example.com',
            AccountId = firstAccount.Id,
            DoNotCall = true
        );

        Contact secondContact = new Contact(
            FirstName = 'Second',
            LastName = 'Current Contact',
            Email = 'second.current@example.com',
            AccountId = secondAccount.Id,
            DoNotCall = true
        );

        insert new List<Contact>{
            firstContact,
            secondContact
        };

        Test.startTest();

        CurrentRecordHighlightsController.HighlightResult result =
            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'DoNotCall',
                'Record_Comparison_Test',
                'AccountId',
                firstAccount.Id
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'A current Contact belonging to the requested parent should be returned.'
        );

        System.assertEquals(
            firstContact.Id,
            result.recordId,
            'The current Contact belonging to the requested Account should be returned.'
        );
    }

    @IsTest
    static void getCurrentRecordRequiresParentIdWhenParentFieldConfigured() {

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'DoNotCall',
                'Record_Comparison_Test',
                'AccountId',
                null
            );

            System.assert(
                false,
                'A configured Parent Lookup Field without a Parent Record Id should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }

    @IsTest
    static void getCurrentRecordRejectsNonReferenceParentField() {

        Account parentAccount = new Account(
            Name = 'Parent Test'
        );

        insert parentAccount;

        try {

            CurrentRecordHighlightsController.getCurrentRecord(
                'Contact',
                'DoNotCall',
                'Record_Comparison_Test',
                'LastName',
                parentAccount.Id
            );

            System.assert(
                false,
                'A non-reference Parent Lookup Field should throw an exception.'
            );

        } catch (AuraHandledException e) {

            System.assert(
                true,
                'Expected AuraHandledException was thrown.'
            );
        }
    }
}