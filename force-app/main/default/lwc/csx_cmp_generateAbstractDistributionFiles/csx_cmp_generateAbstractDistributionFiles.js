import { LightningElement, track, wire } from 'lwc';
import searchCarrierAlphaCode from '@salesforce/apex/CSX_CMP_GenerateAbstractDistributionCtrl.searchCarrierAlphaCode';
import scheduleBatchJob from '@salesforce/apex/CSX_CMP_GenerateAbstractDistributionCtrl.scheduleBatchJob';
import calculateServicePeriod from '@salesforce/apex/CSX_CMP_GenerateAbstractDistributionCtrl.calculateServicePeriod';
import checkProfileName from '@salesforce/apex/CSX_CMP_GenerateAbstractDistributionCtrl.checkProfileName';
import genericError from '@salesforce/label/c.CSX_CMP_Generic_Error_Label';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_generateAbstractDistributionFiles extends LightningElement { 
    loggedINUser;
    isFreight = true;
    isRevenue = false;
    @track selectedRunFor; 
    @track selectedSpecificRailroad;
    @track selectedServicePeriod;
    servicePeriodError = '';
    runForError = '';
    specificRailroadError = '';
    error;
    @track carrierAlphaCode = [];
    @track RunForOptions = [];
    label = { genericError };
    @track selectedValue;
    
    @wire(checkProfileName) 
    wiredcheckProfileName({ data, error }){
        if (data) {
            this.loggedINUser = data;
            if (this.loggedINUser == 'Other') {
                this.adminUser();    
            }
            else if (this.loggedINUser == 'Freight') {
                this.freightUser();
            }
            else if (this.loggedINUser == 'Revenue') {
                this.revenueUser();
            } 

            //Disable Specific RR
            const specificRR = this.template.querySelector('[data-id="SpecificRailroadCode"]');
            if(specificRR != null){
                specificRR.disabled = true;
            }

        }else if (error) {
            console.log('error' + error);
        }
    }

    adminUser() {
        this.isFreight = true;
        this.isRevenue = true;
        this.selectedRunFor = 'Non Class 1';
        this.selectedValue = 'Freight';
        this.selectedSpecificRailroad = '';
        this.searchAlphaCode();
        this.setRunForOption();   
    }

    freightUser() {
        this.isFreight = true;
        this.isRevenue = false;
        this.selectedRunFor = 'Non Class 1';
        this.selectedValue = 'Freight';
        this.selectedSpecificRailroad = '';
        this.searchAlphaCode();
        this.setRunForOption();   

        if (this.loggedINUser == 'Freight') {
            const revenueRadio = this.template.querySelector('[data-id="revenueOption"]');
            revenueRadio.disabled = true;    
        }
    }

    revenueUser() {
        console.log('revenueUser??');
        this.isFreight = false;
        this.isRevenue = true;
        this.selectedRunFor = 'All';
        this.selectedValue = 'Revenue_Railroad';
        this.selectedSpecificRailroad = '';
        this.searchAlphaCode();
        this.setRunForOption();   

        if (this.loggedINUser == 'Revenue') {
            const freightRadio = this.template.querySelector('[data-id="freightOption"]');
            freightRadio.disabled = true;    
        }
    }


    @wire(calculateServicePeriod)
    wiredcalculateServicePeriod({ data, error }) {
        if (data) {
            this.selectedServicePeriod = data;
        } else if (error) {
            console.error('ERROR: ', error);
        }
    }

    searchAlphaCode() {
        this.carrierAlphaCode = [];
        searchCarrierAlphaCode({ strSelectedValue : this.selectedValue, strServicePeriod : this.selectedServicePeriod, strRunFor : this.selectedRunFor})
        .then(result => {
            this.carrierAlphaCode = result.map((elem) => { 
                return {
                    label: elem,
                    value: elem 
                };
            });
        })
        .catch(error => {
            csx_cmp_logError('Csx_cmp_generateAbstractDistributionFiles', 'searchAlphaCode', error, '');
        });    
    }
    
    handleClaimCategoryChange(event) {
        if (event.target.value == 'Freight' && this.loggedINUser == 'Other') {
            this.freightUser();
            this.setRunForOption();
        }
        else if (event.target.value == 'Revenue' && this.loggedINUser == 'Other') {
            this.revenueUser();
            this.setRunForOption();
        }
        else if (event.target.value == 'Freight' && this.loggedINUser == 'Freight') {
            this.freightUser();
            this.setRunForOption();
        }
        else if (event.target.value == 'Revenue' && this.loggedINUser == 'Revenue') {
            this.revenueUser();
            this.setRunForOption();
        }
    }
    
    scheduleJob()
    {
        const servPeriod = this.template.querySelector('[data-id="servicePeriod"]');
        console.log(servPeriod.value == '');

        if (servPeriod.value != '' ) {
            this.selectedServicePeriod = servPeriod.value;
            this.validateServicePeriod(this.selectedServicePeriod);
            
            if (this.selectedSpecificRailroad == '' && this.selectedRunFor == 'Specific RR') {
                this.specificRailroadError = 'Please fill Specific Railroad.';
            } else {
                this.specificRailroadError = '';
            }

            if (this.selectedRunFor == '') {
                this.runForError = 'Please fill Run For.';
            } else {
                this.runForError = '';
            }

            if (this.servicePeriodError == '' && this.runForError == '' && this.specificRailroadError == '') { 
                scheduleBatchJob({ strSelectedValue : this.selectedValue, strServicePeriod : this.selectedServicePeriod, strRunFor : this.selectedRunFor, strspecificRailRoad : this.selectedSpecificRailroad, isManual: true})
                .then(result => {
                    this.showSuccessToast(result);
                    window.location.reload();
                })
                .catch(error => {
                    console.log(error);
                    this.showErrorToast(this.label.genericError);
                });
            }    
        } else {
            this.servicePeriodError = 'Please fill Service Period.';
        }
    }

    showErrorToast(msglabel) {
        const evt = new ShowToastEvent({
            message: msglabel,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    showSuccessToast(msglabel) {
        const evt = new ShowToastEvent({
            message: msglabel,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    connectedCallback() {
        this.setRunForOption();    
    }

    setRunForOption() {
        if (this.isFreight) {
            this.RunForOptions = [
                { label: 'Class 1', value: 'Class 1' },
                { label: 'Non Class 1', value: 'Non Class 1' },
                { label: 'Specific RR', value: 'Specific RR' }, 
            ];    
        }
        else {
            this.RunForOptions = [
                { label: 'All', value: 'All' },
                { label: 'Class 1', value: 'Class 1' },
                { label: 'Non Class 1', value: 'Non Class 1' },
                { label: 'Specific RR', value: 'Specific RR' }, 
            ];
        }
    }

    handleRunForChange(event) {
        this.selectedRunFor = event.detail.value;
        this.selectedSpecificRailroad = '';
        if (this.selectedRunFor != 'Specific RR') {
            //Disable Specific RR
            const specificRR = this.template.querySelector('[data-id="SpecificRailroadCode"]');
            specificRR.disabled = true;   
        } else {
            //Enable Specific RR
            const specificRR = this.template.querySelector('[data-id="SpecificRailroadCode"]');
            specificRR.disabled = false;   
        }
        this.searchAlphaCode();
    }

    handleSpecificRailroadChange(event) {
        this.selectedSpecificRailroad = event.detail.value;
    }

    removeMessage() {
        // Clear previous error message
        this.servicePeriodError = '';
    }

    handleServicePeriodBlur(event) {
        // Clear previous error message
        this.servicePeriodError = '';
        this.selectedSpecificRailroad = '';
        this.selectedServicePeriod = event.target.value;
            
        // Log the entered value for debugging
        this.validateServicePeriod(event.target.value);
        this.searchAlphaCode();
    }

    validateServicePeriod(enteredValue) {
        // Validate servicePeriod field in real-time
        const regexPattern = /^PER-(1[0-2]|[1-9])-[0-9]{2}$/;
        const regexCheckValue = /^PER-\d{1,}-\d{1,}$/;
        if (enteredValue == '') {
            this.servicePeriodError = 'Please fill Service Period.';
        }else if (!regexPattern.test(enteredValue)) {
            this.servicePeriodError = 'Please use the given format: PER-6-23';
        }
        else if (regexCheckValue.test(enteredValue)) {
            // validation for future date 
            const parts = enteredValue.split('-');
            const enteredMonth = parseInt(parts[1], 10);
            const enteredYear = parseInt(parts[2], 10);

            const currentDate = new Date();
            const currentMonth = currentDate.getMonth() + 1; // January is 0, so add 1
            const currentYear = parseInt(currentDate.getFullYear().toString().slice(-2), 10);

            if (enteredYear > currentYear || (enteredYear === currentYear && enteredMonth > currentMonth)) {
                this.servicePeriodError = 'Entered month & year cannot be greater than the current date.';
            } else {
                console.log('Check the numbers you have entered.'); // Log success
            }
        }
        else { 
            this.searchAlphaCode();
        }
    }
}