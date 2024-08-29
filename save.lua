-- Save

function save_to_slot(slot)
    local director = Instance.find(gm.constants.oDirectorControl)
    local hud = Instance.find(gm.constants.oHUD)
    local player = Player.get_client()

    local _survivor = gm.array_get(Class.SURVIVOR, player.class)
    local _difficulty = gm.array_get(Class.DIFFICULTY, gm.variable_global_get("diff_level"))


    -- Base save table
    local save = {
        char_str = gm.array_get(_survivor, 2),
        diff_str = gm.array_get(_difficulty, 2),
        date = gm.date_current_datetime(),
        stages_passed = director.stages_passed + 1,     -- Doesn't yet increment at the time of saving this
        
        stage = current_stage,
        stage_current_level = gm.variable_global_get("stage_current_level"),
        time_start = director.time_start,
        time_total = director.time_total,
        enemy_buff = director.enemy_buff,
        difficulty = gm.array_get(_difficulty, 0).."-"..gm.array_get(_difficulty, 1),
        artifacts = {},

        class = player.class,
        level = director.player_level,
        gold = hud.gold,
        exp = director.player_exp,
        exp_req = director.player_exp_required,
        infusion_hp = player.infusion_hp,
        skin_current = player.skin_current,
        equipment = "",
        skills = {
            gm.array_get(player.skills, 0).default_skill.skill_id,
            gm.array_get(player.skills, 1).default_skill.skill_id,
            gm.array_get(player.skills, 2).default_skill.skill_id,
            gm.array_get(player.skills, 3).default_skill.skill_id
        },
        items = {},
        drones = {},
        
        game_report = {},
    }


    -- Artifacts
    local count = gm.variable_global_get("count_artifact")
    for i = 0, count - 1 do
        local _artifact = gm.array_get(Class.ARTIFACT, i)
        table.insert(save.artifacts, gm.array_get(_artifact, 8))
    end

    -- Equipment
    local equip_id = gm.equipment_get(player)
    if equip_id >= 0 then
        local equip = gm.array_get(Class.EQUIPMENT, gm.equipment_get(player))
        save.equipment = gm.array_get(equip, 0).."-"..gm.array_get(equip, 1)
    end

    -- Items
    local size = gm.array_length(player.inventory_item_order)
    if size > 0 then
        for i = 0, size - 1 do
            local id = gm.array_get(player.inventory_item_order, i)
            local item = Item.get_data(id)
            table.insert(save.items, {
                item.namespace.."-"..item.identifier,
                Item.get_stack_count(player, id, Item.TYPE.real),
                Item.get_stack_count(player, id, Item.TYPE.temporary)
            })
        end
    end

    -- Drones
    local drones_n = {"1", "2,", "3", "4", "5", "6", "7", "8", "9", "10", "Golem"}
    local drones_s = {"", "B", "S"}
    for _, n in ipairs(drones_n) do
        for _, s in ipairs(drones_s) do
            local drone_type = "oDrone"..n..s 
            local drone_obj = gm.constants[drone_type]
            if drone_obj then
                local drone_insts = Instance.find_all(drone_obj)
                for _, d in ipairs(drone_insts) do
                    if d.master == player then
                        if not save.drones[drone_type] then save.drones[drone_type] = 0 end
                        save.drones[drone_type] = save.drones[drone_type] + 1
                    end
                end
            end
        end
    end

    -- Game Report
    local names = gm.struct_get_names(player.game_report)
    for _, n in ipairs(names) do
        save.game_report[n] = gm.struct_get(player.game_report, n)
    end

    
    -- Save to saves table
    saves[slot] = save
    pcall(toml.encodeToFile, {saves = saves}, {file = file_path, overwrite = true})
    log.info("Saved to Slot "..slot)
end