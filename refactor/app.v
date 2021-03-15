module main

import term.ui as tui
import os

// App is the main struct used for state management
struct App {
mut:
	ctx &tui.Context = 0 // init to null

	logging_enabled bool//=true
	log_filename string = "vcoder.log"

	current_file []string
	current_filename string
	is_saved bool

	col ColourStack

	show_centered_menu bool
	show_fullscreen_menu bool
	menu_stack MenuStack // USE THIS TO MODIFY MENUS
	// DON'T MODIFY THESE DIRECTLY !!!
	// todo (jaddison): move these to the MenuStack itself?
	centered_menu Menu
	fullscreen_menu Menu

	scroll_offset int

	cursor_pos Coord
}

// load_file reads app.current_filename into app.current_file
fn (mut app App) load_file() {
	app.log("loading file ${app.current_filename}")
	app.current_file = os.read_lines(app.current_filename) or {
		app.panic(err.msg)
	}
}

// draw_rect draws a rect & takes care of pushing/popping the ColourStack
fn (mut app App) draw_rect(col tui.Color, start Coord, end Coord) {
	app.col.set_bg(col) // rect draws on the bg col
	app.ctx.draw_empty_rect(
		start.x, start.y,
		end.x, end.y
	)
	app.col.pop_bg()
}

// draw_menus efficiently draws menus if they're enabled. Fullscreen is prioritised & will appear "on top"
fn (mut app App) draw_menus() {
	if app.show_fullscreen_menu {
		app.draw_fullscreen_menu()
	} else if app.show_centered_menu {
		app.draw_centered_menu()
	}
}

// log stores a message in app.log_filename if app.logging_enabled is true.
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

// panic shows a fullscreen error message
fn (mut app App) panic(err string) {
	app.log("Panicking: $err")
	app.menu_stack.show_fullscreen({
		title: RichText{
			text: "Error",
			col: {
				custom_fg: true,
				fg: {r: 255, g: 0, b: 0}
			},
			bold: true
		},
		items: [
			MenuItem {
				title: err
			}
		],
		//exit_on_escape: false // todo (jaddison): implement alternative exit route, then disable this
	})
}

// init initializes the app's context, stacks, and clears the log file if logging is enabled
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
	app.menu_stack = MenuStack {
		app: app
	}
	if app.logging_enabled {
		os.write_file(app.log_filename, "") or {app.panic("Tried to clear logfile, but got ${err.msg}")} // clear the logfile
	}
}

// start starts the app
fn (mut app App) start() ? {
	app.ctx.run()?
}