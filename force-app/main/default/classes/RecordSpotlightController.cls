public with sharing class RecordSpotlightController {

    public class HighlightField {
        @AuraEnabled
        public String apiName;

        @AuraEnabled
        public String label;

        @AuraEnabled
        public String dataType;

        @AuraEnabled
        public Object value;
    }

    public class HighlightResult {
        @AuraEnabled
        public Id recordId;

        @AuraEnabled
        public String recordName;

        @AuraEnabled
        public String objectApiName;

        @AuraEnabled
        public List<HighlightField> fields;
    }

    @AuraEnabled(cacheable=true)
    public static HighlightResult getCurrentRecord(
        String objectApiName,
        String currentRecordFieldApiName,
        String fieldSetApiName,
        String parentLookupFieldApiName,
        Id parentRecordId
    ) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException(
                'Object API Name is required.'
            );
        }

        if (String.isBlank(currentRecordFieldApiName)) {
            throw new AuraHandledException(
                'Current Record Field API Name is required.'
            );
        }

        if (String.isBlank(fieldSetApiName)) {
            throw new AuraHandledException(
                'Field Set API Name is required.'
            );
        }

        Map<String, Schema.SObjectType> globalDescribe =
            Schema.getGlobalDescribe();

        if (!globalDescribe.containsKey(objectApiName)) {
            throw new AuraHandledException(
                'Object not found: ' + objectApiName
            );
        }

        Schema.DescribeSObjectResult objectDescribe =
            globalDescribe.get(objectApiName).getDescribe();

        Map<String, Schema.SObjectField> fieldMap =
            objectDescribe.fields.getMap();

        if (!fieldMap.containsKey(currentRecordFieldApiName)) {
            throw new AuraHandledException(
                'Current record field not found: ' +
                currentRecordFieldApiName
            );
        }

        Schema.DescribeFieldResult currentFieldDescribe =
            fieldMap
                .get(currentRecordFieldApiName)
                .getDescribe();

        if (
            currentFieldDescribe.getType() !=
            Schema.DisplayType.BOOLEAN
        ) {
            throw new AuraHandledException(
                'Current record field must be a Checkbox or Formula (Checkbox).'
            );
        }

        Map<String, Schema.FieldSet> fieldSetMap =
            objectDescribe.fieldSets.getMap();

        if (!fieldSetMap.containsKey(fieldSetApiName)) {
            throw new AuraHandledException(
                'Field Set not found: ' + fieldSetApiName
            );
        }

        Boolean filterByParent =
            !String.isBlank(parentLookupFieldApiName);

        if (filterByParent) {
            if (!fieldMap.containsKey(parentLookupFieldApiName)) {
                throw new AuraHandledException(
                    'Parent lookup field not found: ' +
                    parentLookupFieldApiName
                );
            }

            Schema.DescribeFieldResult parentFieldDescribe =
                fieldMap
                    .get(parentLookupFieldApiName)
                    .getDescribe();

            if (
                parentFieldDescribe.getType() !=
                Schema.DisplayType.REFERENCE
            ) {
                throw new AuraHandledException(
                    'Parent Lookup Field must be a Lookup or Master-Detail field.'
                );
            }

            if (parentRecordId == null) {
                throw new AuraHandledException(
                    'A parent record Id is required when Parent Lookup Field is configured.'
                );
            }
        }

        Schema.FieldSet fieldSet =
            fieldSetMap.get(fieldSetApiName);

        List<Schema.FieldSetMember> fieldSetMembers =
            fieldSet.getFields();

        Set<String> queryFieldSet =
            new Set<String>();

        queryFieldSet.add('Id');
        queryFieldSet.add('Name');

        for (
            Schema.FieldSetMember member :
            fieldSetMembers
        ) {
            queryFieldSet.add(member.getFieldPath());
        }

        List<String> queryFields =
            new List<String>();

        queryFields.addAll(queryFieldSet);
        queryFields.sort();

        String soql =
            'SELECT ' +
            String.join(queryFields, ', ') +
            ' FROM ' +
            objectApiName +
            ' WHERE ' +
            currentRecordFieldApiName +
            ' = TRUE';

        if (filterByParent) {
            soql +=
                ' AND ' +
                parentLookupFieldApiName +
                ' = :parentRecordId';
        }

        /*
         * Retrieve at most two records.
         *
         * We only need to know whether there are zero, one,
         * or multiple matching records. Returning an arbitrary
         * record when more than one is current could present
         * incorrect information to the user.
         */
        soql += ' LIMIT 2';

        List<SObject> records =
            Database.query(soql);

        if (records.isEmpty()) {
            return null;
        }

        if (records.size() > 1) {
            throw new AuraHandledException(
                'Multiple current records found. ' +
                'Make sure only one record evaluates to TRUE ' +
                'for the configured current-record field ' +
                'within this context.'
            );
        }

        SObject currentRecord =
            records[0];

        HighlightResult result =
            new HighlightResult();

        result.recordId =
            (Id) currentRecord.get('Id');

        result.recordName =
            String.valueOf(
                currentRecord.get('Name')
            );

        result.objectApiName =
            objectApiName;

        result.fields =
            new List<HighlightField>();

        for (
            Schema.FieldSetMember member :
            fieldSetMembers
        ) {
            HighlightField field =
                new HighlightField();

            field.apiName =
                member.getFieldPath();

            field.label =
                member.getLabel();

            field.dataType =
                String.valueOf(
                    member.getType()
                );

            field.value =
                currentRecord.get(
                    member.getFieldPath()
                );

            result.fields.add(field);
        }

        return result;
    }
}