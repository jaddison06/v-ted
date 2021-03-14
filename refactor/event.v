module main

import term.ui as tui

fn app_process_event(event &tui.Event, x voidptr) {
	mut app := &App(x)

	if app.show_centered_menu {
		app.centered_menu.process_event(event, app)
	}

	if event.typ == .key_down && event.code == .escape {
		exit(0)
	}
}

fn (mut app App) process_event(event &tui.Event) {

}