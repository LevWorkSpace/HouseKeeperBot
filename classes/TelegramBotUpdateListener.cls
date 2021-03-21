public interface TelegramBotUpdateListener {
    Boolean isApplicable(TelegramBotUpdateDTO tUpdate);
    void dispatch(TelegramBotUpdateDTO tUpdate);
}