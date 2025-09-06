public with sharing class TelegramKeyMasterAnswerListener implements TelegramBotUpdateListener {

    private static final String SUCCESS_MESSAGE = '🚦🟢';

    public Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_CallbackQuery callback = tUpdate.callback_query;
        return callback != null && callback.message != null && callback.message.text != null
                && callback.message.text == TelegramKeyMasterListener.TEXT_MESSAGE;
    }

    public void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_CallbackQuery callback = tUpdate.callback_query;
        TelegramBotUpdateDTO.TG_Message message = callback.message;
        try {
            String gate = callback.data;
            Participant__c p = TelegramBotService.findParticipant(callback.tFrom);
            if (p == null || p.FlatNumber__c == null) {
                TelegramBotService.sendNotRegisteredFlat(message.chat.id);
                return;
            }
            if (p.UserNumber__c == null) {
                HousingComplexService.sendNotLoggedIn(message.chat.id);
                return;
            }

            HousingComplexService service = new HousingComplexService();
            Boolean result = service.connect(p.UserNumber__c);
            if (result) {
                result = service.openGate(gate);
            }

            TelegramBotApi.CallbackQuery query = new TelegramBotApi.CallbackQuery();
            query.callback_query_id = callback.id;
            query.text = result ? SUCCESS_MESSAGE : TelegramLoginComplexListener.NO_ACCESS_MESSAGE;
            query.show_alert = true;
            System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.answerCallbackQuery, query));
        } catch (Exception e) {
            HousingComplexService.sendUnknownError(message.chat.id);
            TelegramBotApi.CallbackQuery query = new TelegramBotApi.CallbackQuery();
            query.callback_query_id = callback.id;
            System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.answerCallbackQuery, query));
            Logger.error(e, tUpdate, 'TelegramKeyMasterAnswerListener.dispatch');
        }
    }
}