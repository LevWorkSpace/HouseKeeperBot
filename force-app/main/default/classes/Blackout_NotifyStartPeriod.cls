public with sharing class Blackout_NotifyStartPeriod implements Schedulable {

    public void execute(SchedulableContext context) {
        try {
            String weekDay = Datetime.now().format('EEEE');
            Time now = Datetime.now().time();
            Logger.debug(now, weekDay);
            //intentionally ignore next day 00:00 slot
            List<BlackoutTime__c> times = [
                SELECT Start__c
                FROM BlackoutTime__c
                WHERE Day__r.WeekDay__c = :weekDay
                AND Start__c >= :now
                ORDER BY Start__c
                LIMIT 1
            ];
            if (!times.isEmpty()) {
                Long diffMilliseconds = Datetime.newInstance(Date.today(), times[0].Start__c).getTime() - Datetime.now().getTime();
                if (diffMilliseconds/1000/60 < 10) {
                    sendMessages(times[0].Start__c);
                }
            }
        } catch (Exception e) {
            Logger.error(e, 'Blackout_NotifyStartPeriod.execute');
        }
    }

    @future(callout=true)
    private static void sendMessages(Time start) {
        try {
            List<Participant__c> subscribers = [
                SELECT ChatId__c
                FROM Participant__c
                WHERE SubscribedToBlackoutStartWarning__c = true
                AND ChatId__c != null
                LIMIT 30
            ];
            //todo: limit 30 per second
            for (Participant__c p : subscribers) {
                TelegramBotApi.sendMessage(
                    new TelegramBotService.MessageBuilder(p.ChatId__c)
                        .setText('Expecting blackout at ' + start)
                        .getMessage()
                );
            }
        } catch (Exception e) {
            Logger.error(e, start, 'Blackout_NotifyStartPeriod.sendMessages');
        }
    }

    public static void start() {
        System.schedule(
            'Blackout_NotifyStartPeriod hourly 55',
            '0 55 * * * ?',
            new Blackout_NotifyStartPeriod()
        );
    }

    public static void stop() {
        System.abortJob([SELECT CronTriggerId FROM AsyncApexJob WHERE ApexClass.Name = 'Blackout_NotifyStartPeriod'].CronTriggerId);
    }
}