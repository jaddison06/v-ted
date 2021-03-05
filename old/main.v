module main

import term.ui as tui
import term
import os

// Currently the filename is hard-coded as main.v.bak, change it in main(), at the bottom
// (but make a backup of your work first!)

// TODO:
//   -> infrastructure for menus
//   -> start empty, ctrl+o to open
//   -> tabs
//        -> widgets??
//        -> interface
//   -> config & settings storage (similar to shared-prefs. platform independent)
//        -> reopen last workspace
//   -> command line args to open file/folder
//   -> highlighting
//        -> copy/paste
//   -> syntax highlighting
//   -> impl any remaining menus

struct Coord {
pub mut:
    x int
    y int
}

enum MenuType {
    nothing
    test
    find_in_file
    find_in_workspace
    exit
    save_as
    open_file
    open_workspace
    settings
    run_command
}

struct App {
mut:
    tui &tui.Context = 0
    scroll_offset int
    file []string
    filename string
    is_saved bool
    cursor Coord = {x: 1, y: 1} // bitch starts at (1, 1)
    tab string = "    " // four spaces (todo: customisable via settings)
    message string

    menu_type MenuType = .nothing
    old_menu_type MenuType = .nothing
    menu Menu
    menu_data MenuData

    col ColourStack
}

fn (mut app App) panic(err string) {
    //app.file = ["Error: $err"]
    app.message = "Error: $err"
}

fn (mut app App) menu_has_changed() bool {
    if app.menu_type != app.old_menu_type {
        app.old_menu_type = app.menu_type
        return true
    }
    return false
    // a more elegant, but less readable solution
    /*
    defer {
        app.old_menu_type = app.menu_type
    }
    return app.menu_type == app.old_menu_type
    */
}

fn (mut app App) scroll_up() {
    if app.scroll_offset < (app.file.len - app.tui.window_height) {
    //if app.scroll_offset < (app.file.len - 1) {
        app.scroll_offset++
        app.cursor.y--
    }
}

fn (mut app App) scroll_down() {
    if app.scroll_offset > 0 {
        app.scroll_offset--
        app.cursor.y++
    }
}

fn (mut app App) lowest_rendered_line_no() int {
    return app.scroll_offset + app.tui.window_height
}

fn (mut app App) highest_rendered_line_no() int {
    return app.scroll_offset + 1
}

fn is_navigation_key(kc tui.KeyCode) bool {
    return kc in [.up, .down, .left, .right, .page_up, .page_down, .end, .home]
}

// todo: if we move the cursor & it's outside the screen, scroll to it
fn (mut app App) handle_navigation_key(kc tui.KeyCode) {
    match kc {
        .up {
            if app.get_cursor_line_abs() > 0 {app.cursor.y--}
            if app.get_cursor_line_abs() < app.highest_rendered_line_no()-1 {
                app.scroll_down()
            }
        }
        .down {
            if app.get_cursor_line_abs() < app.file.len-1 {app.cursor.y++}
            if app.get_cursor_line_abs() > app.lowest_rendered_line_no()-1 {
                app.scroll_up()
            }
        }
        .left {
            // move left. if at end, wrap to line above
            if app.cursor.x > 1 {app.cursor.x--}
            else {
                if app.get_cursor_line_abs() > 0 {
                    app.handle_navigation_key(.up)
                    app.handle_navigation_key(.end)
                }
            }
        }
        .right {
            // move right. if at end, wrap to line below
            if app.cursor.x < app.current_line().len+1 {app.cursor.x++}
            else {
                if app.get_cursor_line_abs() < app.file.len-1 {
                    app.handle_navigation_key(.down)
                    app.handle_navigation_key(.home)
                }
            }
        }
        .end {
            app.cursor.x = app.current_line().len+1
        }
        .home {
            app.cursor.x = 1
        }
        .page_down {
            for _ in 0..app.tui.window_height {
                app.handle_navigation_key(.down)
            }
        }
        .page_up {
            for _ in 0..app.tui.window_height {
                app.handle_navigation_key(.up)
            }
        }
        else {
            app.panic("No impl for navigation key $kc")
        }
    }
}

fn (mut app App) delete_char(x int) {
    mut parts := split(app.current_line(), x)
    if x > 1 {
        parts[0] = parts[0][..parts[0].len - 1]
    } else {
        parts[1] = parts[1][1..]
    }
    app.file[app.get_cursor_line_abs()] = join([parts[0], parts[1]])
}

fn is_editing_key(kc tui.KeyCode) bool {
    return kc in [.backspace, .delete]
}

