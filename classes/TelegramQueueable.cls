public without sharing class TelegramQueueable implements Queueable, Database.AllowsCallouts {

    private TelegramBotApi.API_COMMAND command;
    private Object payload;

    public TelegramQueueable(TelegramBotApi.API_COMMAND command, Object payload) {
        this.command = command;
        this.payload = payload;
    }

    public void execute(QueueableContext qc) {
        try {
            switch on command {
                when sendMessage {
                    TelegramBotApi.Result result = TelegramBotApi.sendMessage((TelegramBotApi.Message)payload);
                    if (!result.ok) {
                        Logger.error(result, 'sendMessage result');
                    }
                }
                when pinChatMessage {
                    TelegramBotApi.pinMessage((TelegramBotApi.PinMessage)payload);
                }
                when answerCallbackQuery {
                    TelegramBotApi.answerCallbackQuery((TelegramBotApi.CallbackQuery)payload);
                }
            }
        } catch (Exception e) {
            Logger.error(e, payload, 'TelegramQueueable');
            throw e;
        }
    }
}