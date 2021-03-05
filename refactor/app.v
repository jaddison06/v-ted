module main

import term.ui as tui

struct App {
mut:
	ctx &tui.Context = 0 // init to null

	current_file []string
	current_filename string
	is_saved bool

	scroll_offset int

	cursor_pos Coord
}

fn (mut app App) init(filename string) {
	app.current_filename = filename
	app.ctx = tui.init(
		user_data: app,
		frame_fn: app_process_frame,
		event_fn: app_process_event,
		capture_events: true
	)
}

fn (mut app App) start() ? {
	app.ctx.run()?
}