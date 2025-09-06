public without sharing class TelegramAnswerInlineQueryListener implements TelegramBotUpdateListener {

    private Crowdfunding crowdFunding;

    public Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_CallbackQuery callback = tUpdate.callback_query;
        if (callback == null || callback.message == null) return false;

        try {
            crowdFunding = new Crowdfunding(callback.message.chat.id, callback.message.message_id);
            return crowdFunding.id != null;
        } catch (Exception e) {
            Logger.error(e, 'TelegramAnswerInlineQueryListener.isApplicable ' + callback.message.chat.id + '|' + callback.message.message_id);
            return false;
        }
    }

    public void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_CallbackQuery callback = tUpdate.callback_query;
        try {
            Participant__c participant = TelegramBotService.buildParticipant(callback.tFrom);

            TelegramBotService.upsertParticipant(participant);

            Donate__c donate = new Donate__c(
                    CrowdFunding__c = crowdFunding.id,
                    Participant__c = participant.Id,
                    DonateId__c = crowdFunding.idForReference + participant.TelegramId__c,
                    Amount__c = Decimal.valueOf(callback.data)
            );
            upsert donate Donate__c.DonateId__c;

            TelegramBotApi.CallbackQuery query = new TelegramBotApi.CallbackQuery();
            query.callback_query_id = callback.id;
            query.text = '👍';
            query.show_alert = true;
            System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.answerCallbackQuery, query));

            Crowdfunding fund = new Crowdfunding(callback.message.chat.id, callback.message.message_id);
            System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.sendMessage, fund.buildMessage()));

        } catch (Exception e) {
            TelegramBotApi.CallbackQuery query = new TelegramBotApi.CallbackQuery();
            query.callback_query_id = callback.id;
            query.text = 'Щось пішло не так 😟';
            query.show_alert = true;
            System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.answerCallbackQuery, query));
            Logger.error(e, tUpdate, 'TelegramAnswerInlineQueryListener.dispatch');
        }
    }
}