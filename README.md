# Current Record Highlights

A configurable Salesforce Lightning Web Component that surfaces the record that matters **right now**.

Choose the object, define what makes a record current, choose a Field Set, and place the component wherever users need the context.

No object-specific business logic is hard-coded into the component.

## See It in Action

### Context-Aware Record Page

On a Record Page, Current Record Highlights can find the current child record related to the record being viewed.

![Current Record Highlights displaying an active Call Cycle on a Program Cohort record](images/current-record-highlights-record-page.png)

### Global App or Home Page

Leave **Parent Lookup Field** blank to surface the globally current record on an App Page or Home Page.

![Current Record Highlights displaying a global current record on an App Page](images/current-record-highlights-app-page.png)

### Responsive Lightning Layouts

The component responds to the space Salesforce gives it — not the size of the browser window.

In a wider Lightning page region:

![Current Record Highlights displaying a Primary Contact in a wide Lightning page region](images/current-record-highlights-primary-contact.png)

And in a narrow sidebar:

![Current Record Highlights displaying a Primary Contact in a narrow Lightning page region](images/current-record-highlights-responsive-layout.png)

The same component automatically reflows its fields based on the space available. No separate layout or component configuration is required.

## What "Current" Means Is Up to You

The determining field can be any **Checkbox or Formula (Checkbox)**. It does not have to literally mean "current."

Use it for things like:

- Current program cycle
- Active contract
- Current fiscal period
- Primary contact
- Current grant period
- Active membership
- Current project phase

For example, the component can use `Contact.Primary_Contact__c` on an Account page:

```text
Object API Name:
Contact

Parent Lookup Field:
AccountId

Checkbox Field That Determines Current Record:
Primary_Contact__c

Field Set to Display:
Primary_Contact_Display
```

The component then displays the Contact marked as Primary Contact for the Account being viewed.

## Features

- Standard and custom objects
- Home Pages, App Pages, and Record Pages
- Checkbox or Formula (Checkbox) determines the record
- Field Set determines the displayed fields and their order
- Optional parent-aware filtering on Record Pages
- Clickable record navigation
- Text, number, currency, and percent formatting
- Salesforce formula hyperlinks
- Optional heading and Lightning icon
- Optional accent color with automatically generated body and divider colors
- Responsive field layout based on available component width
- Detects conflicting current records rather than choosing one arbitrarily
- No object-specific production logic

## Global vs. Parent-Aware

### Global

Leave **Parent Lookup Field** blank.

The component finds a record where:

```text
Current__c = TRUE
```

This is useful on Home Pages and App Pages.

### Parent-Aware

On a Record Page, configure the lookup on the source object that points to the page record.

For example:

```text
Program_Cycle__c
WHERE Current__c = TRUE
AND Program__c = current Program
```

This allows each parent record to have its own current child record.

## Configuration

Add **Current Record Highlights** in Lightning App Builder.

| Property | Required | Description |
|---|---|---|
| Object API Name | Yes | Object containing the record to display |
| Parent Lookup Field | No | Lookup or Master-Detail field pointing to the current Record Page record |
| Checkbox Field That Determines Current Record | Yes | Checkbox or Formula (Checkbox) identifying the record |
| Field Set to Display | Yes | Field Set containing the fields to display |
| Heading | No | Text above the clickable record name |
| Icon Name | No | Lightning icon such as `standard:event`, `standard:call`, or `standard:contact` |
| Accent Color | No | Hex color such as `#566B50` |

## Creating the Current Record Field

The component does not decide what "current" means. **Your Salesforce configuration does.**

A date-driven Formula (Checkbox) might be:

```text
AND(
    Start_Date__c <= TODAY(),
    End_Date__c >= TODAY()
)
```

> [!IMPORTANT]
> Your configuration must allow **only one record within the relevant scope** to evaluate to `TRUE`.
>
> This applies whether the determining field is a formula or a manually maintained checkbox. If more than one record evaluates to `TRUE`, Current Record Highlights displays a configuration error instead of choosing a record arbitrarily.

For a global component, that means only one matching record across the configured object.

For a parent-aware component, each parent can have its own current record — but only one matching child record for that parent.

## Field Set

Create a Field Set on the configured object and add the fields you want displayed.

The Field Set controls:

- which fields appear
- the order in which they appear

Admins can therefore change the displayed information without modifying the LWC.

## Styling

### Heading

Optional text displayed above the clickable record name.

```text
Active Call Cycle:
```

### Icon

Use a valid Salesforce Lightning Design System icon name, for example:

```text
standard:call
standard:contact
standard:event
```

Leave blank for no icon.

### Accent Color

Enter a hex color such as:

```text
#566B50
```

The component automatically creates:

- the header and outline color
- a lighter body color
- a darker divider color
- readable light or dark header text

Leave blank for neutral styling.

## Responsive Layout

