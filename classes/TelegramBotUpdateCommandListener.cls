public abstract class TelegramBotUpdateCommandListener implements TelegramBotUpdateListener {

    public enum TELEGRAM_COMMAND {Icollect, Istop, Ioptions, Ime, Ifrom, Ilist_members, Itag, Ilogin, Icar, Iexit1, Ienter1}

    public static Map<TELEGRAM_COMMAND, String> commandNames = new Map<TelegramBotUpdateCommandListener.TELEGRAM_COMMAND, String> {
            TELEGRAM_COMMAND.Icollect => '/collect',
            TELEGRAM_COMMAND.Istop => '/stop',
            TELEGRAM_COMMAND.Ioptions => '/add_options',
            TELEGRAM_COMMAND.Ime => '/me',
            TELEGRAM_COMMAND.Ifrom => '/from',
            TELEGRAM_COMMAND.Ilist_members => '/all',
            TELEGRAM_COMMAND.Itag => '/tag',
            TELEGRAM_COMMAND.Ilogin => '/login',
            TELEGRAM_COMMAND.Icar => '/car',
            TELEGRAM_COMMAND.Iexit1 => '/exit1',
            TELEGRAM_COMMAND.Ienter1 => '/enter1'
    };

    public abstract void dispatch(TelegramBotUpdateDTO tUpdate);

    protected TELEGRAM_COMMAND command;

    protected TelegramBotUpdateCommandListener(TELEGRAM_COMMAND command) {
        this.command = command;
    }

    public virtual Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        if (tUpdate.message.text.startsWith(commandNames.get(command))) {
            tUpdate.message.arguments = tUpdate.message.text.removeStart(commandNames.get(command)).removeStart(TelegramBotCallBack.A_BOT_USERNAME).trim();
            return true;
        }
        return false;
    }
}