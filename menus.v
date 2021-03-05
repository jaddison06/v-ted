module main

import term.ui as tui

// An item in a Menu
struct MenuItem {
pub mut:
    text string
    custom_fg_col bool
    fg_col tui.Color
    custom_bg_col bool
    bg_col tui.Color
    bold bool
    on_hover fn(mut app &App, mut self &MenuItem)
    on_click fn(mut app &App, mut self &MenuItem)
}

// config for a Menu
struct MenuConfig {
    border bool = true
    border_col tui.Color = {r: 255, g: 255, b: 255}

    custom_fg_col bool
    fg_col tui.Color
    custom_bg_col bool
    bg_col tui.Color
}

// MUTABLE!!!!!!!!!!!
//
// an actual Menu to render
struct Menu {
pub mut:
    title string
    items []MenuItem
    conf MenuConfig
}

// sum of the runtime data for different menus
type MenuDataType = int

// data that the current menu needs
struct MenuData {
mut:
    minimums Coord
    maximums Coord

    data MenuDataType
}
