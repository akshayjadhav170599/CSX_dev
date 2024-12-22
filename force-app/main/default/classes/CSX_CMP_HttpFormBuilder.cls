/**
@author : Infosys
@Description : Class for building the HTTP form data for the multipart/form-data requests which will be used as part of ECM requests.
*/
public class CSX_CMP_HttpFormBuilder {
    //  The boundary is alligned so it doesn't produce padding characters when base64 encoded.
    private final static string BOUNDARY = '----------------------------741e90d31eff';
    
    
    //Returns the request's content type for multipart/form-data requests.
    public static string getContentType() {
        return 'multipart/form-data; boundary="' + BOUNDARY + '"';
    }
    

    //Write a key-value pair to the form's body.
    public static Blob writeBodyParameter(string key,string value) {
       // string content;
        Blob contentBlob;
        if(key == 'fileProperties'){ 
            string header1 = '\r\nContent-Disposition: form-data; name="fileProperties"\r\n\r\n';
            String footer1 = '\r\n--'+BOUNDARY+'--';
            String body1 = value + '\r\n';
            contentBlob = Blob.valueOf(header1+body1+footer1);
        }
        else{
            string header = '--'+BOUNDARY+'\r\nContent-Disposition: form-data; name="file"; filename="test.pdf"\r\nContent-Type: application/octet-stream';
            String footer = '\r\n--'+BOUNDARY;   
            String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            while(headerEncoded.endsWith('='))
            {
                header+=' ';
                headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            }
            String last4Bytes = value.substring(value.length()-4,value.length()); 
            
            if(last4Bytes.endsWith('='))
            {
                Blob decoded4Bytes = EncodingUtil.base64Decode(last4Bytes);
                String last4BytesFooter = String.valueOf(decoded4Bytes)+footer;   
                contentBlob = EncodingUtil.base64Decode(headerEncoded+value.substring(0,value.length()-4)+EncodingUtil.base64Encode(Blob.valueOf(last4BytesFooter)));
            }
            else
            {
                contentBlob = EncodingUtil.base64Decode(headerEncoded+value+footerEncoded);
            }
        }
       
        return contentBlob;
    }
    
    
}