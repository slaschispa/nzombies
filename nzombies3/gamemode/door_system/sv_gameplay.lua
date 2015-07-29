function nz.Doors.Functions.OpenDoor( ent )
	//Open the door and any other door with the same link
	if ent:IsButton() then
		ent:ButtonUnlock()
	else
		ent:DoorUnlock()
	end
	
	//Sync
	if ent.link != nil then
		nz.Doors.Data.OpenedLinks[ent.link] = true
		nz.Doors.Functions.SendSync()
	end
end

function nz.Doors.Functions.OpenLinkedDoors( link )
	//Go through all the doors
	for k,v in pairs(ents.GetAll()) do
		if v:IsDoor() or v:IsBuyableProp() or v:IsButton() then
			if v.link != nil then
				if link == v.link then
					nz.Doors.Functions.OpenDoor( v )
				end
			end
		end					
	end
end

function nz.Doors.Functions.LockAllDoors()
	//Force all doors to lock and stay open when opened
	for k,v in pairs(ents.GetAll()) do
		if (v:IsDoor() or v:IsBuyableProp()) then
			//Only lock doors that have been assigned a price - Prop Dynamics may be tied to invisible func_doors
			if nz.Doors.Data.LinkFlags[v:doorIndex()] then
				v:SetUseType( SIMPLE_USE )
				v:DoorLock()
				v:SetKeyValue("wait",-1)
				print("Locked door ", v)
			else
				//Unlocked doors get an output which forces it to stay open once you open it
				//They now get that output the same way as any other door when being opened
				--v:Fire("addoutput", "onclose !self:open::0:-1,0,-1")
				--v:Fire("addoutput", "onclose !self:unlock::0:-1,0,-1")
				--print("added output to", v)
			end
		//Allow locking buttons
		elseif v:IsButton() and nz.Doors.Data.LinkFlags[v:doorIndex()] then
			v:ButtonLock()
			v:SetUseType( SIMPLE_USE )
		end
	end
	nz.Doors.Data.OpenedLinks = {}
	nz.Doors.Functions.SendSync()
end

function nz.Doors.Functions.BuyDoor( ply, ent )
	local price = ent.price
	local req_elec = ent.elec
	local link = ent.link
	local buyable = ent.buyable
	print("Entity info buying ", ent, link, req_elec, price, buyable)
	//If it has a price and it can be bought
	if price != nil and tonumber(buyable) == 1 then
		if ply:CanAfford(price) and ent.Locked == true then
			//If this door doesn't require electricity or if it does, then if the electricity is on at the same time
			if (req_elec == 0 or (req_elec == 1 and IsElec())) then
				ply:TakePoints(price)
				if link == nil then
					nz.Doors.Functions.OpenDoor( ent )
				else
					nz.Doors.Functions.OpenLinkedDoors( link )
				end
			end
		end
	elseif price == nil and buyable == nil then
		//Doors that can be opened because the gamemode doesn't lock them, still need to try and lock upon opening.
		//Additionally, they get the OnClose output added, in case they can still close
		ent:DoorUnlock()
	end
end


//Hooks

function nz.Doors.Functions.OnUseDoor( ply, ent )
	if ent:IsDoor() or ent:IsBuyableProp() or ent:IsButton() then
		nz.Doors.Functions.BuyDoor( ply, ent )
	end
end
hook.Add( "PlayerUse", "player_buydoors", nz.Doors.Functions.OnUseDoor )

function nz.Doors.Functions.CheckUseDoor(ply, ent)
	--print(ply, ent)

	local tr = util.QuickTrace(ply:EyePos(), ply:GetAimVector()*100, ply)
	local door = tr.Entity
	print(door)
	
	if IsValid(door) and door:IsDoor() then
		return door
	end
	
end
hook.Add("FindUseEntity", "CheckDoor", nz.Doors.Functions.CheckUseDoor)