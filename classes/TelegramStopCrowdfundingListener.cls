public without sharing class TelegramStopCrowdfundingListener extends TelegramBotUpdateCommandListener {

    public TelegramStopCrowdfundingListener() {
        super(TELEGRAM_COMMAND.Istop);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;

        if (message.reply_to_message == null) return;

        try {
            Crowdfunding fund = new Crowdfunding(message.chat.id, message.reply_to_message.message_id);

            if (fund != null && fund.isValid()) {
                fund.options = null;
                update fund.getRecord();

                System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.sendMessage, fund.buildMessage()));
            }
        } catch (Exception e) {
            Logger.error(e, tUpdate.message, 'TelegramStopCrowdfundingListener.dispatch');
        }
    }
}