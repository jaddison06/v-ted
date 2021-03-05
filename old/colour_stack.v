module main

import term.ui as tui

struct ColourStack {
mut:
	fg []tui.Color
	bg []tui.Color
	ctx &tui.Context
}

fn (mut stack ColourStack) set_fg(col tui.Color) {
	stack.fg << col
	stack.ctx.set_color(col)
}

fn (mut stack ColourStack) set_bg(col tui.Color) {
	stack.bg << col
	stack.ctx.set_bg_color(col)
}

fn (mut stack ColourStack) pop_fg(col tui.Color) {
	if stack.fg != [] {
		stack.ctx.set_color(stack.fg.pop())
	} else {
		stack.ctx.reset_color()
	}
}

fn (mut stack ColourStack) pop_bg(col tui.Color) {
	if stack.bg != [] {
		stack.ctx.set_bg_color(stack.bg.pop())
	} else {
		stack.ctx.reset_bg_color()
	}
}