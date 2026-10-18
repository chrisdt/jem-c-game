extends Node2D

# Lightweight, active-district-only atmosphere. No particles accumulate while
# a different district/planet is visible.
var world := 1
var pools: Array = []
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	if world == 1:
		for i in 22:
			var point := Vector2(fposmod(i*137.3+sin(time*0.35+i)*25-time*8,2000),fposmod(i*91.7+time*17,1400))
			draw_circle(point,1.3,Color(0.88,0.96,1.0,0.28))
	else:
		for pool in pools:
			for i in 9:
				var phase := fposmod(time*0.25+i*0.113,1)
				var point := Vector2(pool.x+sin(i*3.2)*pool.z*0.7,pool.y+cos(i*2.7)*pool.w*0.55-phase*70)*Vector2(2000.0/1500,1400.0/1050)
				draw_circle(point,1.7,Color(1.0,0.65,0.2,sin(phase*PI)*0.65))
