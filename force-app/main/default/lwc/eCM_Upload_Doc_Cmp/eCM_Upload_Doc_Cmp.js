import { LightningElement } from 'lwc';
import getPDF from '@salesforce/apex/PDFController.getPDF';

export default class ECM_Upload_Doc_Cmp extends LightningElement {
    handleDownload() {
        getPDF()
            .then(base64PDF => {
                // Decode the base64 string to a Blob
                const byteCharacters = atob(base64PDF);
                const byteNumbers = new Array(byteCharacters.length);
                for (let i = 0; i < byteCharacters.length; i++) {
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                const byteArray = new Uint8Array(byteNumbers);
                //const blob = new Blob([byteArray], { type: 'image/jpeg' });
                const blob = new Blob([byteArray], { type: 'application/pdf' });

                // Create a link element, set its href to the blob URL, and click it
                const link = document.createElement('a');
                link.href = window.URL.createObjectURL(blob);
                //link.download = 'image.jpg';
                link.download = 'ECMAPI.pdf';
                link.click();
            })
            .catch(error => {
                console.error('Error downloading image:', error);
            });
    }

}