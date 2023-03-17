ConstructionBrushPlaceable.verifyAccess = Utils.overwrittenFunction(ConstructionBrushPlaceable.verifyAccess, function (self, superFunc, x, y, z)
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