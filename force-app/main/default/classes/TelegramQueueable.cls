public without sharing class TelegramQueueable implements Queueable, Database.AllowsCallouts {

    private TelegramBotApi.API_COMMAND command;
    private Object payload;
    private String messageTypeToSave;
    private Boolean pinMessage;

    public TelegramQueueable(TelegramBotApi.API_COMMAND command, Object payload) {
        this.command = command;
        this.payload = payload;
        this.pinMessage = false;
    }

    //for sendMessage only
    public TelegramQueueable setMessageTypeToSave(String messageTypeToSave) {
        this.messageTypeToSave = messageTypeToSave;
        return this;
    }

    //for sendMessage only
    public TelegramQueueable setPinMessage() {
        this.pinMessage = true;
        return this;
    }

    public void execute(QueueableContext qc) {
        try {
            switch on command {
                when sendMessage {
                    TelegramBotApi.Result result = TelegramBotApi.sendMessage((TelegramBotApi.Message)payload);
                    if (result.ok) {
                        if (String.isNotBlank(this.messageTypeToSave)) {
                            saveMessage(result.result);
                        }
                        if (this.pinMessage) {
                            pinMessage(result.result);
                        }
                    } else {
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

    private void pinMessage(TelegramBotUpdateDTO.TG_Message message) {
        System.enqueueJob(
                new TelegramQueueable(
                        TelegramBotApi.API_COMMAND.pinChatMessage,
                        new TelegramBotApi.PinMessage(message.chat.id, message.message_id)
                )
        );
    }

    private void saveMessage(TelegramBotUpdateDTO.TG_Message message) {
        List<Chat__c> chats = [SELECT Id FROM Chat__c WHERE IsActive__c = true AND ChatId__c = :message.chat.id LIMIT 1];
        if (!chats.isEmpty()) {
            insert new Message__c(
                    Chat__c = chats[0].Id,
                    Type__c = this.messageTypeToSave,
                    MessageId__c = message.message_id
            );
        }
    }
}