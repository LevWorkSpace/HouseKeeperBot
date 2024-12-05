public with sharing class TelegramUnsubscribeToBlackout extends TelegramBotUpdateCommandListener {
    private static final String FROM_MESSAGE = '🧐.. {0} квартира.';
    private static final String FROM_MESSAGE_NOT_FOUND = '😟 не зареєстровано.';

    public TelegramUnsubscribeToBlackout() {
        super(TELEGRAM_COMMAND.Iunsubscribe);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Participant__c fromUser = TelegramBotService.findParticipant(message.tFrom);
            if (fromUser == null) return;
            fromUser.SubscribedToBlackoutStartWarning__c = false;
            TelegramBotService.upsertParticipant(fromUser);

            System.enqueueJob(new TelegramQueueable(
                TelegramBotApi.API_COMMAND.sendMessage,
                new TelegramBotService.MessageBuilder(message.chat.id)
                    .setText('Unsubscribed. To subscribe - /subscribe')
                    .setReplyToId(message.message_id)
                    .getMessage()
            )
            );

        } catch (Exception e) {
            Logger.error(e, message, 'TelegramUnsubscribeToBlackout.dispatch' + message.chat.id + ' _ ' + message.tFrom.first_name + ' _ ' + message.tFrom.first_name);
        }
    }
}