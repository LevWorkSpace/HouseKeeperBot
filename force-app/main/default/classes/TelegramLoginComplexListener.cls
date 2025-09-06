public without sharing class TelegramLoginComplexListener extends TelegramBotUpdateCommandListener {
    private static final String MISSING_CREDS = '❌ До команди додайте логін(або логін/пароль)\n`/login 0991234567`\n`/login 0991234567/0991234567`';
    private static final String SUCCESS_MESSAGE = '🟢 Авторизовано 🔓';
    public static final String NO_ACCESS_MESSAGE = '🔴 Сайт відмовив у доступі - перевірте логін/пароль';

    public TelegramLoginComplexListener() {
        super(TELEGRAM_COMMAND.Ilogin);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        //shutdown
        TelegramBotApi.sendMessage(
            new TelegramBotService.MessageBuilder(tUpdate.message.chat.id)
                .setText('Service unavailable')
                .getMessage()
        );
        if (true) return;

        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Participant__c p = TelegramBotService.findParticipant(message.tFrom);
            if (p == null || p.FlatNumber__c == null) {
                TelegramBotService.sendNotRegisteredFlat(message.chat.id);
                return;
            }

            if (String.isBlank(message.arguments)) {
                TelegramBotApi.sendMessage(
                        new TelegramBotService.MessageBuilder(message.chat.id)
                                .setText(MISSING_CREDS)
                                .getMessage()
                );
                return;
            }

            try {
                HousingComplexService service = new HousingComplexService();
                Boolean result = service.connect(message.arguments);
                TelegramBotApi.sendMessage(
                        new TelegramBotService.MessageBuilder(message.chat.id)
                                .setText(result ? SUCCESS_MESSAGE : NO_ACCESS_MESSAGE)
                                .getMessage()
                );
            } catch (Exception e) {
                HousingComplexService.sendUnknownError(message.chat.id);
                throw e;
            }

            p.UserNumber__c = message.arguments.trim();
            update p;

        } catch (Exception e) {
            Logger.error(e, message, 'TelegramLoginComplexListener.dispatch'
                    + '|' + message.arguments.left(6));
        }
    }
}