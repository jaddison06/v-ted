module main

import term.ui as tui

fn (mut app App) get_centre() Coord {
	return {
		x: app.ctx.window_width / 2,
		y: app.ctx.window_height / 2
	}
}

// can you smell that? it's good abstraction
fn (mut app App) draw_rich(pos Coord, text RichText) {
	if text.col.custom_fg {
		app.col.set_fg(text.col.fg)
		defer {
			app.col.pop_fg()
		}
	}
	if text.col.custom_bg {
		app.col.set_bg(text.col.bg)
		defer {
			app.col.pop_bg()
		}
	}
	// not so tasty. maybe change colour_stack to a format_stack
	// with absolutely everything in it?
	if text.bold {
		app.ctx.bold()
		defer {
			// no way to reset boldness, so we have to reset everything and then
			// update the colours.
			// todo (jaddison): submit a pr to un-bold the character state
			app.ctx.reset()
			app.col.update_all()
		}
	}
	app.ctx.draw_text(pos.x, pos.y, text.text)
}

struct ColourCustomisations {
mut:
	custom_fg bool
	fg tui.Color
	custom_bg bool
	bg tui.Color
}

struct RichText {
	text string
	bold bool
	col ColourCustomisations
}

struct FullscreenMenu {
	title RichText
	lines []RichText
}

struct MenuItem {
	title RichText
	on_hover fn(mut app &App)
	on_click fn(mut app &App)
}

struct Menu {
	title RichText
	lines []MenuItem
	border bool = true
	border_col tui.Color
	padding int = 2
}

fn (mut app App) get_text_centered_x(text string) int {
	return app.get_centre().x - (text.len / 2)
}

fn (mut app App) draw_vertically_centered(y int, text RichText) {
	app.draw_rich({x: app.get_text_centered_x(text.text), y: y}, text)
}

fn (mut app App) show_menu(menu Menu) {
	centre := app.get_centre()
	start_y := centre.y - (menu.lines.len / 2)
	mut max_width := 0
	for i, line in menu.lines {
		if line.title.text.len > max_width {
			max_width = line.title.text.len // todo (jaddison): use max()
		}
		app.draw_vertically_centered(start_y + i, line.title)
	}

	minimums := Coord{x: centre.x - (max_width / 2), y: start_y}
	maximums := Coord{x: centre.x + (max_width / 2), y: centre.y + (menu.lines.len / 2)}

	show_title := menu.title.text != ""

	if show_title {
		// todo (jaddison): Some way of making title bold _without_ making menu mutable?
		/*
		if !menu.title_weight_override {
			menu.title.bold = true
		}*/
		app.draw_rich({x: minimums.x, y: minimums.y - menu.padding}, menu.title)
	}
	if menu.border {
		app.col.set_bg(menu.border_col)
		app.ctx.draw_empty_rect(
			minimums.x - menu.padding,
			minimums.y - (menu.padding * if show_title {2} else {1} ),
			maximums.x + menu.padding,
			maximums.y + menu.padding
		)
		app.col.pop_bg()
	}
}

fn (mut app App) show_fullscreen_menu(menu FullscreenMenu) {
	app.ctx.clear()
	mut y := app.get_centre().y - (menu.lines.len + 2) / 2
	app.draw_vertically_centered(y, menu.title)
	y += 2
	for line in menu.lines {
		app.draw_vertically_centered(y, line)
		y++
	}
}