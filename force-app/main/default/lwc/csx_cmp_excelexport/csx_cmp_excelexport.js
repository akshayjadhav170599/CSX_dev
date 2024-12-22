import { LightningElement, api} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import workbook from "@salesforce/resourceUrl/CSX_CMP_ExportJS";
export default class Csx_cmp_excelexport extends LightningElement {
  @api headerList;
  @api filename;
  @api worksheetNameList;
  @api sheetData;
  librariesLoaded = false;

  renderedCallback() {
    if (this.librariesLoaded) return;
    this.librariesLoaded = true;

    loadScript(this, workbook + "/xlsx.full.min.js")
      .then(() => {
        this.dispatchEvent(new CustomEvent('libraryloaded'));
      })
      .catch(error => {
        csx_cmp_logError('csx_cmp_excelexport', 'renderedCallback', error, '');
      });
  }

  @api
  download() {
    try {
      const XLSX = window.XLSX;
      let xlsData = this.sheetData;
      let xlsHeader = this.headerList;
      let ws_name = this.worksheetNameList;
      let createXLSLFormatObj = Array(xlsData.length).fill([]);

      /* form header list */
      xlsHeader.forEach((item, index) => createXLSLFormatObj[index] = [item])

      /* form data key list */
      xlsData.forEach((item, selectedRowIndex) => {
        let xlsRowKey = Object.keys(item[0]);
        item.forEach((value) => {
          let innerRowData = [];
          xlsRowKey.forEach(item => {
            innerRowData.push(value[item]);
          })
          createXLSLFormatObj[selectedRowIndex].push(innerRowData);
        })

      });
      /* creating new Excel */
      let wb = XLSX.utils.book_new();

      /* creating new worksheet */
      let ws = Array(createXLSLFormatObj.length).fill([]);
      for (let i = 0; i < ws.length; i++) {
        /* converting data to excel format and puhing to worksheet */
        let data = XLSX.utils.aoa_to_sheet(createXLSLFormatObj[i]);
        ws[i] = [...ws[i], data];

        /* Add worksheet to Excel */
        XLSX.utils.book_append_sheet(wb, ws[i][0], ws_name[i]);
      }

      /* Write Excel and Download */
      XLSX.writeFile(wb, this.filename);
    } catch (error) {
      let parameters = JSON.stringify(this.sheetData) + ' filename-' + this.filename;
      csx_cmp_logError('csx_cmp_excelexport', 'download', error, parameters);
    }
  }

  /**exportCSVFile method builds a csv file and allows user to download it. 
  headerList : List of Strings containing all column names as it should be displayed on sheet
  totalData : sample data which needs to be inserted on sheet
  fileName : name of the sheet which will be downloaded
  columnMap : Map of column label and fieldname (refer csx_cmp_uploadShipmentRevRR for details) */
  @api
  exportCSVFile(dataToExport) {
    let data = JSON.parse(dataToExport);
    let headers = data.headerList;
    let totalData = data.data;
    let fileTitle = data.filename;
    let columns = Object.entries(JSON.parse(data.columnMap));
    let columnMap = new Map(columns);
    let doc = '';
    try {
      if (headers.length > 0) {
        headers.forEach(element => {
          doc += element + ',';
        });
      }

      doc += '\r\n';
      if (totalData.length > 0) {
        totalData.forEach(element => {

          headers.forEach(header => {
            doc += element[columnMap.get(header)] + ',';
          });

          doc += '\r\n';
        });
      }

      let element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
      let downloadElement = document.createElement('a');
      downloadElement.href = element;
      downloadElement.target = '_self';
      downloadElement.download = fileTitle;
      document.body.appendChild(downloadElement);
      downloadElement.click();
    } catch (error) {
      let parameters = JSON.stringify(data);
      csx_cmp_logError('csx_cmp_excelexport', 'exportCSVFile', error, parameters);
    }
  }

