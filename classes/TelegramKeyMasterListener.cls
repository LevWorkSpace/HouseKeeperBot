public with sharing class TelegramKeyMasterListener extends TelegramBotUpdateCommandListener {

    public static final String TEXT_MESSAGE = 'Сім-сім...';
    private static final Map<String, String> GATE_CODE_TO_GATE = new Map<String, String> {
            'p_1_cucle_1' => 'КПП 1',
            'p_3_cucle_1' => 'Хвіртка',
            'hp_1_cucle_1' => 'КПП 2'
    };

    public TelegramKeyMasterListener() {
        super(TELEGRAM_COMMAND.Iopen);
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
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
                            .setReplyMarkup(JSON.serialize(getInlineKeyBoard()))
                            .getMessage()
            );
        } catch (Exception e) {
            Logger.error(e, tUpdate.message, 'TelegramKeyMasterListener.dispatch');
        }
    }

    private TelegramBotApi.ReplyMarkup getInlineKeyBoard() {
        List<TelegramBotApi.InlineKeyboardButton> buttons = new List<TelegramBotApi.InlineKeyboardButton>();
        for (String code : GATE_CODE_TO_GATE.keySet()) {
            buttons.add(new TelegramBotApi.InlineKeyboardButton(GATE_CODE_TO_GATE.get(code), code));
        }
        return new TelegramBotApi.ReplyMarkup(buttons);
    }
}