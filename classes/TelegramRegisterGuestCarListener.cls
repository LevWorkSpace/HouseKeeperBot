public virtual with sharing class TelegramRegisterGuestCarListener extends TelegramBotUpdateCommandListener {
    private static final String SUCCESS_MESSAGE = '🟢 Зареєстровано ';
    public static final String MISSING_CAR_NUMBER_MESSAGE = 'Напишіть номер машини, або скиньте скрін';

    private GuestCarRegistration__c setting;

    public TelegramRegisterGuestCarListener() {
        super(TELEGRAM_COMMAND.Icar);
        setting = GuestCarRegistration__c.getInstance();
    }

    protected virtual String getCarNumber(TelegramBotUpdateDTO.TG_Message message) {
        if (String.isBlank(message.arguments)) {
            TelegramBotApi.sendMessage(
                    new TelegramBotService.MessageBuilder(message.chat.id)
                            .setText(MISSING_CAR_NUMBER_MESSAGE)
                            .setReplyToId(message.message_id)
                            .setReplyMarkup(JSON.serialize(new TelegramBotApi.ForceReply(true, true)))
                            .getMessage()
            );
        }
        return message.arguments;
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

            String carNumber = getCarNumber(message);
            if (String.isBlank(carNumber)) return;

            try {
                carNumber = CarNumberService.toUpperLatin(carNumber);
                HousingComplexService service = new HousingComplexService();
                if(service.connect(p.UserNumber__c)) {
                    String requestNumber = service.addGuestCar(p.FlatNumber__c, carNumber);
                    if (requestNumber != null) {
                        TelegramBotApi.sendMessage(
                                new TelegramBotService.MessageBuilder(message.chat.id)
                                        .setText(SUCCESS_MESSAGE + carNumber + ' - `' + requestNumber + '`')
                                        .getMessage()
                        );
                    } else {
                        HousingComplexService.sendUnknownError(message.chat.id);
                    }
                } else {
                    TelegramBotApi.sendMessage(
                            new TelegramBotService.MessageBuilder(message.chat.id)
                                    .setText(TelegramLoginComplexListener.NO_ACCESS_MESSAGE)
                                    .getMessage()
                    );
                }
            } catch (Exception e) {
                HousingComplexService.sendUnknownError(message.chat.id);
                throw e;
            }
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramRegisterGuestCarListener.dispatch'
                    + '|' + message.tFrom.username
                    + '|' + message.tFrom.first_name
                    + '|' + message.tFrom.last_name);
        }
    }
}