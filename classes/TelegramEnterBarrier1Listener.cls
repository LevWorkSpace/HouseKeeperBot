public with sharing class TelegramEnterBarrier1Listener extends TelegramAbstractBarrierListener {

    private static final String GATE_ACTION = 'p_1_cucle_1';

    public TelegramEnterBarrier1Listener() {
        super(TELEGRAM_COMMAND.Ienter1, GATE_ACTION);
    }
}