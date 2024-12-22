import { LightningElement, api, wire, track } from 'lwc';
import getStatesAndCities from '@salesforce/apex/CSX_CMP_StateCityController.getStatesAndCities';
export default class Csx_cmp_displayCityState extends LightningElement {
    @track data
    @api selectedState = '';
    @api selectedCity = '';
    @track stateOptions = [];
    @track cityOptions = [];
    @track cityDisabled = true;
    @api cityLabel = '';
    @api stateLabel = '';
    @api isStateRequired = false;
    @api isCityRequired = false;

    @wire(getStatesAndCities)
    wiredStateAndCityData({ data, error }) {
        if (data) {
            this.data = data;
            this.stateOptions = Object.keys(data).map(state => ({
                label: state,
                value: state
            }));
        }
        if (error) {
            console.error('Error from Apex:', error);
        }
    }
    handleStateChange(event) {
        this.selectedState = event.detail.value;
        this.selectedCity = '';
        if (this.selectedState && this.data && this.data[this.selectedState]) {
            this.cityOptions = this.data[this.selectedState].map(city => ({
                label: city,
                value: city
            }));
            this.cityDisabled = false;
        } else {
            this.cityOptions = [];
            this.cityDisabled = true;
        }

        let data = {
            name: this.stateLabel,
            value: this.selectedState
        }
        this.dispatchEvent(new CustomEvent('selectedstate', { detail: JSON.stringify(data) }));
    }
    handleCityChange(event) {
        this.selectedCity = event.detail.value;

        let data = {
            name: this.cityLabel,
            value: this.selectedCity
        }
        this.dispatchEvent(new CustomEvent('selectedcity', { detail: JSON.stringify(data) }));
    }

    @api
    resetData() {
        this.selectedState = '';
        this.selectedCity = '';
        this.cityOptions = [];
        this.cityDisabled = true;

        return true;
    }

    @api
    validate() {
        let inputFields = this.template.querySelectorAll('lightning-combobox');
        let isValid = true;
        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }
        return isValid;
    }

    @api
    assignValues(state, city) {
        this.selectedState = this.stateOptions.find(stateOption => stateOption.value === state).value;
        this.selectedCity = '';
        if (this.selectedState && this.data && this.data[this.selectedState]) {
            this.cityOptions = this.data[this.selectedState].map(city => ({
                label: city,
                value: city
            }));
            this.cityDisabled = false;
        } else {
            this.cityOptions = [];
            this.cityDisabled = true;
        }
        this.selectedCity = this.cityOptions.find(cityOption => cityOption.value === city).value;
    }

}