/*
mut parts := split(app.current_line(), app.cursor.x)
if app.cursor.x == 1 && app.cursor.y == 1 {
    return
}
if parts[0] != "" {
    parts[0] = parts[0][..parts[0].len - 1]
    app.file[app.get_cursor_line_abs()] = join([parts[0], parts[1]])
} else {
    app.file[app.get_cursor_line_abs()-1] = app.file[app.get_cursor_line_abs()-1] + app.current_line()
    app.file.delete(app.get_cursor_line_abs())
}
app.handle_navigation_key(.left)
*/

fn (mut app App) handle_editing_key(kc tui.KeyCode) {
    match kc {
        .backspace {
            // if we're at the start, don't delete anything
            if app.cursor.x == 1 && app.cursor.y == 1 {
                return
            }
            // if we're at the start of a line, stick this line to the end of the
            // previous one and delete
            if app.cursor.x == 1 {
                // += is fucked on array items
                app.file[app.get_cursor_line_abs() - 1] = app.file[app.get_cursor_line_abs() - 1] + app.current_line()
                moved_line_len := app.current_line().len
                app.file.delete(app.get_cursor_line_abs())
                for _ in 0..moved_line_len+1 {
                    app.handle_navigation_key(.left)
                }
            } else {
                // delete the current char
                app.delete_char(app.cursor.x)
                app.handle_navigation_key(.left)
            }
        }
        .delete {
            // todo: move stuff from backspace to a dedicated function for deleting the char at a certain pos. then keep the
            // start/end and cursor move logic here
            if app.get_cursor_line_abs()+1 >= app.file.len && app.cursor.x > app.current_line().len {
                return
            }
            if app.cursor.x > app.current_line().len {
                app.file[app.get_cursor_line_abs() + 1] = app.current_line() + app.file[app.get_cursor_line_abs() + 1]
                moved_line_len := app.current_line().len
                app.file.delete(app.get_cursor_line_abs())
                for _ in 0..moved_line_len+1 {
                    //app.handle_navigation_key(.right)
                }
            } else {
                app.delete_char(app.cursor.x+1)
            }
        }
        else {
            app.panic("No impl for editing key $kc")
        }
    }
}

fn (mut app App) current_line() string {
    return app.file[app.get_cursor_line_abs()]
}
/*
fn (mut app App) current_char() string {
    if app.cursor.x >= app.current_line().len {
        return ""
    }
    return app.current_line()[app.cursor.x].str()
}*/

fn join(parts []string) string {
    mut out := ""
    for part in parts {
        out += part
    }
    return out
}

fn split(str string, pos int) []string {
    mut start := ""
    mut end := str
    if pos != 0 {
        start = str[..pos-1]
        end = str[pos-1..]
    }
    return [start, end]
}

fn insert(str string, pos int, new string) string {
    parts := split(str, pos)
    return join([parts[0], new, parts[1]])
}

// convert a keycode to a string
fn (mut app App) key_str(kc tui.KeyCode) string {
    return match kc {
        .space {" "}
        .exclamation {"!"}
        ._1 {"1"}
        ._2 {"2"}
        ._3 {"3"}
        ._4 {"4"}
        ._5 {"5"}
        ._6 {"6"}
        ._7 {"7"}
        ._8 {"8"}
        ._9 {"9"}
        ._0 {"0"}
        .underscore {"_"}
        .single_quote{"'"}
        .double_quote{'"'}
        .question_mark{"?"}
        .tab{app.tab}
        .colon{":"}
        else {kc.str()}
    }
}

fn (mut app App) save() {
    mut data := ""
    for line in app.file {
        data += line
        data += "\n"
    }
    os.write_file(app.filename, data) or {
        app.panic(err)
    }
    app.is_saved = true
}

fn (mut app App) handle_control_event(e &tui.Event) {
    // shift: 1
    // ctrl: 2
    // ctrl-shift: 3
    // alt: 4
    // alt_shift: 5
    // ctrl-alt: 6
    // ctrl-alt-shift: 7
        
    if e.modifiers == 2 && e.code == .s {
        app.save()
        
    } else if e.modifiers == 2 && e.code == .o {
        // open

    } else if e.code == .escape || (e.modifiers == 2 && e.code == .q) { // escape or ctrl+q
        app.exit()
    } else if e.modifiers == 6 && e.code == .q {
        // force quit
        exit(0)
    } else if e.modifiers == 2 && e.code == .k {
        // test menu
        app.menu_type = .test
    }
}

fn (mut app App) exit() {
    if !app.is_saved {
        // todo: warning menu
        // todo: menu options side-by-side instead of vertically
        app.message = "Save your work! (Use ctrl+alt+q to force-quit)"
    } else {
        exit(0)
    }
}

fn is_control_event(e &tui.Event) bool {
    return e.modifiers > 1 || e.code in [
        .escape
    ]
}

