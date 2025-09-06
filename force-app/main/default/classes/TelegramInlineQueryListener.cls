public without sharing class TelegramInlineQueryListener implements TelegramBotUpdateListener {
    public Boolean isApplicable(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_InlineQuery inlineQuery = tUpdate.inline_query;
        return (inlineQuery != null && inlineQuery.query != null) ;
    }

    public void dispatch(TelegramBotUpdateDTO tUpdate) {
        TelegramBotUpdateDTO.TG_InlineQuery inlineQuery = tUpdate.inline_query;

        TelegramBotApi.answerInlineQuery(
                new TelegramBotApi.InlineQuery(
                    inlineQuery.id,
                    new List<TelegramBotApi.InlineQueryResultArticle> {
                        new TelegramBotApi.InlineQueryResultArticle('1', 'Hello ' + inlineQuery.tFrom.first_name, inlineQuery.query)
                    }
                )
        );
    }
}