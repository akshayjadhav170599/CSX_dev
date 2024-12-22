import { LightningElement} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Csx_cmp_claimEntry extends NavigationMixin(LightningElement) {
    isModelOpen = false;
    selectedOption = '';
    selectedOpt = '';
    isFreightCreation = false;
    isRevRRCreation = false;
    isRevContractCreation = false;
    isNewClaim = true;
    isClaimSearch = true;
    claimNumber = '';
    claimId;
   // claimRecId;
    declineRes;
    //isShip;
    stylePath = csxStyle;
    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }
    
    openModal() {
        this.isModelOpen = true;
        //this.isClaimSearch = false;
    }
    closeModal() {
        this.isModelOpen = false;
        //this.isClaimSearch = true;
    }

    /*displaySearch() {
        this.selectedOption = '';
        this.selectedOpt = '';
        this.isNewClaim = true;
        this.isClaimSearch = true;
        this.isFreightCreation = false;
        this.isRevRRCreation = false;
        this.isRevContractCreation = false;
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
    }*/

    overlapSearch(event){
       this.isClaimSearch = event.detail.value;
    }
}