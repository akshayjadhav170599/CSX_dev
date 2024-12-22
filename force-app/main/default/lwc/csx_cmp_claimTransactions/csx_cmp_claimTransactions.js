import { LightningElement, api} from 'lwc';
import fetchCostofClaimTransactions from '@salesforce/apex/CSX_CMP_TotalCostofClaimHelper.fetchCostofClaimTransactions';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Csx_cmp_claimTransactions extends LightningElement {
    @api recordId;
    @api showPopup;
    Details = [];
    transactionsPaginatorRecords;
    isCssLoaded = false;

    transactionscolumn = [
        {
            label: 'Type', fieldName: 'type', type: 'text',
            cellAttributes: { alignment: 'left', class: { fieldName: 'totalAmountColor' } }, initialWidth: 200, hideDefaultActions: true
        },
        {
            label: 'Reference #', fieldName: 'referrenceRecordId', type: 'url',
            cellAttributes: {
                alignment: 'left',
            }, typeAttributes: {
                label: { fieldName: 'referrenceNum' }
            }, initialWidth: 150, hideDefaultActions: true
        },
        {
            label: 'Amount', fieldName: 'amount', type: 'currency',
            typeAttributes: { currencyCode: 'USD' },
            cellAttributes: {
                alignment: 'left', class: { fieldName: 'color' },
            }, initialWidth: 100, hideDefaultActions: true

        },
    ];

    closeModal() {
        this.showPopup = false;
        this.dispatchEvent(new CustomEvent('closemodal', {}));
    }

    connectedCallback() {
        fetchCostofClaimTransactions({ claimId: this.recordId }).then(result => {
            console.log('result', result);
            if (result) {
                this.Details = result.map(item => {
                    console.log('item' + item);
                    let color = item.amount > 0 ? "slds-text-color_success" : "slds-text-color_error"
                    let referrenceRecordId = item.referrenceRecordId != '' ? '/' + item.referrenceRecordId : '';

                    let amount = item.amount.toString();
                    amount = parseFloat(amount.includes('-') ? amount.replace('-', '-') : amount);
                    let totalAmountColor;
                    if (item.type === 'Total Amount') {
                        totalAmountColor = 'slds-text-title_bold';
                        color = color + ' slds-text-title_bold';
                    } else {
                        totalAmountColor = '';
                    }
                    return {
                        ...item,
                        "totalAmountColor": totalAmountColor,
                        "color": color,
                        "referrenceRecordId": referrenceRecordId,
                        "amount": amount
                    }
                });
            }
            console.log('this.Details', this.Details);
        }).catch(error => {
            console.error('error', error);
        });
    }

    renderedCallback() {
        if (this.isCssLoaded) {
            return
        }

        this.isCssLoaded = true

        loadStyle(this,).then(() => {
            console.log("Loaded Successfully")
        }).catch(error => {
            console.log(error)
        });
    }

}