package main

import "core:fmt"
import rl "vendor:raylib"

CARD_WIDTH :: 150

CARD_HEIGHT :: 200

water_levels := [Seed]int {
	.None   = 0,
	.Potato = 2,
	.Tomato = 4,
}

seed_rewards := [Seed][dynamic]int {
	.None   = [dynamic]int{},
	.Tomato = [dynamic]int{1, 2, 3},
	.Potato = [dynamic]int{1, 0, 4, 0, 5},
}


Upgrade :: enum {
	Sprinkler,
	Pigs,
	Chicken,
	Barn,
}

WateringLevel :: struct {
	level:  int,
	reward: int,
}

Seed :: enum {
	None,
	Potato,
	Tomato,
}

SeedCard :: struct {
	seed:         Seed,
	price:        int,
	water_levels: int,
}

ToolNone :: struct {}

WateringCan :: struct {
	power: int,
}

Scyte :: struct {}

WateringScyte :: struct {
	power: int,
}

Tool :: union {
	ToolNone,
	WateringCan,
	WateringScyte,
	Scyte,
}

PlayerHand :: struct {
	using box: Box,
	tool:      Tool,
}

Box :: struct {
	rect: rl.Rectangle,
}

Field :: struct {
	using box:   Box,
	card:        SeedCard,
	water_level: int,
}

Player :: struct {
	money:    int,
	upgrades: [dynamic]Upgrade,
	fields:   [dynamic]Field,
	seeds:    [dynamic]SeedCard,
	tools:    [15]Tool,
	hand:     [5]PlayerHand,
}

init_player :: proc() -> ^Player {
	player := new(Player)

	player.money = 0
	player.upgrades = make([dynamic]Upgrade)
	player.fields = make([dynamic]Field, 3)
	player.seeds = make([dynamic]SeedCard, 0)

	gap := 20

	w := len(player.hand) * gap + len(player.hand) * CARD_WIDTH

	middle := f32(w) * 0.5

	center := f32(rl.GetScreenWidth()) * 0.5

	for &card, i in player.hand {
		x := i32(i * CARD_WIDTH + ((i + 1) * gap) + int(center) - int(middle))

		card.rect = rl.Rectangle {
			x      = f32(x),
			y      = f32(rl.GetScreenHeight() - CARD_HEIGHT - 20),
			width  = CARD_WIDTH,
			height = CARD_HEIGHT,
		}
	}

	wfl := len(player.fields) * gap + len(player.fields) * CARD_WIDTH

	for &field, i in player.fields {
		x := f32(i * CARD_WIDTH + ((i + 1) * gap) + int(center) - int(f32(wfl) * 0.5))
		y := f32(f32(rl.GetScreenHeight()) * 0.5 - CARD_HEIGHT * 0.5)

		field.rect = rl.Rectangle {
			x      = x,
			y      = y,
			width  = CARD_WIDTH,
			height = CARD_HEIGHT,
		}

	}

	return player
}

draw_card :: proc(rect: rl.Rectangle, texture: rl.Texture2D) {
	x := i32(rect.x)
	y := i32(rect.y)


	rl.DrawTexture(texture, x, y, rl.WHITE)
}

debug_rect :: proc(rect: rl.Rectangle) {
	rl.DrawRectangleLines(i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height), rl.RED)
}

main :: proc() {

	rl.InitWindow(1200, 800, "Ogwring season")

	rl.SetTargetFPS(60)

	player := init_player()

	wc := rl.LoadTexture("watering_can.png")

	//fmt.printf("%#v\n", player)

	// state

	dragging := false
	dragging_target: ^PlayerHand = nil


	//-----------


	for !rl.WindowShouldClose() {


		if rl.IsMouseButtonReleased(.LEFT) {
			collisioned := false

			if dragging {
				mpr := rl.Rectangle {
					x      = f32(rl.GetMousePosition().x - CARD_WIDTH * 0.5),
					y      = f32(rl.GetMousePosition().y - CARD_HEIGHT * 0.5),
					width  = CARD_WIDTH,
					height = CARD_HEIGHT,
				}


				for &field in player.fields {
					if collisioned {break}
					if rl.CheckCollisionRecs(mpr, field.rect) {
						field.water_level += 1
						dragging_target.tool = ToolNone{}
						collisioned = true
					}
				}
			}

			dragging = false
			dragging_target = nil
		}


		if rl.IsMouseButtonDown(.LEFT) {
			for &card in player.hand {
				switch card.tool {
				// TODO: idk if using unions for this is a good choice
				case WateringCan{}:
					if rl.CheckCollisionPointRec(rl.GetMousePosition(), card.rect) {
						if dragging {continue}
						dragging = true
						dragging_target = &card
					}
				}

			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGREEN)

		for &field in player.fields {
			rl.DrawRectangleRec(field.rect, rl.DARKBROWN)
			rl.DrawText(
				fmt.ctprintf("%d", field.water_level),
				i32(field.rect.x),
				i32(field.rect.y),
				20,
				rl.WHITE,
			)
		}


		for i in 0 ..< len(player.hand) {

			card := &player.hand[i]

			switch card.tool {
			case WateringCan{}:
				if card != dragging_target {
					draw_card(card.rect, wc)
				}
			}

		}

		for i in 0 ..< len(player.hand) {
			card := &player.hand[i]
			if card == dragging_target {
				mpr := rl.Rectangle {
					x      = f32(rl.GetMousePosition().x - CARD_WIDTH * 0.5),
					y      = f32(rl.GetMousePosition().y - CARD_HEIGHT * 0.5),
					width  = f32(CARD_WIDTH),
					height = f32(CARD_HEIGHT),
				}

				draw_card(mpr, wc)
			}
		}


		rl.EndDrawing()
	}

	rl.CloseWindow()
}

main2 :: proc() {
	player := init_player()

	player.fields[0].card = SeedCard {
		seed         = .Potato,
		price        = 2,
		water_levels = 5,
	}
	player.fields[0].water_level = 0


	for &field in player.fields {
		if field.card.seed != .None {
			rewards := seed_rewards[field.card.seed]

			field.water_level += 3

			assert(field.water_level < len(rewards))

			reward := rewards[field.water_level - 1]

			fmt.printf("reward is %d\n", reward)
		}
	}


}
