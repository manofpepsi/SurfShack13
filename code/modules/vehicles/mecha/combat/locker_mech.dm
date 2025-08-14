/obj/vehicle/sealed/mecha/locker_mech
	desc = "A locker with stolen wires, struts, electronics and airlock servos crudely assembled into something that resembles the functions of a mech."
	name = "\improper Locker Mech"
	ui_theme = "neutral"
	// it takes an awfully long locker to make long mech
	icon = 'icons/mob/rideables/long_mechs.dmi'
	icon_state = "lockermech"
	base_icon_state = "lockermech"
	movedelay = 3 // im going to touch you
	max_integrity = 100 //its a closet
	force = 10
	armor_type = /datum/armor/locker_mech
	max_temperature = 20000
  wreckage = /obj/structure/closet
	destruction_sleep_duration = 40
	exit_delay = 40
	accesses = list(ACCESS_MAINT_TUNNELS)
	mecha_flags = IS_ENCLOSED | HAS_LIGHTS
	mech_type = EXOSUIT_MODULE_LOCKER_MECH
	max_equip_by_category = list(
		MECHA_L_ARM = 1,
		MECHA_R_ARM = 0,
		MECHA_UTILITY = 0,
		MECHA_POWER = 0,
		MECHA_ARMOR = 0,
	)
	equip_by_category = list(
		MECHA_L_ARM = /obj/item/mecha_parts/mecha_equipment/tension_belt,
		MECHA_R_ARM = null,
		MECHA_UTILITY = list(),
		MECHA_POWER = list(),
		MECHA_ARMOR = list(),
	)

/datum/armor/locker_mech
	melee = 20
	bullet = 10
	laser = 10
	energy = 0
	bomb = 10
	bio = 0
	fire = 70
	acid = 60

/obj/vehicle/sealed/mecha/locker_mech/Initialize(mapload, built_manually)
	. = ..()
	AddElementTrait(TRAIT_WADDLING, REF(src), /datum/element/waddling)

/obj/item/mecha_parts/mecha_equipment/tension_belt
	name = "Tension Belt"
	desc = "A makeshift support belt made of fabric scraps and rods thats usually jammed into mech to keep it upright. pulling on it causes the mech to violently shutter back and forward."
	icon_state = "tension_belt"
	equip_cooldown = 4 SECONDS
	energy_drain = 0.01 * STANDARD_CELL_CHARGE
	range = MECHA_MELEE
	toolspeed = 0.3
	harmful = TRUE
	mech_flags = EXOSUIT_MODULE_LOCKER_MECH

/obj/effect/landingzone_locker_mech
	icon = 'icons/obj/supplypods_32x32.dmi'
	icon_state = "LZ"
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	anchored = TRUE

/obj/item/mecha_parts/mecha_equipment/tension_belt/action(mob/living/source, atom/target, list/modifiers)
	var/target_loc = get_turf(target)
	if(target_loc == chassis.loc)
		return

	var/obj/effect/landingzone_locker_mech/LZ = new(target_loc)
	source.visible_message(span_alertwarning("[chassis] starts rocking back and forward, It looks like its going to fall over!"),\
		span_warning("you start rocking [chassis] forwards and backwards, trying to tip it over"))
	playsound(chassis, 'sound/effects/clang.ogg', 50)
	if(!do_after(source, 4 SECONDS, target_loc, extra_checks = CALLBACK(src, PROC_REF(check_mech), chassis.dir, chassis.loc)))
		qdel(LZ)
		return
	if(chassis.fall_and_crush(target_loc, chassis.force, 0, 0, 3 SECONDS, chassis.dir, BRUTE, MELEE, 90) & SUCCESSFULLY_FELL_OVER)
		chassis.pixel_y = -12
		// fall_and_crush proc doesnt knock down target (because the attack is so weak) so we handle that.
		for(var/mob/living/L in target_loc)
			if(L == source)
				continue
			L.Knockdown(3 SECONDS, TRUE)
		chassis.take_damage(chassis.force/2, BRUTE, MELEE) //damage mech
		source.apply_damage(chassis.force/2, BRUTE) //damage passenger
		source.Paralyze(2.2 SECONDS) //stop "mech" from moving while on ground
	qdel(LZ)
	return ..()

/obj/item/mecha_parts/mecha_equipment/tension_belt/proc/check_mech(dir_started, loc_started)
	if(dir_started == chassis.dir && loc_started == chassis.loc)
		return TRUE
	//else
	return FALSE

/obj/vehicle/sealed/mecha/locker_mech/post_tilt()
	addtimer(CALLBACK(src, PROC_REF(untilt)), 20)
	return ..()

/obj/vehicle/sealed/mecha/locker_mech/proc/untilt()
	var/matrix/to_turn = turn(transform, -90)
	animate(src, transform = to_turn, 0.2 SECONDS)
	pixel_y = 0
