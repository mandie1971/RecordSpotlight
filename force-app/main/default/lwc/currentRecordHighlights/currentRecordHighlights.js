import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCurrentRecord from '@salesforce/apex/CurrentRecordHighlightsController.getCurrentRecord';

export default class CurrentRecordHighlights extends NavigationMixin(LightningElement) {
    _recordId;
    _sourceObjectApiName;
    _parentLookupFieldApiName;
    _currentRecordFieldApiName;
    _fieldSetApiName;

    @api heading;
    @api iconName;
    @api backgroundColor;

    record;
    error;

    connected = false;
    loadRequestId = 0;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        this.loadRecord();
    }

    @api
    get sourceObjectApiName() {
        return this._sourceObjectApiName;
    }

    set sourceObjectApiName(value) {
        this._sourceObjectApiName = value;
        this.loadRecord();
    }

    @api
    get parentLookupFieldApiName() {
        return this._parentLookupFieldApiName;
    }

    set parentLookupFieldApiName(value) {
        this._parentLookupFieldApiName = value;
        this.loadRecord();
    }

    @api
    get currentRecordFieldApiName() {
        return this._currentRecordFieldApiName;
    }

    set currentRecordFieldApiName(value) {
        this._currentRecordFieldApiName = value;
        this.loadRecord();
    }

    @api
    get fieldSetApiName() {
        return this._fieldSetApiName;
    }

    set fieldSetApiName(value) {
        this._fieldSetApiName = value;
        this.loadRecord();
    }

    connectedCallback() {
        this.connected = true;
        this.loadRecord();
    }

    async loadRecord() {
        if (!this.connected) {
            return;
        }

        if (
            !this._sourceObjectApiName ||
            !this._currentRecordFieldApiName ||
            !this._fieldSetApiName
        ) {
            return;
        }

        /*
         * A parent lookup is optional.
         *
         * When one is configured, the component must be running in a
         * record context so Salesforce can provide the parent record Id.
         *
         * When no parent lookup is configured, null is deliberately sent
         * to Apex. This supports global use on Home and App pages.
         */
        if (
            this._parentLookupFieldApiName &&
            !this._recordId
        ) {
            return;
        }

        const requestId = ++this.loadRequestId;

        try {
            const data = await getCurrentRecord({
                objectApiName:
                    this._sourceObjectApiName,
                currentRecordFieldApiName:
                    this._currentRecordFieldApiName,
                fieldSetApiName:
                    this._fieldSetApiName,
                parentLookupFieldApiName:
                    this._parentLookupFieldApiName || null,
                parentRecordId:
                    this._recordId || null
            });

            /*
             * App Builder can set several public properties in rapid
             * succession. Ignore an older response if a newer request
             * has already started.
             */
            if (requestId !== this.loadRequestId) {
                return;
            }

            this.record = data || undefined;
            this.error = undefined;
        } catch (error) {
            if (requestId !== this.loadRequestId) {
                return;
            }

            this.record = undefined;
            this.error = error;
        }
    }

    get hasRecord() {
        return !!this.record;
    }

    get hasError() {
        return !!this.error;
    }

    get showNoRecord() {
        return !this.record && !this.error;
    }

    get hasHeading() {
        return !!this.heading?.trim();
    }

    get hasIcon() {
        return !!this.iconName?.trim();
    }

    get hasAccentColor() {
        return this.isValidHexColor(this.backgroundColor);
    }

    get containerStyle() {
        if (!this.hasAccentColor) {
            return '';
        }

        return `border-color: ${this.backgroundColor};`;
    }

    get headerStyle() {
        if (!this.hasAccentColor) {
            return '';
        }

        const textColor =
            this.getReadableTextColor(this.backgroundColor);

        const dividerColor =
            this.mixWithBlack(this.backgroundColor, 0.22);

        return `
            background-color: ${this.backgroundColor};
            color: ${textColor};
            border-bottom-color: ${dividerColor};
        `;
    }

    get bodyStyle() {
        if (!this.hasAccentColor) {
            return '';
        }

        const bodyColor =
            this.mixWithWhite(this.backgroundColor, 0.84);

        return `background-color: ${bodyColor};`;
    }

    get errorMessage() {
        return (
            this.error?.body?.message ||
            'Unable to load the current record.'
        );
    }

    get displayFields() {
        if (!this.record?.fields) {
            return [];
        }

        return this.record.fields.map((field) => {
            const hyperlink =
                this.parseSalesforceHyperlink(field.value);

            return {
                ...field,

                isLink: !!hyperlink,
                linkUrl: hyperlink?.url,
                linkLabel: hyperlink?.label,

                displayValue:
                    field.dataType === 'PERCENT' &&
                    field.value != null
                        ? Number(field.value) / 100
                        : field.value,

                isPercent:
                    !hyperlink &&
                    field.dataType === 'PERCENT',

                isCurrency:
                    !hyperlink &&
                    field.dataType === 'CURRENCY',

                isNumber:
                    !hyperlink &&
                    (
                        field.dataType === 'INTEGER' ||
                        field.dataType === 'DOUBLE' ||
                        field.dataType === 'LONG'
                    ),

                isText:
                    !hyperlink &&
                    field.dataType !== 'PERCENT' &&
                    field.dataType !== 'CURRENCY' &&
                    field.dataType !== 'INTEGER' &&
                    field.dataType !== 'DOUBLE' &&
                    field.dataType !== 'LONG'
            };
        });
    }

    parseSalesforceHyperlink(value) {
        if (typeof value !== 'string') {
            return null;
        }

        const match = value.match(
            /^<a\s+href=["']([^"']+)["'](?:\s+target=["'][^"']*["'])?\s*>(.*?)<\/a>$/i
        );

        if (!match) {
            return null;
        }

        return {
            url: match[1],
            label: match[2]
        };
    }

    isValidHexColor(color) {
        if (!color) {
            return false;
        }

        return /^#([0-9A-F]{3}|[0-9A-F]{6})$/i.test(
            color.trim()
        );
    }

    normalizeHex(hex) {
        let value =
            hex.trim().substring(1);

        if (value.length === 3) {
            value = value
                .split('')
                .map(
                    (character) =>
                        character + character
                )
                .join('');
        }

        return value;
    }

    hexToRgb(hex) {
        const normalized =
            this.normalizeHex(hex);

        const number =
            parseInt(normalized, 16);

        return {
            r: (number >> 16) & 255,
            g: (number >> 8) & 255,
            b: number & 255
        };
    }

    rgbToHex(r, g, b) {
        return (
            '#' +
            [r, g, b]
                .map((value) =>
                    Math.round(value)
                        .toString(16)
                        .padStart(2, '0')
                )
                .join('')
        );
    }

    mixWithWhite(hex, amount) {
        const { r, g, b } =
            this.hexToRgb(hex);

        return this.rgbToHex(
            r + (255 - r) * amount,
            g + (255 - g) * amount,
            b + (255 - b) * amount
        );
    }

    mixWithBlack(hex, amount) {
        const { r, g, b } =
            this.hexToRgb(hex);

        return this.rgbToHex(
            r * (1 - amount),
            g * (1 - amount),
            b * (1 - amount)
        );
    }

    getReadableTextColor(hex) {
        const { r, g, b } =
            this.hexToRgb(hex);

        const luminance =
            (
                0.2126 * r +
                0.7152 * g +
                0.0722 * b
            ) / 255;

        return luminance > 0.6
            ? '#181818'
            : '#ffffff';
    }

    handleRecordClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:
                    this.record.recordId,
                objectApiName:
                    this.record.objectApiName,
                actionName: 'view'
            }
        });
    }
}