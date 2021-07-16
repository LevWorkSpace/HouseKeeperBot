@RestResource(urlMapping='/updates/*')
global without sharing class TelegramBotCallBack {

    public static final String BOT_USERNAME = Secured__c.getInstance().BotUsername__c;
    public static final String A_BOT_USERNAME = '@'+BOT_USERNAME;

    private static final String PRIVATE_CHAT_TYPE = 'private';
    private static final String REGISTER_MESSAGE = 'Зареєструйте квартиру в чаті дому! 🏡';

    public static List<TelegramBotUpdateCommandListener> groupCommandHandlers = new List<TelegramBotUpdateCommandListener> {
            new TelegramCreateCrowdfundingListener(),
            new TelegramCrowdfundingAddOptionsListener(),
            new TelegramStopCrowdfundingListener(),
            new TelegramSayMeFromListener(),
            new TelegramFromFlatListener(),
            new TelegramListMembersListener(),
            new TelegramTagFlatListener()
    };

    public static List<TelegramBotUpdateCommandListener> privateCommandHandlers = new List<TelegramBotUpdateCommandListener> {
            new TelegramLoginComplexListener(),
            new TelegramRegisterGuestCarListener(),
            new TelegramEnterBarrier1Listener(),
            new TelegramExitBarrier1Listener()
    };

    public static List<TelegramBotUpdateListener> groupListeners = new List<TelegramBotUpdateListener> {
            new TelegramAnswerInlineQueryListener(),
            new TelegramNewMemberListener(),
            new TelegramNewMemberAnswerListener()
            //new TelegramInlineQueryListener()
    };

    public static List<TelegramBotUpdateListener> privateListeners = new List<TelegramBotUpdateListener> {
        new TelegramRegisterImageGuestCarListener()
    };

    @HttpPost
    global static Boolean postUpdates() {
        try {
            TelegramBotUpdateDTO tUpdate = TelegramBotUpdateDTO.deserialize(RestContext.request.requestBody.toString());

            return isPrivateChat(tUpdate.message) ? privateInteraction(tUpdate) : groupInteraction(tUpdate);
        } catch(Exception e) {
            Logger.error(e, 'TelegramBotCallBack.postUpdates');
            return false;
        }
    }

    private static Boolean groupInteraction(TelegramBotUpdateDTO tUpdate) {
        if (isNotAuthorizedGroup(tUpdate, RestContext.request.requestURI)) return false;

        if (isCommand(tUpdate)) {
            for (TelegramBotUpdateCommandListener commandHandler : groupCommandHandlers) {
                try {
                    if (commandHandler.isApplicable(tUpdate)) {
                        commandHandler.dispatch(tUpdate);
                        return true;
                    }
                } catch (Exception e) {
                    Logger.error(e, commandHandler.toString());
                }
            }
        } else {
            for (TelegramBotUpdateListener listener : groupListeners) {
                try {
                    if (listener.isApplicable(tUpdate)) {
                        listener.dispatch(tUpdate);
                    }
                } catch (Exception e) {
                    Logger.error(e, listener.toString());
                }
            }
        }
        return true;
    }

    private static Boolean privateInteraction(TelegramBotUpdateDTO tUpdate) {
        if (isNotAuthorizedUser(tUpdate, RestContext.request.requestURI)) return false;
        Logger.debug(tUpdate, 'test');

        if (isCommand(tUpdate)) {
            for (TelegramBotUpdateCommandListener commandHandler : privateCommandHandlers) {
                try {
                    if (commandHandler.isApplicable(tUpdate)) {
                        commandHandler.dispatch(tUpdate);
                        return true;
                    }
                } catch (Exception e) {
                    Logger.error(e, commandHandler.toString());
                }
            }
        } else {
            for (TelegramBotUpdateListener listener : privateListeners) {
                try {
                    if (listener.isApplicable(tUpdate)) {
                        listener.dispatch(tUpdate);
                    }
                } catch (Exception e) {
                    Logger.error(e, listener.toString());
                }
            }
        }
        return true;
    }

    private static Boolean isPrivateChat(TelegramBotUpdateDTO.TG_Message tgMessage) {
        return tgMessage != null && tgMessage.chat.type == PRIVATE_CHAT_TYPE;
    }

    private static Boolean isCommand(TelegramBotUpdateDTO tUpdate) {
        return tUpdate.message != null && tUpdate.message.text != null && tUpdate.message.text.startsWith('/');
    }

    private static Boolean isNotAuthorizedGroup(TelegramBotUpdateDTO tUpdate, String url) {
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

    private static Boolean isNotAuthorizedUser(TelegramBotUpdateDTO tUpdate, String url) {
        if (!url.endsWith(Secured__c.getInstance().SFToken__c)) {
            Logger.error('url:' + url, 'isNotAuthorized');
            return true;
        }
        if (null == TelegramBotService.findParticipant(tUpdate.message != null ? tUpdate.message.tFrom : tUpdate.inline_query.tFrom)) {
            Logger.error('user:' + JSON.serialize(tUpdate.message != null ? tUpdate.message.tFrom : tUpdate.inline_query.tFrom),
                    'isNotAuthorized');
            if (isCommand(tUpdate)) {
                TelegramBotApi.sendMessage(
                        new TelegramBotService.MessageBuilder(tUpdate.message.chat.id)
                                .setText(REGISTER_MESSAGE)
                                .getMessage()
                );
            }
            return true;
        }
        return false;
    }

    @HttpGet
    global static Boolean helloWorld2() {
        return true;
    }
}