module main

// main is vcoder's entrypoint
fn main() {
	mut app := &App{}
	app.init("../main.v.bak")

	app.menu_stack.show_centered({
		title: RichText {
			text: "Centered",
			bold: true
		},
		items: [
			MenuItem {
				title: RichText {
					text: "Normal text 1"
				}
			},
			MenuItem {
				title: "Normal text 2"
			},
			MenuItem {
				title: RichText {
					text: "Spicy",
					bold: true,
					col: {
						custom_bg: true,
						bg: {r: 255,b:255},
						custom_fg: true,
						fg: {g: 255}
					}
				}
			},
		],
		border_col: {r: 255, g: 255}
	})

	app.menu_stack.show_fullscreen({
		title: RichText {
			text: "Fullscreen",
			bold: true
		},
		border_col: {r: 255, g: 0, b: 0},
		items: [
			MenuItem {
				title: "Item 1"
			},
			MenuItem {
				title: "Item 2"
			}
		]
	})

	app.start()?
}