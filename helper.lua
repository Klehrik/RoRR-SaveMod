-- Helper

function seconds_to_minutes(seconds)
    return math.floor(seconds / 60), math.floor(seconds % 60)
end


function delete_save_slot(slot)
    if slot == 0 then return end
    
    current_file = 0
    table.remove(saves, slot)
    pcall(toml.encodeToFile, {saves = saves}, {file = file_path, overwrite = true})
    
    log.info("Deleted Slot "..slot)
end