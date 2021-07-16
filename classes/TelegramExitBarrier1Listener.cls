public with sharing class TelegramExitBarrier1Listener extends TelegramAbstractBarrierListener {

    private static final String GATE_ACTION = 'p_2_cucle_1';

    public TelegramExitBarrier1Listener() {
        super(TELEGRAM_COMMAND.Iexit1, GATE_ACTION);
    }
}