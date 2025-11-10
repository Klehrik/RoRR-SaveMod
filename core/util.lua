-- Util

function scribble_draw_with_shadow(x, y, str)
    local bstr = "<bl>"..str:gsub("<.->", "")
    if str:find("<fa_right>")   then bstr = "<fa_right>"..bstr end
    local xs = {1, 1, 0}
    local ys = {0, 1, 1}
    for i = 1, #xs do
        gm.scribble_draw(x + xs[i], y + ys[i], bstr)
    end
    gm.scribble_draw(x, y, str)
end


function draw_arrow(x, y, dir, scale)
    dir   = dir   or 1
    scale = scale or 1
    gm.draw_triangle(
        x - 6*dir*scale, y - 10*scale,
        x + 6*dir*scale, y,
        x - 6*dir*scale, y + 10*scale,
        false
    )
end


function seconds_to_minutes(seconds)
    local min, sec = math.floor(seconds / 60), math.floor(seconds % 60)
    return min, sec
end


function format_color_to_hex(col)
    col = string.format("%x", Color.to_hex(col))
    while #col < 6 do col = "0"..col end
    return col
end


function format_time(seconds)
    local min, sec = seconds_to_minutes(seconds)
    if min < 10 then min = "0"..min end
    if sec < 10 then sec = "0"..sec end
    return min, sec
end


function format_date(date)
    return math.floor(gm.date_get_year(date)),
           math.floor(gm.date_get_month(date)),
           math.floor(gm.date_get_day(date))
end