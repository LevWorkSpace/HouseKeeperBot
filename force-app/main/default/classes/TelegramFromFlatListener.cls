public class TelegramFromFlatListener extends TelegramBotUpdateCommandListener {
    private static final String FROM_MESSAGE = '🧐.. {0} квартира.';
    private static final String FROM_MESSAGE_NOT_FOUND = '😟 не зареєстровано.';

    public TelegramFromFlatListener() {
        super(TELEGRAM_COMMAND.Ifrom);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        Integer flatNumber;
        try {
            Participant__c mentionUser = TelegramBotService.findParticipantFromMentioning(message, message.tFrom);
            if (mentionUser == null) return;

            flatNumber = TelegramBotService.getFlatNumber(message.arguments);
            if (flatNumber == null) {
                mentionUser = TelegramBotService.findParticipant(mentionUser);
                String messageText;
                if (mentionUser != null && mentionUser.FlatNumber__c != null) {
                    messageText = String.format(
                            FROM_MESSAGE,
                            new List<String>{String.valueOf(mentionUser.FlatNumber__c)}
                    );
                } else {
                    messageText = FROM_MESSAGE_NOT_FOUND;
                }
                TelegramBotApi.sendMessage(
                        new TelegramBotService.MessageBuilder(message.chat.id)
                                .setText(messageText)
                                .setReplyToId(message.message_id)
                                .disableNotifications()
                                .getMessage()
                );
            } else if (TelegramBotService.isAdminUser(message.tFrom)) {
                mentionUser.FlatNumber__c = flatNumber;
                TelegramBotService.upsertParticipant(mentionUser);
                TelegramBotService.updateAllMembersMessage(message.chat.id);
            }
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramFromFlatListener.dispatch' + flatNumber);
        }
    }
}