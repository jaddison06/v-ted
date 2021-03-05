module main

fn (mut app App) before_frame() {
	app.log("before_frame() at ${app.ctx.frame_count}")
	if app.current_file == [] { // todo (jaddison): if the file is actually empty this will get called each frame
		app.load_file()
	}

	app.ctx.clear()
}

fn (mut app App) after_frame() {
	app.ctx.flush()
}

fn app_process_frame(x voidptr) {
	mut app := &App(x)

	app.before_frame()

	for i, line in app.current_file {
		app.ctx.draw_text(1, i+1, line)
		app.log("$i | $line at ${i+2}")
	}

	app.after_frame()

}