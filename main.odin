package main

import "core:fmt"
import rl "vendor:raylib"

CARD_WIDTH :: 150

CARD_HEIGHT :: 200

Upgrade :: enum {
	Sprinkler,
	Pigs,
	Chicken,
	Barn,
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

Box :: struct {
	rect: rl.Rectangle,
}

Field :: struct {
	using box:   Box,
	seed:        SeedCard,
	water_level: int,
}

Player :: struct {
	money:    int,
	upgrades: [dynamic]Upgrade,
	fields:   [dynamic]Field,
	seeds:    [dynamic]SeedCard,
}

init_player :: proc() -> ^Player {
	player := new(Player)

	player.money = 0
	player.upgrades = make([dynamic]Upgrade)
	player.fields = make([dynamic]Field, 4)
	player.seeds = make([dynamic]SeedCard, 15)

	gap := 20

	w := len(player.fields) * gap + len(player.fields) * CARD_WIDTH

	middle := f32(w) * 0.5

	center := f32(rl.GetScreenWidth()) * 0.5

	for &field, i in player.fields {
		x := i32(i * CARD_WIDTH + ((i + 1) * gap) + int(center) - int(middle))

		field.rect = rl.Rectangle {
			x      = f32(x),
			y      = f32(rl.GetScreenHeight() - CARD_HEIGHT - 20),
			width  = CARD_WIDTH,
			height = CARD_HEIGHT,
		}
	}

	return player
}

main :: proc() {

	rl.InitWindow(1200, 800, "Ogwring season")

	rl.SetTargetFPS(60)

	player := init_player()

	// state

	dragging := false
	dragging_target: ^Field = nil


	//-----------


	for !rl.WindowShouldClose() {

		if rl.IsMouseButtonDown(.LEFT) {

			for &field in player.fields {
				if dragging {continue}
				if rl.CheckCollisionPointRec(rl.GetMousePosition(), field.rect) {
					dragging = true
					dragging_target = &field
					break
				}
			}
		} else {
			dragging = false
			dragging_target = nil
		}


		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		gap := 20

		w := len(player.fields) * gap + len(player.fields) * CARD_WIDTH

		middle := f32(w) * 0.5

		for &field, i in player.fields {
			if &field != dragging_target {
				rl.DrawRectangleRec(field.rect, rl.DARKBROWN)
			}
		}

		for &field in player.fields {

			if dragging && &field == dragging_target {
				mpr := rl.Rectangle {
					x      = f32(rl.GetMouseX()) - CARD_WIDTH * 0.5,
					y      = f32(rl.GetMouseY()) - CARD_HEIGHT * 0.5,
					width  = CARD_WIDTH,
					height = CARD_HEIGHT,
				}

				rl.DrawRectangleRec(mpr, rl.BLUE)
				continue
			}
		}


		rl.EndDrawing()
	}

	rl.CloseWindow()
}
