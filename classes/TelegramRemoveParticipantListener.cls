public without sharing class TelegramRemoveParticipantListener  extends TelegramBotUpdateCommandListener {

    public TelegramRemoveParticipantListener() {
        super(TELEGRAM_COMMAND.Iremove);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            if (!TelegramBotService.isAdminUser(message.tFrom)) return;

            Participant__c mentionUser = TelegramBotService.findParticipant(
                    TelegramBotService.findParticipantFromMentioning(message, message.tFrom)
            );
            if (mentionUser == null) return;

            Logger.debug(mentionUser, 'Removing user');
            delete mentionUser;
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramRemoveParticipantListener.dispatch');
        }
    }

}