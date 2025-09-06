public without sharing class TelegramMemberLeftListener implements TelegramBotUpdateListener {

    public static final String USER_MESSAGE = '🖖 Живи довго і процвітай!';
    private static final String BOT_MESSAGE = 'Не буду сумувати - від нього такий вуглецевий слід 💨';

    public Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        return tUpdate.message != null && tUpdate.message.left_chat_member != null;
    }

    public void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            String text;
            TelegramBotUpdateDTO.TG_User leftUser = message.left_chat_member;
            if (!leftUser.is_bot) {
                Participant__c leftParticipant = TelegramBotService.findParticipant(leftUser);
                delete leftParticipant;

                text = USER_MESSAGE;
            } else {
                text = BOT_MESSAGE;
            }

            System.enqueueJob(new TelegramQueueable(
                    TelegramBotApi.API_COMMAND.sendMessage,
                    new TelegramBotService.MessageBuilder(message.chat.id)
                            .setText(text)
                            .setReplyToId(message.message_id)
                            .disableNotifications()
                            .getMessage()
            ));
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramMemberLeftListener.dispatch');
        }
    }
}