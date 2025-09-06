public with sharing class TelegramRegisterImageGuestCarListener extends TelegramRegisterGuestCarListener {

    public static final String CANNOT_RECOGNIZE_CAR_NUMBER_MESSAGE = 'Не можу розпізнати номер 🚗';
    public static final String MISSING_CAR_NUMBER_MESSAGE = 'Так і не отримав номер машини 🚗';
    private Boolean imageFlow;

    public override Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        if(tUpdate.message != null && tUpdate.message.photo != null && !tUpdate.message.photo.isEmpty()
                && (tUpdate.message.caption == commandNames.get(command)
                    || (tUpdate.message.reply_to_message.tFrom.username == TelegramBotCallBack.BOT_USERNAME
                    && tUpdate.message.reply_to_message.text.startsWith(TelegramRegisterGuestCarListener.MISSING_CAR_NUMBER_MESSAGE)))
                ) {
            imageFlow = true;
            return true;
        }
        if(tUpdate.message != null && tUpdate.message.reply_to_message != null
                && tUpdate.message.reply_to_message.tFrom.username == TelegramBotCallBack.BOT_USERNAME
                && tUpdate.message.reply_to_message.text.startsWith(TelegramRegisterGuestCarListener.MISSING_CAR_NUMBER_MESSAGE)) {
            imageFlow = false;
            return true;
        }
        return false;
    }

    protected override String getCarNumber(TelegramBotUpdateDTO.TG_Message message) {
        String carNumber;
        if (imageFlow == true) {
            //few quality options
            String fileId = message.photo[message.photo.size() - 1].file_id;
            TelegramBotApi.FileResult fileResult = TelegramBotApi.getFile(fileId);

            Blob file = TelegramBotApi.downloadFile(fileResult.result);

            carNumber = CarNumberService.recognizeNumber(file);
        } else {
            carNumber = message.text;
        }

        if (carNumber == null) {
            TelegramBotApi.sendMessage(
                    new TelegramBotService.MessageBuilder(message.chat.id)
                            .setText((imageFlow == true) ? CANNOT_RECOGNIZE_CAR_NUMBER_MESSAGE : MISSING_CAR_NUMBER_MESSAGE)
                            .getMessage()
            );
        }

        return carNumber;
    }
}