fn (mut app App) process_keydown(e &tui.Event) {
    if is_navigation_key(e.code) {
        app.handle_navigation_key(e.code)
    } else if is_editing_key(e.code) {
        app.handle_editing_key(e.code)
        app.is_saved = false
    } else if is_control_event(e) {
        app.handle_control_event(e)
    } else {
        app.is_saved = false
        if e.code == .enter {
            mut line_no := app.get_cursor_line_abs()
            parts := split(app.current_line(), app.cursor.x)
            app.file[line_no] = parts[0]
            app.file.insert(line_no + 1, parts[1])
            app.handle_navigation_key(.right)
        } else {
            mut char := app.key_str(e.code)
            if e.modifiers == 1 {
                // shift
                char = char.to_upper()
            }
            
            mut line_no := app.get_cursor_line_abs()
            // insert char at the cursor
            app.file[line_no] = insert(app.current_line(), app.cursor.x, char)
            for _ in 0..char.len {
                // if it's a tab then char could be four spaces
                app.handle_navigation_key(.right)
            }
        }
    }
    // todo:
    //   -> menus n shit (kb shortcuts)
    
}

// todo: consistency w/ process_* vs handle_*

fn process_event(e &tui.Event, x voidptr) {
    mut app := &App(x)
    if e.typ == .mouse_scroll {
        // scrolling
        if e.direction == .up {
            app.scroll_up()
        } else if e.direction == .down {
            app.scroll_down()
        }
    }
    else if e.typ == .key_down {
        app.process_keydown(e)        
    } else if e.typ == .mouse_down {
        if app.event_is_for_menu(e) {
            app.handle_mouse_event(e)
        } else {
            app.cursor.x = e.x
            app.cursor.y = e.y
        }
    } else if e.typ == .mouse_drag {
        // todo: drags
        //   -> scroll bar
        //   -> text move
        //   -> tab reposition
        //   -> highlighting
    } else if e.typ == .mouse_move {
        // hovers
        app.handle_mouse_event(e)
    }
}

// get the cursor's line no in the file
fn (app App) get_cursor_line_abs() int {
    return app.cursor.y + app.scroll_offset - 1
}

fn (mut app App) set_cursor_to_line_end() {
    line_length := app.current_line().len
    //app.tui.set_window_title("Line $cursor_line_no | Length $line_length")
    // just set cursor_x to the max() ?
    // TODO: this doesn't work for tabs
    if line_length < app.cursor.x {
        app.cursor.x = line_length + 1
    }
}

fn (mut app App) debug_window_title() {
    app.tui.set_window_title("Highest: ${app.highest_rendered_line_no()} | Lowest: ${app.lowest_rendered_line_no()} | Cursor line: ${app.get_cursor_line_abs()} | Cursor pos: (${app.cursor.x}, ${app.cursor.y}) | File: ${app.filename}")
}

fn (mut app App) draw_bold(x int, y int, text string) {
    app.tui.bold()
    app.tui.draw_text(x, y, text)
    app.tui.reset()
}

// returns start pos, length
//
// copy/pasted from show_menu
fn (mut app App) get_menu_item_pos(i int) (Coord, int) {
    centre_y := app.tui.window_height / 2
    start_y := centre_y - (app.menu.items.len / 2)
    centre_x := app.tui.window_width / 2
    item_len := app.menu.items[i].text.len
    item_x := centre_x - (item_len / 2)
    item_y := start_y + i
    return {x: item_x, y: item_y}, item_len
}

fn test(i int) (Coord, int) {
    return {x: 69, y: 420}, 0
}

// show the menu @ the centre of the screen
fn (mut app App) show_menu() {

    if app.menu.conf.custom_fg_col {
        app.tui.set_color(app.menu.conf.fg_col)
        defer {
            app.tui.reset_color()
        }
    }
    if app.menu.conf.custom_bg_col {
        app.tui.set_bg_color(app.menu.conf.bg_col)
        defer {
            app.tui.reset_bg_color()
        }
    }

    centre_y := app.tui.window_height / 2
    start_y := centre_y - (app.menu.items.len / 2)
    centre_x := app.tui.window_width / 2
    mut max_width := 0
    for i, item in app.menu.items {
        item_x := centre_x - (item.text.len / 2)
        item_y := start_y + i
        if item.text.len > max_width {
            max_width = item.text.len
        }
        if item.custom_fg_col {
            app.tui.set_color(item.fg_col)
            defer {
                app.tui.set_color(app.menu.conf.fg_col)
            }
        }
        if item.custom_bg_col {
            app.tui.set_bg_color(item.bg_col)
            defer {
                app.tui.set_bg_color(app.menu.conf.bg_col)
            }
        }
        if item.bold {
            app.draw_bold(item_x, item_y, item.text)
        } else {
            app.tui.draw_text(item_x, item_y, item.text)
        }
    }

    min_x := centre_x - (max_width / 2)
    max_x := centre_x + (max_width / 2)
    max_y := centre_y + (app.menu.items.len / 2)
    padding := 2

    final_min_x := min_x - padding
    final_min_y := start_y - (padding * if app.menu.title != "" {2} else {1})
    final_max_x := max_x + padding
    final_max_y := max_y + padding
    
    if app.menu.title != "" {
        app.draw_bold(min_x, start_y - padding, app.menu.title)
    }

    if app.menu.conf.border {
        app.tui.set_bg_color(app.menu.conf.border_col)
        app.tui.draw_empty_rect(final_min_x, final_min_y, final_max_x, final_max_y)
        //app.message = app.menu.title
    }

    // array would be more efficient
    app.menu_data.minimums.x = final_min_x
    app.menu_data.minimums.y = final_min_y
    app.menu_data.maximums.x = final_max_x
    app.menu_data.maximums.y = final_max_y
    
}