Lightning page regions can be much narrower than the browser itself.

Current Record Highlights uses an intrinsic grid that responds to the **actual width available to the component**, allowing fields to reflow naturally in full-width regions, columns, and sidebars.

## Supported Field Display

Current Record Highlights provides formatting for:

- Text
- Numbers
- Currency
- Percentages
- Salesforce formula hyperlinks

Other returned values fall back to text display.

## Formula Hyperlinks

Formula fields using Salesforce `HYPERLINK()` can be included in the Field Set and rendered as clickable links.

Example:

```text
HYPERLINK(
    "/" & Parent__c,
    Parent__r.Name,
    "_self"
)
```

## Installation

Clone or download this repository.

Authenticate the target Salesforce org with Salesforce CLI, then deploy:

```bash
sf project deploy start \
  --source-dir force-app/main/default \
  --target-org YOUR_ORG_ALIAS \
  --test-level RunSpecifiedTests \
  --tests RecordSpotlightController_Test \
  --wait 30
```

## Permissions

Users need access to:

- the configured source object
- the current-record checkbox field
- fields included in the Field Set
- the parent lookup field when parent-aware filtering is used
- `RecordSpotlightController`

Grant Apex Class Access through the appropriate Profile or Permission Set.

Normal Salesforce object and field security still applies.

## Test Metadata

The repository includes:

```text
Contact.Record_Comparison_Test
```

This Field Set exists only to support the included Apex tests without requiring implementation-specific custom objects.

### Contact Do Not Call Access

The test fixture uses the standard Contact `DoNotCall` checkbox.

The deploying user must have field-level access to **Contact → Do Not Call** when running the included tests.

If deployment reports:

```text
Operation failed due to fields being inaccessible on Sobject Contact
```

verify the deploying user's access to that standard field.

This is a test-fixture requirement, not a runtime dependency of Current Record Highlights.

## Troubleshooting

### No current record appears

Verify:

1. Object API Name is correct.
2. The determining field exists and is a Checkbox or Formula (Checkbox).
3. A record evaluates to `TRUE`.
4. The running user has access to the configured metadata.

### Multiple current records found

More than one record is evaluating to `TRUE` within the same scope.

If the current-record field is a **formula**, check the formula logic and the underlying data to make sure the valid periods or conditions cannot overlap.

If the field is a **manually maintained checkbox**, make sure the process for marking a new record current also clears the previous current record.

The component deliberately refuses to choose between multiple matches because doing so could display incorrect information.

### Wrong record appears on a Record Page

If "current" should be specific to the page record, configure **Parent Lookup Field**.

### Nothing appears after adding Parent Lookup Field

Verify that:

- the component is on a Record Page
- the field is a Lookup or Master-Detail field
- the lookup points to the page record
- a related record evaluates to `TRUE`

### Icon doesn't appear

Use a valid Lightning Design System icon name including its category, such as:

```text
standard:event
```

## Architecture

```text
Lightning Page
      ↓
recordSpotlight
      ↓
Imperative Apex Request
      ↓
RecordSpotlightController
      ↓
Dynamic Schema Validation
      ↓
Dynamic SOQL
      ↓
0 matches → No current record
1 match   → Display record
2 matches → Configuration error
      ↓
Current Record + Field Set Metadata
      ↓
Responsive Highlights
```

The LWC loads the record imperatively so both Record Page context and global Home/App Page use work reliably.

The Apex controller validates the configured object, checkbox, Field Set, and optional parent lookup before constructing the query. A configured parent field must be a Salesforce `REFERENCE` field.

The query retrieves at most two matching records. This is enough to distinguish between no current record, exactly one current record, and an invalid configuration containing multiple current records.

## Project Structure

```text
force-app/main/default/
├── classes/
│   ├── RecordSpotlightController.cls
│   ├── RecordSpotlightController.cls-meta.xml
│   ├── RecordSpotlightController_Test.cls
│   └── RecordSpotlightController_Test.cls-meta.xml
├── lwc/
│   └── recordSpotlight/
│       ├── recordSpotlight.css
│       ├── recordSpotlight.html
│       ├── recordSpotlight.js
│       └── recordSpotlight.js-meta.xml
└── objects/
    └── Contact/
        └── fieldSets/
            └── Record_Comparison_Test.fieldSet-meta.xml
```

## Compatibility

Built with Salesforce API Version **65.0** for Lightning Experience.

The source has been successfully deployed and tested across unrelated Salesforce orgs.

## Design Philosophy

Current Record Highlights separates three questions:

**Which record matters?**  
Your Checkbox or Formula (Checkbox) decides.

**Which fields matter?**  
Your Field Set decides.

**Where does it matter?**  
Lightning App Builder decides.

The component just brings those decisions together.

## License

Released under the MIT License. See `LICENSE`.

## Author

Created by **mandie mcdougal**  
**agency llc**

**Empowered. By Design.**