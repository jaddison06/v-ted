module main

fn (mut app App) before_frame() {
	app.ctx.clear()
}

fn (mut app App) after_frame() {
	app.ctx.flush()
}

fn app_process_frame(x voidptr) {
	mut app := &App(x)

	app.before_frame()

	app.ctx.draw_text(3, 3, "hello world")

	app.after_frame()

}