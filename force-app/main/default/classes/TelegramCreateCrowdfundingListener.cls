public without sharing class TelegramCreateCrowdfundingListener extends TelegramBotUpdateCommandListener {
    // /collect card_number//option1,option2//description
    public TelegramCreateCrowdfundingListener() {
        super(TELEGRAM_COMMAND.Icollect);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        try {
            Crowdfunding fund = new Crowdfunding(tUpdate.message);
            if (fund.isValid()) {
                CrowdFunding__c cf = fund.getRecord();
                insert cf;
                fund.idForReference = [SELECT Name FROM CrowdFunding__c WHERE Id = :cf.Id].Name;

                sendMessage(JSON.serialize(fund.buildMessage()), fund.idForReference);
            }
        } catch (Exception e) {
            Logger.error(e, tUpdate.message, 'TelegramCreateCrowdfundingListener.dispatch');
        }
    }

    @future(callout=true)
    private static void sendMessage(String messagePayload, String idForReference) {
        try {
            TelegramBotApi.Result result = TelegramBotApi.sendMessage((TelegramBotApi.Message) JSON.deserialize(messagePayload, TelegramBotApi.Message.class));
            if (result.ok) {
                CrowdFunding__c cf = [SELECT MessageId__c, ChatId__c FROM CrowdFunding__c WHERE Name = :idForReference];
                cf.MessageId__c = result.result.message_id;

                pinMessage(cf.ChatId__c, cf.MessageId__c);

                update cf;

            } else {
                Logger.error(result, 'sendMessage result');
            }
        } catch (Exception e) {
            Logger.error(e, messagePayload, 'TelegramCreateCrowdfundingListener.sendMessage' + idForReference);
        }
    }

    private static void pinMessage(String chatId, String messageId) {
        try {
            TelegramBotApi.pinMessage(new TelegramBotApi.PinMessage(chatId, messageId));
        } catch (Exception e) {
            Logger.error(e, chatId, 'TelegramCreateCrowdfundingListener.pinMessage' + messageId);
        }
    }
}