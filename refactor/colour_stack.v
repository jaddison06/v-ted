module main

import term.ui as tui

struct ColourStack {
mut:
	fg []tui.Color
	bg []tui.Color
	ctx &tui.Context
}

// if we've accidentally called ctx.reset(), use this to set the colours
// back to what they should be
fn (mut stack ColourStack) update_all() {
	stack.update_fg()
	stack.update_bg()
}

fn (mut stack ColourStack) update_fg() {
	if stack.fg != [] {
		stack.ctx.set_color(stack.fg.last())
	} else {
		stack.ctx.reset_color()
	}
}

fn (mut stack ColourStack) update_bg() {
	if stack.bg != [] {
		stack.ctx.set_bg_color(stack.bg.last())
	} else {
		stack.ctx.reset_bg_color()
	}
}

fn (mut stack ColourStack) set_fg(col tui.Color) {
	stack.fg << col
	stack.update_fg()
}

fn (mut stack ColourStack) set_bg(col tui.Color) {
	stack.bg << col
	stack.update_bg()
}

fn (mut stack ColourStack) pop_fg() {
	stack.fg.delete_last() // pop() likes to be assigned to a variable - we're not doing that
	stack.update_fg()
}

fn (mut stack ColourStack) pop_bg() {
	stack.bg.delete_last()
	stack.update_bg()
}