////////////////////////////////////////////////////////////////////////////////
/// Drinks.
////////////////////////////////////////////////////////////////////////////////
/obj/item/weapon/reagent_containers/food/drinks
	name = "drink"
	desc = "yummy"
	icon = 'icons/obj/drinks.dmi'
	icon_state = null
	flags = FPRINT | TABLEPASS | OPENCONTAINER
	var/gulp_size = 5 //This is now officially broken ... need to think of a nice way to fix it.
	possible_transfer_amounts = list(5,10,25)
	volume = 50

	//merged from bottle.dm - Hinaichigo
	var/const/duration = 13 //Directly relates to the 'weaken' duration. Lowered by armor (i.e. helmets)
	var/isGlass = 1 //Whether the 'bottle' is made of glass or not so that milk cartons dont shatter when someone gets hit by it

	//molotov variables
	var/molotov = 0 //-1 = can be made into molotov, 0 = can't, 1 = has had rag stuffed into it
	var/lit = 0
	var/brightness_lit = 3

	on_reagent_change()
		if (gulp_size < 5) gulp_size = 5
		else gulp_size = max(round(reagents.total_volume / 5), 5)

	attack_self(mob/user as mob)
		attack(user,user)
		return

	attack(mob/M as mob, mob/user as mob, def_zone)
		if(!is_open_container())
			user << "<span  class='rose'>You can't; [src] is closed.</span>"  //Added this here and elsewhere to prevent drinking, etc. from closed drink containers. - Hinaichigo
			return 0
		var/datum/reagents/R = src.reagents
		var/fillevel = gulp_size

		if(!R.total_volume || !R)
			user << "<span  class='rose'>None of [src] left, oh no!<span>"
			return 0

		if(M == user)
			M << "<span  class='notice'>You swallow a gulp of [src].</span>"
			if(reagents.total_volume)
				reagents.reaction(M, INGEST)
				spawn(5)
					reagents.trans_to(M, gulp_size)

			playsound(M.loc,'sound/items/drink.ogg', rand(10,50), 1)
			return 1
		else if( istype(M, /mob/living/carbon/human) )

			for(var/mob/O in viewers(world.view, user))
				O.show_message("\red [user] attempts to feed [M] [src].", 1)
			if(!do_mob(user, M)) return
			for(var/mob/O in viewers(world.view, user))
				O.show_message("\red [user] feeds [M] [src].", 1)

			M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been fed [src.name] by [user.name] ([user.ckey]) Reagents: [reagentlist(src)]</font>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Fed [M.name] by [M.name] ([M.ckey]) Reagents: [reagentlist(src)]</font>")

			log_attack("<font color='red'>[user.name] ([user.ckey]) fed [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")
			if(!iscarbon(user))
				M.LAssailant = null
			else
				M.LAssailant = user

			if(reagents.total_volume)
				reagents.reaction(M, INGEST)
				spawn(5)
					reagents.trans_to(M, gulp_size)

			if(isrobot(user)) //Cyborg modules that include drinks automatically refill themselves, but drain the borg's cell
				var/mob/living/silicon/robot/bro = user
				bro.cell.use(30)
				var/refill = R.get_master_reagent_id()
				spawn(600)
					R.add_reagent(refill, fillevel)

			playsound(M.loc,'sound/items/drink.ogg', rand(10,50), 1)
			return 1

		return 0


	afterattack(obj/target, mob/user , flag)
		if(istype(target, /obj/structure/reagent_dispensers)) //A dispenser. Transfer FROM it TO us.
			if(!is_open_container())
				user << "<span  class='rose'>You can't; [src] is closed.</span>"
				return 0

			if(!target.reagents.total_volume)
				user << "<span  class='rose'>[target] is empty.</span>"
				return

			if(reagents.total_volume >= reagents.maximum_volume)
				user << "<span  class='rose'>[src] is full.</span>"
				return

			var/trans = target.reagents.trans_to(src, target:amount_per_transfer_from_this)
			user << "<span  class='notice'>You fill [src] with [trans] units of the contents of [target].<span>"

		else if(target.is_open_container()) //Something like a glass. Player probably wants to transfer TO it.
			if(!is_open_container())
				user << "<span  class='rose'>You can't; [src] is closed.</span>"
				return 0

			if(!reagents.total_volume)
				user << "<span  class='rose'>[src] is empty.</span>"
				return

			if(target.reagents.total_volume >= target.reagents.maximum_volume)
				user << "<span  class='rose'>[target] is full.</span>"
				return



			var/datum/reagent/refill
			var/datum/reagent/refillName
			if(isrobot(user))
				refill = reagents.get_master_reagent_id()
				refillName = reagents.get_master_reagent_name()

			var/trans = src.reagents.trans_to(target, amount_per_transfer_from_this)
			user << "<span  class='notice'>You transfer [trans] units of the solution to [target].</span>"

			if(isrobot(user)) //Cyborg modules that include drinks automatically refill themselves, but drain the borg's cell
				var/mob/living/silicon/robot/bro = user
				var/chargeAmount = max(30,4*trans)
				bro.cell.use(chargeAmount)
				user << "Now synthesizing [trans] units of [refillName]..."


				spawn(300)
					reagents.add_reagent(refill, trans)
					user << "Cyborg [src] refilled."

		return

	examine()
		set src in view()
		..()
		if (!(usr in range(0)) && usr!=src.loc) return
		if(!reagents || reagents.total_volume==0)
			usr << "<span  class='notice'>\The [src] is empty!</span>"
		else if (reagents.total_volume<=src.volume/4)
			usr << "<span  class='notice'>\The [src] is almost empty!</span>"
		else if (reagents.total_volume<=src.volume*0.66)
			usr << "<span  class='notice'>\The [src] is half full!</span>"
		else if (reagents.total_volume<=src.volume*0.90)
			usr << "<span  class='notice'>\The [src] is almost full!</span>"
		else
			usr << "<span  class='notice'>\The [src] is full!</span>"


