public with sharing class TelegramKeyMasterListener extends TelegramBotUpdateCommandListener {

    public static final String TEXT_MESSAGE = 'Сім-сім...';

    private static final List<Map<String, String>> BUTTONS_LAYOUT = new List<Map<String, String>> {
            new Map<String, String> {
                    'p_1_cucle_1' => '🚘1 - шлагбаум',
                    'hp_1_cucle_1' => '🚘2 - шлагбаум'
            },
            new Map<String, String> {
                    'p_3_cucle_19' => '🛒🚶- хвіртка',
                    'p_3_cucle_17' => '⬅🚶 - турнікет',
                    'p_3_cucle_15' => '➡🚶 - турнікет'
            },
            new Map<String, String> {
                    'SOCKET_RELAY_9.133:88_1' => '🏡1 - під‘їзд',
                    'SOCKET_RELAY_9.133:88_2' => '🏡2 - під‘їзд'
            }
    };

    public TelegramKeyMasterListener() {
        super(TELEGRAM_COMMAND.Iopen);
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
            Participant__c p = TelegramBotService.findParticipant(tUpdate.message.tFrom);
            if (p == null || p.FlatNumber__c == null) {
                TelegramBotService.sendNotRegisteredFlat(message.chat.id);
                return;
            }

            if (p.UserNumber__c == null) {
                HousingComplexService.sendNotLoggedIn(message.chat.id);
                return;
            }

            TelegramBotApi.sendMessage(
                    new TelegramBotService.MessageBuilder(message.chat.id)
                            .setText(TEXT_MESSAGE)
                            .setReplyMarkup(JSON.serialize(
                                    new TelegramBotApi.ReplyMarkup(BUTTONS_LAYOUT))
                            )
                            .getMessage()
            );
        } catch (Exception e) {
            Logger.error(e, tUpdate.message, 'TelegramKeyMasterListener.dispatch');
        }
    }
}