PlaceableSpeedDisplay = {
    modName = g_currentModName,
    specName = "placeableSpeedDisplay",
    prerequisitesPresent = function (specializations)
        return true
    end
}

PlaceableSpeedDisplay.specPath = "spec_" .. PlaceableSpeedDisplay.modName .. "." .. PlaceableSpeedDisplay.specName

function PlaceableSpeedDisplay.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onSpeedDisplayTriggerCallback", PlaceableSpeedDisplay.onSpeedDisplayTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "setDisplayNumbers", PlaceableSpeedDisplay.setDisplayNumbers)
end

function PlaceableSpeedDisplay.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSpeedDisplay.onLoad)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSpeedDisplay.onDelete)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSpeedDisplay)
end

function PlaceableSpeedDisplay.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("SpeedDisplay")
    basePath = basePath .. ".speedDisplay"

    schema:register(XMLValueType.NODE_INDEX,    basePath .. "#triggerNode", "Trigger of speed display. When driving thogh the speed is measured.")
    schema:register(XMLValueType.NODE_INDEX,    basePath .. "#triggerMarkers", "Show trigger marker during placement to show where the trigger is. When placing hide trigger markers")
    schema:register(XMLValueType.INT,           basePath .. "#speedLimit", "The allowed speed limit of the vehicle. When Speed is higher than this the text will be in another color", 50)
    schema:register(XMLValueType.NODE_INDEX,    basePath .. ".display(?)#node", "Display start node")
	schema:register(XMLValueType.STRING,        basePath .. ".display(?)#font", "Display font name")
	schema:register(XMLValueType.STRING,        basePath .. ".display(?)#alignment", "Display text alignment")
	schema:register(XMLValueType.FLOAT,         basePath .. ".display(?)#size", "Display text size")
	schema:register(XMLValueType.FLOAT,         basePath .. ".display(?)#scaleX", "Display text x scale")
	schema:register(XMLValueType.FLOAT,         basePath .. ".display(?)#scaleY", "Display text y scale")
	schema:register(XMLValueType.STRING,        basePath .. ".display(?)#mask", "Display text mask")
	schema:register(XMLValueType.FLOAT,         basePath .. ".display(?)#emissiveScale", "Display emissive scale")
	schema:register(XMLValueType.COLOR,         basePath .. ".display(?)#colorFine", "Display text color when driving below the speed limit")
    schema:register(XMLValueType.COLOR,         basePath .. ".display(?)#colorTooFast", "Display text color when driving above the speed limit")
	schema:register(XMLValueType.COLOR,         basePath .. ".display(?)#hiddenColor", "Display text hidden color")
	schema:setXMLSpecializationType()
