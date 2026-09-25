-- Micro 2.0.15 cannot decode native horizontal wheel events on Unix terminals.
-- Control plus vertical wheel pans the viewport without moving the cursor.
local horizontal_scroll_step = 6

local function scroll_horizontal(bp, delta)
    local view = bp:GetView()
    view.StartCol = math.max(0, view.StartCol + delta)
end

function scrollLeft(bp)
    scroll_horizontal(bp, -horizontal_scroll_step)
    return true
end

function scrollRight(bp)
    scroll_horizontal(bp, horizontal_scroll_step)
    return true
end
