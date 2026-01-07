extends Node

# Level signals
@warning_ignore("unused_signal")
signal switch_level
@warning_ignore("unused_signal")
signal game_started

# Death signals
@warning_ignore("unused_signal")
signal falling_into_hole(position)

# Timer signals
@warning_ignore("unused_signal")
signal add_time(amount)
@warning_ignore("unused_signal")
signal times_up

# Coin signals
@warning_ignore("unused_signal")
signal collect_coin
