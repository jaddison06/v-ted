module main

import term.ui as tui

// ColourStack is a data structure for handling both bg and fg colour for tui. Don't
// forget to initialize its reference to the tui.Context!
struct ColourStack {
mut:
	fg []tui.Color
	bg []tui.Color
	ctx &tui.Context
}

// update_all calls update_fg() and update_bg().
// if we've accidentally called ctx.reset(), use this to set the colours
// back to what they should be
fn (mut stack ColourStack) update_all() {
	stack.update_fg()
	stack.update_bg()
}

// update_fg sets the app's foreground colour, or resets it if necessary.
fn (mut stack ColourStack) update_fg() {
	if stack.fg != [] {
		stack.ctx.set_color(stack.fg.last())
	} else {
		stack.ctx.reset_color()
	}
}

// update_bg sets the app's background colour, or resets it if necessary.
fn (mut stack ColourStack) update_bg() {
	if stack.bg != [] {
		stack.ctx.set_bg_color(stack.bg.last())
	} else {
		stack.ctx.reset_bg_color()
	}
}

// set_fg sets the app's foreground colour
fn (mut stack ColourStack) set_fg(col tui.Color) {
	stack.fg << col
	stack.update_fg()
}

// set_bg sets the app's background colour
fn (mut stack ColourStack) set_bg(col tui.Color) {
	stack.bg << col
	stack.update_bg()
}

// pop_fg returns the app to the previous foreground colour
fn (mut stack ColourStack) pop_fg() {
	stack.fg.delete_last() // pop() likes to be assigned to a variable - we're not doing that
	stack.update_fg()
}

// pop_bg returns the app to the previous background colour
fn (mut stack ColourStack) pop_bg() {
	stack.bg.delete_last()
	stack.update_bg()
}