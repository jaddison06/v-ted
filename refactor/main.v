module main

fn main() {
	mut app := &App{}
	app.init("../main.v.bak")
	app.start()?
}