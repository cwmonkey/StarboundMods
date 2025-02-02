-- Make sure to run old hooks before ours
light_and_animation_switches_for_objects_fuInit = init
light_and_animation_switches_for_objects_fuUpdate = update
light_and_animation_switches_for_objects_fuOnNodeConnectionChange = onNodeConnectionChange
light_and_animation_switches_for_objects_fuOnInputNodeChange = onInputNodeChange

function init()
  if light_and_animation_switches_for_objects_fuInit then light_and_animation_switches_for_objects_fuInit() end

  if storage.state == nil then storage.state = config.getParameter("defaultLightState", true) end

  self.defaultLightInput = config.getParameter("defaultLightInput", 0)
  self.animationStateType = config.getParameter("animationStateType", "light")
  self.animationStateOn = config.getParameter("animationStateOn", "on")
  self.animationStateOff = config.getParameter("animationStateOff", "off")
  self.animationStateIdle = config.getParameter("animationStateIdle", nil)

  if config.getParameter("inputNodes") then
    processWireInput()
  end

  setLightState(storage.state)
end

function update(dt)
  if light_and_animation_switches_for_objects_fuUpdate then light_and_animation_switches_for_objects_fuUpdate(dt) end

  -- sb.logInfo(config.getParameter("objectName", "unknown"))

  -- If the state is "idle" then we want to turn it off if the switch is off
  if self.animationStateIdle then
    if animator.animationState(self.animationStateType) == self.animationStateIdle and not storage.state then
      animator.setAnimationState(self.animationStateType, self.animationStateOff)
    end
  end
end

function onNodeConnectionChange(args)
  if light_and_animation_switches_for_objects_fuOnNodeConnectionChange then light_and_animation_switches_for_objects_fuOnNodeConnectionChange(args) end
  processWireInput()
end

function onInputNodeChange(args)
  if light_and_animation_switches_for_objects_fuOnInputNodeChange then light_and_animation_switches_for_objects_fuOnInputNodeChange(args) end
  processWireInput()
end

function processWireInput()
  if object.isInputNodeConnected(self.defaultLightInput) then
    storage.state = object.getInputNodeLevel(self.defaultLightInput)
    setLightState(storage.state)
  end
end

function setLightState(newState)
  -- TODO: cleanup/DRY
  -- upgradeable machine
  if self.stageDataList and storage.currentStage and self.stageDataList[storage.currentStage] then
    local stageData = self.stageDataList[storage.currentStage]

    if newState then
      animator.setAnimationState("stage", stageData.animationState)
      if stageData.lightColor then
        object.setLightColor(stageData.lightColor)
      elseif config.getParameter("lightColor") then
        object.setLightColor(config.getParameter("lightColor"))
      end
    else
      if stageData.idleState then
        animator.setAnimationState("stage", stageData.idleState)
      end
      object.setLightColor(config.getParameter("lightColorOff", {0, 0, 0}))
    end
  -- other machine
  else
    -- I have no idea why, but using "self.*" here for "fu_blastfurnace" causes a type error

    if newState then
      animator.setAnimationState(self.animationStateType, self.animationStateOn)
      object.setSoundEffectEnabled(true)
      if animator.hasSound(self.animationStateOn) then
        animator.playSound(self.animationStateOn);
      end
      --TODO: support lightColors configuration
      object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
    else
      animator.setAnimationState(self.animationStateType, self.animationStateOff)
      object.setSoundEffectEnabled(false)
      if animator.hasSound("off") then
        animator.playSound("off");
      end
      object.setLightColor(config.getParameter("lightColorOff", {0, 0, 0}))
    end
  end
end
