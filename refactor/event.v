module main

import term.ui as tui

fn app_process_event(event &tui.Event, x voidptr) {
	//mut app := &App(x)

	if event.typ == .key_down && event.code == .escape {
		exit(0)
	}
}