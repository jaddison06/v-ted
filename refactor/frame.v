module main

// before_frame does any processing needed before the render, including loading the file &
// clearing the screen
fn (mut app App) before_frame() {
	app.log("before_frame() at ${app.ctx.frame_count}")
	if app.current_file == [] { // todo (jaddison): if the file is actually empty this will get called each frame
		app.load_file()
	}

	app.ctx.clear()
}

// after_frame does any processing needed after the render, including flushing the tui context
fn (mut app App) after_frame() {
	// display at all costs!
	app.draw_rich(Coord{0, 0}, app.debug_msg)

	app.ctx.flush()
}

// app_process_frame is the callback passed to tui which handles top-level render logic
fn app_process_frame(x voidptr) {
	mut app := &App(x)

	app.before_frame()

	for i, line in app.current_file {
		app.ctx.draw_text(1, i+2, line) // todo (jaddison): why +2?
		app.log("$i | $line at ${i+2}")
	}

	app.draw_menus()

	app.after_frame()

}