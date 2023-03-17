ConstructionBrushPlaceable.verifyAccess = Utils.overwrittenFunction(ConstructionBrushPlaceable.verifyAccess, function (self, superFunc, x, y, z)
    local specName = "spec_FS22_SpeedDisplay.placeableSpeedDisplay"
    local speedDisplaySpec = self.placeable[specName]
    print("farmlandId: " .. tostring(g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)))
    print("NO_OWNER_FARM_ID: " .. FarmlandManager.NOT_BUYABLE_FARM_ID)

    if SpecializationUtil.hasSpecialization(PlaceableSpeedDisplay, self.placeable.specializations) then
        if not self:hasPlayerPermission() then
            return ConstructionBrush.ERROR.NO_PERMISSION
        elseif g_farmlandManager:getFarmlandIdAtWorldPosition(x, z) == FarmlandManager.NOT_BUYABLE_FARM_ID then
            return nil
        else
            return superFunc(self, x, y, z)
        end
    else
        return superFunc(self, x, y, z)
    end
end)