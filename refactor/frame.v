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

	app.panic("Test")

	app.after_frame()

}