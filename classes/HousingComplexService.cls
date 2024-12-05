public with sharing class HousingComplexService {

    public static final String UNKNOWN_ERROR_MESSAGE = '😥 Щось пішло не так\nЗконтактуйте з адміном!\nА до того часу спробуйте через сайт:\n';
    private static final String LOGIN_FIRST_MESSAGE = '🔒 Ви не авторизовані . Виконайте спочатку \n`/login username/password`';
    private static final String LOGIN1_URL_SUFFIX = '/?frame=login&message_alert=';
    private static final String LOGIN2_URL_SUFFIX = '/?frame=login';
    private static final String OPENGATE_URL_SUFFIX = '/go.php?mode=';
    private static final String GUEST_CAR_URL_SUFFIX = '?frame=guests_invited';
    private static final String CAR_KEY = 'p_car_num';
    private static final String HOURS_KEY = 'p_hours';
    private static final String HOURS = '24';
    private static final Integer TIMEOUT = 20000;

    private static final Integer LINK_WORK_DAYS = 5;
    private static final Integer LINK_MINUTES_AFTER_USE = 60;
    private static final String GUEST_LINK_URL_SUFFIX = '?frame=guests_cabinet&menu=create_link&cmd=create_link&ch_1=1&ch_10=10&ch_5=5&p_qty_day='
            + LINK_WORK_DAYS + '&p_qty_min=' + LINK_MINUTES_AFTER_USE;
    private static final String LINK_DESCRIPTION_KEY = 'descr_user';



    private String cookie;
    private String url;
    private String carAdditionalParam;

    public HousingComplexService() {
        url = GuestCarRegistration__c.getInstance().Url__c;
        carAdditionalParam = GuestCarRegistration__c.getInstance().AdditionalRequestParam__c;
    }
    public Boolean connect(String creds) {
        List<String> userPassword = creds.split('/', 2);
        try {
            String urlLoginInit = url + LOGIN1_URL_SUFFIX;
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint(urlLoginInit);
            request.setTimeout(TIMEOUT);
            HttpResponse response1 = new Http().send(request);

            if (response1.getStatusCode() != 200 ||
                    (response1.getHeader('Set-Cookie') == null
                            && response1.getHeader('set-cookie') == null)) {
                HCLoginException e = new HCLoginException();
                e.setMessage('1|' + response1.getStatus() + '|' + response1.getStatusCode() + '|' + urlLoginInit);
                throw e;
            }
            this.cookie = response1.getHeader('Set-Cookie') == null
                    ? response1.getHeader('set-cookie')
                    : response1.getHeader('Set-Cookie');
            String pass = (userPassword.size() > 1) ? userPassword[1] : userPassword[0];
            String urlLogin = url + LOGIN2_URL_SUFFIX + '&login=' + userPassword[0].trim() + '&password=' + pass.trim();
            HttpRequest request2 = new HttpRequest();
            request2.setMethod('GET');
            request2.setEndpoint(urlLogin);
            request2.setHeader('cookie', this.cookie);
            request2.setTimeout(TIMEOUT);
            HttpResponse response2 = new Http().send(request2);
            if (response2.getStatusCode() != 200 && response2.getStatusCode() != 302) {
                HCLoginException e = new HCLoginException();
                e.setMessage('2|' + response2.getStatus() + '|' + response2.getStatusCode() + '|' + urlLogin);
                throw e;
            }
            return response2.getStatusCode() == 302;
        } catch (Exception e) {
            Logger.error(e, creds, 'HousingComplexService.connect ' + userPassword[0].left(6));
            return false;
        }
    }

    public Boolean openGate(String gate) {
        String urlOpen = url + OPENGATE_URL_SUFFIX + gate;
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(urlOpen);
        request.setHeader('cookie', this.cookie);
        request.setTimeout(TIMEOUT);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() != 200 || response.getBody() == null || !response.getBody().contains('"color"')) {
            HCLoginException e = new HCLoginException();
            e.setMessage('openGate|' + response.getStatus() + '|' + response.getStatusCode() + '|' + response.getBody() + '|' + urlOpen);
            throw e;
        }

        Boolean result = response.getBody().contains('"color":"#00FF00"');

        if (!result) {
            Logger.error(response.getBody(), 'TelegramExitBarrier1Listener.openGate');
        }
        return result;
    }

    public String addGuestCar(Decimal flatNumber, String car) {
        String url = url + GUEST_CAR_URL_SUFFIX;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setHeader('cookie', this.cookie);

        String encodedBody = CAR_KEY + '=' + EncodingUtil.urlEncode(car, 'UTF-8')
                + '&' + HOURS_KEY + '=' + HOURS
                + '&' + carAdditionalParam;

        request.setMethod('POST');
        request.setBody(encodedBody);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Content-Length', String.valueOf(encodedBody.length()));
        request.setTimeout(TIMEOUT);

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() == 302 && response.getStatus() == 'Found'
                && (response.getHeaderKeys().contains('Location') || response.getHeaderKeys().contains('location'))) {
            String location = response.getHeaderKeys().contains('Location') ? response.getHeader('Location') : response.getHeader('location');

            //temp debug to find issue
            if(!location.right(6).isNumeric()) {
                Logger.error(location, this.cookie);
            } else {
                Logger.debug(location, this.cookie);
            }

            return location.right(6);
        } else {
            String error = flatNumber + '|' + response.getStatus() + '|' + response.getStatusCode() + '/';
            for (String key : response.getHeaderKeys()) {
                error += '<&>' +  key + '=' + response.getHeader(key);
            }
            Logger.error(error, 'park request');
            return null;
        }
    }

    public Boolean createGuestLink(String description) {
        String urlCreateLink = url + GUEST_LINK_URL_SUFFIX + '&' + LINK_DESCRIPTION_KEY + '=' + description;
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(urlCreateLink);
        request.setHeader('cookie', this.cookie);
        HttpResponse response = new Http().send(request);
        System.debug(response.getStatusCode());
        System.debug(response.getBody());
        if (response.getStatusCode() != 200 || response.getBody() == null || !response.getBody().contains('"color"')) {
            HCLoginException e = new HCLoginException();
            e.setMessage('openGate|' + response.getStatus() + '|' + response.getStatusCode() + '|' + response.getBody() + '|' + urlCreateLink);
            throw e;
        }

        Boolean result = response.getBody().contains('"color":"#00FF00"');

        if (!result) {
            Logger.error(response.getBody(), 'TelegramExitBarrier1Listener.openGate');
        }
        return result;
    }

    public static void sendUnknownError(String chatId) {
        TelegramBotApi.sendMessage(
                new TelegramBotService.MessageBuilder(chatId)
                        .setText(UNKNOWN_ERROR_MESSAGE + '['+GuestCarRegistration__c.getInstance().Url__c+']')
                        .getMessage()
        );
    }

    public static void sendNotLoggedIn(String chatId) {
        TelegramBotApi.sendMessage(
                new TelegramBotService.MessageBuilder(chatId)
                        .setText(LOGIN_FIRST_MESSAGE)
                        .getMessage()
        );
    }

    public class HCLoginException extends Exception{}
}