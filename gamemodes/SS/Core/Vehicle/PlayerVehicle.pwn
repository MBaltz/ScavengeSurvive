#include <YSI\y_hooks>


enum
{
	VEH_CELL_MODEL,		// 00
	VEH_CELL_HEALTH,	// 01
	VEH_CELL_FUEL,		// 02
	VEH_CELL_POSX,		// 03
	VEH_CELL_POSY,		// 04
	VEH_CELL_POSZ,		// 05
	VEH_CELL_ROTZ,		// 06
	VEH_CELL_COL1,		// 07
	VEH_CELL_COL2,		// 08
	VEH_CELL_PANELS,	// 09
	VEH_CELL_DOORS,		// 10
	VEH_CELL_LIGHTS,	// 11
	VEH_CELL_TIRES,		// 12
	VEH_CELL_ARMOUR,	// 13
	VEH_CELL_KEY,		// 14
	VEH_CELL_LOCKED,	// 15
	VEH_CELL_END
}


SavePlayerVehicles(printeach = false, printtotal = false)
{
	new
		count,
		owner[MAX_PLAYER_NAME];

	for(new i; i < MAX_SPAWNED_VEHICLES; i++)
	{
		GetVehicleOwner(i, owner);

		if(IsValidVehicleID(i))
		{
			if(strlen(owner) >= 3)
			{
				SavePlayerVehicle(i, owner, printeach);
				count++;
			}
		}
		else
		{
			if(strlen(owner) >= 3)
				RemovePlayerVehicleFile(i);
		}
	}

	if(printtotal)
		printf("Saved %d Player vehicles\n", count);
}

LoadPlayerVehicles(printeach = false, printtotal = false)
{
	new
		dir:direc = dir_open(DIRECTORY_SCRIPTFILES DIRECTORY_VEHICLE_DAT),
		item[28],
		type;

	while(dir_list(direc, item, type))
	{
		if(type == FM_FILE)
		{
			LoadPlayerVehicle(item, printeach);
		}
	}

	dir_close(direc);

	if(printtotal)
		printf("Loaded %d Player vehicles\n", Iter_Count(veh_Index));

	return;
}

