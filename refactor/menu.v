module main

import term.ui as tui

// get_centre returns the coordinates of the centre of the window
fn (mut app App) get_centre() Coord {
	return {
		x: app.ctx.window_width / 2,
		y: app.ctx.window_height / 2
	}
}

// draw_rich renders a RichText in the app.
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

// ColourCustomisations are basically a workaround for V's lack of null. They
// allow customisation of foreground & backgroun colours, but allow you to ignore
// them. Mutable because sometimes we want to keep the colour, but change up the enable.
struct ColourCustomisations {
mut:
	custom_fg bool
	fg tui.Color
	custom_bg bool
	bg tui.Color
}

// RichText holds information for drawing formatted text to the window.
struct RichText {
	text string
	bold bool
	col ColourCustomisations
}

// MenuItem represents an item in a menu.
struct MenuItem {
	title RichText
	highlight_on_hover bool
	hover_col tui.Color
}

// Menu represents a menu - either fullscreen or centered, depending on the context.
// It also holds the callback for the menu's logic.
struct Menu {
	title RichText
	lines []MenuItem
	border bool = true
	border_col tui.Color
	padding int = 2 // unused in a fullscreen menu
	close_on_escape bool = true // close when Escape key pressed?
	
	on_item_click fn(mut app App, item_index int)
}

// get_text_centered_x gets the xpos needed to render the text centrally in the window.
fn (mut app App) get_text_centered_x(text string) int {
	return app.get_centre().x - (text.len / 2)
}

// draw_vertically_centered draws the text at the y pos, centered on the x axis.
fn (mut app App) draw_vertically_centered(y int, text RichText) {
	app.draw_rich({x: app.get_text_centered_x(text.text), y: y}, text)
}

// draw_centered_menu draws a menu centrally in the window.
fn (mut app App) draw_centered_menu() {
	centre := app.get_centre()
	start_y := centre.y - (app.centered_menu.lines.len / 2)
	mut max_width := 0
	for i, line in app.centered_menu.lines {
		if line.title.text.len > max_width {
			max_width = line.title.text.len // todo (jaddison): use max()
		}
		app.draw_vertically_centered(start_y + i, line.title)
	}

	minimums := Coord{x: centre.x - (max_width / 2), y: start_y}
	maximums := Coord{x: centre.x + (max_width / 2), y: centre.y + (app.centered_menu.lines.len / 2)}

	show_title := app.centered_menu.title.text != ""

	if show_title {
		// todo (jaddison): Some way of making title bold _without_ making menu mutable?
		/*
		if !menu.title_weight_override {
			menu.title.bold = true
		}*/
		app.draw_rich({x: minimums.x, y: minimums.y - app.centered_menu.padding}, app.centered_menu.title)
	}
	if app.centered_menu.border {
		app.draw_rect(
			app.centered_menu.border_col,
			{
				x: minimums.x - app.centered_menu.padding,
				y: minimums.y - (app.centered_menu.padding * if show_title {2} else {1} )
			},
			{
				x: maximums.x + app.centered_menu.padding,
				y: maximums.y + app.centered_menu.padding
			}
		)
	}
}

// draw_fullscreen_menu draws a menu fullscreen in the window
fn (mut app App) draw_fullscreen_menu() {
	app.ctx.clear()
	mut y := app.get_centre().y - (app.fullscreen_menu.lines.len + 2) / 2
	app.draw_vertically_centered(y, app.fullscreen_menu.title)
	y += 2
	for line in app.fullscreen_menu.lines {
		app.draw_vertically_centered(y, line.title)
		y++
	}
	
	if app.fullscreen_menu.border {
		app.draw_rect(
			app.fullscreen_menu.border_col,
			{
				x: 1,
				y: 1
			},
			{
				x: app.ctx.window_width,
				y: app.ctx.window_height
			}
		)
	}
}

// process_event processes an event passed to it by app.process_event() and handles hovers,
// special keys, and firing the menu's callback if an item is clicked.
// it returns -1 if we want to exit, else 0. Doing it this way because we don't know
// if we're a centered or fullscreen menu, therefore we don't know what to pop. Caller's
// responsibility.
fn (menu Menu) process_event(event &tui.Event, mut app &App) int {
	if menu.close_on_escape && event.typ == .key_down && event.code == .escape {
		return -1
	}



	return 0
}