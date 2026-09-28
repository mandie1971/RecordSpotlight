/*
 * CURRENT RECORD HIGHLIGHTS
 *
 * Reusable controller for displaying selected fields from a configured
 * current record.
 *
 * CONFIGURATION IS PROVIDED BY THE LWC:
 * - Object API Name
 * - Checkbox or Formula (Checkbox) field that identifies the current record
 * - Field Set that determines which fields are displayed
 * - Optional Parent Lookup Field used to restrict the current record
 *   to the record page where the component is displayed
 */
public with sharing class CurrentRecordHighlightsController {

    public class HighlightField {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String dataType;
        @AuraEnabled public Object value;

        public HighlightField(
            String label,
            String apiName,
            String dataType,
            Object value
        ) {
            this.label = label;
            this.apiName = apiName;
            this.dataType = dataType;
            this.value = value;
        }
    }

    public class HighlightResult {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String recordName;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public List<HighlightField> fields;
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
                'Checkbox Field That Determines Current Record is required.'
            );
        }

        if (String.isBlank(fieldSetApiName)) {
            throw new AuraHandledException(
                'Field Set to Display is required.'
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

        Map<String, Schema.SObjectField> objectFields =
            objectDescribe.fields.getMap();

        if (!objectFields.containsKey(currentRecordFieldApiName)) {
            throw new AuraHandledException(
                objectApiName +
                ' does not contain a field named ' +
                currentRecordFieldApiName + '.'
            );
        }

        Schema.DescribeFieldResult currentFieldDescribe =
            objectFields.get(currentRecordFieldApiName).getDescribe();

        if (
            currentFieldDescribe.getType() !=
            Schema.DisplayType.BOOLEAN
        ) {
            throw new AuraHandledException(
                currentRecordFieldApiName +
                ' must be a Checkbox or Formula (Checkbox).'
            );
        }

        Boolean filterByParent =
            !String.isBlank(parentLookupFieldApiName);

        if (filterByParent) {
            if (parentRecordId == null) {
                throw new AuraHandledException(
                    'A Parent Record Id is required when Parent Lookup Field is configured.'
                );
            }

            if (!objectFields.containsKey(parentLookupFieldApiName)) {
                throw new AuraHandledException(
                    objectApiName +
                    ' does not contain a field named ' +
                    parentLookupFieldApiName + '.'
                );
            }

            Schema.DescribeFieldResult parentFieldDescribe =
                objectFields.get(parentLookupFieldApiName).getDescribe();

            if (
                parentFieldDescribe.getType() !=
                Schema.DisplayType.REFERENCE
            ) {
                throw new AuraHandledException(
                    parentLookupFieldApiName +
                    ' must be a Lookup or Master-Detail field.'
                );
            }
        }

        Map<String, Schema.FieldSet> fieldSets =
            objectDescribe.fieldSets.getMap();

        if (!fieldSets.containsKey(fieldSetApiName)) {
            throw new AuraHandledException(
                objectApiName +
                ' does not contain a Field Set named ' +
                fieldSetApiName + '.'
            );
        }

        Schema.FieldSet fieldSet =
            fieldSets.get(fieldSetApiName);

        List<Schema.FieldSetMember> fieldSetMembers =
            fieldSet.getFields();

        List<String> queryFields =
            new List<String>{ 'Id' };

        Boolean hasNameField =
            objectFields.containsKey('Name');

        if (hasNameField) {
            queryFields.add('Name');
        }

        for (Schema.FieldSetMember member : fieldSetMembers) {
            String fieldPath =
                member.getFieldPath();

            if (
                !fieldPath.contains('.') &&
                objectFields.containsKey(fieldPath) &&
                !queryFields.contains(fieldPath)
            ) {
                queryFields.add(fieldPath);
            }
        }

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

        soql += ' LIMIT 1';

        List<SObject> records =
            Database.query(soql);

        if (records.isEmpty()) {
            return null;
        }

        SObject currentRecord =
            records[0];

        HighlightResult result =
            new HighlightResult();

        result.recordId =
            (Id) currentRecord.get('Id');

        result.objectApiName =
            objectApiName;

        result.recordName =
            hasNameField
                ? String.valueOf(currentRecord.get('Name'))
                : objectDescribe.getLabel();

        result.fields =
            new List<HighlightField>();

        for (Schema.FieldSetMember member : fieldSetMembers) {
            String fieldPath =
                member.getFieldPath();

            if (
                fieldPath.contains('.') ||
                !objectFields.containsKey(fieldPath)
            ) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe =
                objectFields.get(fieldPath).getDescribe();

            result.fields.add(
                new HighlightField(
                    member.getLabel(),
                    fieldPath,
                    String.valueOf(fieldDescribe.getType()),
                    currentRecord.get(fieldPath)
                )
            );
        }

        return result;
    }
}