LoadPlayerVehicle(filename[], prints)
{
	new
		File:file,
		filedir[64],
		vehicleid,
		vehicletype,
		owner[MAX_PLAYER_NAME],
		containerid,
		array_data[VEH_CELL_END],
		array_inv[CNT_MAX_SLOTS * 3],
		itemid;

	filedir = DIRECTORY_VEHICLE_DAT;
	strcat(filedir, filename);

	if(strlen(filename) <= 4)
	{
		fclose(file);
		fremove(filedir);
		return 0;
	}

	file = fopen(filedir, io_read);

	if(!file)
		return 0;

	fblockread(file, array_data, sizeof(array_data));
	fclose(file);

	vehicletype = GetVehicleType(array_data[VEH_CELL_MODEL]);

	if(!(400 <= array_data[VEH_CELL_MODEL] <= 612))
	{
		printf("ERROR: Removing Vehicle file: %s. Invalid model ID.", filename);
		fremove(filedir);
		return 0;
	}

	if(Float:array_data[VEH_CELL_HEALTH] < 255.5)
	{
		printf("ERROR: Removing Vehicle %s file: %s due to low health.", VehicleNames[array_data[VEH_CELL_MODEL]-400], filename);
		fremove(filedir);
		return 0;
	}

	if(vehicletype == VTYPE_TRAIN)
	{
		printf("ERROR: Removing Vehicle %s file: %s because train.", VehicleNames[array_data[VEH_CELL_MODEL]-400], filename);
		fremove(filedir);
		return 0;
	}

	if(vehicletype != VTYPE_SEA)
	{
		if(!IsPointInMapBounds(Float:array_data[VEH_CELL_POSX], Float:array_data[VEH_CELL_POSY], Float:array_data[VEH_CELL_POSZ]))
		{
			if(vehicletype == VTYPE_HELI || vehicletype == VTYPE_PLANE)
			{
				array_data[VEH_CELL_POSZ] = _:(Float:array_data[VEH_CELL_POSZ] + 10.0);
			}
			else
			{
				printf("ERROR: Removing Vehicle %s file: %s because it's out of the map bounds.", VehicleNames[array_data[VEH_CELL_MODEL]-400], filename);
				fremove(filedir);

				return 0;
			}
		}
	}

	strmid(owner, filename, 0, strlen(filename) - 4);

	if(strlen(owner) < 3)
	{
		printf("ERROR: Vehicle owner name is invalid: '%s' Length: %d", owner, strlen(owner));
		DestroyVehicle(vehicleid, 1);
		fremove(filedir);
		return 0;
	}

	vehicleid = CreateVehicle(
		array_data[VEH_CELL_MODEL],
		Float:array_data[VEH_CELL_POSX],
		Float:array_data[VEH_CELL_POSY],
		Float:array_data[VEH_CELL_POSZ],
		Float:array_data[VEH_CELL_ROTZ],
		array_data[VEH_CELL_COL1],
		array_data[VEH_CELL_COL2],
		86400);

	if(!IsValidVehicleID(vehicleid))
		return 0;

	SetVehicleSpawnPoint(vehicleid,
		Float:array_data[VEH_CELL_POSX],
		Float:array_data[VEH_CELL_POSY],
		Float:array_data[VEH_CELL_POSZ],
		Float:array_data[VEH_CELL_ROTZ]);

	SetVehicleOwner(vehicleid, owner);

	if(prints)
		printf("\t[LOAD] Vehicle %d: %s for %s at %f, %f, %f", vehicleid, VehicleNames[array_data[VEH_CELL_MODEL]-400], owner, array_data[VEH_CELL_POSX], array_data[VEH_CELL_POSY], array_data[VEH_CELL_POSZ], array_data[VEH_CELL_ROTZ]);

	Iter_Add(veh_Index, vehicleid);

	if(Float:array_data[VEH_CELL_HEALTH] > 990.0)
		array_data[VEH_CELL_HEALTH] = _:990.0;

	veh_Data[vehicleid][veh_health]				= Float:array_data[VEH_CELL_HEALTH];
	veh_Data[vehicleid][veh_Fuel]				= Float:array_data[VEH_CELL_FUEL];
	veh_Data[vehicleid][veh_panels]				= array_data[VEH_CELL_PANELS];
	veh_Data[vehicleid][veh_doors]				= array_data[VEH_CELL_DOORS];
	veh_Data[vehicleid][veh_lights]				= array_data[VEH_CELL_LIGHTS];
	veh_Data[vehicleid][veh_tires]				= array_data[VEH_CELL_TIRES];
	veh_Data[vehicleid][veh_armour]				= array_data[VEH_CELL_ARMOUR];
	veh_Data[vehicleid][veh_colour1]			= array_data[VEH_CELL_COL1];
	veh_Data[vehicleid][veh_colour2]			= array_data[VEH_CELL_COL2];
	veh_Data[vehicleid][veh_key]				= array_data[VEH_CELL_KEY];
	veh_Data[vehicleid][veh_locked]				= array_data[VEH_CELL_LOCKED];

	SetVehicleExternalLock(vehicleid, veh_Data[vehicleid][veh_locked]);

	if(VehicleFuelData[array_data[VEH_CELL_MODEL]-400][veh_trunkSize] > 0)
	{
		filedir = DIRECTORY_VEHICLE_INV;
		strcat(filedir, filename);

		file = fopen(filedir, io_read);

		if(!file)
		{
			printf("ERROR: Vehicle inventory file for '%s' is missing!", filedir);
			return 0;
		}

		fblockread(file, array_inv, sizeof(array_inv));
		fclose(file);

		containerid = CreateContainer("Trunk", VehicleFuelData[array_data[VEH_CELL_MODEL]-400][veh_trunkSize], .virtual = 1);
		SetVehicleContainer(vehicleid, containerid);

		for(new i, j; j < CNT_MAX_SLOTS; i += 3, j++)
		{
			if(!IsValidItemType(ItemType:array_inv[i]) || array_inv[i] == 0)
				continue;

			itemid = CreateItem(ItemType:array_inv[i], 0.0, 0.0, 0.0);

			if(array_inv[i + 1] == 1)
			{
				if(!IsItemTypeSafebox(ItemType:array_inv[i]) && !IsItemTypeBag(ItemType:array_inv[i]))
				{
					SetItemExtraData(itemid, array_inv[i + 2]);
				}

				AddItemToContainer(containerid, itemid);
			}
		}
	}
	else
	{
		SetVehicleContainer(vehicleid, INVALID_CONTAINER_ID);
	}

	t:veh_BitData[vehicleid]<veh_Player>;

	UpdateVehicleData(vehicleid);
	CreateVehicleArea(vehicleid);

	return 1;
}

