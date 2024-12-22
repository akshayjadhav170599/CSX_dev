import { LightningElement, api } from 'lwc';

export default class Csx_cmp_contactDetails extends LightningElement {

    @api contactName = '';
    @api email = '';
    phone = '';
    emailIds = '';
    USFormat = '(000) 000-0000';
    placeHolder = this.USFormat;
    formatLength = this.placeHolder.length;
    @api contactLabel = '';
    @api phoneLabel = '';
    @api emailLabel = '';
    @api emailsLabel = '';
    @api isPhoneRequired = false;
    @api isNameRequired = false;
    @api isEmailRequired = false;
    @api isEmailTextArea = false;

    handleNameChange(event) {
        this.contactName = event.target.value;
        let data = {
            label: 'contactName',
            value: this.contactName
        }
        this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
    }
    // onPhoneChange(event) {
    //     let getIndexOfSpecialCharMap = new Map();
    //     getIndexOfSpecialCharMap.set(0, '(');
    //     getIndexOfSpecialCharMap.set(4, ')');
    //     getIndexOfSpecialCharMap.set(5, ' ');
    //     getIndexOfSpecialCharMap.set(9, '-');


    //     let valueEntered = event.target.value;
    //     console.log('valueEntered : ', valueEntered);






    //     // let getIndexOfSpecialChar = [];
    //     // let getActualSpecialChar = [];
    //     // for (let i = 0; i < this.placeHolder.length; i++) {
    //     //     if (this.placeHolder[i] == ' ' || this.placeHolder[i] == '(' || this.placeHolder[i] == ')' || this.placeHolder[i] == '-') {
    //     //         getIndexOfSpecialChar.push(i);
    //     //         getActualSpecialChar.push(this.placeHolder[i]);
    //     //     }
    //     // }

    //     // let backSpace = event.keyCode;
    //     // console.log('event.target.value : ', event.target.value);
    //     // let len = event.target.value.length;
    //     // if (backSpace == 8) {
    //     //     len = len - 1;
    //     // } else if (event.keyCode == 9) {
    //     //     len = len - 1;
    //     // } else {
    //     //     len = event.target.value.length;
    //     // }

    //     // let eventTargetValue = event.target.value;
    //     // let phoneEntered;
    //     // if (event.target.value.length !== 0) {
    //     //     for (let i = 0; i < this.placeHolder.length; i++) {
    //     //         if (len == getIndexOfSpecialChar[i] && backSpace != 8) {
    //     //             phoneEntered = eventTargetValue + getActualSpecialChar[i];
    //     //             if (phoneEntered.length == getIndexOfSpecialChar[i + 1]) {
    //     //                 phoneEntered = phoneEntered + getActualSpecialChar[i + 1];
    //     //             }
    //     //         }
    //     //     }
    //     // }

    //     // if (phoneEntered) {
    //     //     this.phone = phoneEntered;
    //     // }

    //     // let eventTargetValue = event.target.value;
    //     // for (let i = 0; i < this.placeHolder.length; i++) {
    //     //     if (len == getIndexOfSpecialChar[i] && backSpace != 8) {
    //     //         this.phone = eventTargetValue + getActualSpecialChar[i];
    //     //         if (this.phone.length == getIndexOfSpecialChar[i + 1]) {
    //     //             this.phone = this.phone + getActualSpecialChar[i + 1];
    //     //         }
    //     //     }
    //     // }
    // }
    handlePhoneChange(event) {
        let phoneEntered = this.template.querySelector('[data-id="phoneNumberValue"]');
        let updatedPhone = '';
        if (phoneEntered) {
            phoneEntered.value = phoneEntered.value.replace(/[\(\)\-\s]/g, '');
            updatedPhone = this.arrangePhone(phoneEntered.value);
        }

        if (updatedPhone) {
            phoneEntered.value = updatedPhone;
        }

        let phoneRegex = /^(\([0-9]{3}\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}$/;

        if (event.target.value.length !== 0) {
            if (phoneEntered.value.match(phoneRegex)) {
                phoneEntered.setCustomValidity("");
                this.phone = event.target.value;
                let data = {
                    label: 'phoneNumber',
                    value: this.phone
                }
                this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
            } else {
                this.phone = event.target.value;
                phoneEntered.setCustomValidity("Please enter valid phone");
            }
        } else {
            phoneEntered.setCustomValidity("");
        }
        phoneEntered.reportValidity();
    }

    arrangePhone(phoneEntered) {
        let phoneEnteredArray = phoneEntered.split('');
        if (phoneEntered.length > 0) {
            phoneEnteredArray.splice(0, 0, '(');
        }
        if (phoneEntered.length > 3) {
            phoneEnteredArray.splice(4, 0, ')');
            phoneEnteredArray.splice(5, 0, ' ');
        }
        if (phoneEntered.length > 6) {
            phoneEnteredArray.splice(9, 0, '-');
        }
        return phoneEnteredArray.join('');
    }

    handleEmailChange(event) {
        let emailRegex = /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/;
        let emailsEntered = this.template.querySelector('[data-id="txtAreaEmailAddress"]');
        this.emailIds = event.target.value;
        let allValid = true;

        if (this.emailIds.length !== 0) {
            // let emailIdArray = this.emailIds.split(/[\n;]+/).map(email => email.trim());
            let semiRegex = /[;]{2,}/;
            if (this.emailIds.match(semiRegex)) {
                allValid = false;
            } else {
                let emailIdArray = this.emailIds.split(/[\n;]+/).map(email => email.trim());
                emailIdArray.forEach(email => {
                    if (!email.match(emailRegex)) {
                        allValid = false;
                    }
                });
            }

            if (allValid) {
                emailsEntered.setCustomValidity("");
            } else {
                emailsEntered.setCustomValidity("Please enter valid email.");
            }

            let data = {
                label: 'email',
                value: this.emailIds
            };
            this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
        } else {
            emailsEntered.setCustomValidity("");
        }
        emailsEntered.reportValidity();
    }





    handleEmailValidation(event) {
        if (event.target.value) {
            let emailRegex = /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/; // I have changed the regex need to check and test the function
            //  /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            let emailEntered = this.template.querySelector('[data-id="txtEmailAddress"]');
            let emailVal = emailEntered.value;
            if (emailVal.length !== 0) {
                if (emailVal.match(emailRegex)) {
                    emailEntered.setCustomValidity("");
                    this.email = event.target.value;
                    let data = {
                        label: 'email',
                        value: this.email
                    }
                    this.dispatchEvent(new CustomEvent('datachange', { detail: JSON.stringify(data) }));
                } else {
                    this.email = event.target.value;
                    emailEntered.setCustomValidity("Please enter valid email");
                }
            } else {
                emailEntered.setCustomValidity("");
            }
            emailEntered.reportValidity();
        }
    }

    @api
    validate() {
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ... this.template.querySelectorAll('lightning-textarea')];
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
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ... this.template.querySelectorAll('lightning-textarea')];
        if (inputFields) {
            inputFields.forEach(inputField => {
                console.log(inputField.label, inputField.required);
                inputField.value = '';
                let required = false;
                if (inputField.required) {
                    required = true;
                    inputField.required = false;
                }
                inputField.setCustomValidity("");
                inputField.reportValidity();
                if (required) {
                    inputField.required = true;
                }
            });
        }
    }
}