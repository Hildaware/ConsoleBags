local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ConsoleBags" then
        if ConsoleBagsDB then
            CouchModeDB = CouchModeDB or {}
            if not CouchModeDB.profiles then return end
            if not CouchModeDB.profiles.Default then return end
            if CouchModeDB.profiles.Default.bags then return end
            CouchModeDB.profiles.Default.bags = ConsoleBagsDB.Bags.global
            ConsoleBagsDB = nil
            print("|cFF00FF00[CouchMode]|r: Successfully migrated your old ConsoleBags settings!")
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
