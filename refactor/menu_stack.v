module main

// todo (jaddison): lots of repeated code from ColourStack. abstraction? difficult without classes...

struct MenuStack {
mut:
	centered []Menu
	fullscreen []Menu
	app &App
}

fn (mut stack MenuStack) update_centered() {
	if stack.centered != [] {
		stack.app.centered_menu = stack.centered.last()
	} else {
		stack.app.show_centered_menu = false
	}
}

fn (mut stack MenuStack) update_fullscreen() {
	if stack.fullscreen != [] {
		stack.app.fullscreen_menu = stack.fullscreen.last()
	} else {
		stack.app.show_fullscreen_menu = false
	}
}

fn (mut stack MenuStack) show_centered(menu Menu) {
	stack.app.show_centered_menu = true
	stack.centered << menu
	stack.update_centered()
}

fn (mut stack MenuStack) show_fullscreen(menu Menu) {
	stack.app.show_fullscreen_menu = true
	stack.fullscreen << menu
	stack.update_fullscreen()
}

fn (mut stack MenuStack) pop_centered() {
	stack.centered.delete_last()
	stack.update_centered()
}

fn (mut stack MenuStack) pop_fullscreen() {
	stack.fullscreen.delete_last()
	stack.update_fullscreen()
}