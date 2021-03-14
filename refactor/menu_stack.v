module main

// todo (jaddison): lots of repeated code from ColourStack. abstraction? difficult without classes...

// MenuStack is a data structure for handling both centered and fullscreen menus within an App. Don't
// forget to initialize its reference to the parent app!
struct MenuStack {
mut:
	centered []Menu
	fullscreen []Menu
	app &App
}

// update_centered sets the app's centered menu, or hides it if necessary.
fn (mut stack MenuStack) update_centered() {
	if stack.centered != [] {
		stack.app.centered_menu = stack.centered.last()
	} else {
		stack.app.show_centered_menu = false
	}
}

// update_fullscreen sets the app's fullscreen menu, or hides it if necessary.
fn (mut stack MenuStack) update_fullscreen() {
	if stack.fullscreen != [] {
		stack.app.fullscreen_menu = stack.fullscreen.last()
	} else {
		stack.app.show_fullscreen_menu = false
	}
}

// show_centered shows a new centered menu.
fn (mut stack MenuStack) show_centered(menu Menu) {
	stack.app.show_centered_menu = true
	stack.centered << menu
	stack.update_centered()
}

// show_fullscreen shows a new fullscreen menu.
fn (mut stack MenuStack) show_fullscreen(menu Menu) {
	stack.app.show_fullscreen_menu = true
	stack.fullscreen << menu
	stack.update_fullscreen()
}

// pop_centered closes the current centered menu.
fn (mut stack MenuStack) pop_centered() {
	stack.centered.delete_last()
	stack.update_centered()
}

// pop_fullscreen closes the current fullscreen menu.
fn (mut stack MenuStack) pop_fullscreen() {
	stack.fullscreen.delete_last()
	stack.update_fullscreen()
}