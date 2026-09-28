# Current Record Highlights

A configurable Salesforce Lightning Web Component that displays the record that matters **right now**.

Current Record Highlights lets Salesforce admins surface a single current or active record on a Home Page, App Page, or Record Page without hard-coding an object, fields, or business process into the component.

Configure the object, tell the component how your org identifies the current record, choose a Field Set, and you're done.

On Record Pages, the component can also limit the search to records related to the record you're currently viewing.

## What It Does

At its simplest:

```text
Current Record?
      ↓
Checkbox / Formula Checkbox = TRUE
      ↓
Current Record Highlights
      ↓
Fields defined by your Field Set
```

On a Record Page, you can optionally add parent context:

```text
Current Record?
      ↓
Checkbox / Formula Checkbox = TRUE
      +
Related to THIS page record?
      ↓
Current Record Highlights
      ↓
Fields defined by your Field Set
```

That means the same component can support very different use cases without changing the code.

Examples include:

- Current program cycle
- Active contract
- Current fiscal period
- Current grant period
- Active membership
- Current campaign phase
- Current service plan
- Current semester
- Current project phase
- Current strategic plan

If your Salesforce data can identify **the record that is current**, the component can display it.

---

## Features

- Works with custom and standard objects
- Supports Home Pages, App Pages, and Record Pages
- Uses a Checkbox or Formula (Checkbox) field to identify the current record
- Uses a Field Set to control which fields are displayed
- Preserves the field order defined in the Field Set
- Supports optional parent-aware filtering on Record Pages
- Displays the current record name as a clickable link
- Supports text, number, currency, and percent formatting
- Supports Salesforce hyperlink formulas
- Optional heading
- Optional Salesforce Lightning icon
- Optional accent color
- Automatically creates a lighter body color from the configured accent
- Automatically chooses readable light or dark header text
- No object-specific business logic in the component

---

## Global vs. Parent-Aware Current Records

Current Record Highlights supports two useful patterns.

### Global Current Record

Use this on a Home Page, App Page, or anywhere there is one current record for the entire organization.

For example:

```text
Fiscal_Period__c
Current__c = TRUE
```

Leave **Parent Lookup Field** blank.

The component finds the record where:

```text
Current__c = TRUE
```

### Current Record for This Record

On a Lightning Record Page, you can also tell the component which lookup on the source object points back to the page record.

For example, imagine:

```text
Program__c
    ↓
Program_Cycle__c
```

`Program_Cycle__c` contains:

```text
Current__c
Program__c
```

Configure:

```text
Object API Name:
Program_Cycle__c

Parent Lookup Field:
Program__c

Checkbox Field That Determines Current Record:
Current__c
```

When viewing a Program, the component effectively looks for:

```text
Program_Cycle__c
WHERE Current__c = TRUE
AND Program__c = current Program
```

This allows different parent records to have different current child records while using the same component.

---

## Configuration

Add **Current Record Highlights** to a Lightning page in Lightning App Builder.

The following properties are available.

| Property | Required | Description |
|---|---|---|
| Object API Name | Yes | API name of the object containing the record to display |
| Parent Lookup Field | No | Lookup or Master-Detail field on the source object pointing to the current Record Page record |
| Checkbox Field That Determines Current Record | Yes | Checkbox or Formula (Checkbox) field identifying the current record |
| Field Set to Display | Yes | Field Set containing the fields to display |
| Heading | No | Text displayed above the current record name |
| Icon Name | No | Salesforce Lightning icon name, such as `standard:event` or `standard:call` |
| Accent Color | No | Hex color such as `#566B50` |

---

## Creating the Current Record Field

The component does not decide what "current" means.

**You do.**

This is intentional because "current" means different things for different Salesforce implementations.

A Formula (Checkbox) is often a simple way to define it.

For a record with start and end dates:

```text
AND(
    Start_Date__c <= TODAY(),
    End_Date__c >= TODAY()
)
```

The component will display the record where that formula evaluates to `TRUE`.

You can use any Checkbox or Formula (Checkbox) field appropriate to your business process.

### Important

Your configuration should result in **one current record within the relevant scope**.

The component retrieves a single matching record. It is not intended to choose between multiple competing "current" records.

---

## Creating the Field Set

Create a Field Set on the object configured as **Object API Name**.

Add the fields you want displayed.

The component uses the Field Set to determine:

- which fields appear
- the order in which they appear

This means an administrator can change the displayed fields later without modifying or redeploying the LWC.

---

## Styling

### Heading

The heading is optional.

For example:

```text
Active Contract:
```

If no heading is configured, only the clickable record name is displayed.

### Icon

The icon is optional.

Use a valid Salesforce Lightning Design System icon name, for example:

```text
standard:event
```

or:

```text
standard:call
```

If no icon is configured, no icon space is reserved.

### Accent Color

Enter a hexadecimal color such as:

```text
#566B50
```

The component uses the accent color for the header and border and automatically creates a lighter version for the body.

Header text automatically switches between light and dark based on the configured color.

If no valid accent color is supplied, the component uses its default Salesforce-style appearance.

---

## Example Configurations

### Current Fiscal Period on a Home Page

```text
Object API Name:
Fiscal_Period__c

Parent Lookup Field:
[blank]

Checkbox Field That Determines Current Record:
Current__c

Field Set to Display:
Highlights

Heading:
Current Fiscal Period

Icon Name:
standard:event
```

### Active Contract on an Account

