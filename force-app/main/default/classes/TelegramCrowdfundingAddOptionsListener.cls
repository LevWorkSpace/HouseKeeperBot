public without sharing class TelegramCrowdfundingAddOptionsListener extends TelegramBotUpdateCommandListener {
    //reply to Crowdfunding message with /add_options 45,65,46
    public TelegramCrowdfundingAddOptionsListener() {
        super(TELEGRAM_COMMAND.Ioptions);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;

        if (String.isBlank(message.arguments) || message.reply_to_message == null) return;
        try {
            Crowdfunding fund = new Crowdfunding(message.chat.id, message.reply_to_message.message_id);

            if (fund != null && fund.isValid()) {
                Set<Decimal> validOptions = new Set<Decimal>(Crowdfunding.splitOptions(message.arguments.remove(' ')));

                if (fund.options != null) {
                    validOptions.addAll(fund.options);
                }
                fund.options = new List<Decimal>(validOptions);
                fund.options.sort();
                update fund.getRecord();

                System.enqueueJob(new TelegramQueueable(TelegramBotApi.API_COMMAND.sendMessage, fund.buildMessage()));
            }
        } catch (Exception e) {
            Logger.error(e, tUpdate.message, 'TelegramCrowdfundingAddOptionsListener.dispatch');
        }
    }
}