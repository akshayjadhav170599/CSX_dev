import { LightningElement, api } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';

export default class Csx_cmp_ldrTypeSelection extends NavigationMixin(LightningElement) {
    display = [
        { label: 'displayDerailment', display: false },
        { label: 'displayCustomer', display: false },
        { label: 'displayIntransit', display: false },
        { label: 'displaySearch', display: true },
    ]; 
    
    displayDerailment = false;
    displayCustomer = false;
    displayIntransit = false;
    @api displaySearch = false;
    @api displayModal;
    ldrNumber = '';
    ldrId;
    ldrRecId;

    selectedOption = { 'label': '', 'value': '' };
    stylePath = csxStyle;

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
        this.displayModal = true;
    }

    closeModal() {
        this.displayModal = false;
        if(this.displaySearch == false){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'CSX_CMP_LD_Report__c',
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
                    apiName: 'CSX_CMP_LD_Report_Search'
                },
            });
        }
    }

    openSelectedType(event) {
        let data = JSON.parse(event.detail);
        let picklistOptions = data.picklistOptions;
        let selectedOption = picklistOptions.find(option => option.display == true);
        this.selectedOption.label = selectedOption.label;
        this.selectedOption.value = selectedOption.value;
        if (selectedOption.value == 'Recovery') {
            selectedOption = picklistOptions.find(option => option.label == 'In transit');
        }
        let optionLabel = 'display' + selectedOption.label + ' '; //Do not remove space after label
        optionLabel = optionLabel.replace(/\s/g, '');

        // Updating display Object with selected option
        this.display.forEach(option => {
            if (option.label == optionLabel) {
                option.display = true;
            } else {
                option.display = false;
            }
        });

        //assigning values to display variables
        this.updateDisplay();
        this.displayModal = false;

        this.dispatchEvent(new CustomEvent('closesearch', {
            detail: {
                value: this.displaySearch,
            }
        }));
    }

    sendtoConfirmation(event) {
        let data = JSON.parse(event.detail);
        this.displayDerailment = false;
        this.displayCustomer = false;
        this.displayIntransit = false;
        this.ldrNumber = data.ldrName;
        this.ldrId = data.ldrId;
        this.ecmLink = data.ecmLink;
    }
    updateDisplay() {
        this.displayDerailment = this.display.find(option => option.label == 'displayDerailment').display;
        this.displayCustomer = this.display.find(option => option.label == 'displayCustomer').display;
        this.displayIntransit = this.display.find(option => option.label == 'displayIntransit').display;
        this.displaySearch = this.display.find(option => option.label == 'displaySearch').display;
    }
}