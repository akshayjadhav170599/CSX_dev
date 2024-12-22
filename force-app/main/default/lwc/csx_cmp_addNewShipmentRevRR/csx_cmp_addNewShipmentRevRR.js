import { LightningElement } from 'lwc';

export default class Csx_cmp_addNewShipmentRevRR extends LightningElement {

    // Object to store current form values with all attributes
    maximumDate;
    newShipment = {
        urrwinNumber: '',
        urrwinDate: '',
        stcc: '',
        description: '',
        equipmentInitial: '',
        equipmentNumber: '',
        waybillNumber: '',
        waybillDate: '',
        claimAmount: '',
        totalCars: '',
        actualOriginStateCode: '',
        actualOriginCityName: '',
        actualDestinationStateCode: '',
        actualDestinationCityName: ''
    }


    connectedCallback() {
        this.maximumDate = new Date().toISOString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
    }
    /** To handle changes done for user input*/
    handleInputChange(event) {
        if (event.target.type == 'date') {
            this.newShipment[event.target.name] = new Date(event.target.value).toISOString('en-US', { year: "numeric", month: "2-digit", day: "2-digit" }).split('T')[0];
        } else {
            this.newShipment[event.target.name] = event.target.value;
        }
    }

    /**  To handle both city changes on the sheet caused due to custom event passed*/
    handleCityChange(event) {
        let data = JSON.parse(event.detail);
        if (data.name === 'Origin City') {
            this.newShipment['actualOriginCityName'] = data.value;
        } else if (data.name === 'Destination City') {
            this.newShipment['actualDestinationCityName'] = data.value;
        }
    }
    /**  To handle both state changes on the sheet caused due to custom event passed*/
    handleStateChange(event) {
        let data = JSON.parse(event.detail);
        if (data.name === 'Origin State') {
            this.newShipment['actualOriginStateCode'] = data.value;
        } else if (data.name === 'Destination State') {
            this.newShipment['actualDestinationStateCode'] = data.value;
        }
    }

    /** Method to add claim to datatable */
    addToClaim() {

        let inputFields = this.template.querySelectorAll('lightning-input');
        let cityState = this.template.querySelectorAll('c-csx_cmp_display-city-state');
        let originCityState = cityState[0].validate();
        let destinationCityState = cityState[1].validate();
        let isValid = true;
        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }
        let newClaim = [];
        newClaim.push(this.newShipment);
        if (isValid && originCityState && destinationCityState) {
            this.dispatchEvent(new CustomEvent('addclaim', { detail: JSON.stringify(newClaim) }));
            this.resetForm();
        }
    }


    /** Will reset the complete form*/
    resetForm() {
        let inputFields = this.template.querySelectorAll('lightning-input');
        if (inputFields) {
            inputFields.forEach(inputField => {
                inputField.value = '';
            });
        }
        let reset = this.template.querySelectorAll('c-csx_cmp_display-city-state');
        reset.forEach(element => {
            element.resetData();
        });
        this.newShipment = {
            urrwinNumber: '',
            urrwinDate: '',
            stcc: '',
            description: '',
            equipmentInitial: '',
            equipmentNumber: '',
            waybillNumber: '',
            waybillDate: '',
            claimAmount: '',
            totalCars: '',
            actualOriginStateCode: '',
            actualOriginCityName: '',
            actualDestinationStateCode: '',
            actualDestinationCityName: ''
        }
    }

    /** Method to close popup*/
    closeModal() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

}