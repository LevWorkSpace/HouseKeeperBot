public with sharing class TelegramBotApi {

    private static final String TELEGRAM_API_URL = 'https://api.telegram.org/bot';
    private static final String TELEGRAM_FILE_API_URL = 'https://api.telegram.org/file/bot';

    public enum MESSAGE_MOD {Markdown, MarkdownV2}
    public enum API_COMMAND {sendMessage, pinChatMessage, answerCallbackQuery, editMessageText, answerInlineQuery, getFile, downloadFile}

    public static void answerCallbackQuery(CallbackQuery callback) {
        sendRequest(callback, API_COMMAND.answerCallbackQuery);
    }

    public static void answerInlineQuery(InlineQuery callback) {
        sendRequest(callback, API_COMMAND.answerInlineQuery);
    }

    public static TelegramBotApi.Result sendMessage(Message telegramMessage) {
        HttpResponse response = sendRequest(telegramMessage, telegramMessage.message_id == null ? API_COMMAND.sendMessage : API_COMMAND.editMessageText);
        if (response.getStatusCode() == 200) {
            TelegramBotApi.Result result = (TelegramBotApi.Result)JSON.deserialize(response.getBody(), TelegramBotApi.Result.class);
            return result;
        } else {
            Logger.error(response.getStatus() + '|' + response.getStatusCode() + '|' + response.getBody(), 'TelegramBotApi.sendMessage');
            return null;
        }
    }

    public static void pinMessage(PinMessage pin) {
        sendRequest(pin, API_COMMAND.pinChatMessage);
    }

    public static FileResult getFile(String fileId) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(getEndpoint(API_COMMAND.getFile) + '?file_id='+fileId);
            request.setMethod('GET');
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                return (FileResult)JSON.deserialize(response.getBody(), FileResult.class);
            } else {
                Logger.error(response.getStatus() + '|' + response.getStatusCode() + '|' + response.getBody(), 'TelegramBotApi.getFile');
                return null;
            }
        } catch (Exception e) {
            Logger.error(e, 'TelegramBotApi.getFile');
            throw e;
        }
    }

    public static Blob downloadFile(FileInfo file) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(getEndpoint(API_COMMAND.downloadFile) + '/' + file.file_path);
            request.setMethod('GET');
            request.setTimeout(60000);
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                return response.getBodyAsBlob();
            } else {
                Logger.error(response.getStatus() + '|' + response.getStatusCode() + '|' + response.getBody(), 'TelegramBotApi.downloadFile');
                return null;
            }
        } catch (Exception e) {
            Logger.error(e, 'TelegramBotApi.downloadFile');
            throw e;
        }
    }

    private static HttpResponse sendRequest(Object body, API_COMMAND command) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setEndpoint(getEndpoint(command));
        request.setMethod('POST');
        request.setBody(JSON.serialize(body));
        return new Http().send(request);
    }

    private static String getEndpoint(API_COMMAND command) {
        if (command == API_COMMAND.downloadFile) {
            return TELEGRAM_FILE_API_URL + Secured__c.getInstance().TelegramBotToken__c;
        } else {
            return TELEGRAM_API_URL + Secured__c.getInstance().TelegramBotToken__c + '/' + command.name();
        }
    }

    public class Result {
        public Boolean ok;
        public TelegramBotUpdateDTO.TG_Message result;
    }

    public class FileResult {
        public Boolean ok;
        public FileInfo result;
    }

    public class FileInfo {
        public String file_id;
        public String file_unique_id;
        public Integer file_size;
        public String file_path;
    }

    public class PinMessage {
        public String message_id;
        public String chat_id;
        public Boolean disable_notification;

        public PinMessage(String chat_id, String message_id) {
            this.chat_id = chat_id;
            this.message_id = message_id;
            this.disable_notification = true;
        }
    }

    public class Message {
        public String message_id;
        public String chat_id;
        public String text;
        public String reply_to_message_id;
        public String parse_mode;
        public String reply_markup = '';
        public Boolean disable_notification;
    }

    public class CallbackQuery {
        public String callback_query_id;
        public String text;
        public Boolean show_alert;
    }

    public class ForceReply {
        public Boolean force_reply;
        public Boolean selective;

        public ForceReply(Boolean force_reply, Boolean selective) {
            this.force_reply = force_reply;
            this.selective = selective;
        }
    }

    public class ReplyMarkup {
        public List<List<InlineKeyboardButton>> inline_keyboard;

        public ReplyMarkup(List<InlineKeyboardButton> buttons) {
            inline_keyboard = new List<List<InlineKeyboardButton>>{buttons};
        }
    }

    public class InlineQuery {
        public String inline_query_id;
        public List<InlineQueryResultArticle> results;

        public InlineQuery(String inline_query_id, List<InlineQueryResultArticle> results) {
            this.inline_query_id = inline_query_id;
            this.results = results;
        }
    }

    public class InlineQueryResultArticle {
        public String type = 'article';
        public String id;
        public String title;
        public InputTextMessageContent input_message_content;

        public InlineQueryResultArticle(String id, String title, String message_text) {
            this.id = id;
            this.title = title;
            this.input_message_content = new InputTextMessageContent(message_text);
        }
    }

    public class InputTextMessageContent {
        public String message_text;

        public InputTextMessageContent(String message_text) {
            this.message_text = message_text;
        }
    }

    public class InlineKeyboardButton {
        public String text;
        public String callback_data;

        public InlineKeyboardButton(String text) {
            this(text, text);
        }

        public InlineKeyboardButton(String text, String callback_data) {
            this.text = text;
            this.callback_data = callback_data;
        }
    }

    public class MessageEntity {
        public String type;
        public Integer offset;
        public Integer length;
        public String url;
    }
}