  /** 
  readCSVFile method needs single csv file as input and returns 
  flow of methods is readCSVFile -> load -> parseCSV
  columnMap : Map of column label and fieldname (refer csx_cmp_uploadShipmentRevRR for details)
  headerMap : Object containing label, fieldname and required status of column 
  */
  @api
  async readCSVFile(data) {
    let file = data.file;
    let columns = Object.entries(JSON.parse(data.columnMap));
    let columnMap = new Map(columns);
    let headerMap = data.headerMap;
    try {
      const result = await this.load(file);
      if (result && columnMap && headerMap) {
        let data = this.parseCSV(result, columnMap, headerMap);
        return JSON.stringify(data);
      } else {
        let parameters = JSON.stringify(data);
        csx_cmp_logError('csx_cmp_excelexport', 'readCSVFile', 'Check columnMap or headerMap format and file type', parameters);
      }

    } catch (error) {
      let parameters = JSON.stringify(data);
      csx_cmp_logError('csx_cmp_excelexport', 'readCSVFile', error, parameters);
    }
  }

  async load(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = () => {
        resolve(reader.result);
      };
      reader.onerror = () => {
        reject(reader.error);
      };
      reader.readAsText(file);
    });
  }

  parseCSV(csv, columnMap, headerMap) {
    let regexMap = new Map();
    regexMap.set('date', /^\d{1,2}\/\d{1,2}\/\d{4}$/);
    regexMap.set('text', /^[A-Za-z ]+$/);
    regexMap.set('number', /^[0-9]+$/);
    regexMap.set('decimal', /^[0-9]+(\.[0-9]{1,2})?$/);
    regexMap.set('alphanumeric', /^[A-Za-z0-9]+$/);
    regexMap.set('alphanumericwithspace', /^[A-Za-z0-9 ]+$/);
    regexMap.set('alphanumericwithspecialcharacters', /^[A-Za-z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/? ]+$/);
    regexMap.set('email', /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/);
    regexMap.set('currency', /^[0-9]+(\.[0-9]{1,2})?$/);

    try {
      const lines = csv.split(/\r\n|\n/);
      const headers = lines[0].split(',');
      headers.forEach((header, i) => {
        if (header === undefined || header == null || header === '') {
          headers.splice(i, 1);
        }
      });
      const data = [];
      if (headers.length !== columnMap.size) {
        data.push({ errorMessage: 'Column count mismatch' });
      } else {
        let stopParsing = false;
        lines.forEach((line, i) => {
          stopParsing = line.split(',').every(value => {
            if (value === undefined || value == null || value === '') {
              return true;
            }
          });
          if (i > 0 && line !== '' && line !== undefined && line != null && !stopParsing) {
            const obj = {};

            const currentline = line.split(',');

            let errorMessage = '';
            let fields = [];
            let fieldsForBadData = [];

            for (let j = 0; j < headers.length; j++) {
              let headerValue = columnMap.get(headers[j]);
              let header = headerMap.find(header => header.value === headerValue);
              if (header) {
                let type = header.type;
                let regex = regexMap.get(type);
                if (!currentline[j].match(regex) && currentline[j] !== null && currentline[j] !== '') {
                  obj[header.value] = currentline[j];
                  fieldsForBadData.push(header.label);
                } else {
                  obj[header.value] = currentline[j];
                }

                if (type === 'date') {
                  let value = currentline[j].toLocaleString("en-US", { year: "numeric", month: "2-digit", day: "2-digit" });
                  if (value.match(regexMap.get('date'))) {
                    obj[header.value] = value;
                  }
                }

                if (header.maxLength && currentline[j].length > header.maxLength) {
                  fieldsForBadData.push(header.label);
                }
                if (header.required && !currentline[j]) {
                  fields.push(header.label);
                }
              }
            }
            if (fields.length > 0) {
              errorMessage = fields.join(', ') + ' are required fields' + '\r\n';
            }
            if (fieldsForBadData.length > 0) {
              errorMessage += fieldsForBadData.join(', ') + ' are invalid' + '\r\n';
            }
            obj.errorMessage = errorMessage;
            data.push(obj);
          }
        });

        return data;
      }
    }
    catch (error) {
      let parameters = 'columnMap-' + JSON.stringify(columnMap) + ' headerMap-' + JSON.stringify(headerMap);
      csx_cmp_logError('csx_cmp_excelexport', 'parseCSV', error, parameters);
    }

  }
}