// /program/ files are executable programs that do things.
/datum/computer_file/program
	filetype = "PRG"
	filename = "UnknownProgram"				// File name.
	var/required_access = null				// List of required accesses to *run* the program.
	var/datum/nano_module/NM = null			// If the program uses NanoModule, put it here and it will be automagically opened. Otherwise implement ui_interact.
	var/nanomodule_path = null				// Path to nanomodule, make sure to set this if implementing new program.
	var/running = 0							// Set to 1 when the program is run and back to 0 when it's stopped.
	var/atom/movable/computer = null		// Device that runs this program.
	var/filedesc = "Unknown Program"		// User-friendly name of this program.
	var/program_icon_state = null			// Overlay for this program, selected by computer
	var/keyboard_icon_state = null			// Program-specific keboard icon state
	var/requires_ntnet = 0					// Set to 1 for program to require nonstop NTNet connection to run. If NTNet connection is lost program crashes.
	var/requires_ntnet_feature = 0			// Optional, if above is set to 1 checks for specific function of NTNet (currently NTNET_SOFTWAREDOWNLOAD, NTNET_PEERTOPEER, NTNET_SYSTEMCONTROL and NTNET_COMMUNICATION)
	var/ntnet_status = 1					// NTNet status, updated every tick by computer running this program. Don't use this for checks if NTNet works, computers do that. Use this for calculations, etc.
	var/usage_flags = PROGRAM_ALL			// Bitflags (PROGRAM_CONSOLE, PROGRAM_LAPTOP, PROGRAM_TABLET combination) or PROGRAM_ALL

/datum/computer_file/program/New(var/atom/movable/comp = null)
	..()
	if(comp)
		computer = comp

/datum/computer_file/program/clone()
	var/datum/computer_file/program/temp = ..()
	temp.required_access = required_access
	temp.nanomodule_path = nanomodule_path
	temp.filedesc = filedesc
	temp.program_icon_state = program_icon_state
	temp.requires_ntnet = requires_ntnet
	temp.requires_ntnet_feature = requires_ntnet_feature
	temp.usage_flags = usage_flags
	return temp

/datum/computer_file/program/proc/is_supported_by_hardware(var/hardware_flag = 0, var/loud = 0, var/mob/user = null)
	if(!(hardware_flag & usage_flags))
		if(loud && computer && user)
			user << "<span class='danger'>\The [computer] flashes an \"Hardware Error - Incompatible software\" warning.</span>"
		return 0
	return 1

// Check if the user can run program. Only humans can operate computer. Automatically called in run_program()
// User has to wear their ID or have it inhand for ID Scan to work.
/datum/computer_file/program/proc/can_run(var/mob/living/user, var/loud = 0)
	if(!required_access) // No required_access, allow it.
		return 1
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		var/obj/item/weapon/card/id/I = H.wear_id
		var/obj/item/device/pda/P = H.wear_id
		if(P && istype(P)) // PDA. Try to grab the ID from it then.
			I = P.id
		if(!I) // No equipped ID, let's try checking active hand too
			I = H.get_active_hand()
			P = H.get_active_hand()
			if(P && istype(P))
				I = P.id
		if(!I || !istype(I)) // Still no ID.
			if(loud && computer)
				user << "<span class='danger'>\The [computer] flashes an \"RFID Error - Unable to scan ID\" warning.</span>"
			return 0

		if(required_access in I.access)
			return 1
	if(loud && computer)
		user << "<span class='danger'>\The [computer] flashes an \"Access Denied\" warning.</span>"
	return 0

// This attempts to retrieve header data for NanoUIs. If implementing completely new device of different type than existing ones
// always include the device here in this proc. This proc basically relays the request to whatever is running the program.
/datum/computer_file/program/proc/get_header_data()
	if(istype(computer, /obj/machinery/modular_computer))
		var/obj/machinery/modular_computer/L = computer
		return L.get_header_data()
	if(istype(computer, /obj/item/modular_computer))
		var/obj/item/modular_computer/L = computer
		return L.get_header_data()
	return list()

// This is performed on program startup. May be overriden to add extra logic. Remember to include ..() call. Return 1 on success, 0 on failure.
// When implementing new program based device, use this to run the program.
/datum/computer_file/program/proc/run_program(var/mob/living/user)
	if(can_run(user, 1))
		if(nanomodule_path)
			NM = new nanomodule_path(computer)	// Computer is passed here as it's (probably!) physical object. Some UI's perform get_turf() and passing program datum wouldn't go well with this.
			NM.program = src					// Set the program reference to separate variable, instead.
		running = 1
		return 1
	return 0

// Use this proc to kill the program. Designed to be implemented by each program if it requires on-quit logic, such as the NTNRC client.
/datum/computer_file/program/proc/kill_program(var/forced = 0)
	running = 0
	qdel(NM)
	NM = null
	return 1

// This is called every tick when the program is enabled. Ensure you do parent call if you override it. If parent returns 1 continue with UI initialisation.
// It returns 0 if it can't run or if NanoModule was used instead. I suggest using NanoModules where applicable.
/datum/computer_file/program/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(!running) // Our program was closed. Close the ui if it exists.
		if(ui)
			ui.close()
		return 0
	if(NM)
		NM.ui_interact(user, ui_key, ui, force_open)
		return 0
	return 1


// CONVENTIONS, READ THIS WHEN CREATING NEW PROGRAM AND OVERRIDING THIS PROC:
// Topic calls are automagically forwarded from NanoModule this program contains.
// Calls beginning with "PRG_" are reserved for programs handling.
// Calls beginning with "PC_" are reserved for computer handling (by whatever runs the program)
// ALWAYS INCLUDE PARENT CALL ..() OR DIE IN FIRE.
/datum/computer_file/program/Topic(href, href_list)

	if(computer)
		computer.Topic(href, href_list)
	..()

