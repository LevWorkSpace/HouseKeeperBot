@RestResource(urlMapping='/updates/*')
global without sharing class TelegramBotCallBack {

    public static final String BOT_USERNAME = Secured__c.getInstance().BotUsername__c;
    public static final String A_BOT_USERNAME = '@'+BOT_USERNAME;

    public static List<TelegramBotUpdateCommandListener> commandHandlers = new List<TelegramBotUpdateCommandListener> {
            new TelegramCreateCrowdfundingListener(),
            new TelegramCrowdfundingAddOptionsListener(),
            new TelegramStopCrowdfundingListener(),
            new TelegramSayMeFromListener(),
            new TelegramFromFlatListener(),
            new TelegramListMembersListener(),
            new TelegramTagFlatListener()
    };

    public static List<TelegramBotUpdateListener> listeners = new List<TelegramBotUpdateListener> {
            new TelegramAnswerInlineQueryListener(),
            new TelegramNewMemberListener(),
            new TelegramNewMemberAnswerListener()
            //new TelegramInlineQueryListener()
    };

    @HttpPost
    global static Boolean postUpdates() {
        try {
            TelegramBotUpdateDTO tUpdate = TelegramBotUpdateDTO.deserialize(RestContext.request.requestBody.toString());

            if (isNotAuthorized(tUpdate, RestContext.request.requestURI)) return false;

            if (isCommand(tUpdate)) {
                for (TelegramBotUpdateCommandListener commandHandler : commandHandlers) {
                    try {
                        if (commandHandler.isApplicable(tUpdate)) {
                            commandHandler.dispatch(tUpdate);
                            return true;
                        }
                    } catch(Exception e) {
                        Logger.error(e, commandHandler.toString());
                    }
                }
            } else {
                for (TelegramBotUpdateListener listener : listeners) {
                    try {
                        if (listener.isApplicable(tUpdate)) {
                            listener.dispatch(tUpdate);
                        }
                    } catch(Exception e) {
                        Logger.error(e, listener.toString());
                    }
                }
            }

            return true;
        } catch(Exception e) {
            Logger.error(e, 'TelegramBotCallBack.postUpdates');
            return false;
        }
    }

    private static Boolean isCommand(TelegramBotUpdateDTO tUpdate) {
        return tUpdate.message != null && tUpdate.message.text != null && tUpdate.message.text.startsWith('/');
    }

    private static Boolean isNotAuthorized(TelegramBotUpdateDTO tUpdate, String url) {
        Set<String> supportedChannels = Secured__c.getInstance().SupportedChannels__c != null ? new Set<String>(Secured__c.getInstance().SupportedChannels__c.split(';')) : null;
        if  (supportedChannels != null) {
            if (tUpdate.message != null && !supportedChannels.contains(tUpdate.message.chat.id)) {
                Logger.error('chat:' + tUpdate.message.chat.id, 'isNotAuthorized');
                return true;
            }
            if (tUpdate.callback_query != null && tUpdate.callback_query.message != null && !supportedChannels.contains(tUpdate.callback_query.message.chat.id)) {
                Logger.error('chat:' + tUpdate.callback_query.message.chat.id, 'isNotAuthorized');
                return true;
            }
        }
        if (!url.endsWith(Secured__c.getInstance().SFToken__c)) {
            Logger.error('url:' + url, 'isNotAuthorized');
            return true;
        }
        return false;
    }

    @HttpGet
    global static Boolean helloWorld2() {
        return true;
    }
}