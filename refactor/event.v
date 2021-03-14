module main

import term.ui as tui

// app_process_event is the callback passed to tui. It handles top-level event logic.
// Any open menu captures all events - even outside its bounding box. Fullscreen takes priority,
// as it gets rendered on top. If no menu is open then the event gets passed to app.process_event()
fn app_process_event(event &tui.Event, x voidptr) {
	mut app := &App(x)

	if app.show_fullscreen_menu {
		if app.fullscreen_menu.process_event(event, mut app) == -1 {
			app.menu_stack.pop_fullscreen()
		}
	} else if app.show_centered_menu {
		if app.centered_menu.process_event(event, mut app) == -1 {
			app.menu_stack.pop_centered()
		}
	} else {
		app.process_event(event)
	}
}

// process_event contains the main event handling logic for the App.
fn (mut app App) process_event(event &tui.Event) {
	if event.typ == .key_down && event.code == .escape {
		exit(0)
	}
}