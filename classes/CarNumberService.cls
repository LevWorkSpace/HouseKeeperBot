public with sharing class CarNumberService {

    public class RecognizeException extends Exception {}

    public static String recognizeNumber(Blob image) {
        if (GuestCarRegistration__c.getInstance().RecognizeCarNumberUrl__c == null) {
            RecognizeException e = new RecognizeException();
            e.setMessage('CarNumberService.GuestCarRegistration__c.RecognizeCarNumberUrl__c is not set');
            throw e;
        }
        HttpResponse response = uploadFile(image, GuestCarRegistration__c.getInstance().RecognizeCarNumberUrl__c);
        if (response.getStatusCode() == 200) {
            return response.getBody() == '0' ? null : response.getBody();
        } else {
            RecognizeException e = new RecognizeException();
            e.setMessage('CarNumberService.recognize|' + response.getStatus() + '|' + response.getStatusCode() + '|' + response.getBody());
            throw e;
        }
    }

    public static HttpResponse uploadFile(Blob file_body, String reqEndPoint){
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        req.setEndpoint(reqEndPoint);
        req.setBody(EncodingUtil.urlEncode(EncodingUtil.base64Encode(file_body), 'UTF-8'));
        req.setTimeout(120000);
        return new Http().send(req);
    }

    public static String toUpperLatin(String car) {
        car = car.toUpperCase();
        for (String key : UPPER_CYRILLIC_TO_LATIN.keySet()) {
            car = car.replace(key, UPPER_CYRILLIC_TO_LATIN.get(key));
        }
        return car;
    }

    private static final Map<String, String> UPPER_CYRILLIC_TO_LATIN = new Map<String, String>{
            'А' => 'A',
            'В' => 'B',
            'С' => 'C',
            'Е' => 'E',
            'Н' => 'H',
            'І' => 'I',
            'К' => 'K',
            'М' => 'M',
            'О' => 'O',
            'Р' => 'P',
            'Т' => 'T',
            'Х' => 'X'
    };
}