module main

import term.ui as tui

// get_centre returns the coordinates of the centre of the window
fn (mut app App) get_centre() Coord {
	return {
		x: app.ctx.window_width / 2,
		y: app.ctx.window_height / 2
	}
}

// draw_rich renders a Text in the app.
fn (mut app App) draw_rich(pos Coord, text Text) {
	if text is RichText {
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
	}
	app.ctx.draw_text(pos.x, pos.y, text.str())
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
mut:
	text string
	bold bool
	col ColourCustomisations
}

// Text represents some text on screen.
type Text = RichText | string

fn (text Text) str() string {
	if text is RichText {
		return text.text
	} else if text is string {
		return text
	}
	return "" // to please the compiler
}

fn (text Text) to_rich() RichText {
	if text is RichText {
		return text
	} else if text is string {
		return RichText {
			text: text
		}
	}
	return RichText{}
}

/*
fn (a Text) == (b Text) bool {
	if a is string || b is string {
		return a.str() == b.str()
	} else if a is RichText && b is RichText {
		return (a as RichText) == (b as RichText)
	}
}*/

// MenuItem represents an item in a menu.
struct MenuItem {
	title Text
	highlight_on_hover bool
	hover_col tui.Color
mut:
	is_hovered bool
}

// Menu represents a menu - either fullscreen or centered, depending on the context.
// It also holds the callback for the menu's logic.
struct Menu {
	title Text
	items []MenuItem
	border bool = true
	border_col tui.Color
	padding int = 2 // unused in a fullscreen menu
	close_on_escape bool = true // close when Escape key pressed?
	
	// callback for when an item is clicked.
	// todo (jaddison): this doesn't know if it's centered or fullscreen, so it can't reflect via the App
	on_item_click fn(mut app App, item_index int)
}

// get_text_centered_x gets the xpos needed to render the text centrally in the window.
fn (mut app App) get_text_centered_x(text string) int {
	return app.get_centre().x - (text.len / 2)
}

// draw_vertically_centered draws the text at the y pos, centered on the x axis.
fn (mut app App) draw_vertically_centered(y int, text Text) {
	app.draw_rich({x: app.get_text_centered_x(text.str()), y: y}, text)
}

fn (mut app App) clear_rect(min Coord, max Coord) {
	mut empty_line_str := ""
	for _ in 0..(max.x - min.x) {
		empty_line_str += " "
	}
	for i in 0..(max.y - min.y) {
		app.draw_rich(Coord {x: min.x, y: min.y + i}, empty_line_str)
	}
}

fn (mut app App) draw_menu_item(item MenuItem, y int) {
	mut text := item.title.to_rich()
	if item.is_hovered {
		text.col.custom_bg = true
		text.col.bg = item.hover_col
	}
	app.draw_vertically_centered(y, text)
}

// draw_centered_menu draws a menu centrally in the window.
fn (mut app App) draw_centered_menu() {
	centre := app.get_centre()
	start_y := centre.y - (app.centered_menu.items.len / 2)
	mut max_width := 0
	for line in app.centered_menu.items {
		if line.title.str().len > max_width {
			max_width = line.title.str().len // todo (jaddison): use max()
		}
	}
	
	show_title := app.centered_menu.title.str() != ""
	
	minimums := Coord{x: centre.x - (max_width / 2), y: start_y}
	maximums := Coord{x: centre.x + (max_width / 2), y: centre.y + (app.centered_menu.items.len / 2)}

	bounds_min := Coord {
		x: minimums.x - app.centered_menu.padding,
		y: minimums.y - (app.centered_menu.padding * if show_title {2} else {1} )
	}
	bounds_max := Coord {
		x: maximums.x + app.centered_menu.padding,
		y: maximums.y + app.centered_menu.padding
	}

	app.clear_rect(bounds_min, bounds_max)

	for i, line in app.centered_menu.items {
		//app.draw_vertically_centered(start_y + i, line.title)
		app.draw_menu_item(line, start_y + i)
	}
	
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
			bounds_min,
			bounds_max
		)
	}
}

// draw_fullscreen_menu draws a menu fullscreen in the window
fn (mut app App) draw_fullscreen_menu() {
	app.ctx.clear()
	mut y := app.get_centre().y - (app.fullscreen_menu.items.len + 2) / 2
	app.draw_vertically_centered(y, app.fullscreen_menu.title)
	y += 2
	for line in app.fullscreen_menu.items {
		app.draw_menu_item(line, y)
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

// get_menu_item_bounding_box returns the position of the start & end of the item, inclusive on
// both sides. It assumes that the item doesn't wrap around to multiple lines, so the y positions
// of both Coords will be the same.
fn (mut app App) get_menu_item_bounding_box(menu Menu, index int) (Coord, Coord) {

	mut start := Coord{}
	mut end := Coord{}
	
	item_text := menu.items[index].title.str()

	start.x = app.get_text_centered_x(item_text)
	end.x = start.x + item_text.len
	
	return 
		Coord {
			x: 1,
			y: 1
		},
		Coord {
			x: 1,
			y: 1
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
	
	// todo (jaddison): mouse move/click stuff - hovers, or callback on click
	if event.typ == .mouse_move {
		app.debug_msg = event.str()
		for i, mut item in menu.items {
			min, max := app.get_menu_item_bounding_box(menu, i)
			if
				min.x >= event.x &&
				max.x <= event.x &&
				min.y <= event.y &&
				max.y >= event.y &&
				item.highlight_on_hover
			{
				item.is_hovered = true
			}
		}
	}
	
	return 0
}