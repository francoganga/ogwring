package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"
import "core:strings"
import "core:path/filepath"

CARD_WIDTH :: 150

CARD_HEIGHT :: 200


load_directory_of_textures :: proc(pattern: string) -> map[string]rl.Texture2D {
    textures := make(map[string]rl.Texture2D)

    matches, _ := filepath.glob(pattern)

    for match in matches {
        index := strings.last_index_any(match, `/\`)
        path := strings.clone(filepath.stem(match[index+1:]))
        fmt.println(path)
        textures[path] = rl.LoadTexture(fmt.ctprintf("%s", match))
    }

    for match in matches {
        delete(match)
    }

    delete(matches)

    return textures
}



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

tool_textures := [Tool]string{
    .None = "watering_can",
    .WateringCan = "watering_can",
    .WateringScyte = "watering_can",
    .Scyte =  "watering_can"
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

Tool :: enum {
	None,
	WateringCan,
	WateringScyte,
	Scyte,
}

PlayerHand :: struct {
	using box: Box,
	tool:      Tool,
    texture:   rl.Texture2D,
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
    dragging_target: ^PlayerHand,
    dragging: bool,
}

random_hand :: proc(textures: map[string]rl.Texture2D) -> [5]PlayerHand {
    hand := [5]PlayerHand{}

    seed := u64(1337)
    r := rand.create(seed)
    context.random_generator = rand.default_random_generator(&r)
    for &card in hand {
        tool: Tool = .WateringCan
        card.tool = tool
        texture_name := tool_textures[tool]
        card.texture = textures[texture_name]
    }

    init_hand(hand)

    return hand
}

init_hand :: proc(hand: [5]PlayerHand) {

    gap := 20

	w := len(hand) * gap + len(hand) * CARD_WIDTH

	middle := f32(w) * 0.5

	center := f32(rl.GetScreenWidth()) * 0.5

	for &card, i in hand {
		x := i32(i * CARD_WIDTH + ((i + 1) * gap) + int(center) - int(middle))

		card.rect = rl.Rectangle {
			x      = f32(x),
			y      = f32(rl.GetScreenHeight() - CARD_HEIGHT - 20),
			width  = CARD_WIDTH,
			height = CARD_HEIGHT,
		}
	}

}

init_player :: proc(textures: map[string]rl.Texture2D) -> ^Player {
	player := new(Player)

	player.money = 0
	player.upgrades = make([dynamic]Upgrade)
	player.fields = make([dynamic]Field, 3)
	player.seeds = make([dynamic]SeedCard, 0)

    init_hand(player.hand)

    gap := 20

    center := f32(rl.GetScreenWidth()) * 0.5

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

    player.hand = random_hand(textures)


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

draw_fields :: proc(player: ^Player) {

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
}

draw_hand :: proc(player: ^Player) {

    for i in 0 ..< len(player.hand) {
        card := &player.hand[i]
        switch card.tool {
            case .None:
            case .WateringCan, .Scyte, .WateringScyte:
            if card != player.dragging_target {
                draw_card(card.rect, card.texture)
            }
        }
    }

    for i in 0 ..< len(player.hand) {
        card := &player.hand[i]
        if card == player.dragging_target {
            mpr := rl.Rectangle {
                x      = f32(rl.GetMousePosition().x - CARD_WIDTH * 0.5),
                y      = f32(rl.GetMousePosition().y - CARD_HEIGHT * 0.5),
                width  = f32(CARD_WIDTH),
                height = f32(CARD_HEIGHT),
            }

            draw_card(mpr, card.texture)
        }
    }
}


main :: proc() {

	rl.InitWindow(1200, 800, "Ogwring season")

	rl.SetTargetFPS(60)

    textures := load_directory_of_textures("assets/*.png")

	player := init_player(textures)
    fmt.printf("%#v\n", player)

	for !rl.WindowShouldClose() {

		if rl.IsMouseButtonReleased(.LEFT) {

            fields: [dynamic]^Field
            collision_recs: [dynamic]rl.Rectangle

			if player.dragging {
				mpr := rl.Rectangle {
					x      = f32(rl.GetMousePosition().x - CARD_WIDTH * 0.5),
					y      = f32(rl.GetMousePosition().y - CARD_HEIGHT * 0.5),
					width  = CARD_WIDTH,
					height = CARD_HEIGHT,
				}


				for &field in player.fields {
					if rl.CheckCollisionRecs(mpr, field.rect) {
                        append(&fields, &field)
                        cr := rl.GetCollisionRec(mpr, field.rect)
                        append(&collision_recs, cr)
					}
				}
			}

            if len(fields) == 1 {
                fields[0].water_level += 1
                player.dragging_target.tool = .None
            }

            if len(fields) > 1 {
                field: ^Field
                cr := rl.Rectangle{}
                acr := f32(0)

                for i in 0..<len(fields) {
                    area := collision_recs[i].width * collision_recs[i].height

                    if area > acr {
                        acr = area
                        field = fields[i]
                        cr = collision_recs[i]
                    }
                }

                assert(field != nil)

                field.water_level += 1
                player.dragging_target.tool = .None
            }

			player.dragging = false
			player.dragging_target = nil
		}


		if rl.IsMouseButtonDown(.LEFT) {
			for &card in player.hand {
                #partial switch card.tool {
				case .WateringCan:
					if rl.CheckCollisionPointRec(rl.GetMousePosition(), card.rect) {
						if player.dragging {continue}
						player.dragging = true
						player.dragging_target = &card
					}
				}

			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGREEN)


        draw_fields(player)

        draw_hand(player)



		rl.EndDrawing()
	}

	rl.CloseWindow()
}
