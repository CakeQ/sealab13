// Relays don't handle any actual communication. Global NTNet datum does that, relays only tell the datum if it should or shouldn't work.
/obj/machinery/ntnet_relay
	name = "NTNet Quantum Relay"
	desc = "A very complex router and transmitter capable of connecting electronic devices together. Looks fragile."
	use_power = 1
	idle_power_usage = 20000 //20kW, apropriate for machine that keeps massive cross-Zlevel wireless network operational.
	icon_state = "bus"
	anchored = 1
	density = 1
	var/datum/ntnet/NTNet = null // This is mostly for backwards reference and to allow varedit modifications from ingame.

// TODO: Implement more logic here. For now it's only a placeholder.
/obj/machinery/ntnet_relay/proc/is_operational()
	if(stat & (BROKEN | NOPOWER | EMPED))
		return 0
	return 1

/obj/machinery/ntnet_relay/New()
	if(ntnet_global)
		ntnet_global.relays.Add(src)
		NTNet = ntnet_global
		ntnet_global.add_log("New quantum relay activated. Current amount of linked relays: [NTNet.relays.len]")
	..()

/obj/machinery/ntnet_relay/Destroy()
	if(ntnet_global)
		ntnet_global.relays.Remove(src)
		ntnet_global.add_log("Quantum relay connection severed. Current amount of linked relays: [NTNet.relays.len]")
		NTNet = null
	..()