end
--load from xml file of the storeItem
function PlaceableSpeedDisplay:onLoad(savegame)
    local spec = self[PlaceableSpeedDisplay.specPath]
    local key = "placeable.speedDisplay"

    spec.trigger = self.xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)

    if spec.trigger == nil then
        Logging.xmlError(self.xmlFile, "missing vehicle trigger for speed display")

        return
    end

    addTrigger(spec.trigger, "onSpeedDisplayTriggerCallback", self)

    spec.triggerMarkers = self.xmlFile:getValue(key .. "#triggerMarkers", nil, self.components, self.i3dMappings)

    if spec.triggerMarkers == nil then
        Logging.xmlWarning(self.xmlFile, "Missing trigger markers. User can't see trigger position during placement.")
    else
        setVisibility(spec.triggerMarkers, true)
    end

    spec.speedLimit = self.xmlFile:getValue(key .. "#speedLimit", 50)

    spec.vehicle = {}
    spec.displays = {}

    --load displays
    self.xmlFile:iterate(key .. ".display", function (_, displayKey)
        local displayNode = self.xmlFile:getValue(displayKey .. "#node", nil, self.components, self.i3dMappings)

		if displayNode ~= nil then
			local fontName = self.xmlFile:getValue(displayKey .. "#font", "DIGIT"):upper()
			local fontMaterial = g_materialManager:getFontMaterial(fontName, self.customEnvironment)

			if fontMaterial ~= nil then
				local display = {}
				local alignmentStr = self.xmlFile:getValue(displayKey .. "#alignment", "RIGHT")
				local alignment = RenderText["ALIGN_" .. alignmentStr:upper()] or RenderText.ALIGN_RIGHT
				local size = self.xmlFile:getValue(displayKey .. "#size", 1)
				local scaleX = self.xmlFile:getValue(displayKey .. "#scaleX", 1)
				local scaleY = self.xmlFile:getValue(displayKey .. "#scaleY", 1)
				local mask = self.xmlFile:getValue(displayKey .. "#mask", "00")
				local emissiveScale = self.xmlFile:getValue(displayKey .. "#emissiveScale", 0.2)
				local colorFine = self.xmlFile:getValue(displayKey .. "#colorFine", {
					0,
					1,
					0,
					1
				}, true)
                local colorTooFast = self.xmlFile:getValue(displayKey .. "#colorTooFast", colorFine, true)
				local hiddenColor = self.xmlFile:getValue(displayKey .. "#hiddenColor", nil, true)
				display.displayNode = displayNode
				display.formatStr, display.formatPrecision = string.maskToFormat(mask)
				display.fontMaterial = fontMaterial
				display.characterLineFine = fontMaterial:createCharacterLine(display.displayNode, mask:len(), size, colorFine, hiddenColor, emissiveScale, scaleX, scaleY, alignment)
				display.characterLineTooFast = fontMaterial:createCharacterLine(display.displayNode, mask:len(), size, colorTooFast, hiddenColor, emissiveScale, scaleX, scaleY, alignment)

				table.insert(spec.displays, display)
			end
		end
    end)

    self:setDisplayNumbers(0)
end

--save to placeable xml of savegame
function PlaceableSpeedDisplay:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[PlaceableSpeedDisplay.specPath]

    xmlFile:setValue(key .. "#speedLimit", spec.speedLimit or 50)
end

-- load from placeable xml of savegame
function PlaceableSpeedDisplay:loadFromXMLFile(xmlFile, key)
    local spec = self[PlaceableSpeedDisplay.specPath]

    spec.speedLimit = xmlFile:getValue(key .. "#speedLimit", 50)
end

function PlaceableSpeedDisplay:onDelete()
    local spec = self[PlaceableSpeedDisplay.specPath]

    if spec.trigger ~= nil then
        removeTrigger(spec.trigger)

        spec.trigger = nil
    end
end

function PlaceableSpeedDisplay:onFinalizePlacement()
    local spec = self[PlaceableSpeedDisplay.specPath]

    if spec.triggerMarkers ~= nil then
        setVisibility(spec.triggerMarkers, false)
    end
end

function PlaceableSpeedDisplay:setDisplayNumbers(speed)
    local spec = self[PlaceableSpeedDisplay.specPath]

    if speed == 0 then
        for _, display in pairs(spec.displays) do
            setVisibility(display.displayNode, false)
        end
    else
        for _, display in pairs(spec.displays) do
            setVisibility(display.displayNode, true)

            local int, floatPart = math.modf(speed)
            local value = string.format(display.formatStr, int, math.abs(math.floor(floatPart * 10^display.formatPrecision)))

            local characterLine = display.characterLineFine
            if speed > spec.speedLimit then
                characterLine = display.characterLineTooFast
            end
		    display.fontMaterial:updateCharacterLine(characterLine, value)
        end
    end
end

function PlaceableSpeedDisplay:onSpeedDisplayTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self[PlaceableSpeedDisplay.specPath]
    if onEnter then
        local vehicle = g_currentMission:getNodeObject(otherId)

        if vehicle ~= nil and vehicle.spec_driveable ~= nil and vehicle.spec_enterable and vehicle.spec_motorized then
            spec.vehicle = vehicle
        end
    end

    if onEnter or onStay then
        local speed = MathUtil.round(spec.vehicle:getLastSpeed())

        self:setDisplayNumbers(speed)
    elseif onLeave then
        spec.vehicle = {}
        self:setDisplayNumbers(0)
    end
end