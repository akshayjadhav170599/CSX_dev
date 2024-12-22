@isTest
public class CSX_CMP_HttpFormBuilderTest {
    @isTest
    static void testGetContentType() {
        // Test the getContentType method
        String contentType = CSX_CMP_HttpFormBuilder.getContentType();
        System.assertEquals('multipart/form-data; boundary="----------------------------741e90d31eff"', contentType, 'The content type should be multipart/form-data with the correct boundary');
    }

    @isTest
    static void testWriteBodyParameterFileProperties() {
        // Test the writeBodyParameter method with 'fileProperties' key
        String key = 'fileProperties';
        String value = '{"name":"testFile"}';
        Blob result = CSX_CMP_HttpFormBuilder.writeBodyParameter(key, value);
        
        String expectedHeader = '\r\nContent-Disposition: form-data; name="fileProperties"\r\n\r\n';
        String expectedFooter = '\r\n------------------------------741e90d31eff--';
        String expectedBody = value + '\r\n';
        Blob expectedBlob = Blob.valueOf(expectedHeader + expectedBody + expectedFooter);
        
        System.assertEquals(expectedBlob.toString(), result.toString(), 'The body parameter for "fileProperties" should match the expected format');
    }

    @isTest
    static void testWriteBodyParameterFile() {
        // Test the writeBodyParameter method with 'file' key
        String key = 'file';
        String value = EncodingUtil.base64Encode(Blob.valueOf('This is a test file content.'));
        Blob result = CSX_CMP_HttpFormBuilder.writeBodyParameter(key, value);
        
        String header = '------------------------------741e90d31eff\r\nContent-Disposition: form-data; name="file"; filename="test.pdf"\r\nContent-Type: application/octet-stream\r\n\r\n';
        String footer = '\r\n------------------------------741e90d31eff';
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header));
        String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        
        String last4Bytes = value.substring(value.length() - 4, value.length());
        Blob contentBlob;
        
        if (last4Bytes.endsWith('=')) {
            Blob decoded4Bytes = EncodingUtil.base64Decode(last4Bytes);
            String last4BytesFooter = String.valueOf(decoded4Bytes) + footer;
            contentBlob = EncodingUtil.base64Decode(headerEncoded + value.substring(0, value.length() - 4) + EncodingUtil.base64Encode(Blob.valueOf(last4BytesFooter)));
        } else {
            contentBlob = EncodingUtil.base64Decode(headerEncoded + value + footerEncoded);
        }
        
        // Log the actual and expected values
        //System.debug('Expected Blob: ' + contentBlob);
        //System.debug('Actual Blob: ' + result);
    }
}