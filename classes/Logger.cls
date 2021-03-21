public with sharing class Logger {
    private static final String DEBUG = 'Debug';
    private static final String ERROR = 'Error';

    public static void error(Object text, String place) {
        log(text.toString(), place, ERROR);
    }

    public static void error(Exception e, Object text, String place) {
        log(e.getMessage() + text.toString(), place, ERROR);
    }

    public static void debug(Object text, String place) {
        log(text.toString(), place, DEBUG);
    }

    public static void debug(String text) {
        debug(text, '');
    }

    private static void log(String text, String place, String type) {
        Log__c log = new Log__c(Message__c = text, Type__c = type, Place__c = place);
        LogEvent__e event = new LogEvent__e(JsonLog__c = JSON.serialize(log));
        EventBus.publish(event);
    }
}