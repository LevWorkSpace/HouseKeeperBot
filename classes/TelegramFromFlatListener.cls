public class TelegramFromFlatListener extends TelegramBotUpdateCommandListener {

    public TelegramFromFlatListener() {
        super(TELEGRAM_COMMAND.Ifrom);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            if (!TelegramBotService.isAdminUser(message.tFrom)) return;

            Participant__c mentionUser = TelegramBotService.findParticipantFromMentioning(message, message.tFrom);
            if (mentionUser == null) return;

            Integer flatNumber = TelegramBotService.getFlatNumber(message.arguments);
            if (flatNumber == null) return;

            mentionUser.FlatNumber__c = flatNumber;
            TelegramBotService.upsertParticipant(mentionUser);
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramFromFlatListener.dispatch');
        }
    }
}