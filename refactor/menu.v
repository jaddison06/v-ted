module main

import term.ui as tui

fn (mut app App) get_centre() Coord {
	return {
		x: app.ctx.window_width / 2,
		y: app.ctx.window_height / 2
	}
}

// can you smell that? it's good abstraction
fn (mut app App) write_rich(pos Coord, text RichText) {
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

struct Menu {
	title RichText
	lines []RichText
	border_col tui.Color
}

fn (mut app App) get_text_centered_x(text string) int {
	return app.get_centre().x - (text.len / 2)
}

fn (mut app App) show_menu(menu Menu) {
	// todo (jaddison): impl
}

fn (mut app App) show_fullscreen_menu(menu FullscreenMenu) {
	app.ctx.clear()
	mut y := app.get_centre().y - (menu.lines.len + 2) / 2
	app.write_rich({x: app.get_text_centered_x(menu.title.text), y: y}, menu.title)
	y += 2
	for line in menu.lines {
		app.write_rich({x: app.get_text_centered_x(line.text), y: y}, line)
		y++
	}
}