```text
Object API Name:
Contract

Parent Lookup Field:
AccountId

Checkbox Field That Determines Current Record:
Current__c

Field Set to Display:
Contract_Highlights

Heading:
Active Contract
```

The component will display the current Contract related to the Account being viewed.

### Current Program Cycle

```text
Object API Name:
Program_Cycle__c

Parent Lookup Field:
Program__c

Checkbox Field That Determines Current Record:
Current__c

Field Set to Display:
Highlights

Heading:
Active Program Cycle:

Icon Name:
standard:call

Accent Color:
#566B50
```

---

## Supported Field Display

Current Record Highlights provides formatting for:

- Text
- Numbers
- Currency
- Percentages
- Salesforce hyperlink formulas

Other field values fall back to standard text display.

---

## Installation

Clone or download this repository.

Authenticate the target Salesforce org with Salesforce CLI, then deploy the source:

```bash
sf project deploy start \
  --source-dir force-app/main/default \
  --target-org YOUR_ORG_ALIAS \
  --test-level RunSpecifiedTests \
  --tests CurrentRecordHighlightsController_Test \
  --wait 30
```

Replace:

```text
YOUR_ORG_ALIAS
```

with the alias for your target org.

---

## Permissions

Users who view Current Record Highlights need access to:

- the configured source object
- the configured current-record checkbox field
- the fields included in the configured Field Set
- the configured parent lookup field, when parent-aware filtering is used
- `CurrentRecordHighlightsController`

Grant Apex Class Access to:

```text
CurrentRecordHighlightsController
```

through the appropriate Profile or Permission Set.

Normal Salesforce object and field security still applies.

---

## Test Metadata

The repository includes:

```text
Contact.Record_Comparison_Test
```

This Field Set exists only to support the included Apex tests.

The tests use standard Contact metadata so the component can be tested without requiring a custom object from a particular Salesforce implementation.

### Do Not Call Field Access

The test fixture uses the standard Contact `DoNotCall` checkbox.

The user performing the deployment must have field-level access to **Contact → Do Not Call** when running the included tests.

If a deployment reports an error similar to:

```text
Operation failed due to fields being inaccessible on Sobject Contact
```

verify that the deploying user has access to the standard Contact **Do Not Call** field.

This requirement affects the included test fixture; it is not a runtime dependency of the Current Record Highlights component.

---

## Troubleshooting

### No current record is displayed

Verify that:

1. The Object API Name is correct.
2. The configured current-record field exists on that object.
3. The field is a Checkbox or Formula (Checkbox).
4. A record currently evaluates to `TRUE`.
5. The running user has access to the object and configured fields.

### A Record Page shows the wrong current record

If the current record should be specific to the page record, configure **Parent Lookup Field**.

For example:

```text
Program_Cycle__c.Program__c
```

When the component is placed on a Program Record Page:

```text
Parent Lookup Field = Program__c
```

This restricts the result to the current Program.

### No record appears after configuring Parent Lookup Field

Verify that:

- the component is on a Record Page
- the configured field is a Lookup or Master-Detail field
- the lookup points to the type of record represented by the page
- a related record has the current-record checkbox set to `TRUE`

### The icon doesn't appear

Verify that the configured value is a valid Salesforce Lightning Design System icon name.

For example:

```text
standard:event
```

The icon name must include its category.

### Percentages look wrong

Salesforce stores and returns percentage values differently from the decimal format expected by the Lightning formatted-number component. Current Record Highlights accounts for this conversion automatically.

---

## Architecture

The component consists of:

```text
currentRecordHighlights
        ↓
CurrentRecordHighlightsController
        ↓
Dynamic Schema Validation
        ↓
Dynamic SOQL
        ↓
Current Record
        ↓
Field Set Metadata
        ↓
Rendered Highlights
```

The Apex controller validates configured object, field, Field Set, and lookup metadata before constructing the query.

When parent-aware filtering is configured, the parent field must be a Salesforce `REFERENCE` field.

No source object or business-specific field is hard-coded into the production component.

---

## Project Structure

```text
force-app/main/default/
├── classes/
│   ├── CurrentRecordHighlightsController.cls
│   ├── CurrentRecordHighlightsController.cls-meta.xml
│   ├── CurrentRecordHighlightsController_Test.cls
│   └── CurrentRecordHighlightsController_Test.cls-meta.xml
├── lwc/
│   └── currentRecordHighlights/
│       ├── currentRecordHighlights.css
│       ├── currentRecordHighlights.html
│       ├── currentRecordHighlights.js
│       └── currentRecordHighlights.js-meta.xml
└── objects/
    └── Contact/
        └── fieldSets/
            └── Record_Comparison_Test.fieldSet-meta.xml
```

---

## Compatibility

Current Record Highlights is built with:

```text
Salesforce API Version 65.0
```

It uses Lightning Web Components and Apex and is intended for Salesforce Lightning Experience.

The source has been successfully deployed and tested across unrelated Salesforce orgs.

---

## Design Philosophy

Current Record Highlights intentionally separates three questions:

**Which record matters?**

Your Checkbox or Formula (Checkbox) decides.

**Which fields matter?**

Your Field Set decides.

**Where does it matter?**

Lightning App Builder decides.

The component just brings those decisions together.

---

## License

This project is released under the MIT License.

See `LICENSE` for details.

---

## Author

Created by **mandie mcdougal**  
agency llc

**Empowered. By Design.**