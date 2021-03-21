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
            upsert participant Participant__c.TelegramId__c;

            //TelegramBotService.sendNewMemberFlatMessage(message.chat.id, message.message_id, participant);
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramSayMeFromListener.dispatch');
        }
    }
}