public with sharing class TelegramHelpListener extends TelegramBotUpdateCommandListener {

    TelegramLongSettings__mdt setting;

    public TelegramHelpListener() {
        super(TELEGRAM_COMMAND.Ihelp);
        setting = [SELECT NoAccessHelp__c, Help__c FROM TelegramLongSettings__mdt LIMIT 1];
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Participant__c p = TelegramBotService.findParticipant(tUpdate.message.tFrom);

            String text = (p == null || p.FlatNumber__c == null) ? setting.NoAccessHelp__c : setting.Help__c;
            TelegramBotApi.sendMessage(
                    new TelegramBotService.MessageBuilder(message.chat.id)
                            .setText(text)
                            .disableNotifications()
                            .getMessage()
            );

        } catch (Exception e) {
            Logger.error(e, tUpdate.message, 'TelegramHelpListener.dispatch');
        }
    }

}