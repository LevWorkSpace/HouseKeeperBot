public class TelegramBotUpdateDTO {
    public String update_id;
    public TG_Message message;
    public TG_CallbackQuery callback_query;
    public TG_ChatMemberUpdated chat_member;
    public TG_InlineQuery inline_query;
    public TG_ChosenInlineResult chosen_inline_result;

    public class TG_Message {
        public String message_id;
        public TG_User tFrom;
        public TG_Chat chat;
        public String tDate;
        public String text;
        public String caption;
        public String arguments;
        public List<TG_Photo> photo;
        public String author_signature;
        public TG_Message reply_to_message;
        public List<TG_User> new_chat_members;
        public TG_User left_chat_member;
        public List<TG_MessageEntity> entities;
        public List<TG_MessageEntity> caption_entities;
    }

    public class TG_MessageEntity {
        public String type;
        public Integer offset;
        public Integer length;
        public TG_User user;
    }

    public class TG_CallbackQuery {
        public String id;
        public TG_User tFrom;
        public TG_Message message;
        public String tDate;
        public String chat_instance;
        public String data;
    }

    public class TG_ChatMemberUpdated {
        public TG_User tFrom;
        public TG_Chat chat;
        public TG_Message message;
        public String tDate;
        public TG_ChatMember old_chat_member;
        public TG_ChatMember new_chat_member;
    }

    public class TG_Photo {
        public String file_id;
        public String file_unique_id;
        public Integer width;
        public Integer height;
        public Integer file_size;
    }

    public class TG_ChatMember {
        public TG_User user;
        public String status;
    }

    public class TG_InlineQuery {
        public String id;
        public TG_User tFrom;
        public String query;
    }

    public class TG_ChosenInlineResult {
        public String result_id;
        public TG_User tFrom;
        public String inline_message_id;
        public String query;
    }

    public class TG_User {
        public String id;
        public Boolean is_bot;
        public String first_name;
        public String last_name;
        public String username;
    }

    public class TG_Chat {
        public String id;
        public String first_name;
        public String last_name;
        public String username;
        public String type;
    }

    public static TelegramBotUpdateDTO deserialize(String jsonString) {
        jsonString = jsonString.replace('"from":', '"tFrom":');
        jsonString = jsonString.replace('"date":', '"tDate":');
        return (TelegramBotUpdateDTO)JSON.deserialize(jsonString, TelegramBotUpdateDTO.class);
    }
}