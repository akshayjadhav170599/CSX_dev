import { LightningElement, track, wire } from 'lwc';
import getClaims from '@salesforce/apex/CSX_CMP_HandleNettingCalculation.calculateNettingResults';
import notFound from '@salesforce/label/c.CSX_CMP_NoResultsFound';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import sessionLabel from '@salesforce/label/c.CSX_CMP_Netting_Create_Session_Time';
import getClaimRecordTypeRole from '@salesforce/apex/CSX_CMP_HandleNettingCalculation.getClaimRecordTypeRole';

export default class Csx_cmp_nettingRequestSubmission extends LightningElement {
    userId = Id;
    userProfileName;

    @track servicePeriod;
    matchValue = false;
    @track claimRecords = [];
    error;
    isClaimAvailable = true;
    isButtonDisable = true;
    showSpinner = false;
    servicePeriodError = '';
    clickCount = 0;
    label = {
        notFound,
        sessionLabel
    };
    claimSelectionRoad = {
        'radioClaim': '',
        'radioRun': ''
    };
    defaultSelectedvalue = '';
    otherProfile = true;
    isButtonShow = false;
    labelValue;
    nettingListLabel;

    currentTimePreview;
    currentTimeCreate;
    timeDuration;
    userRoleName = '';
    userDetails;

    @wire(getClaimRecordTypeRole)
    layoutDetails({ data, error }) {
        if (data) {
            this.userDetails = data;
        } else if (error) {
            csx_cmp_logError('Csx_cmp_NettingRequestSubmission', 'layoutDetails', error, '');
        }
    }

    get Options() {
        let returnList = [];
        let options = [{ label: 'Freight', value: 'Freight' },
        { label: 'Revenue Railroad', value: 'Revenue_Railroad' }];
        let recordTypeMap = new Map();
        recordTypeMap.set('Freight', 'Freight');
        recordTypeMap.set('Revenue Railroad', 'Railroad Revenue');
        let user = this.userDetails;

        if (user) {
            if (user.CSX_CMP_Run_Netting_Jobs__c) {
                let recordTypes = user.CSX_CMP_Search_Layout_Access__c;
                let availableRecordTypes = recordTypes.split(',');
                options.forEach(element => {
                    if (availableRecordTypes.includes(recordTypeMap.get(element.label))) {
                        returnList.push(element);
                    }
                });
            }

            if (returnList.length > 0) {
                if (user.Label != 'Claims Admin') {
                    this.defaultSelectedvalue = returnList[0].value;
                    this.claimSelectionRoad['radioClaim'] = returnList[0].value;
                }
            }
            if (user.Label === 'Claims Admin') {
                this.defaultSelectedvalue = '';
                //this.claimSelectionRoad['radioClaim'] = '';
                this.otherProfile = false;
            }
        }
        return returnList;
    }

    get optionRunType() {
        return [
            { label: 'Preview', value: 'Preview' },
            { label: 'Create', value: 'Create' },
            { label: 'Post View', value: 'View' },
        ];
    }


    constructor() {
        super();
        this.isButtonDisable = true;
        const currentDate = new Date();
        // Get the month and year of the current date
        const currentMonth = currentDate.getMonth();
        const currentYear = currentDate.getFullYear();

        // Calculate the month and year of the previous month
        let previousMonth = currentMonth;
        let previousYear = currentYear;
        if (previousMonth <= 0) {
            // If the previous month is negative, subtract 1 from the year and set the month to 11 (December)
            previousMonth = 12;
            previousYear -= 1;
        }
        this.servicePeriod = 'PER-' + previousMonth + '-' + previousYear.toString().substring(2, 4);
    }


    handleChange(event) {
        this.servicePeriod = '';
        this.claimRecords = [];
        if (event.target.value) {
            this.servicePeriod = event.target.value;
            this.matchValue = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleInputChange(event) {
        this.claimRecords = [];
        if (event.target.name === 'radioClaim') {
            this.claimSelectionRoad[event.target.name] = '';
            this.claimSelectionRoad[event.target.name] = event.target.value;
        } else if (event.target.name === 'radioRun') {
            this.claimSelectionRoad[event.target.name] = '';
            this.claimSelectionRoad[event.target.name] = event.target.value;
        }
        //2 May changes | Start
        if (this.claimSelectionRoad.radioRun == 'Preview') {
            this.labelValue = 'Run';
            this.nettingListLabel = 'Pre Netting Results';
        } else if (this.claimSelectionRoad.radioRun == 'Create') {
            this.labelValue = 'Execute';
            this.nettingListLabel = 'Netting Results';
        } else if (this.claimSelectionRoad.radioRun == 'View') {
            this.labelValue = 'Run';
            this.nettingListLabel = 'Post Netting Results';
        }
        //2 May changes | End
        if (this.claimSelectionRoad.radioClaim && this.servicePeriod && this.claimSelectionRoad.radioRun) {
            this.isButtonShow = true;
            this.isButtonDisable = false;
        }
    }

    handleClick() {
        if (this.claimSelectionRoad.radioRun == 'Preview') {
            this.clickCount++;
            this.currentTimePreview = new Date().getTime();
        }
        if (this.clickCount == 0 && this.claimSelectionRoad.radioRun == 'Create') {
            this.showToast('Error', 'Please preview once', 'warning');
            return;
        }
        if (!this.servicePeriod) {
            this.claimRecords = [];
            this.showSpinner = false;
            this.showToast('Error', 'Please fill service period', 'error');
            return;
        }

        this.matchValue = false;
        this.showSpinner = false;
        if (this.servicePeriod) {
            this.showSpinner = false;
            const regexpattern = /^PER-([1-9]|1[0-2])-\d{2}$/;
            const isValidFormat = regexpattern.test(this.servicePeriod);
            if (!isValidFormat) {
                this.claimRecords = [];
                this.showSpinner = false;
                this.servicePeriodError = 'Incorrect PER-M-YY Format';
                this.matchValue = true;
                return;
            }
        }

        //====15 May changes | Start
        if (this.claimSelectionRoad.radioRun == 'Create') {
            this.currentTimeCreate = new Date().getTime();
            this.timeDuration = this.currentTimeCreate - this.currentTimePreview;
            const sessionTimeDur = this.label.sessionLabel * 60000;
            if (this.timeDuration > sessionTimeDur) {
                window.alert('Kindly preview again and then proceed with creation.');
                location.reload();
                return;
            }
        }
        //====15 May changes | END
        if (this.matchValue == false) {
            this.servicePeriodError = '';
            this.showSpinner = true;
            getClaims({ claimCategory: this.claimSelectionRoad.radioClaim, servicePeriod: this.servicePeriod, runType: this.claimSelectionRoad.radioRun })
                .then(result => {
                    if (result != null) {
                        this.claimRecords = result;
                        this.showSpinner = false;

                    }
                    if (this.claimRecords.length > 0) {
                        this.isClaimAvailable = true;
                        this.showSpinner = false;
                    } else {
                        this.isClaimAvailable = false;
                        this.showSpinner = false;
                    }
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.claimRecords = undefined;
                    this.showSpinner = false;
                    let parameters = ''
                    csx_cmp_logError('Csx_cmp_NettingRequestSubmission', 'handleClick', error, parameters);
                })
        }

    }
}