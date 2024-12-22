import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import fetchCaseDetail from '@salesforce/apex/CSX_CMP_InterfaceUtility.fetchCaseDetail';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

const caseResponseColumn = [
    { label: 'Created Date', fieldName: 'createdDate', type: 'date',hideDefaultActions: true,initialWidth: 150,cellAttributes: { alignment: 'left' },typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' } },
    { label: 'Response By', fieldName: 'responseBy', type: 'text',hideDefaultActions: true,initialWidth: 150 },
    { label: 'Type of User', fieldName: 'responseType', type: 'text',hideDefaultActions: true,initialWidth: 100 },
    { label: 'Details', fieldName: 'response', type: 'text',hideDefaultActions: true ,wrapText: true,initialWidth: 788}
];

const casecommentColumn = [
    { label: 'Created Date', fieldName: 'commentCreatedDate', type: 'date',hideDefaultActions: true,initialWidth: 150,cellAttributes: { alignment: 'left' } ,typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' }},
    { label: 'Comment By', fieldName: 'commentBy', type: 'text',hideDefaultActions: true,initialWidth: 150 },
    { label: 'Comment', fieldName: 'caseCommentInternal', type: 'text',hideDefaultActions: true,wrapText: true,initialWidth: 888 }
];

export default class Csx_cmp_caseSummary extends LightningElement {
    stylePath = csxStyle;
    caseResColumn = caseResponseColumn;
    caseComColumn = casecommentColumn;
    claimRecordData = {};

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }

    @wire(CurrentPageReference) pageReference;

    
    connectedCallback() {
        if (this.pageReference) {
            const state = this.pageReference.state;
            if (state) {
                const claimNumber = state.c__caseRecordId;
                console.log('claimNumber ::', claimNumber);
                if (claimNumber) {
                    fetchCaseDetail({ caseNumber: claimNumber })
                        .then(result => {
                            this.claimRecordData = result;
                            console.log('data @@', this.claimRecordData);
                        })
                        .catch(error => {
                            console.log('error ::', error);
                            csx_cmp_logError('Csx_cmp_caseSummary', 'connectedCallback', error, '');
                        })
                }
            }
        }
    }
}