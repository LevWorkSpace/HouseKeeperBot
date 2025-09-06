public with sharing class TelegramSubscribeToBlackout extends TelegramBotUpdateCommandListener {
    private static final String FROM_MESSAGE = '🧐.. {0} квартира.';
    private static final String FROM_MESSAGE_NOT_FOUND = '😟 не зареєстровано.';

    public TelegramSubscribeToBlackout() {
        super(TELEGRAM_COMMAND.Isubscribe);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        //shutdown
        TelegramBotApi.sendMessage(
            new TelegramBotService.MessageBuilder(tUpdate.message.chat.id)
                .setText('Service unavailable')
                .getMessage()
        );
        if (true) return;
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Participant__c fromUser = TelegramBotService.findParticipant(message.tFrom);
            if (fromUser == null) return;
            fromUser.ChatId__c = message.chat.id;
            fromUser.SubscribedToBlackoutStartWarning__c = true;
            TelegramBotService.upsertParticipant(fromUser);

            System.enqueueJob(new TelegramQueueable(
                TelegramBotApi.API_COMMAND.sendMessage,
                new TelegramBotService.MessageBuilder(message.chat.id)
                        .setText('Subscribed. To unsubscribe - /unsubscribe')
                        .setReplyToId(message.message_id)
                        .getMessage()
                )
            );

        } catch (Exception e) {
            Logger.error(e, message, 'TelegramSubscribeToBlackout.dispatch' + message.chat.id + ' _ ' + message.tFrom.first_name + ' _ ' + message.tFrom.first_name);
        }
    }
}