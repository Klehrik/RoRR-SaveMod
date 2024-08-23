-- Helper

function seconds_to_minutes(seconds)
    return math.floor(seconds / 60), math.floor(seconds % 60)
end


function get_name(local_str)
    -- Accounts for stuff that doesn't use localization strings
    local l = gm.ds_map_find_value(lang_map, local_str)
    if l then return l end
    return local_str
end


function delete_save_slot(slot)
    if slot == 0 then return end
    
    current_file = 0
    table.remove(saves, slot)
    pcall(toml.encodeToFile, {saves = saves}, {file = file_path, overwrite = true})
    
    log.info("Deleted Slot "..slot)
end