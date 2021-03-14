module main

fn main() {
	mut app := &App{}
	app.init("../main.v.bak")

	app.menu_stack.show_centered({
		title: RichText{
			text: "Test menu",
			bold: true
		},
		lines: [
			MenuItem{
				title: RichText{
					text: "Normal text 1"
				}
			},
			MenuItem{
				title: RichText{
					text: "Normal text 2"
				}
			},
			MenuItem{
				title: RichText{
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

	app.start()?
}