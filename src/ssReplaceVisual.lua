---------------------------------------------------------------------------------------------------------
-- SCRIPT TO ADD PHYSICAL SNOW LAYERS
---------------------------------------------------------------------------------------------------------
-- Purpose:  to create plowable snow on the ground
-- Authors:  mrbear
--

ssReplaceVisual = {}

function ssReplaceVisual:loadMap(name)
    -- General initalization
    -- g_currentMission.environment:addHourChangeListener(self)
    ssSeasonsMod:addSeasonChangeListener(self)

    self.textureReplacements={}
    self.textureReplacements["Spring"]={}
    self.textureReplacements["Summer"]={}
    self.textureReplacements["Autumn"]={}
    self.textureReplacements["Winter"]={}
    self.textureReplacements["Default"]={}
    self.textureReplacements["Spring"]["tree5m"]={}
    self.textureReplacements["Spring"]["tree5m"]["tree5m"]={}
    self.textureReplacements["Spring"]["tree5m"]["tree5m"]["replacementName"]="ssTr_treeBranch_spring"

    self.textureReplacements["Summer"]["pine_stage3"]={}
    self.textureReplacements["Summer"]["pine_stage3"]["attachments"]={}
    self.textureReplacements["Summer"]["pine_stage3"]["attachments"]["replacementName"]="ssTr_pineBranch_spring"

    self.textureReplacements["Winter"]["pine_stage3"]={}
    self.textureReplacements["Winter"]["pine_stage3"]["attachments"]={}
    self.textureReplacements["Winter"]["pine_stage3"]["attachments"]["replacementName"]="ssTr_pineBranch_spring"

    local modReplacements = loadI3DFile(ssSeasonsMod.modDir .. "resources/replacementTexturesMaterialHolder.i3d") -- Loading materialHolder

    ssReplaceVisual:loadTextureIdTable(getRootNode()) -- Built into map
    ssReplaceVisual:loadTextureIdTable(modReplacements)
    ssReplaceVisual:updateTextures(getRootNode())
end

function ssReplaceVisual:deleteMap()
end

function ssReplaceVisual:mouseEvent(posX, posY, isDown, isUp, button)
end

function ssReplaceVisual:keyEvent(unicode, sym, modifier, isDown)
end

function ssReplaceVisual:draw()
end

function ssReplaceVisual:seasonChanged()
    log("Season changed into "..ssSeasonsUtil:seasonName())
    ssReplaceVisual:updateTextures(getRootNode())
end

function ssReplaceVisual:hourChanged()
end

-- Stefan Geiger - GIANTS Software (https://gdn.giants-software.com/thread.php?categoryId=16&threadId=664)
function findNodeByName(nodeId, name)
    if getName(nodeId) == name then
        return nodeId
    end
    for i=0, getNumOfChildren(nodeId)-1 do
        local tmp = findNodeByName(getChildAt(nodeId, i), name)
        if tmp ~= nil then
            return tmp
        end
    end
    return nil
end

--
-- Texture replacement
--

-- Finds the Id for the replacement materials and adds it to self.textureReplacements.
-- Searchbase is the root node of a loaded I3D file.
function ssReplaceVisual:loadTextureIdTable(searchBase)
    for seasonName,seasonTable in pairs(self.textureReplacements) do
        for shapeName,shapeNameTable in pairs(seasonTable) do
            for secondaryNodeName,  secondaryNodeTable in pairs(shapeNameTable) do
                local materialSrcId = findNodeByName(searchBase, secondaryNodeTable["replacementName"])
                if materialSrcId ~= nil then -- Can be defined in an other I3D file.
                    -- print("Loading mapping for texture replacement: Shapename: " .. shapeName .. " secondaryNodeName: " .. secondaryNodeName .. " searchBase: " .. searchBase .. " season: " .. seasonName .. " Value: " .. secondaryNodeTable["replacementName"] .. " materialID: " .. materialSrcId )
                    self.textureReplacements[seasonName][shapeName][secondaryNodeName]["materialId"] = getMaterial(materialSrcId, 0)
                    if self.textureReplacements["Default"][shapeName] == nil then
                        self.textureReplacements["Default"][shapeName]={}
                    end
                    if self.textureReplacements["Default"][shapeName][secondaryNodeName] == nil then
                        self.textureReplacements["Default"][shapeName][secondaryNodeName]={}
                    end
                    self.textureReplacements["Default"][shapeName][secondaryNodeName]["materialId"] = ssReplaceVisual:findOriginalMaterial(getRootNode(), shapeName, secondaryNodeName)
                end
            end
        end
    end
end

-- Finds the material of the original Shape object
function ssReplaceVisual:findOriginalMaterial(searchBase, shapeName, secondaryNodeName)
    -- print("Searching for object: " .. shapeName .. "/" .. secondaryNodeName .. " under " .. searchBase )
    local parentShapeId=findNodeByName(searchBase, shapeName)
    local childShapeId
    local materialId
    -- print("DEBUG: " .. parentShapeId )
    if parentShapeId ~= nil then
        childShapeId=(findNodeByName(parentShapeId, secondaryNodeName))
        if childShapeId ~= nil then
            materialId=getMaterial(childShapeId, 0)
            -- print("Found materialID: " .. materialId .. " for childobject " ..  childShapeId .. ".")
        end
    end
    return materialId
end

-- Walks the node tree and replaces materials according to season as specified in self.textureReplacements
function ssReplaceVisual:updateTextures(nodeId)
    local currentSeason=ssSeasonsUtil:seasonName()
    if self.textureReplacements[currentSeason][getName(nodeId)] ~= nil then
        for secondaryNodeName, secondaryNodeTable in pairs(self.textureReplacements[currentSeason][getName(nodeId)]) do
            -- print("Asking for texture change: " .. getName(nodeId) .. " (" .. nodeId .. ")/" .. secondaryNodeName .. " to " .. secondaryNodeTable["materialId"] .. ".")
            ssReplaceVisual:updateTexturesSubNode(nodeId,secondaryNodeName,secondaryNodeTable["materialId"])
        end
    elseif self.textureReplacements["Default"][getName(nodeId)] ~= nil then
        for secondaryNodeName, secondaryNodeTable in pairs(self.textureReplacements["Default"][getName(nodeId)]) do
            -- print("Asking for texture change: " .. getName(nodeId) .. " (" .. nodeId .. ")/" .. secondaryNodeName .. " to " .. secondaryNodeTable["materialId"] .. ".")
            ssReplaceVisual:updateTexturesSubNode(nodeId,secondaryNodeName,secondaryNodeTable["materialId"])
        end
    end
    for i=0, getNumOfChildren(nodeId)-1 do
        local tmp = ssReplaceVisual:updateTextures(getChildAt(nodeId, i), name)
        if tmp ~= nil then
            return tmp
        end
    end
    return nil
end

-- Does a specified replacement on subnodes of nodeId.
function ssReplaceVisual:updateTexturesSubNode(nodeId, shapeName, materialSrcId)
    if getName(nodeId) == shapeName then
        -- print("Setting texture for " .. getName(nodeId) .. " (" .. nodeId .. ") to " .. materialSrcId .. ".")
        setMaterial(nodeId, materialSrcId, 0)
    end
    for i=0, getNumOfChildren(nodeId)-1 do
        local tmp = ssReplaceVisual:updateTexturesSubNode(getChildAt(nodeId, i), shapeName, materialSrcId)
        if tmp ~= nil then
            return tmp
        end
    end
    return nil
end

function ssReplaceVisual:update(dt)
end
