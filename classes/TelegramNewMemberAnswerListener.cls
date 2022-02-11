public with sharing class TelegramNewMemberAnswerListener implements TelegramBotUpdateListener {

    public Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        return tUpdate.message != null && tUpdate.message.reply_to_message != null
                && tUpdate.message.reply_to_message.tFrom.username == TelegramBotCallBack.BOT_USERNAME
                && tUpdate.message.reply_to_message.text.startsWith(TelegramNewMemberListener.MESSAGE_STARTS);
    }

    public void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Integer flatNumber = TelegramBotService.getFlatNumber(message.text);
            if (flatNumber == null) return;

            Participant__c newMember = TelegramBotService.findParticipantFromMentioning(message.reply_to_message, message.tFrom);

            if (newMember != null) {
                newMember.FlatNumber__c = flatNumber;
                TelegramBotService.upsertParticipant(newMember);
                TelegramBotService.sendNewMemberFlatMessage(message.chat.id, message.message_id, newMember);
                TelegramBotService.updateAllMembersMessage(message.chat.id);
            }
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramNewMemberAnswerListener.dispatch');
        }
    }
}