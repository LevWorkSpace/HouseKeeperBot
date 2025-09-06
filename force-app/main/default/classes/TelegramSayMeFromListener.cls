public without sharing class TelegramSayMeFromListener extends TelegramBotUpdateCommandListener {

    public TelegramSayMeFromListener() {
        super(TELEGRAM_COMMAND.Ime);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Integer flatNumber = TelegramBotService.getFlatNumber(message.arguments);
            if (flatNumber == null) return;

            Participant__c participant = TelegramBotService.buildParticipant(message.tFrom);
            participant.FlatNumber__c = flatNumber;
            TelegramBotService.upsertParticipant(participant);

            TelegramBotService.sendNewMemberFlatMessage(message.chat.id, message.message_id, participant);
            TelegramBotService.updateAllMembersMessage(message.chat.id);

        } catch (Exception e) {
            Logger.error(e, message, 'TelegramSayMeFromListener.dispatch');
        }
    }
}