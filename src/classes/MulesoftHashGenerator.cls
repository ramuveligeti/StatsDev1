public class MulesoftHashGenerator {
    final String privateKey;
    final String publicKey;
    final String unixTimeStamp;
    
    public MulesoftHashGenerator(String privateKey, String publicKey) {
        this.privateKey = privateKey;
        this.publicKey = publicKey;
        this.unixTimeStamp = timestamp(dateTime.now());
    }
    
    public String xDatetime() {
        return unixTimeStamp;
    }
    
    public String xSignature(String requestBody) {
        return xSignature(requestBody, unixTimeStamp);
    }
    
    public String xSignature(String requestBody, String timestamp) {
        String requestBodyHash = hashRequestBody(requestBody);
        return hashXSignature(publicKey + timestamp + requestBodyHash);
    }

    public String xSignatureWithoutBodyHash(String requestBody) {
        return xSignature(requestBody, unixTimeStamp);
    }
    
    public String xSignatureWithoutBodyHash(String requestBody, String timestamp) {
        return hashXSignature(publicKey + timestamp + requestBody);
    }
    
    String timestamp(DateTime dt) {
        return '' + dt.getTime() / 1000;
    }
    
    String hashRequestBody(String requestBody) {
        Blob input = Blob.valueOf(requestBody);
        Blob key = Blob.valueOf(privateKey);
        Blob hMax = Crypto.generateMac('hmacMD5', input, key);
        return EncodingUtil.base64Encode(hMax);
    }
    
    String hashXSignature(String xSignature) {
        Blob input = Blob.valueOf(xSignature);
        Blob key = Blob.valueOf(privateKey);
        Blob hMax = Crypto.generateMac('hmacSHA256', input, key);
        return EncodingUtil.base64Encode(hMax);
    }
}