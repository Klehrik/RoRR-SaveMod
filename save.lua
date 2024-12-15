-- Save

function save_to_slot(slot)
    local director = Instance.find(gm.constants.oDirectorControl)
    local hud = Instance.find(gm.constants.oHUD)
    local player = Player.get_client()

    local _survivor = Survivor.wrap(player.class)
    local _difficulty = Difficulty.wrap(gm.variable_global_get("diff_level"))


    -- Base save table
    local save = {
        char_str = _survivor.token_name,
        diff_str = _difficulty.token_name,
        date = gm.date_current_datetime(),
        stages_passed = director.stages_passed + 1,     -- Doesn't yet increment at the time of saving this
        
        stage = current_stage,
        stage_current_level = gm.variable_global_get("stage_current_level"),
        time_start = director.time_start,
        time_total = director.time_total,
        enemy_buff = director.enemy_buff,
        difficulty = _difficulty.namespace.."-".._difficulty.identifier,
        artifacts = {},

        class = _survivor.namespace.."-".._survivor.identifier,
        level = director.player_level,
        gold = hud.gold,
        exp = director.player_exp,
        exp_req = director.player_exp_required,
        infusion_hp = player.infusion_hp,
        skin_current = player.skin_current,
        equipment = "",
        skills = {},
        items = {},
        drones = {},
        
        game_report = {}
    }


    -- Artifacts
    local count = gm.variable_global_get("count_artifact")
    for i = 0, count - 1 do
        local _artifact = Artifact.wrap(i)
        if Helper.is_true(_artifact.active) then
            table.insert(save.artifacts, _artifact.namespace.."-".._artifact.identifier)
        end
    end

    -- Skills
    for s = 1, 4 do
        local skill = Skill.wrap(player:get_default_skill(s - 1).skill_id)
        save.skills[s] = skill.namespace.."-"..skill.identifier
    end

    -- Equipment
    local equip = player:get_equipment()
    if equip then save.equipment = equip.namespace.."-"..equip.identifier end

    -- Items
    local size = #player.inventory_item_order
    if size > 0 then
        for i = 0, size - 1 do
            local id = player.inventory_item_order:get(i)
            local item = Item.wrap(id)
            table.insert(save.items, {
                item.namespace.."-"..item.identifier,
                player:item_stack_count(item, Item.STACK_KIND.normal),
                player:item_stack_count(item, Item.STACK_KIND.temporary_blue)
            })
        end
    end

    -- Drones
    local drones_n = {"1", "2,", "3", "4", "5", "6", "7", "8", "9", "10", "Golem"}
    local drones_s = {"", "B", "S"}
    for _, n in ipairs(drones_n) do
        for _, s in ipairs(drones_s) do
            local drone_type = "drone"..n..s 
            local drone_obj = Object.find("ror", drone_type)
            if drone_obj then
                local drone_insts = Instance.find_all(drone_obj)
                for _, d in ipairs(drone_insts) do
                    if d.master:same(player) then
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