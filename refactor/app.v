module main

import term.ui as tui
import os

struct App {
mut:
	ctx &tui.Context = 0 // init to null

	logging_enabled bool//=true
	log_filename string = "vcoder.log"

	current_file []string
	current_filename string
	is_saved bool

	col ColourStack

	scroll_offset int

	cursor_pos Coord
}

fn (mut app App) load_file() {
	app.log("loading file ${app.current_filename}")
	app.current_file = os.read_lines(app.current_filename) or {
		app.panic(err.msg)
	}
}

// we can't print debug stuff to stdout because termui will clear it, so
// we have to store it persistently instead
fn (mut app App) log(msg string) {
	if app.logging_enabled {
		panic_msg := "Tried to log $msg, but got "
		mut fh := os.open_append(app.log_filename) or {panic(panic_msg + err.msg)} // app.panic() calls this, so we can't loop back there
		fh.writeln(msg) or {panic(panic_msg + err.msg)}
		fh.close() // does it autoclose? best not to find out
	}
}

fn (mut app App) panic(err string) {
	app.log("Panicking: $err")
	app.show_fullscreen_menu({
		title: {
			text: "Error",
			col: {
				custom_fg: true,
				fg: {r: 255, g: 0, b: 0}
			},
			bold: true
		},
		lines: [{
			text: err
		}]
	})
}

fn (mut app App) init(filename string) {
	app.current_filename = filename
	app.ctx = tui.init(
		user_data: app,
		frame_fn: app_process_frame,
		event_fn: app_process_event,
		capture_events: true
	)
	app.col = ColourStack {
		ctx: app.ctx
	}
	os.write_file(app.log_filename, "") or {app.panic("Tried to clear logfile, but got ${err.msg}")} // clear the logfile
}

fn (mut app App) start() ? {
	app.ctx.run()?
}