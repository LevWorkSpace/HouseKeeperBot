public without sharing class TelegramListMembersListener extends TelegramBotUpdateCommandListener {

    public TelegramListMembersListener() {
        super(TELEGRAM_COMMAND.Ilist_members);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            if (!TelegramBotService.isAdminUser(message.tFrom)) return;

            String text = TelegramBotService.formatAllMembersList();

            System.enqueueJob(
                    new TelegramQueueable(
                            TelegramBotApi.API_COMMAND.sendMessage,
                            new TelegramBotService.MessageBuilder(tUpdate.message.chat.id)
                                    .setText(text)
                                    .disableNotifications()
                                    .getMessage()
                    ).setMessageTypeToSave('All Members')
                    .setPinMessage()
            );
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramListMembersListener.dispatch');
        }
    }
}