SavePlayerVehicle(vehicleid, name[MAX_PLAYER_NAME], print = false)
{
	if(!IsValidVehicleID(vehicleid))
	{
		if(print)
			printf("ERROR: Saving vehicle ID %d for %s. Invalid vehicle ID", vehicleid, name);

		return 0;
	}

	if(isnull(name))
	{
		if(print)
			printf("ERROR: Saving vehicle ID %d for %s. Name is null", vehicleid, name);

		return 0;
	}

	if(veh_BitData[vehicleid] & veh_Dead)
	{
		if(print)
			printf("ERROR: Saving vehicle ID %d for %s. Vehicle is dead.", vehicleid, name);

		return 0;
	}

	new
		File:file,
		filename[MAX_PLAYER_NAME + 22],
		array_data[VEH_CELL_END],
		array_inv[CNT_MAX_SLOTS * 3],
		itemid;

	array_data[VEH_CELL_MODEL] = GetVehicleModel(vehicleid);

	if(GetVehicleType(array_data[VEH_CELL_MODEL]) == VTYPE_TRAIN)
		return 0;

	GetVehicleHealth(vehicleid, Float:array_data[1]);

	array_data[VEH_CELL_FUEL] = _:GetVehicleFuel(vehicleid);
	GetVehiclePos(vehicleid, Float:array_data[VEH_CELL_POSX], Float:array_data[VEH_CELL_POSY], Float:array_data[VEH_CELL_POSZ]);
	GetVehicleZAngle(vehicleid, Float:array_data[VEH_CELL_ROTZ]);
	array_data[VEH_CELL_COL1] = veh_Data[vehicleid][veh_colour1];
	array_data[VEH_CELL_COL2] = veh_Data[vehicleid][veh_colour2];
	GetVehicleDamageStatus(vehicleid, array_data[VEH_CELL_PANELS], array_data[VEH_CELL_DOORS], array_data[VEH_CELL_LIGHTS], array_data[VEH_CELL_TIRES]);
	array_data[VEH_CELL_ARMOUR] = 0;
	array_data[VEH_CELL_KEY] = veh_Data[vehicleid][veh_key];

	if(!IsVehicleOccupied(vehicleid))
		array_data[VEH_CELL_LOCKED] = veh_Data[vehicleid][veh_locked];

	format(filename, sizeof(filename), DIRECTORY_VEHICLE_DAT"%s.dat", name);
	file = fopen(filename, io_write);

	if(!file)
	{
		printf("ERROR: Opening file '%s'", filename);
		return 0;
	}

	fblockwrite(file, array_data, sizeof(array_data));
	fclose(file);

	SetVehicleOwner(vehicleid, name);

	if(!IsValidContainer(GetVehicleContainer(vehicleid)))
		return 1;

	for(new i, j; j < CNT_MAX_SLOTS; i += 3, j++)
	{
		if(IsContainerSlotUsed(GetVehicleContainer(vehicleid), j))
		{
			itemid = GetContainerSlotItem(GetVehicleContainer(vehicleid), j);
			array_inv[i] = _:GetItemType(itemid);
			array_inv[i + 1] = 1;
			array_inv[i + 2] = GetItemExtraData(itemid);

			if(array_inv[i] == 0)
				return 0;
		}
		else
		{
			array_inv[i] = -1;
			array_inv[i + 1] = 1;
			array_inv[i + 2] = 0;
		}
	}

	format(filename, sizeof(filename), DIRECTORY_VEHICLE_INV"%s.dat", name);
	file = fopen(filename, io_write);
	fblockwrite(file, array_inv, sizeof(array_inv));
	fclose(file);

	return 1;
}

SetVehicleOwner(vehicleid, name[MAX_PLAYER_NAME], print = false)
{
	if(!IsValidVehicleID(vehicleid))
		return 0;

	if(!isnull(veh_Owner[vehicleid]))
	{
		if(strcmp(veh_Owner[vehicleid], name))
			RemovePlayerVehicleFile(vehicleid, print);
	}

	veh_Owner[vehicleid] = name;

	for(new i; i < MAX_SPAWNED_VEHICLES; i++)
	{
		if(i == vehicleid)
			continue;

		if(!strcmp(veh_Owner[i], veh_Owner[vehicleid]))
			veh_Owner[i][0] = EOS;
	}

	return 1;
}

