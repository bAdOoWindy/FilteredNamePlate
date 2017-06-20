FilteredNamePlate = {}
function FilteredNamePlate:printCurrentScaleList(sl)
    print("Curr SYSTEM "..sl.SYSTEM..(" normal ")..sl.normal..(" only ")..sl.only)
    print("Curr other "..sl.other..(" orgwidht ")..sl.orgWidth..(" smallWidth ")..sl.smallWidth)
end

function FilteredNamePlate:printSavedScaleList(sl)
    print("Saved other "..sl.other..(" only ")..sl.only..(" normal ")..sl.normal)
end

function FilteredNamePlate:insertATabValue(tab, value)
    local isExist = false;
    for pos, name in ipairs(tab) do
        if (name == value) then
            isExist = true;
        end
    end
    if not isExist then table.insert(tab, value) end;
end

function FilteredNamePlate:removeATabValue(tab, value)
    for pos, name in ipairs(tab) do
        if (name == value) then
            table.remove(tab, pos)
        end
    end
end