fn (mut app App) event_is_for_menu(e &tui.Event) bool {
    assert e.typ in [.mouse_move, .mouse_down]
    return (
        app.menu_data.minimums.x <= e.x &&
        e.x <= app.menu_data.maximums.x && 
        app.menu_data.minimums.y <= e.y && 
        e.y <= app.menu_data.maximums.y
    )
}

// first, check which item it's for
// then, fire callback based on whether it's a mouse move or a mouse down
fn (mut app App) handle_mouse_event(e &tui.Event) {
    for i, item in app.menu.items {
        pos, len := app.get_menu_item_pos(i)
        if e.y == pos.y && e.x >= pos.x && e.x <= (pos.x + len) {
            if e.typ == .mouse_move {
                item.on_hover()
            } else if e.typ == .mouse_down {
                item.on_click()
            }
            break
        }
    }
}

fn (mut app App) process_menu() {
    hover_cb := fn(mut app &App, mut self &MenuItem) {
        // make all items non-highlighted (un-highlight the previous one)
        for mut item in app.menu.items {
            item.custom_fg_col = false
        }
        // now highlight this one
        self.custom_fg_col = true
    }

    match app.menu_type {
        .nothing {}
        .test {
            app.menu = {
                title: "Test menu"
                items: [
                    MenuItem{text: "1", bold: true, fg_col: {r: 255}, on_hover: hover_cb},
                    MenuItem{text: "2", fg_col: {g: 255}, on_hover: hover_cb},
                    MenuItem{text: "reeeeeeeeeeeee", fg_col: {b: 255}, on_hover: hover_cb}
                ]
                conf: {
                    border: true
                    border_col: {r: 255, g: 255, b: 0}
                }
            }
        }
        else {
            app.panic("No impl for menu ${app.menu}")
        }
    }
    if app.menu_type != .nothing {
        app.show_menu()
    }

}

fn process_frame(x voidptr) {
    mut app := &App(x)

    // load file
    if app.file == []{} {
        app.is_saved = true
        app.file = os.read_lines(app.filename) or {
            app.panic(err)
            app.file = ['']
            return
        }
    }

    app.tui.clear()
    //app.tui.set_bg_color(r: 69, g: 0, b: 69)
    //app.tui.set_window_title("size: ${app.tui.window_width}x${app.tui.window_height} line: ${app.scroll_offset}")
    app.tui.set_window_title(app.filename + if app.is_saved {""} else {" *"})
    file_line_count := app.file.len
    
    // line in the _file_ which the cursor is on
    for i in 0..app.tui.window_height {
        this_line_no := app.scroll_offset + i
        if this_line_no >= file_line_count {
            break
        }
        mut this_line := app.file[this_line_no]
        if this_line.len > app.tui.window_width {
            this_line = this_line[..app.tui.window_width]
        }

        //app.debug_window_title()

        //app.tui.draw_text(0, i+1, "${this_line_no + 1}   $this_line")
        app.tui.draw_text(0, i+1, "$this_line")

    }

    app.draw_bold(app.tui.window_width - app.message.len - 2, 1, app.message)

    app.process_menu()

    app.set_cursor_to_line_end()

    // cursor gets moved around by painting n stuff (which is annoying - should termui functions replace the cursor after
    // doing their stuff??) Anyway, this means that if we want to manually reposition the cursor we have to do it AFTER
    // painting etc
    app.tui.set_cursor_position(app.cursor.x, app.cursor.y)

    // if we're out of the screen, hide cursor
    if app.cursor.y <= 0 || app.cursor.y > app.tui.window_height {
        term.hide_cursor()
    } else {
        term.show_cursor()
    }

    app.tui.reset()
    app.tui.flush()
}

fn (mut app App) init(filename string) {
    app.filename = filename
    app.tui = tui.init(
        user_data: app,
        event_fn: process_event,
        frame_fn: process_frame,
        capture_events: true
    )

    app.col = ColourStack {
        ctx: app.tui
    }
}

fn main() {
    mut app := &App{}
    app.init("../main.v.bak")
    app.tui.run()?
}