public without sharing class TelegramTagFlatListener extends TelegramBotUpdateCommandListener {

    private static final String NO_MEMBERS = '` - Ніхто не зареєстрований в цій квартирі.`';

    public TelegramTagFlatListener() {
        super(TELEGRAM_COMMAND.Itag);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Integer flatNumber = TelegramBotService.getFlatNumber(message.arguments);
            if (flatNumber == null) return;

            String text = '';
            for (Participant__c p : [SELECT TelegramUsername__c, TelegramId__c, Name, LastName__c, FlatNumber__c FROM Participant__c WHERE FlatNumber__c = :flatNumber]) {
                text += TelegramBotService.mention(p) + ', ';
            }
            if (String.isBlank(text)) {
                text = flatNumber + NO_MEMBERS;
            } else {
                text = flatNumber + ':' + text.removeEnd(', ');
            }
            System.enqueueJob(
                    new TelegramQueueable(
                            TelegramBotApi.API_COMMAND.sendMessage,
                            new TelegramBotService.MessageBuilder(tUpdate.message.chat.id).setText(text).disableNotifications().getMessage()
                    )
            );
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramTagFlatListener.dispatch');
        }
    }
}