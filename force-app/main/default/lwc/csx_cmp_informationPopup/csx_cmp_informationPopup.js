import { LightningElement,api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Csx_cmp_informationPopup extends LightningElement {

    @api isModalOpen=false;
    isSpinner=false;
    @api informationHeading;
    @api informationData=[];
    @api informationColoumn=[];
    sortByDetail='';
    sortDirection = 'asc';

        connectedCallback() {

            if(this.informationData){
                this.isSpinner=true;
            }

            }
            Exit(){
                this.closeModal();
            }
            
            closeModal(){
                this.isModalOpen=false;
                const name= 'Close';
                const selectEvent=new CustomEvent('detailchange',{detail:name,bubbles:true});
                this.dispatchEvent(selectEvent);
                this.dispatchEvent(new CloseActionScreenEvent());
            }

            doSortingDetail(event){
                let sortbyField = event.detail.fieldName;
                this.sortByDetail = sortbyField;
                
                this.sortDirection = event.detail.sortDirection;
                this.sortDataDetail(this.sortByDetail, this.sortDirection);
                this.sortByDetail = sortbyField;
            }
            sortDataDetail(fieldName, sortDirection){
                let sortResult = Object.assign([], this.informationData);
                this.informationData = sortResult.sort(function (a, b) {
                    a = a[fieldName] ? a[fieldName] : ''; // handling null values
                    b = b[fieldName] ? b[fieldName] : '';          
                    if (a < b) {
                        return sortDirection === 'asc' ? -1 : 1;
                    } else if (a > b) {
                        return sortDirection === 'asc' ? 1 : -1;
                    } else {
                        return 0;
                    }
                })
                if (this.searchResultDetail) {
                    this.searchResultDetail = false;
                }
                else {
                    this.searchResultDetail = true;
                }        
            }  

    }