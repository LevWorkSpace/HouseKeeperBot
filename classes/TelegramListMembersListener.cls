public without sharing class TelegramListMembersListener extends TelegramBotUpdateCommandListener {

    public TelegramListMembersListener() {
        super(TELEGRAM_COMMAND.Ilist_members);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            if (!TelegramBotService.isAdminUser(message.tFrom)) return;

            String text = '';
            for (Participant__c p : [SELECT TelegramUsername__c, TelegramId__c, Name, LastName__c, FlatNumber__c FROM Participant__c ORDER BY FlatNumber__c NULLS LAST]) {
                text += format(p) + '\n';
            }
            System.enqueueJob(
                    new TelegramQueueable(
                            TelegramBotApi.API_COMMAND.sendMessage,
                            new TelegramBotService.MessageBuilder(tUpdate.message.chat.id).setText(text).disableNotifications().getMessage()
                    )
            );
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramListMembersListener.dispatch');
        }
    }

    private static String format(Participant__c p) {
        String flat = p.FlatNumber__c != null ? String.valueOf(p.FlatNumber__c) : '?';
        return flat + ' - ' + TelegramBotService.mention(p);
    }
}