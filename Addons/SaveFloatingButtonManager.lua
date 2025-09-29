local httpService = game:GetService("HttpService")

local FloatingButtonManager = {}
FloatingButtonManager.Folder = "FloatingButtons"
FloatingButtonManager.Buttons = {}
FloatingButtonManager.Library = nil

local function serializeUDim2(u)
    return {
        ScaleX = u.X.Scale, OffsetX = u.X.Offset,
        ScaleY = u.Y.Scale, OffsetY = u.Y.Offset
    }
end

local function deserializeUDim2(t)
    return UDim2.new(t.ScaleX, t.OffsetX, t.ScaleY, t.OffsetY)
end

function FloatingButtonManager:BuildFolderTree()
    local paths = { self.Folder, self.Folder .. "/settings" }
    for _, path in ipairs(paths) do
        if not isfolder(path) then makefolder(path) end
    end
end
FloatingButtonManager:BuildFolderTree()

function FloatingButtonManager:AddButton(id, frame)
    self.Buttons[id] = frame
end

function FloatingButtonManager:Save(name)
    local path = self.Folder .. "/settings/" .. name .. ".json"
    local data = {}
    for id, frame in pairs(self.Buttons) do
        data[id] = {
            size = serializeUDim2(frame.Size),
            position = serializeUDim2(frame.Position)
        }
    end
    local success, encoded = pcall(httpService.JSONEncode, httpService, data)
    if not success then return false, "encode failed" end
    writefile(path, encoded)
    return true
end

function FloatingButtonManager:Load(name)
    local path = self.Folder .. "/settings/" .. name .. ".json"
    if not isfile(path) then return false, "no such file" end
    local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(path))
    if not success then return false, "decode failed" end
    for id, saved in pairs(decoded) do
        local frame = self.Buttons[id]
        if frame then
            frame.Size = deserializeUDim2(saved.size)
            frame.Position = deserializeUDim2(saved.position)
        end
    end
    return true
end

function FloatingButtonManager:RefreshConfigList()
    local list = listfiles(self.Folder .. "/settings")
    local out = {}
    for _, file in ipairs(list) do
        if file:sub(-5) == ".json" then
            local pos = file:find(".json", 1, true)
            local p = pos
            local char = file:sub(p, p)
            while char ~= "/" and char ~= "\\" and char ~= "" do
                p = p - 1
                char = file:sub(p, p)
            end
            local name = file:sub(p + 1, pos - 1)
            table.insert(out, name)
        end
    end
    return out
end

function FBM:SetLibrary(library)
    self.Library = library
    self.Options = library.Options
end

function FloatingButtonManager:BuildConfigSection(tab)
    assert(self.Library, "Must set FloatingButtonManager.Library")

    local section = tab:AddSection("Floating Buttons Config")

    section:AddInput("FB_ConfigName", { Title = "Layout name" })
    section:AddDropdown("FB_ConfigList", {
        Title = "Layouts list",
        Values = self:RefreshConfigList(),
        AllowNull = true
    })

    section:AddButton({
        Title = "Create layout",
        Callback = function()
            local name = self.Library.Options.FB_ConfigName.Value
            if name:gsub(" ", "") == "" then
                return self.Library:Notify({
                    Title = "Floating Buttons",
                    Content = "Invalid layout name",
                    Duration = 5
                })
            end
            local success, err = self:Save(name)
            if not success then
                return self.Library:Notify({
                    Title = "Floating Buttons",
                    Content = "Failed to save: " .. err,
                    Duration = 5
                })
            end
            self.Library:Notify({
                Title = "Floating Buttons",
                Content = string.format("Saved layout %q", name),
                Duration = 5
            })
            self.Library.Options.FB_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.FB_ConfigList:SetValue(nil)
        end
    })

    section:AddButton({
        Title = "Load layout",
        Callback = function()
            local name = self.Library.Options.FB_ConfigList.Value
            local success, err = self:Load(name)
            if not success then
                return self.Library:Notify({
                    Title = "Floating Buttons",
                    Content = "Failed to load: " .. err,
                    Duration = 5
                })
            end
            self.Library:Notify({
                Title = "Floating Buttons",
                Content = string.format("Loaded layout %q", name),
                Duration = 5
            })
        end
    })

    section:AddButton({
        Title = "Overwrite layout",
        Callback = function()
            local name = self.Library.Options.FB_ConfigList.Value
            local success, err = self:Save(name)
            if not success then
                return self.Library:Notify({
                    Title = "Floating Buttons",
                    Content = "Failed to overwrite: " .. err,
                    Duration = 5
                })
            end
            self.Library:Notify({
                Title = "Floating Buttons",
                Content = string.format("Overwrote layout %q", name),
                Duration = 5
            })
        end
    })

    section:AddButton({
        Title = "Refresh list",
        Callback = function()
            self.Library.Options.FB_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.FB_ConfigList:SetValue(nil)
        end
    })

    local autoPath = self.Folder .. "/settings/autoload.txt"
    local AutoloadButton
    AutoloadButton = section:AddButton({
        Title = "Set as autoload",
        Description = "Current autoload layout: none",
        Callback = function()
            local name = self.Library.Options.FB_ConfigList.Value
            if isfile(autoPath) then
                delfile(autoPath)
                AutoloadButton:SetDesc("Current autoload layout: none")
                self.Library:Notify({
                    Title = "Floating Buttons",
                    Content = "Autoload disabled",
                    Duration = 5
                })
            else
                writefile(autoPath, name)
                AutoloadButton:SetDesc("Current autoload layout: " .. name)
                self.Library:Notify({
                    Title = "Floating Buttons",
                    Content = string.format("Set %q to autoload", name),
                    Duration = 5
                })
            end
        end
    })
    if isfile(autoPath) then
        local name = readfile(autoPath)
        AutoloadButton:SetDesc("Current autoload layout: " .. name)
    end
end

return FloatingButtonManager
