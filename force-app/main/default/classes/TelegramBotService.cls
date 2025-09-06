public without sharing class TelegramBotService {

    private static final String REGISTER_FLAT_MESSAGE = 'Зареєструйте квартиру в Загальному чаті дому! 🏡\nДля цього відправте в чаті дому \n`/me 31`';

    public static Participant__c buildParticipant(TelegramBotUpdateDTO.TG_User user) {
        return new Participant__c(
                Name = user.first_name,
                LastName__c = user.last_name,
                TelegramId__c = user.id,
                TelegramUsername__c = (user.username != null) ? '@' + user.username : null
        );
    }

    public static String mention(TelegramBotUpdateDTO.TG_User user) {
        return (user.username != null) ? '@' + user.username.replace('_', '\\_') : '[' + notNull(user.last_name) + ' ' + notNull(user.first_name) + '](tg://user?id='+user.id+')';
    }

    private static String notNull(String s) {
        return (s == null || s == 'null') ? '' : s;
    }

    public static String mention(Participant__c user) {
        return (user.TelegramUsername__c != null)
                ? user.TelegramUsername__c.replace('_', '\\_')
                : '[' + notNull(user.LastName__c) + ' ' + notNull(user.Name) + '](tg://user?id='+user.TelegramId__c+')';
    }

    public static Integer getFlatNumber(String text) {
        try {
            return Integer.valueOf(text.trim());
        } catch (Exception e) {
            Matcher matcher = Pattern.compile('[ |.|к|кв](\\d+)').matcher(text);
            if (matcher.find() && matcher.groupCount() > 0) {
                return Integer.valueOf(matcher.group(1).trim());
            } else {
                Matcher matcher2 = Pattern.compile('^(\\d+)\\D+').matcher(text);
                return matcher2.find() && matcher2.groupCount() > 0 ? Integer.valueOf(matcher2.group(1).trim()) : null;
            }
        }
    }

    public static void upsertParticipant(Participant__c participant) {
        if (participant.TelegramUsername__c == null
                || (participant.TelegramId__c != null
                    && [SELECT count() FROM Participant__c WHERE TelegramId__c = :participant.TelegramId__c] == 1)) {
            upsert participant Participant__c.TelegramId__c;
        } else {
            upsert participant Participant__c.TelegramUsername__c;
        }
    }

    public static void sendNewMemberFlatMessage(String chatId, String messageId, Participant__c newMember) {
        List<Participant__c> oldMembers = [
                SELECT TelegramId__c, LastName__c, Name, TelegramUsername__c
                FROM Participant__c
                WHERE FlatNumber__c = :newMember.FlatNumber__c
                AND (TelegramId__c = null OR TelegramId__c != :newMember.TelegramId__c)
                AND (TelegramUsername__c = null OR TelegramUsername__c != :newMember.TelegramUsername__c)
        ];
        String message;
        if (oldMembers.isEmpty()) {
            message = '👍👍';
        } else {
            message = '';
            for (Participant__c p : oldMembers) {
                message += TelegramBotService.mention(p) + ', ';
            }
            message += 'з вами у ' + newMember.FlatNumber__c + ' квартирі тепер ' + TelegramBotService.mention(newMember);
        }
        System.enqueueJob(new TelegramQueueable(
                TelegramBotApi.API_COMMAND.sendMessage,
                new TelegramBotService.MessageBuilder(chatId).setText(message).setReplyToId(messageId).disableNotifications().getMessage()
        ));
    }

    public static Participant__c findParticipantFromMentioning(TelegramBotUpdateDTO.TG_Message message, TelegramBotUpdateDTO.TG_User fromUser) {
        if (message.entities != null && !message.entities.isEmpty()) {
            for (TelegramBotUpdateDTO.TG_MessageEntity entity : message.entities) {
                if (entity.type == 'text_mention') {
                    return TelegramBotService.buildParticipant(entity.user);
                } else if (entity.type == 'mention') {
                    String userName = message.text.substring(entity.offset, entity.offset + entity.length);
                    if (fromUser.username != null && '@' + fromUser.username == userName) {
                        return TelegramBotService.buildParticipant(fromUser);
                    } else {
                        return new Participant__c(TelegramUsername__c = userName);
                    }
                }
            }
        }
        return null;
    }

    public static Boolean isAdminUser(TelegramBotUpdateDTO.TG_User user) {
        return [SELECT count() FROM Participant__c WHERE IsAdmin__c = true AND (TelegramUsername__c = :('@'+user.username) OR TelegramUsername__c = :user.id)] > 0;
    }

    public class MessageBuilder {
        private TelegramBotApi.Message message;

        public MessageBuilder(String chatId) {
            message = new TelegramBotApi.Message();
            message.chat_id = chatId;
            message.parse_mode = TelegramBotApi.MESSAGE_MOD.Markdown.name();
        }

        public MessageBuilder setReplyToId(String replyTo) {
            message.reply_to_message_id = replyTo;
            return this;
        }

        public MessageBuilder setReplyMarkup(String reply_markup) {
            message.reply_markup = reply_markup;
            return this;
        }

        public MessageBuilder setMessageId(String messageId) {
            message.message_id = messageId;
            return this;
        }

        public MessageBuilder setText(String text) {
            message.text = text;
            return this;
        }

        public MessageBuilder disableNotifications() {
            message.disable_notification = true;
            return this;
        }

        public TelegramBotApi.Message getMessage() {
            return message;
        }
    }

    public static Participant__c findParticipant(TelegramBotUpdateDTO.TG_User tgUser) {
        return findParticipant(tgUser.username, tgUser.id);
    }

    public static Participant__c findParticipant(Participant__c tgUser) {
        return findParticipant(tgUser.TelegramUsername__c, tgUser.TelegramId__c);
    }

    private static Participant__c findParticipant(String tgUsername, String tgId) {
        List<Participant__c> ps = [
                SELECT Id, FlatNumber__c, UserNumber__c, ChatId__c, TelegramUsername__c, TelegramId__c
                FROM Participant__c
                WHERE (TelegramId__c != null AND TelegramId__c = :tgId)
                OR (TelegramUsername__c != null AND TelegramUsername__c = :tgUsername)
                LIMIT 1
        ];
        return ps.isEmpty() ? null : ps[0];
    }



    public static void sendNotRegisteredFlat(String chatId) {
        TelegramBotApi.sendMessage(
                new TelegramBotService.MessageBuilder(chatId)
                        .setText(REGISTER_FLAT_MESSAGE)
                        .getMessage()
        );
    }

    public static TelegramBotUpdateDTO.TG_Message getMessageDTO(TelegramBotUpdateDTO tUpdate) {
        if (tUpdate.message != null) return tUpdate.message;
        if (tUpdate.callback_query != null && tUpdate.callback_query.message != null) return tUpdate.callback_query.message;
        return null;
    }

    public static TelegramBotUpdateDTO.TG_User getFromDTO(TelegramBotUpdateDTO tUpdate) {
        if (tUpdate.message != null) return tUpdate.message.tFrom;
        if (tUpdate.callback_query != null) return tUpdate.callback_query.tFrom;
        if (tUpdate.inline_query != null) return tUpdate.inline_query.tFrom;
        return null;
    }

    public static String formatAllMembersList() {
        String text = '';
        List<Participant__c> ps = [SELECT TelegramUsername__c, TelegramId__c, Name, LastName__c, FlatNumber__c FROM Participant__c ORDER BY FlatNumber__c NULLS LAST];
        for (Participant__c p : ps) {
            text += format(p) + '\n';
        }
        text += 'Всього: ' + ps.size();
        return text;
    }

    @future(callout=true)
    public static void updateAllMembersMessage(String chatId) {
        List<Message__c> ms = [SELECT MessageId__c FROM Message__c
                               WHERE Chat__r.IsActive__c = true AND Chat__r.ChatId__c = :chatId
                               ORDER BY CreatedDate DESC LIMIT 1];
        if (!ms.isEmpty()) {
            TelegramBotApi.sendMessage(
                    new MessageBuilder(chatId)
                            .setMessageId(ms[0].MessageId__c)
                            .setText(formatAllMembersList())
                            .getMessage()
            );
        }
    }

    private static String format(Participant__c p) {
        String flat = p.FlatNumber__c != null ? String.valueOf(p.FlatNumber__c) : '?';
        return flat + ' - ' + TelegramBotService.mention(p);
    }
}