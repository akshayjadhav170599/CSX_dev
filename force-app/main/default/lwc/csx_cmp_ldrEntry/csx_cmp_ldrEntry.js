import { LightningElement } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Csx_cmp_ldrEntry extends LightningElement {

   
    displaySearch = true;
    displayModal = false;

    selectedOption = { 'label': '', 'value': '' };
    stylePath = csxStyle;
    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }

    openModal() {
        this.displayModal = true;
    }
    closeModal() {
        this.displayModal = false;
    }

    overlapSearch(event){
       this.displaySearch = event.detail.value;
    }

}