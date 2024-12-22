import { LightningElement, api } from 'lwc';

export default class Csx_cmp_claimContactDetails extends LightningElement {

    contactName = '';
    phone = '';
    email = '';
    @api contactLabel = '';
    @api phoneLabel = '';
    @api emailLabel = '';
    @api isPhoneRequired = false;
    @api isNameRequired = false;
    @api isEmailRequired = false;

    handleNameChange(event) {
        this.contactName = event.target.value;
        let data = {
            label: 'contactName',
            value: this.contactName
        }
        this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
    }
    handlePhoneChange(event) {
        this.phone = event.target.value;
        let data = {
            label: 'phoneNumber',
            value: this.phone
        }
        this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
    }
    handleEmailChange(event) {
        this.email = event.target.value;
        let data = {
            label: 'email',
            value: this.email
        }
        this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
    }

    @api
    validate() {
        let inputFields = this.template.querySelectorAll('lightning-input');
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
    resetPage() {
        this.contactName = '';
        this.phone = '';
        this.email = '';
    }

}