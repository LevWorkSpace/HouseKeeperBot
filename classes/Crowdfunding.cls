public without sharing class Crowdfunding {

    public Id id;
    public String card;
    public List<Decimal> options;
    public String description;
    public String chatId;
    public String messageId;
    public String idForReference;
    public Decimal gathered;
    public List<Donate__c> donates;

    public Crowdfunding(TelegramBotUpdateDTO.TG_Message message) {
        this.chatId = message.chat.id;

        String payload = message.arguments;
        List<String> parts = payload.split('//');
        this.description = parts[2];

        String card = parts[0].trim().replace(' ', '');
        if (card.length() == 16) {
            this.card = card.left(4) + ' '
                    + card.mid(4, 4) + ' '
                    + card.mid(8, 4) + ' '
                    + card.right(4);
        }
        this.options = splitOptions(parts[1].trim());
        this.gathered = 0;
    }

    public Crowdfunding(String chatId, String message_id) {
        List<CrowdFunding__c> cf = [SELECT Id, Name, Gathered__c, CardNumber__c, Message__c, Options__c, ChatId__c, MessageId__c,
                    (SELECT DonateId__c, Participant__r.FlatNumber__c, Participant__r.Name, Participant__r.LastName__c, Participant__r.TelegramUsername__c, Participant__r.TelegramId__c, Amount__c FROM Donates__r ORDER BY Participant__r.FlatNumber__c)
                FROM CrowdFunding__c WHERE ChatId__c = :chatId AND MessageId__c = :message_id];
        if (!cf.isEmpty()) {
            setFromRecord(cf[0]);
        }
    }

    public Crowdfunding(String name) {
        List<CrowdFunding__c> cf = [SELECT Id, Name, Gathered__c, CardNumber__c, Message__c, Options__c, ChatId__c, MessageId__c,
                    (SELECT DonateId__c, Participant__r.FlatNumber__c, Participant__r.Name, Participant__r.LastName__c, Participant__r.TelegramUsername__c, Participant__r.TelegramId__c, Amount__c FROM Donates__r ORDER BY Participant__r.FlatNumber__c)
                FROM CrowdFunding__c WHERE Name = :name LIMIT 1];
        if (!cf.isEmpty()) {
            setFromRecord(cf[0]);
        }
    }

    public Boolean isValid() {
        return this.card != null;
    }

    public void setFromRecord(CrowdFunding__c cf) {
        this.card = cf.CardNumber__c;
        this.description = cf.Message__c;
        this.idForReference = cf.Name;
        this.chatId = cf.ChatId__c;
        this.messageId = cf.MessageId__c;
        this.options = splitOptions(cf.Options__c);
        this.gathered = cf.Gathered__c;
        this.donates = cf.Donates__r;
        this.id = cf.Id;
    }

    public TelegramBotApi.Message buildMessage() {
        String message = '💳`' + this.card + '`👈';
        message += '\n\n💰: *' + this.gathered + '*грн' ;
        message += '\n\n💡' + this.description;
        if (donates != null && !donates.isEmpty() && this.gathered > 0) {
            message += '\n\n💪😇:';
            for (Donate__c d : donates) {
                if (d.Amount__c > 0) {
                    Participant__c p = d.Participant__r;
                    message += '\n' + (p.FlatNumber__c != null ? String.valueOf(p.FlatNumber__c) : '?') + '|' + TelegramBotService.mention(p) + '|```' + d.Amount__c.format() + '```грн';
                }
            }
        }

        message += '\n\n🔧' + TelegramBotUpdateCommandListener.commandNames.get(TelegramBotUpdateCommandListener.TELEGRAM_COMMAND.Istop);

        return new TelegramBotService.MessageBuilder(chatId)
                .setText(message)
                .setMessageId(messageId)
                .setReplyMarkup(JSON.serialize(getInlineKeyBoard()))
                .disableNotifications()
                .getMessage();
    }

    public CrowdFunding__c getRecord() {
        return new CrowdFunding__c(
                Id = this.id,
                CardNumber__c = this.card,
                Message__c = this.description,
                Options__c = this.options == null ? null : String.join(this.options, ','),
                ChatId__c = this.chatId,
                MessageId__c = this.messageId
        );
    }

    private TelegramBotApi.ReplyMarkup getInlineKeyBoard() {
        List<TelegramBotApi.InlineKeyboardButton> buttons = new List<TelegramBotApi.InlineKeyboardButton>();
        if (this.options != null) {
            for (Decimal option : this.options) {
                buttons.add(
                        new TelegramBotApi.InlineKeyboardButton(option.format())
                );
            }
            buttons.add(new TelegramBotApi.InlineKeyboardButton('0'));
        }
        return new TelegramBotApi.ReplyMarkup(buttons);
    }

    public static List<Decimal> splitOptions(String stringOptions) {
        if (stringOptions != null) {
            List<Decimal> options = new List<Decimal>();
            for (String option : stringOptions.split(',')) {
                options.add(Decimal.valueOf(option.trim()));
            }
            return options;
        } else {
            return null;
        }
    }
}