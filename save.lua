-- Save

function save_to_slot(slot)
    local director = Instance.find(gm.constants.oDirectorControl)
    local hud = Instance.find(gm.constants.oHUD)
    local player = Player.get_client()

    local _survivor = class_survivor[player.class + 1]
    local _difficulty = class_difficulty[gm.variable_global_get("diff_level") + 1]


    -- Base save table
    local save = {
        char_str = _survivor[3],
        diff_str = _difficulty[3],
        date = gm.date_current_datetime(),
        stages_passed = director.stages_passed + 1,     -- Doesn't yet increment at the time of saving this
        
        stage = current_stage,
        stage_current_level = gm.variable_global_get("stage_current_level"),
        time_start = director.time_start,
        time_total = director.time_total,
        enemy_buff = director.enemy_buff,
        difficulty = _difficulty[1].."-".._difficulty[2],
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
            player.skills[1].default_skill.skill_id,
            player.skills[2].default_skill.skill_id,
            player.skills[3].default_skill.skill_id,
            player.skills[4].default_skill.skill_id
        },
        items = {},
        drones = {},
        
        game_report = {},
    }


    -- Artifacts
    local count = gm.variable_global_get("count_artifact")
    for i = 1, count do
        table.insert(save.artifacts, class_artifact[i][9])
    end

    -- Equipment
    local equip = class_equipment[gm.equipment_get(player) + 1]
    if equip then save.equipment = equip[1].."-"..equip[2] end

    -- Items
    if gm.array_length(player.inventory_item_order) > 0.0 then
        for _, i in ipairs(player.inventory_item_order) do
            local item = Item.get_data(i)
            table.insert(save.items, {
                item.namespace.."-"..item.identifier,
                Item.get_stack_count(player, i, Item.TYPE.real),
                Item.get_stack_count(player, i, Item.TYPE.temporary)
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