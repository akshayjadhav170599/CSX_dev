import { LightningElement, api } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Csx_cmp_nettingClaimSummary extends LightningElement {
    hideTableHeader = true;
    stylePath = csxStyle;
    @api claimRecordWrapper;
    @api inbClaim;
    @api outClaim;
    summaryColumn = [
        { label: "Case Number", fieldName: 'Id',type: 'url', typeAttributes: {label: { fieldName: 'CaseNumber' }, target: '_blank' } },
        { label: "Amount", fieldName: 'CSX_CMP_Claim_Amount__c', type: 'currency',
        cellAttributes:{alignment: 'center',class:{fieldName:'amountColor'}} }
    ];

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }

}