/turf/simulated/ocean
	name = "ocean floor"
	desc = "Rough rocky seabed"
	icon = 'icons/turf/ocean.dmi'
	icon_state = "rocky"
	density = FALSE
	opacity = FALSE
	flooded = TRUE

	light_outer_range = 3
	light_max_bright = 0.3
	light_color = COLOR_OCEAN_DAY

/turf/simulated/ocean/is_plating()
	return 1

/turf/simulated/ocean/sand
	icon_state = "sand0"
	desc = "Silty seabed"
	color = COLOR_SAND

/turf/simulated/ocean/sand/New()
	. = ..()
	icon_state = "sand[rand(0, 7)]"

/turf/simulated/ocean/abyss
	name = "abyssal silt"
	desc = "Unfathomably silty, its practically quicksand"
	icon_state = "mud_light"

/turf/simulated/ocean/open
	name = "open ocean"
	desc = ""
	icon_state = "still"
