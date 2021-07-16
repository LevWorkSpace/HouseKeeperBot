public abstract without sharing class TelegramAbstractBarrierListener extends TelegramBotUpdateCommandListener {

    private static final String SUCCESS_MESSAGE = '🚦🟢';

    private String gateAction;

    public TelegramAbstractBarrierListener(TelegramBotUpdateCommandListener.TELEGRAM_COMMAND command, String gateAction) {
        super(command);
        this.gateAction = gateAction;
    }

    public override void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_Message message = tUpdate.message;
        try {
            Participant__c p = TelegramBotService.findParticipant(message.tFrom);
            if (p == null || p.FlatNumber__c == null) {
                TelegramBotService.sendNotRegisteredFlat(message.chat.id);
                return;
            }
            if (p.UserNumber__c == null) {
                HousingComplexService.sendNotLoggedIn(message.chat.id);
                return;
            }

            Boolean result;
            try {
                HousingComplexService service = new HousingComplexService();
                result = service.connect(p.UserNumber__c);
                if (result) {
                    result = service.openGate(gateAction);
                }
            } catch (Exception e) {
                HousingComplexService.sendUnknownError(message.chat.id);
                throw e;
            }

            TelegramBotApi.sendMessage(
                    new TelegramBotService.MessageBuilder(message.chat.id)
                            .setText(result ? SUCCESS_MESSAGE : TelegramLoginComplexListener.NO_ACCESS_MESSAGE)
                            .getMessage()
            );
        } catch (Exception e) {
            Logger.error(e, message, 'TelegramAbstractBarrierListener.dispatch'
                    + '|' + message.arguments);
        }
    }
}