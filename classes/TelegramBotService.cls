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
        Matcher matcher = Pattern.compile('(\\d+)').matcher(text);
        return matcher.find() && matcher.groupCount() > 0 ? Integer.valueOf(matcher.group(1)) : null;
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
        List<Participant__c> ps = [
                SELECT FlatNumber__c, UserNumber__c
                FROM Participant__c
                WHERE TelegramId__c = :tgUser.id
                OR (TelegramUsername__c != null AND TelegramUsername__c = :tgUser.username)
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
}