////////////////////////////////////////////////////////////////////////////////
/// Drinks. END
////////////////////////////////////////////////////////////////////////////////

/obj/item/weapon/reagent_containers/food/drinks/golden_cup
	desc = "A golden cup"
	name = "golden cup"
	icon_state = "golden_cup"
	item_state = "" //nope :(
	w_class = 4
	force = 14
	throwforce = 10
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = null
	volume = 150
	isGlass = 0
	flags = FPRINT | CONDUCT | TABLEPASS | OPENCONTAINER

/obj/item/weapon/reagent_containers/food/drinks/golden_cup/tournament_26_06_2011
	desc = "A golden cup. It will be presented to a winner of tournament 26 june and name of the winner will be graved on it."


///////////////////////////////////////////////Drinks
//Notes by Darem: Drinks are simply containers that start preloaded. Unlike condiments, the contents can be ingested directly
//	rather then having to add it to something else first. They should only contain liquids. They have a default container size of 50.
//	Formatting is the same as food.

/obj/item/weapon/reagent_containers/food/drinks/milk
	name = "Space Milk"
	desc = "It's milk. White and nutritious goodness!"
	icon_state = "milk"
	item_state = "carton"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("milk", 50)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/flour
	name = "flour sack"
	desc = "A big bag of flour. Good for baking!"
	icon = 'icons/obj/food.dmi'
	icon_state = "flour"
	item_state = "flour"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("flour", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soymilk
	name = "SoyMilk"
	desc = "It's soy milk. White and nutritious goodness!"
	icon_state = "soymilk"
	item_state = "carton"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("soymilk", 50)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/coffee
	name = "Robust Coffee"
	desc = "Careful, the beverage you're about to enjoy is extremely hot."
	icon_state = "coffee"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("coffee", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/tea
	name = "Duke Purple Tea"
	desc = "An insult to Duke Purple is an insult to the Space Queen! Any proper gentleman will fight you, if you sully this tea."
	icon_state = "tea"
	item_state = "coffee"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("tea", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/ice
	name = "Ice Cup"
	desc = "Careful, cold ice, do not chew."
	icon_state = "coffee"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("ice", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/h_chocolate
	name = "Dutch Hot Coco"
	desc = "Made in Space South America."
	icon_state = "tea"
	item_state = "coffee"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("hot_coco", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/dry_ramen
	name = "Cup Ramen"
	desc = "Just add 10ml water, self heats! A taste that reminds you of your school years."
	icon_state = "ramen"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("dry_ramen", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/beer
	name = "Space Beer"
	desc = "Beer. In space."
	icon_state = "beer"
	molotov = -1 //can become a molotov
	New()
		..()
		reagents.add_reagent("beer", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/ale
	name = "Magm-Ale"
	desc = "A true dorf's drink of choice."
	icon_state = "alebottle"
	item_state = "beer"
	molotov = -1 //can become a molotov
	New()
		..()
		reagents.add_reagent("ale", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/cola
	name = "Space Cola"
	desc = "Cola. in space."
	icon_state = "cola"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("cola", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/tonic
	name = "T-Borg's Tonic Water"
	desc = "Quinine tastes funny, but at least it'll keep that Space Malaria away."
	icon_state = "tonic"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("tonic", 50)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/sodawater
	name = "Soda Water"
	desc = "A can of soda water. Why not make a scotch and soda?"
	icon_state = "sodawater"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("sodawater", 50)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/lemon_lime
	name = "Lemon-Lime"
	desc = "You wanted ORANGE. It gave you Lemon Lime."
	icon_state = "lemon-lime"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("lemon_lime", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/space_up
	name = "Space-Up"
	desc = "Tastes like a hull breach in your mouth."
	icon_state = "space-up"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("space_up", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/starkist
	name = "Star-kist"
	desc = "The taste of a star in liquid form. And, a bit of tuna...?"
	icon_state = "starkist"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("cola", 15)
		reagents.add_reagent("orangejuice", 15)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/space_mountain_wind
	name = "Space Mountain Wind"
	desc = "Blows right through you like a space wind."
	icon_state = "space_mountain_wind"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("spacemountainwind", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/thirteenloko
	name = "Thirteen Loko"
	desc = "The CMO has advised crew members that consumption of Thirteen Loko may result in seizures, blindness, drunkeness, or even death. Please Drink Responsably."
	icon_state = "thirteen_loko"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("thirteenloko", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)

/obj/item/weapon/reagent_containers/food/drinks/soda_cans/dr_gibb
	name = "Dr. Gibb"
	desc = "A delicious mixture of 42 different flavors."
	icon_state = "dr_gibb"
	isGlass = 0
	New()
		..()
		reagents.add_reagent("dr_gibb", 30)
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)


/obj/item/weapon/reagent_containers/food/drinks/sillycup
	name = "Paper Cup"
	desc = "A paper water cup."
	icon_state = "water_cup_e"
	possible_transfer_amounts = null
	volume = 10
	isGlass = 0
	New()
		..()
		src.pixel_x = rand(-10.0, 10)
		src.pixel_y = rand(-10.0, 10)
	on_reagent_change()
		if(reagents.total_volume)
			icon_state = "water_cup"
		else
			icon_state = "water_cup_e"
//////////////////////////drinkingglass and shaker//
//Note by Darem: This code handles the mixing of drinks. New drinks go in three places: In Chemistry-Reagents.dm (for the drink
//	itself), in Chemistry-Recipes.dm (for the reaction that changes the components into the drink), and here (for the drinking glass
//	icon states.

/obj/item/weapon/reagent_containers/food/drinks/shaker
	name = "Shaker"
	desc = "A metal shaker to mix drinks in."
	icon_state = "shaker"
	amount_per_transfer_from_this = 10
	isGlass = 0
	volume = 100

/obj/item/weapon/reagent_containers/food/drinks/flask
	name = "Captain's Flask"
	desc = "A metal flask belonging to the captain"
	icon_state = "flask"
	isGlass = 0
	volume = 60

/obj/item/weapon/reagent_containers/food/drinks/flask/detflask
	name = "Detective's Flask"
	desc = "A metal flask with a leather band and golden badge belonging to the detective."
	icon_state = "detflask"
	isGlass = 0
	volume = 60

/obj/item/weapon/reagent_containers/food/drinks/flask/barflask
	name = "flask"
	desc = "For those who can't be bothered to hang out at the bar to drink."
	icon_state = "barflask"
	isGlass = 0
	volume = 60

/obj/item/weapon/reagent_containers/food/drinks/britcup
	name = "cup"
	desc = "A cup with the british flag emblazoned on it."
	icon_state = "britcup"
	isGlass = 0
	volume = 30


///////////////////////////////////////////////Alchohol bottles! -Agouri //////////////////////////
//Functionally identical to regular drinks. The only difference is that the default bottle size is 100. - Darem
//Bottles now weaken and break when smashed on people's heads. - Giacom


/obj/item/weapon/reagent_containers/food/drinks/bottle
	amount_per_transfer_from_this = 10
	volume = 100
	g_amt=500

//Keeping this here for now, I'll ask if I should keep it here.
/obj/item/weapon/broken_bottle

	name = "broken bottle" // changed to lowercase - Hinaichigo
	desc = "A bottle with a sharp broken bottom."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "broken_bottle"
	force = 9.0
	throwforce = 5.0
	throw_speed = 3
	throw_range = 5
	item_state = "beer"
	attack_verb = list("stabbed", "slashed", "attacked")
	var/icon/broken_outline = icon('icons/obj/drinks.dmi', "broken")
	g_amt=500

/obj/item/weapon/broken_bottle/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	playsound(loc, 'sound/weapons/bladeslice.ogg', 50, 1, -1)
	return ..()


/obj/item/weapon/reagent_containers/food/drinks/bottle/gin
	name = "Griffeater Gin"
	desc = "A bottle of high quality gin, produced in the New London Space Station."
	icon_state = "ginbottle"
	New()
		..()
		reagents.add_reagent("gin", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/whiskey
	name = "Uncle Git's Special Reserve"
	desc = "A premium single-malt whiskey, gently matured inside the tunnels of a nuclear shelter. TUNNEL WHISKEY RULES."
	icon_state = "whiskeybottle"
	New()
		..()
		reagents.add_reagent("whiskey", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/vodka
	name = "Tunguska Triple Distilled"
	desc = "Aah, vodka. Prime choice of drink AND fuel by Russians worldwide."
	icon_state = "vodkabottle"
	New()
		..()
		reagents.add_reagent("vodka", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/tequilla
	name = "Caccavo Guaranteed Quality Tequilla"
	desc = "Made from premium petroleum distillates, pure thalidomide and other fine quality ingredients!"
	icon_state = "tequillabottle"
	New()
		..()
		reagents.add_reagent("tequilla", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing
	name = "Bottle of Nothing"
	desc = "A bottle filled with nothing"
	icon_state = "bottleofnothing"
	New()
		..()
		reagents.add_reagent("nothing", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/patron
	name = "Wrapp Artiste Patron"
	desc = "Silver laced tequilla, served in space night clubs across the galaxy."
	icon_state = "patronbottle"
	New()
		..()
		reagents.add_reagent("patron", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/rum
	name = "Captain Pete's Cuban Spiced Rum"
	desc = "This isn't just rum, oh no. It's practically GRIFF in a bottle."
	icon_state = "rumbottle"
	New()
		..()
		reagents.add_reagent("rum", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/holywater
	name = "Flask of Holy Water"
	desc = "A flask of the chaplain's holy water."
	icon_state = "holyflask"
	New()
		..()
		reagents.add_reagent("holywater", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/vermouth
	name = "Goldeneye Vermouth"
	desc = "Sweet, sweet dryness~"
	icon_state = "vermouthbottle"
	New()
		..()
		reagents.add_reagent("vermouth", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/kahlua
	name = "Robert Robust's Coffee Liqueur"
	desc = "A widely known, Mexican coffee-flavoured liqueur. In production since 1936, HONK"
	icon_state = "kahluabottle"
	New()
		..()
		reagents.add_reagent("kahlua", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/goldschlager
	name = "College Girl Goldschlager"
	desc = "Because they are the only ones who will drink 100 proof cinnamon schnapps."
	icon_state = "goldschlagerbottle"
	New()
		..()
		reagents.add_reagent("goldschlager", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/cognac
	name = "Chateau De Baton Premium Cognac"
	desc = "A sweet and strongly alchoholic drink, made after numerous distillations and years of maturing. You might as well not scream 'SHITCURITY' this time."
	icon_state = "cognacbottle"
	New()
		..()
		reagents.add_reagent("cognac", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/wine
	name = "Doublebeard Bearded Special Wine"
	desc = "A faint aura of unease and asspainery surrounds the bottle."
	icon_state = "winebottle"
	New()
		..()
		reagents.add_reagent("wine", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/absinthe
	name = "Jailbreaker Verte"
	desc = "One sip of this and you just know you're gonna have a good time."
	icon_state = "absinthebottle"
	New()
		..()
		reagents.add_reagent("absinthe", 100)

//////////////////////////JUICES AND STUFF ///////////////////////

/obj/item/weapon/reagent_containers/food/drinks/bottle/orangejuice
	name = "Orange Juice"
	desc = "Full of vitamins and deliciousness!"
	icon_state = "orangejuice"
	item_state = "carton"
	isGlass = 0
	g_amt=0
	New()
		..()
		reagents.add_reagent("orangejuice", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/cream
	name = "Milk Cream"
	desc = "It's cream. Made from milk. What else did you think you'd find in there?"
	icon_state = "cream"
	item_state = "carton"
	isGlass = 0
	g_amt=0
	New()
		..()
		reagents.add_reagent("cream", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/tomatojuice
	name = "Tomato Juice"
	desc = "Well, at least it LOOKS like tomato juice. You can't tell with all that redness."
	icon_state = "tomatojuice"
	item_state = "carton"
	isGlass = 0
	g_amt=0
	New()
		..()
		reagents.add_reagent("tomatojuice", 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/limejuice
	name = "Lime Juice"
	desc = "Sweet-sour goodness."
	icon_state = "limejuice"
	item_state = "carton"
	isGlass = 0
	g_amt=0
	New()
		..()
		reagents.add_reagent("limejuice", 100)




/obj/item/weapon/reagent_containers/food/drinks/proc/smash(mob/living/target as mob, mob/living/user as mob)

	if(molotov) //for molotovs
		if(lit)
			new /obj/effect/decal/cleanable/ash(src.loc)
		else
			new /obj/item/weapon/reagent_containers/glass/rag(src.loc)

	//Creates a shattering noise and replaces the bottle with a broken_bottle
	user.drop_item()
	var/obj/item/weapon/broken_bottle/B = new /obj/item/weapon/broken_bottle(user.loc)
	if(istype(src, /obj/item/weapon/reagent_containers/food/drinks/drinkingglass))  //for drinking glasses
		B.name = "broken glass"
		B.force = 5
	else if(istype(src, /obj/item/weapon/reagent_containers/food/drinks/bottle/holywater)) //for holy water flasks
		B.name = "broken flask"
	user.put_in_active_hand(B)
	if(prob(33))
		getFromPool(/obj/item/weapon/shard, target.loc) // Create a glass shard at the target's location!
	B.icon_state = src.icon_state

	var/icon/I = new('icons/obj/drinks.dmi', src.icon_state)
	I.Blend(B.broken_outline, ICON_OVERLAY, rand(5), 1)
	I.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
	B.icon = I

	playsound(src, "shatter", 70, 1)
	user.put_in_active_hand(B)
	src.transfer_fingerprints_to(B)

	del(src)

/obj/item/weapon/reagent_containers/food/drinks/attack(mob/living/target as mob, mob/living/user as mob)

	if(!target)
		return

	if(src.molotov == 1)  //once there's a rag inside, can't be smashed on someone
		return

	if(user.a_intent != "hurt" || !isGlass)
		return ..()


	force = 15 //Smashing bottles over someoen's head hurts.

	var/datum/organ/external/affecting = user.zone_sel.selecting //Find what the player is aiming at

	var/armor_block = 0 //Get the target's armour values for normal attack damage.
	var/armor_duration = 0 //The more force the bottle has, the longer the duration.

	//Calculating duration and calculating damage.
	if(ishuman(target))

		var/mob/living/carbon/human/H = target
		var/headarmor = 0 // Target's head armour
		armor_block = H.run_armor_check(affecting, "melee") // For normal attack damage

		//If they have a hat/helmet and the user is targeting their head.
		if(istype(H.head, /obj/item/clothing/head) && affecting == "head")

			// If their head has an armour value, assign headarmor to it, else give it 0.
			if(H.head.armor["melee"])
				headarmor = H.head.armor["melee"]
			else
				headarmor = 0
		else
			headarmor = 0

		//Calculate the weakening duration for the target.
		armor_duration = (duration - headarmor) + force

	else
		//Only humans can have armour, right?
		armor_block = target.run_armor_check(affecting, "melee")
		if(affecting == "head")
			armor_duration = duration + force
	armor_duration /= 10

	//Apply the damage!
	target.apply_damage(force, BRUTE, affecting, armor_block)

	// You are going to knock someone out for longer if they are not wearing a helmet.
	if(affecting == "head" && istype(target, /mob/living/carbon/))

		//Display an attack message.
		for(var/mob/O in viewers(user, null))
			if(target != user) O.show_message(text("\red <B>[target] has been hit over the head with a bottle of [src.name], by [user]!</B>"), 1)
			else O.show_message(text("\red <B>[target] hit himself with a bottle of [src.name] on the head!</B>"), 1)
		//Weaken the target for the duration that we calculated and divide it by 5.
		if(armor_duration)
			target.apply_effect(min(armor_duration, 10) , WEAKEN) // Never weaken more than a flash!

	else
		//Default attack message and don't weaken the target.
		for(var/mob/O in viewers(user, null))
			if(target != user) O.show_message(text("\red <B>[target] has been attacked with a bottle of [src.name], by [user]!</B>"), 1)
			else O.show_message(text("\red <B>[target] has attacked himself with a bottle of [src.name]!</B>"), 1)

	//Attack logs
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Has attacked [target.name] ([target.ckey]) with a bottle!</font>")
	target.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been smashed with a bottle by [user.name] ([user.ckey])</font>")
	log_attack("<font color='red'>[user.name] ([user.ckey]) attacked [target.name] with a bottle. ([target.ckey])</font>")
	if(!iscarbon(user))
		target.LAssailant = null
	else
		target.LAssailant = user

	//The reagents in the bottle splash all over the target, thanks for the idea Nodrak
	if(src.reagents)
		for(var/mob/O in viewers(user, null))
			O.show_message(text("\blue <B>The contents of the [src] splashes all over [target]!</B>"), 1)
		src.reagents.reaction(target, TOUCH)

	//Finally, smash the bottle. This kills (del) the bottle.
	src.smash(target, user)

	return



//smashing when thrown

/obj/item/weapon/reagent_containers/food/drinks/throw_impact(atom/hit_atom)
	..()
	if(isGlass)
		isGlass = 0 //to avoid it from hitting the wall, then hitting the floor, which would cause two broken bottles to appear
		src.visible_message("<span  class='warning'>The [src.name] shatters!</span>","<span  class='warning'>You hear a shatter!</span>")
		playsound(src, 'sound/effects/hit_on_shattered_glass.ogg', 70, 1)
		if(reagents.total_volume)
			src.reagents.reaction(hit_atom, TOUCH)  //maybe this could be improved?
			spawn(5) src.reagents.clear_reagents()  //maybe this could be improved?
		invisibility = INVISIBILITY_MAXIMUM  //so it stays a while to ignite any fuel

		if(molotov) //for molotovs
			if(lit)
				new /obj/effect/decal/cleanable/ash(src.loc)
			else
				new /obj/item/weapon/reagent_containers/glass/rag(src.loc)

		//create new broken bottle
		var/obj/item/weapon/broken_bottle/B = new /obj/item/weapon/broken_bottle(loc)
		if(istype(src, /obj/item/weapon/reagent_containers/food/drinks/drinkingglass))  //for drinking glasses
			B.name = "broken glass"
			B.force = 5
		else if(istype(src, /obj/item/weapon/reagent_containers/food/drinks/bottle/holywater)) //for holy water flasks
			B.name = "broken flask"
		if(prob(33))
			getFromPool(/obj/item/weapon/shard, src.loc) // Create a glass shard at the target's location!
		B.icon_state = src.icon_state //make sure to delete overlays
		var/icon/Q = new('icons/obj/drinks.dmi', src.icon_state)
		Q.Blend(B.broken_outline, ICON_OVERLAY, rand(5), 1)
		Q.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
		B.icon = Q
		src.transfer_fingerprints_to(B)


	spawn(50)
		del(src)

//////////////////////
// molotov cocktail //
//  by Hinaichigo   //
//////////////////////

/obj/item/weapon/reagent_containers/food/drinks/attackby(var/obj/item/I, mob/user as mob)
	if(istype(I, /obj/item/weapon/reagent_containers/glass/rag) && molotov == -1)  //check if it is a molotovable drink - just beer and ale for now - other bottles require different rag overlay positions - if you can figure this out then go for it
		user << "<span  class='notice'>You stuff the [I] into the mouth of the [src].</span>"
		del(I)
		molotov = 1
		flags ^= OPENCONTAINER
		name = "incendiary cocktail"
		desc = "A rag stuffed into a bottle."
		update_icon()
		slot_flags = SLOT_BELT
	else if(istype(I, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = I
		if(WT.isOn())
			light()
			update_brightness(user)
	else if(istype(I, /obj/item/weapon/lighter))
		var/obj/item/weapon/lighter/L = I
		if(L.lit)
			light()
			update_brightness(user)
	else if(istype(I, /obj/item/weapon/match))
		var/obj/item/weapon/match/M = I
		if(M.lit)
			light()
			update_brightness(user)
	else if(istype(I, /obj/item/device/assembly/igniter))
		var/obj/item/device/assembly/igniter/C = I
		C.activate()
		light()
		update_brightness(user)
	else if(istype(I, /obj/item/clothing/mask/cigarette))
		var/obj/item/clothing/mask/cigarette/C = I
		if(C.lit)
			light()
			update_brightness(user)
	else if(istype(I, /obj/item/candle))
		var/obj/item/candle/C = I
		if(C.lit)
			light()
			update_brightness(user)
		return

/obj/item/weapon/reagent_containers/food/drinks/proc/light(var/flavor_text = "<span  class='rose'>[usr] lights the [name].</span>")
	if(!lit && molotov == 1)
		lit = 1
		for(var/mob/O in viewers(usr, null))
			O.show_message(flavor_text, 1)
		processing_objects.Add(src)
		update_icon()

/obj/item/weapon/reagent_containers/food/drinks/proc/update_brightness(var/mob/user = null)
	if(lit)
		if(loc == user)
			user.SetLuminosity(user.luminosity + brightness_lit)
		else if(isturf(loc))
			SetLuminosity(src.brightness_lit)
	else
		if(loc == user)
			user.SetLuminosity(user.luminosity - brightness_lit)
		else if(isturf(loc))
			SetLuminosity(0)

/obj/item/weapon/reagent_containers/food/drinks/pickup(mob/user)
	if(lit)
		user.SetLuminosity(user.luminosity + brightness_lit)
		SetLuminosity(0)


/obj/item/weapon/reagent_containers/food/drinks/dropped(mob/user)
	if(src)
		user.SetLuminosity(user.luminosity - brightness_lit)
		SetLuminosity(brightness_lit)


/obj/item/weapon/reagent_containers/food/drinks/update_icon()
	src.overlays.len = 0
	var/image/Im
	if(molotov == 1)
		Im = image('icons/obj/grenade.dmi', icon_state = "molotov_rag")
		overlays += Im
	if(molotov == 1 && lit)
		Im = image('icons/obj/grenade.dmi', icon_state = "molotov_fire")
		overlays += Im
	else
		item_state = initial(item_state)
	if(ishuman(src.loc))
		var/mob/living/carbon/human/H = src.loc
		H.update_inv_belt()
	return


/obj/item/weapon/reagent_containers/food/drinks/process()
	var/turf/loca = get_turf(src)
	if(lit)
		loca.hotspot_expose(700, 1000)
	return



////////  Could be expanded upon:
//  make it work with more chemicals and reagents, more like a chem grenade
//  only allow the bottle to be stuffed if there are certain reagents inside, like fuel
//  different flavor text for different means of lighting
//  new fire overlay - current is edited version of the IED one
//  a chance to not break, if desired
//  fingerprints appearing on the object, which might already happen, and the shard
//  belt sprite and new hand sprite
//	ability to put out with water or otherwise
//	burn out after a time causing the contents to ignite
//	generalize to all bottles - just need to somehow get the sprites to line up and give them molotov = -1
//	make into its own item type so they could be spawned full of fuel with New()
//  colored light instead of white light
//	the rag can store chemicals as well so maybe the rag's chemicals could react with the bottle's chemicals before or upon breaking
//  somehow make it possible to wipe down the bottles instead of exclusively stuffing rags into them
//  make rag retain chemical properties or color (if implemented) after smashing
////////