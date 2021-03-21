public without sharing class TelegramNewMemberListener implements TelegramBotUpdateListener {

    public static final String MESSAGE_STARTS = 'Вітаю, ';
    private static final String MESSAGE_ENDS = '! Напишіть з якої ви квартири, будь-ласка!';

    public Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        return tUpdate.message != null && tUpdate.message.new_chat_members != null;
    }

    public void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            List<Participant__c> idParticipants = new List<Participant__c>();
            List<Participant__c> usernameParticipants = new List<Participant__c>();
            for (TelegramBotUpdateDTO.TG_User newUser : message.new_chat_members) {
                if (!newUser.is_bot) {
                    Participant__c participant = TelegramBotService.buildParticipant(newUser);
                    if (participant.TelegramUsername__c == null) {
                        idParticipants.add(participant);
                    } else {
                        usernameParticipants.add(participant);
                    }

                    String text = MESSAGE_STARTS + TelegramBotService.mention(newUser) + MESSAGE_ENDS;
                    System.enqueueJob(new TelegramQueueable(
                            TelegramBotApi.API_COMMAND.sendMessage,
                            new TelegramBotService.MessageBuilder(message.chat.id)
                                    .setText(text)
                                    .setReplyToId(message.message_id)
                                    .setReplyMarkup(JSON.serialize(new TelegramBotApi.ForceReply(true, true)))
                                    .disableNotifications()
                                    .getMessage()
                    ));
                }
            }
            upsert idParticipants Participant__c.TelegramId__c;
            upsert usernameParticipants Participant__c.TelegramUsername__c;
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramNewMemberListener.dispatch');
        }
    }
}