#define DEFAULT_SEED "glowshroom"
#define VINE_GROWTH_STAGES 5

/proc/spacevine_infestation()
	spawn() //to stop the secrets panel hanging
		var/list/turf/simulated/floor/turfs = list() //list of all the empty floor turfs in the hallway areas
		for(var/areapath in typesof(/area/hallway))
			var/area/A = locate(areapath)
			for(var/area/B in A.related)
				for(var/turf/simulated/floor/F in B.contents)
					if(!F.contents.len)
						turfs += F

		if(turfs.len) //Pick a turf to spawn at if we can
			var/turf/simulated/floor/T = pick(turfs)
			var/datum/seed/seed = plant_controller.create_random_seed(1)
			seed.set_trait(TRAIT_SPREAD,2)            // So it will function properly as vines.
			seed.set_trait(TRAIT_POTENCY,rand(40,50)) // Guarantee a wide spread and powerful effects.
			new /obj/effect/plant(T,seed)
			message_admins("<span class='notice'>Event: Spacevines spawned at [T.loc] ([T.x],[T.y],[T.z])</span>")

/obj/effect/dead_plant
	anchored = 1
	opacity = 0
	density = 0
	color = DEAD_PLANT_COLOUR

/obj/effect/dead_plant/attack_hand()
	del(src)

/obj/effect/dead_plant/attackby()
	..()
	for(var/obj/effect/plant/neighbor in view(1,src))
		neighbor.wake_up()
	del(src)

/obj/effect/plant
	name = "plant"
	anchored = 1
	opacity = 0
	density = 0
	icon = 'icons/obj/hydroponics_growing.dmi'
	icon_state = "bush4-1"
	layer = 3
	pass_flags = PASSTABLE

	var/health = 10
	var/max_health = 100
	var/growth_threshold = 0
	var/growth_type = 0
	var/max_growth = 0

	var/list/children = list()
	var/obj/effect/plant/parent
	var/datum/seed/seed
	var/floor = 0
	var/spread_chance = 40
	var/spread_distance = 3
	var/spread_into_adjacent = 60
	var/evolve_chance = 2
	var/last_tick = 0
	var/obj/machinery/portable_atmospherics/hydroponics/soil/invisible/plant

/obj/effect/plant/single
	spread_chance = 0

/obj/effect/plant/New(var/newloc, var/datum/seed/newseed)
	..()

	if(!plant_controller)
		sleep(250) // ugly hack, should mean roundstart plants are fine.
	if(!plant_controller)
		world << "<span class='danger'>Plant controller does not exist and [src] requires it. Aborting.</span>"
		del(src)
		return

	if(!istype(newseed))
		newseed = plant_controller.seeds[DEFAULT_SEED]
	seed = newseed
	if(!seed)
		del(src)
		return

	name = seed.display_name
	max_health = round(seed.get_trait(TRAIT_ENDURANCE)/2)
	if(seed.get_trait(TRAIT_SPREAD)==2)
		max_growth = VINE_GROWTH_STAGES
		growth_threshold = max_health/VINE_GROWTH_STAGES
		icon = 'icons/obj/hydroponics_vines.dmi'
		growth_type = 2 // Vines by default.
		if(seed.get_trait(TRAIT_CARNIVOROUS) == 2)
			growth_type = 1 // WOOOORMS.
		else if(!(seed.seed_noun in list("seeds","pits")))
			if(seed.seed_noun == "nodes")
				growth_type = 3 // Biomass
			else
				growth_type = 4 // Mold
	else
		max_growth = seed.growth_stages
		growth_threshold = max_health/seed.growth_stages

	if(max_growth > 2 && prob(50))
		max_growth-- //Ensure some variation in final sprite, makes the carpet of crap look less wonky.

	spread_into_adjacent = round(seed.get_trait(TRAIT_POTENCY)/2)
	spread_distance = ((growth_type>0) ? round(spread_into_adjacent/2) : round(spread_into_adjacent/15))
	spread_chance = round(spread_into_adjacent/2)

	set_dir(calc_dir())
	update_icon()
	wake_up()
	last_tick = world.timeofday

/obj/effect/plant/update_icon()

	refresh_icon()
	if(growth_type == 0 && !floor)
		src.transform = null
		var/matrix/M = matrix()
		M.Translate(0,-(rand(12,14))) // should make the plant flush against the wall it's meant to be growing from.
		switch(dir)
			if(WEST)
				M.Turn(90)
			if(NORTH)
				M.Turn(180)
			if(EAST)
				M.Turn(270)
		src.transform = M
	var/icon_colour = seed.get_trait(TRAIT_PLANT_COLOUR)
	if(icon_colour)
		color = icon_colour
	// Apply colour and light from seed datum.
	if(seed.get_trait(TRAIT_BIOLUM))
		SetLuminosity(1+round(seed.get_trait(TRAIT_POTENCY)/20))
		if(seed.get_trait(TRAIT_BIOLUM_COLOUR))
			l_color = seed.get_trait(TRAIT_BIOLUM_COLOUR)
		else
			l_color = null
		return
	else
		SetLuminosity(0)

/obj/effect/plant/proc/refresh_icon()
	var/growth = min(max_growth,max(1,round(health/growth_threshold)))
	if(growth_type > 0)
		switch(growth_type)
			if(1)
				icon_state = "worms"
			if(2)
				icon_state = "vines-[growth]"
			if(3)
				icon_state = "mass-[growth]"
			if(4)
				icon_state = "mold-[growth]"
	else
		icon_state = "[seed.get_trait(TRAIT_PLANT_ICON)]-[growth]"

	layer = (growth == max_growth ? 4 : 3)

/obj/effect/plant/Del()
	if(children && children.len)
		die_off(null,1)
	..()

/obj/effect/plant/proc/get_dist_to_parent(var/current_count)
	if(!parent)
		return current_count
	current_count++
	return parent.get_dist_to_parent(current_count)

/obj/effect/plant/proc/get_root()
	if(parent)
		return parent.get_root()
	else
		return src

/obj/effect/plant/proc/calc_dir(turf/location = loc)
	set background = 1
	var/direction = 16

	for(var/wallDir in cardinal)
		var/turf/newTurf = get_step(location,wallDir)
		if(newTurf.density)
			direction |= wallDir

	for(var/obj/effect/plant/shroom in location)
		if(shroom == src)
			continue
		if(shroom.floor) //special
			direction &= ~16
		else
			direction &= ~shroom.dir

	var/list/dirList = list()

	for(var/i=1,i<=16,i <<= 1)
		if(direction & i)
			dirList += i

	if(dirList.len)
		var/newDir = pick(dirList)
		if(newDir == 16)
			floor = 1
			newDir = 1
		return newDir

	floor = 1
	return 1

/obj/effect/plant/attackby(var/obj/item/weapon/W, var/mob/user)

	if(istype(W, /obj/item/weapon/wirecutters) || istype(W, /obj/item/weapon/scalpel))
		if(!seed)
			user << "There is nothing to take a sample from in \the [src]."
			return
		// Create a sample.
		seed.harvest(user,0,1)
		health -= (rand(3,5)*10)
	else
		..()
		if(W.force)
			health -= W.force
	check_health()

/obj/effect/plant/ex_act(severity)
	switch(severity)
		if(1.0)
			die_off()
			return
		if(2.0)
			if (prob(50))
				die_off()
				return
		if(3.0)
			if (prob(5))
				die_off()
				return
		else
	return

/obj/effect/plant/proc/check_health()
	if(health <= 0)
		die_off(1)

/obj/effect/plant/proc/is_mature()
	return (health < (max_health/3))