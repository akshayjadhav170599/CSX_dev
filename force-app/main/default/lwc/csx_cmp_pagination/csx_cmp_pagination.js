import { LightningElement, api, track } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { loadStyle } from 'lightning/platformResourceLoader';
const recordsPerPage = [ 25,50,100];
const recordPerPageIns= [25,50,100];
const DEFAULTPAGESIZE = 25;
const pageNumber = 1;
const showIt = 'visibility:visible';
const hideIt = 'visibility:hidden'; //visibility keeps the component space, but display:none doesn't
export default class Cg_paginator extends LightningElement {

    @api showPagination; //Show/hide pagination; valid values are true/false
    @api pageSizeOptions = recordsPerPage; //Page size options; valid values are array of integers
    @api totalRecords; //Total no.of records; valid type is Integer
    @api records; //All records available in the data table; valid type is Array 
    @api paginationType;
    @api pageSize=''; //No.of records to be displayed per page
    totalPages = 1; //Total no.of pages
    pageNumber = pageNumber; //Page number
    searchKey; //Search Input
    controlPagination = showIt;
    controlPrevious = hideIt; //Controls the visibility of Previous page button
    controlNext = showIt; //Controls the visibility of Next page button
    @track recordsToDisplay = []; //Records to be displayed on the page
    showInfo = false;
    @api tableTitle; // Title of the table

    @api defaultRecordsPage = false;
    stylePath = csxStyle;
    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }
    //Called after the component finishes inserting to DOM
    connectedCallback() {
        console.log('this.pageSize: '+this.pageSize);
        if(this.paginationType==="Inspection"){
            this.pageSizeOptions=recordPerPageIns;
        }
        console.log('paginationType:'+this.paginationType);
        console.log('calling connectedCallback:'+ this.pageSizeOptions);
        this.setRecordsToDisplay();
        if (this.pageSizeOptions && this.pageSizeOptions.length > 0) {
                console.log('this.pageSize:'+this.pageSize);
                this.pageSize = this.pageSizeOptions[0];
                this.setRecordsToDisplay();
        }
        else {
            console.log('Inside:else: 48 ');
            this.pageSize = this.totalRecords;
            this.showPagination = false;
            this.setRecordsToDisplay();
        }
        console.log('size of records: '+this.totalRecords);
        if (this.defaultRecordsPage) {
            setTimeout(() =>
                this.template.querySelector('[name="selectRecordsPerPage"]').selectedIndex = 1
            );
            console.log('DEFAULTPAGESIZE: '+DEFAULTPAGESIZE);
            this.pageSize = DEFAULTPAGESIZE;
        }
        this.controlPagination = this.showPagination === false ? hideIt : showIt;
        if (this.totalRecords != 0) {
            console.log('Inside:else: 63 '+this.pageSize);
            this.setRecordsToDisplay();
        }

    }

    handleRecordsPerPage(event) {
        try{
        console.log('inside 74 handleRecordsPerPage');
        this.pageSize = event.target.value;
        this.dispatchEvent(new CustomEvent('pagesize', { detail: this.pageSize}));
        console.log('inside 72 handleRecordsPerPage');
        this.setRecordsToDisplay();
        }catch(ex){
            console.log('error:'+ex)
        }
    }
    handlePageNumberChange(event) {
        if (event.keyCode === 13) {
            console.log('inside 77 handlePageNumberChange');
            this.pageNumber = event.target.value;
            this.setRecordsToDisplay();
        }
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        console.log('previousPage 84 handlePageNumberChange');
        this.setRecordsToDisplay();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        console.log('previousPage 89 handlePageNumberChange');
        this.setRecordsToDisplay();
    }

    setRecordsToDisplay() {
        try {
            console.log('Inside: setRecordsToDisplay: '+this.pageSize);
            this.recordsToDisplay = [];
            if (!this.pageSize)
                this.pageSize = this.totalRecords;

            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            if (this.totalPages === 0 && this.totalRecords >= 0 && this.pageSize >= 0) {
                this.totalPages = 1;
            }

            this.setPaginationControls();

            for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
                if (i === this.totalRecords) 
                break;
                this.recordsToDisplay.push(this.records[i]);
            }
            this.dispatchEvent(new CustomEvent('paginatorchange', { detail: this.recordsToDisplay })); //Send records to display on table to the parent component
        } catch (ex) {
            console.log('exception error: ' + ex);
        }
    }

    setPaginationControls() {
        //Control Pre/Next buttons visibility by Total pages
        if (this.totalPages === 1) {
            this.controlPrevious = hideIt;
            this.controlNext = hideIt;
        } else if (this.totalPages > 1) {
            this.controlPrevious = showIt;
            this.controlNext = showIt;
        }
        //Control Pre/Next buttons visibility by Page number
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
            this.controlPrevious = hideIt;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
            this.controlNext = hideIt;
        }
        //Control Pre/Next buttons visibility by Pagination visibility
        if (this.controlPagination === hideIt) {
            this.controlPrevious = hideIt;
            this.controlNext = hideIt;
        }
    }
}

export function csx_cmp_paginatorMethod(recordsToDisplay, selectRow) {
    selectedRows = [];
    let updatedItemsSet = new Set();
    // List of selected items we maintain.
    let selectedItemsSet = new Set(selectRow);
    // List of items currently loaded for the current view.
    let loadedItemsSet = new Set();
    selectRow.map((ele) => {
        loadedItemsSet.add(ele.Id);
    });
    if (selectRow) {
        selectRow.map((ele) => {
            updatedItemsSet.add(ele.Id);
        });
        // Add any new items to the selectedRows list
        updatedItemsSet.forEach((id) => {
            if (!selectedItemsSet.has(id)) {
                selectedItemsSet.add(id);
            }
        });
    }
    loadedItemsSet.forEach((id) => {
        if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
            // Remove any items that were unselected.
            selectedItemsSet.delete(id);
        }
    });
    this.selectedRows = [...selectedItemsSet];
}