import { LightningElement, api } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

export default class Csx_cmp_claimRecTypeSelection extends NavigationMixin(LightningElement)  {
    @api isModelOpen;
    @api isClaimSearch = false;;
    selectedOption = '';
    selectedOpt = '';
    isFreightCreation = false;
    isRevRRCreation = false;
    isRevContractCreation = false;
    claimNumber = '';
    claimId;
    declineRes;
    stylePath = csxStyle;

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
        this.isModelOpen = true;
       
    }
    
    closeModal() {
        this.isModelOpen = false;
        if(this.isClaimSearch == false){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Case',
                    actionName: 'list'
                },
                state: {
                    filterName: '__Recent' 
                }
            });
        }else{
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'CSX_CMP_Claim_Search'
                },
            });
        }

    }

    openFreight(event) {
        this.selectedOption = event.detail.label;
        this.selectedOpt = event.detail.value;
        if (this.selectedOption === 'Freight') {
            console.log('inside freight');
            this.isModelOpen = false;
            this.isNewClaim = false;
            this.isClaimSearch = false;
            this.isFreightCreation = true;
        }
        else if (this.selectedOption === 'Railroad Revenue') {//Revenue - Railroad
            this.isModelOpen = false;
            this.isNewClaim = false;
            this.isClaimSearch = false;
            this.isRevRRCreation = true;

        }
        else if (this.selectedOption === 'Contract Refund') {
            this.isModelOpen = false;
            this.isNewClaim = false;
            this.isClaimSearch = false;
            this.isRevContractCreation = true;
        }

        this.dispatchEvent(new CustomEvent('closesearch', {
            detail: {
                value: this.isClaimSearch,
            }
        }));
    }
    
    sendClaimtoConfirmation(event) {
        
        let data = JSON.parse(event.detail);
        this.isFreightCreation = false;
        this.isRevRRCreation = false;
        this.isRevContractCreation = false;
        this.claimNumber = data.claimNum;
        this.claimId = data.claimId;
        this.ecmLink=data.ecmLink;
        this.declineRes = data.declineReason;
        //this.isShip = data.shipCSX;
        // this.claimRecId=event.detail.;
    }

}