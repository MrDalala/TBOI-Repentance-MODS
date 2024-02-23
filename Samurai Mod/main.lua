local mod = RegisterMod("Samurai Mod", 1)
local sfx = SFXManager()
local swordBlockSFX = Isaac.GetSoundIdByName("Sword Block")
local samuraiSword = Isaac.GetItemIdByName("Samurai Sword")
local samuraiType = Isaac.GetPlayerTypeByName("The Samurai", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/character/The_Samurai_head.anm2")
local successfulParries = 0
local parryDamage = 0.5
local parryDistance = 70


--Adds the custom head to the character.
function mod:GiveCostumeOnInit(player)
    if player:GetPlayerType() ~= samuraiType then
        return
    end

    player:AddNullCostume(hairCostume)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumeOnInit)


-- When Samurai Sword is used, if an enemy projectile is within a radius of 80, increase
-- the player's damage by 1, deletes the projectile and isaac shoots a tear back to the enemy.
-- If sword used while a projectile is not within 80, then the item loses its charge and nothing happens.
function mod:OnSamuraiSwordUse(item)
    local player = Isaac.GetPlayer(0)
    local entities = Isaac.FindInRadius(player.Position, parryDistance, EntityPartition.BULLET) -- Bullets in a radius of 80

    if #entities > 0 then
        for _, entity in ipairs(entities) do
            local distance = entity.Position:Distance(player.Position)

            if distance < parryDistance then
                sfx:Play(swordBlockSFX, 1)
                successfulParries = successfulParries + 1
                player.Damage = player.Damage + parryDamage
                player:EvaluateItems()

                local velocity = entity.Velocity
                local direction = -velocity:Normalized()  -- Reverse the tear's velocity

                local newTear = player:FireTear(entity.Position, direction * 10, false, true, false) -- Fire tear back
                newTear.CollisionDamage = player.Damage  -- Assign player's damage value to the fired tear
                entity:Remove()

                return -- No animation and no discharge if parried successfully
                {
                    Discharge = false,
                    Remove = false,
                    ShowAnim = false
                }
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnSamuraiSwordUse, samuraiSword)

-- Removes the damage added by the Samurai Sword when Isaac enters another room.
function mod:newRoom()
    local player = Isaac.GetPlayer(0)
    player.Damage = (player.Damage - (parryDamage * successfulParries))
    successfulParries = 0
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.newRoom)