RemovePlayerVehicleFile(vehicleid, print = true)
{
	new owner[MAX_PLAYER_NAME];

	GetVehicleOwner(vehicleid, owner);

	if(isnull(owner))
		return 0;

	if(print)
		printf("[DELT] Removing vehicle: %d for player: %s", vehicleid, owner);

	new filename[MAX_PLAYER_NAME + 22];

	format(filename, sizeof(filename), DIRECTORY_VEHICLE_DAT"%s.dat", owner);
	fremove(filename);

	format(filename, sizeof(filename), DIRECTORY_VEHICLE_INV"%s.dat", owner);
	fremove(filename);

	return 1;
}


// OLD METHOD

/*
LoadPlayerVehicles_OLD(printeach = false, printtotal = false)
{
	new
		dir:direc = dir_open(PLAYER_VEHICLE_DIRECTORY),
		item[28],
		type;

	while(dir_list(direc, item, type))
	{
		if(type == FM_FILE)
		{
			LoadPlayerVehicle(item, printeach);
		}
	}

	dir_close(direc);

	if(printtotal)
		printf("Loaded %d Player vehicles\n", Iter_Count(veh_Index));

	return;
}

SavePlayerVehicle_OLD(vehicleid, name[MAX_PLAYER_NAME], print = false)
{
	new
		File:file,
		filename[MAX_PLAYER_NAME + 22],
		array[VEH_CELL_INV + (CNT_MAX_SLOTS * 3)],
		itemid;

	array[VEH_CELL_MODEL] = GetVehicleModel(vehicleid);

	if(GetVehicleType(array[VEH_CELL_MODEL]) == VTYPE_TRAIN)
		return 0;

	GetVehicleHealth(vehicleid, Float:array[1]);

	array[VEH_CELL_FUEL] = _:GetVehicleFuel(vehicleid);
	GetVehiclePos(vehicleid, Float:array[VEH_CELL_POSX], Float:array[VEH_CELL_POSY], Float:array[VEH_CELL_POSZ]);
	GetVehicleZAngle(vehicleid, Float:array[VEH_CELL_ROTZ]);
	array[VEH_CELL_COL1] = veh_Data[vehicleid][veh_colour1];
	array[VEH_CELL_COL2] = veh_Data[vehicleid][veh_colour2];
	GetVehicleDamageStatus(vehicleid, array[VEH_CELL_PANELS], array[VEH_CELL_DOORS], array[VEH_CELL_LIGHTS], array[VEH_CELL_TIRES]);
	array[VEH_CELL_ARMOUR] = 0;

	if(print)
		printf("\t[SAVE] Vehicle %d: %s for %s at %f, %f, %f", vehicleid, VehicleNames[array[VEH_CELL_MODEL]-400], name, Float:array[VEH_CELL_POSX], Float:array[VEH_CELL_POSY], Float:array[VEH_CELL_POSZ]);

	if(IsValidContainer(GetVehicleContainer(vehicleid)))
	{
		for(new i, j; j < CNT_MAX_SLOTS; i += 3, j++)
		{
			if(IsContainerSlotUsed(GetVehicleContainer(vehicleid), j))
			{
				itemid = GetContainerSlotItem(GetVehicleContainer(vehicleid), j);
				array[VEH_CELL_INV + i] = _:GetItemType(itemid);
				array[VEH_CELL_INV + i + 1] = 1;
				array[VEH_CELL_INV + i + 2] = GetItemExtraData(itemid);

				if(array[VEH_CELL_INV + i] == 0)
					return 0;
			}
			else
			{
				array[VEH_CELL_INV + i] = -1;
				array[VEH_CELL_INV + i + 1] = 1;
				array[VEH_CELL_INV + i + 2] = 0;
			}
		}
	}

	SetVehicleOwner(vehicleid, name);

	format(filename, sizeof(filename), PLAYER_VEHICLE_FILE, name);
	file = fopen(filename, io_write);
	fblockwrite(file, array, sizeof(array));
	fclose(file);

	return 1;
}

*/
