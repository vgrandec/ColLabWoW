------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
---------------------------------- ColLab for Wow ----------------------------------------
------------------------------ Uppsala University 2013 -----------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------




------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
---------------------------------- Variable declarations ---------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


-- To be able to use several files. This way functions can be stored in the table "addon"
-- and accessed from any file, as this table will be the same for every single file in 
-- the same addon
local addonName, addon = ...

local discussion_width = 1000 
local discussion_height = 600 



------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--------------------------------- Participants window ------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


-- Auxiliary window containing the list of participants of the discussion
-- It is anchored to the main discussion window, so it moves when that one moves, etc.
-- But it can be closed independently (and reopen with a slash command)
function addon:createParticipantsWindow( prefix)

  local conflict = addon.conflicts_active_testing[prefix]
  local discussionWindow = conflict.conflict_ui.editwindow
 
  local Participantswindow = CreateFrame("Frame", "Participants" .. prefix, discussionWindow, "BasicFrameTemplate")
  Participantswindow:SetWidth(184)
  Participantswindow:SetHeight(discussion_height) -- discussionWindow:GetHeight())
  Participantswindow:SetPoint("TOPLEFT", discussionWindow, "TOPRIGHT" )
  Participantswindow:SetBackdrop({
    --bgFile = "Interface\\ACHIEVEMENTFRAME/UI-ACHIEVEMENT-ACHIEVEMENTBACKGROUND.png",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 5, bottom = 3 }
  });
  Participantswindow:SetScript("OnEvent", Participants_OnEvent) -- TODO when someone new connects, add to the list
  Participantswindow:SetScript("OnUpdate", Participants_Update)
  Participantswindow:SetMovable(true)
  Participantswindow:EnableMouse(true)
  Participantswindow:CreateTitleRegion()

    -- Title bar
  Participantswindow.header = CreateFrame("EditBox", "ParticipantsTitle of " .. prefix, Participantswindow, "InputBoxTemplate")
  Participantswindow.header:SetSize(Participantswindow:GetWidth()-10, 44)
  Participantswindow.header:SetPoint("CENTER", Participantswindow, "TOP", 5, -10)
  Participantswindow.header:SetText("Participants")
  Participantswindow.header:SetAutoFocus(false)
  Participantswindow.header:Disable()


  -- Displays list of participants as individual no editable text boxes
  conflict.conflict_ui.participants_boxes = {}
  local counter = 1
  for player_name, join in pairs(conflict.participants) do
    local player = CreateFrame("EditBox", "Participant".. tostring(counter) , Participantswindow, "InputBoxTemplate")
    player:SetHeight(85)
    player:SetWidth(175) -- participants width - 9
    table.insert(conflict.conflict_ui.participants_boxes, player)
    if (counter == 1) then
      player:SetPoint("LEFT", Participantswindow, "TOPLEFT", 7, -50)
    else
      player:SetPoint("TOP", conflict.conflict_ui.participants_boxes[counter-1], "BOTTOM")
    end
    player:SetText(player_name)
    player:SetMaxLetters(255)
    player:SetTextInsets(5, 5, 2, 2)
    player:Disable() -- No editable
    counter = counter + 1
  end
  return conflict
end



------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------ Editing stage ---------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


function proceedToVoting( button )
  addon:proceedToVoting(button)
end


function editBox_OnEnterPressed ( box )
  local name = box:GetName()
  local data, prefix = name:match("(.+):(.+)") --TODO What to do when Prefix is in the name?
  local newText = box:GetText()
  -- Request to the master to update the text for every participant
  SendAddonMessage(prefix, ("upd%s=%s"):format(data,newText), "WHISPER", addon.conflicts_active_testing[prefix].master)
  box:ClearFocus()
end




function createButtonsBar( discussion )
  local prefix = discussion:GetName():match("Discussion(.+)")
  local buttonbar = CreateFrame("Frame", "ButtonBar" .. prefix, discussion.scrollframe.content)
  buttonbar:SetSize(300 ,100) -- width, height
  buttonbar:SetPoint("CENTER", discussion.scrollframe.content, "BOTTOM", 0, 0)
  local proceedbutton = CreateFrame("Button", ("ProcB:%s"):format(prefix), buttonbar, "UIPanelButtonTemplate")
  proceedbutton:SetSize(100 ,50) -- width, height
  proceedbutton:SetText("Proceed\n to voting")
  proceedbutton:SetPoint("CENTER", buttonbar, "CENTER", 0, 70)
  proceedbutton:SetScript("OnClick", proceedToVoting)
  local abandonbutton = CreateFrame("Button", "AbandonButton", buttonbar, "UIPanelButtonTemplate")
  abandonbutton:SetSize(100 ,50) -- width, height
  abandonbutton:SetText("Abandon\n conflict")
  abandonbutton:SetPoint("CENTER", buttonbar, "RIGHT", 0, 70)
  abandonbutton:SetScript("OnClick", function()
    print("Abandon conflict clicked")
  end)
end




-- Create editboxes to display solutions and consequences for the conflict
function createEditBoxes( prefix)
  local conflict = addon.conflicts_active_testing[prefix]
  local discussion = conflict.conflict_ui.editwindow
  conflict.conflict_ui["description"] = discussion.header

  -- Create options/solutions bar
  local option_boxes = {}
  local posneg_boxes = {}
  for option_number = 1, #(conflict.conflict_data["options"]) do
    local option = CreateFrame ("EditBox", ("opt%d:%s"): format(option_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
    option:SetHeight(15)
    option:SetWidth(200)
    option_boxes[option_number] = option 
    if (option_number == 1) then
      option:SetPoint("LEFT", discussion.scrollframe.content, "TOPLEFT", 135*2,-40)--discussion.header:GetHeight()+20) -- 175 to leave space horizontally for the stakeholders column
    else
      option:SetPoint("LEFT", option_boxes[option_number-1], "RIGHT", 15, 0)    
    end

    option:SetText(conflict.conflict_data["options"][option_number])
    option:SetTextInsets(5, 5, 2, 2)
    option:SetMultiLine(true)
    option:SetAutoFocus(false)
    option:SetScript("OnEnterPressed", editBox_OnEnterPressed)

    -- Create positive/negative consequences indicators boxes (non editable)
    for counter = 1, 2 do
      -- Calculate column (even or odd and option number)
      local posneg_index = option_number*2
      if counter == 1 then
        posneg_index = posneg_index -1
      end
      local posneg = CreateFrame("EditBox", ("pos_neg%d:%s"):format(posneg_index, prefix), discussion.scrollframe.content, "InputBoxTemplate")
      posneg:SetHeight(15)
      posneg:SetWidth((option:GetWidth())/2)
      
      if (counter == 1) then
        posneg:SetPoint("TOPLEFT", option, "BOTTOMLEFT")
        posneg:SetPoint("TOPRIGHT", option, "BOTTOM")
      else
        posneg:SetPoint("TOPRIGHT", option, "BOTTOMRIGHT", 0, 0)
        posneg:SetPoint("TOPLEFT", option, "BOTTOM", 0, 0)
      end
      posneg:SetTextInsets(5, 5, 2, 2)
      posneg:SetText(conflict.conflict_data["posneg"][posneg_index])
      posneg:SetAutoFocus(false)
      posneg:SetScript("OnEnterPressed", editBox_OnEnterPressed)
      posneg:Disable()
      posneg_boxes[posneg_index] = posneg
    end
  end -- End of creation of options boxes
  conflict.conflict_ui["options"] = option_boxes
  conflict.conflict_ui["posneg"] = posneg_boxes

  -- Create stakeholders column and interests column, plus rows of consequences
  local stakeholder_boxes = {}
  local interests_boxes = {}
  local consequences_boxes = {}
 
  for stakeholder_number=1, #(conflict.conflict_data["stakeholders_names"]) do
    local stakeholder = CreateFrame ("EditBox", ("sta%d:%s"):format(stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
    stakeholder:SetWidth(135)
    -- Height of this box depends on how many interests that stakeholder has
    stakeholder:SetHeight(140) --TODO (*#(conflict.conflict_data["stakeholders_interests_names"][stakeholder_number])))
    stakeholder_boxes[stakeholder_number] = stakeholder 
    if (stakeholder_number == 1) then
      stakeholder:SetPoint("TOPRIGHT", option_boxes[1], "LEFT", -135, 0) -- --175 to leave room for the interests column
    else
      stakeholder:SetPoint("TOP", stakeholder_boxes[stakeholder_number-1], "BOTTOM", 0, 0)    
    end

    stakeholder:SetText(conflict.conflict_data["stakeholders_names"][stakeholder_number])
    stakeholder:SetTextInsets(5, 5, 2, 2)
    stakeholder:SetAutoFocus(false)
    stakeholder:SetScript("OnEnterPressed", editBox_OnEnterPressed)

    interests_boxes[stakeholder_number] = {}
    consequences_boxes[stakeholder_number] = {}

    -- Create boxes with the names of the interests of that stakeholder (and their values)
    for interest_number, interestlist in pairs (conflict.conflict_data["stakeholders_interests_values"][stakeholder_number]) do
      local interestbox = CreateFrame ("EditBox", ("int%d,%d:%s"):format(interest_number, stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
      interestbox:SetHeight(82)-- TODO #conflict.conflict_data["stakeholders_interests_values"][stakeholder_number][interest_number][1])
      interestbox:SetWidth(125)
      interests_boxes[stakeholder_number][interest_number] = interestbox
      if (interest_number == 1) then
        interestbox:SetPoint("LEFT", stakeholder, "RIGHT", 0, 0)
      else
        interestbox:SetPoint("TOP", interests_boxes[stakeholder_number][interest_number-1], "BOTTOM", 0, -30)    
      end
      interestbox:SetText(conflict.conflict_data["stakeholders_interests_names"][stakeholder_number][interest_number])
      interestbox:SetTextInsets(5, 5, 2, 2)
      interestbox:SetMultiLine(true)
      interestbox:SetAutoFocus(false)
      interestbox:SetScript("OnEnterPressed", editBox_OnEnterPressed)

      consequences_boxes[stakeholder_number][interest_number] = {} -- Consequences stored by interest

      -- Create row of values for each interest

      for posneg_number, consequences_list in pairs(interestlist) do
        consequences_boxes[stakeholder_number][interest_number][posneg_number] = {}
        for consequence_number, consequence_value in pairs(consequences_list) do
          local consequencebox = CreateFrame ("EditBox", ("con%d,%d,%d,%d:%s"):format(consequence_number, posneg_number, interest_number, stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
          consequencebox:SetHeight(25)
          consequencebox:SetWidth(200/2)
          consequences_boxes[stakeholder_number][interest_number][posneg_number][consequence_number] = consequencebox 
          if (consequence_number == 1) then
            local distance = 15 + (posneg_number-1) * consequencebox:GetWidth() -- See how many columns wide distance to skip
            if (consequence_number % 2 == 0) then
              consequencebox:SetPoint("LEFT", interestbox, "RIGHT", distance, 0)
            else
              consequencebox:SetPoint("LEFT", interestbox, "RIGHT", distance, 0)
            end
          else
            consequencebox:SetPoint("TOP", consequences_boxes[stakeholder_number][interest_number][posneg_number][consequence_number-1], "BOTTOM", 0, 0) 
          end
          consequencebox:SetText(consequence_value)
          consequencebox:SetMultiLine(true)
          consequencebox:SetTextInsets(5, 5, 2, 2)
          consequencebox:SetAutoFocus(false)
          consequencebox:SetScript("OnEnterPressed", editBox_OnEnterPressed)
        end
      end
    end
  
  end -- Create stakeholder boxes
  conflict.conflict_ui["stakeholders"] = stakeholder_boxes
  conflict.conflict_ui["interests"] = interests_boxes
  conflict.conflict_ui["consequences"] = consequences_boxes
  return conflict

end







function addon:createEditionWindow(prefix)

-- Code for scroll window adapted from http://us.battle.net/wow/en/forum/topic/1305771013
  -- Parent frame 
  local discussion = CreateFrame("Frame", "Discussion" .. prefix, UIParent, "BasicFrameTemplate")
  discussion:SetSize(discussion_width, discussion_height) 
  discussion:SetPoint("CENTER") 
  discussion:SetBackdrop({
    --bgFile = "Interface\\ACHIEVEMENTFRAME/UI-ACHIEVEMENT-ACHIEVEMENTBACKGROUND.png",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 5, bottom = 3 }
  })
  discussion:SetScript("OnDragStart",function()  discussion:StartMoving(); end)
  discussion:SetScript("OnDragStop", function()  discussion:StopMovingOrSizing(); end)
  discussion:RegisterForDrag("LeftButton")
  discussion:SetMovable(true)
  discussion:EnableMouse(true)
  discussion:CreateTitleRegion()

  -- Title bar (conflict description)
  discussion.header = CreateFrame("EditBox", ("tit:%s"):format(prefix), discussion, "InputBoxTemplate")
  discussion.header:SetSize(discussion:GetWidth()-50, 44)
  discussion.header:SetPoint("CENTER", discussion, "TOP", 55, -10)
  discussion.header:SetText(addon.conflicts_active_testing[prefix].conflict_data["description"])
  discussion.header:SetAutoFocus(false)
  discussion.header:SetScript("OnEnterPressed", editBox_OnEnterPressed)


  --Scrollframe 
  local scrollframe = CreateFrame("ScrollFrame", nil, discussion) 
  scrollframe:SetPoint("TOPLEFT", 10, -10) 
  scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 
  discussion.scrollframe = scrollframe 

  -- Scrollbar 
  local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
  scrollbar:SetPoint("TOPLEFT", discussion, "TOPRIGHT", -20, -37) 
  scrollbar:SetPoint("BOTTOMLEFT", discussion, "BOTTOMRIGHT", 4, 16) 
  scrollbar:SetMinMaxValues(1, 100) 
  scrollbar:SetValueStep(6) 
  scrollbar.scrollStep = 1 
  scrollbar:SetValue(0) 
  scrollbar:SetWidth(16) 
  scrollbar:SetScript("OnValueChanged", function (discussion, value) discussion:GetParent():SetVerticalScroll(value) end) 
  local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
  scrollbg:SetAllPoints(scrollbar) 
  scrollbg:SetTexture(0, 0, 0, 0.4) 
  discussion.scrollbar = scrollbar 

  -- Content frame 
  local discussionContent = CreateFrame("Frame", "discussionContent of" .. prefix, scrollframe) 
  discussionContent:SetSize(discussion_width, discussion_height) 
  scrollframe.content = discussionContent 
  scrollframe:SetScrollChild(discussionContent)

--[[
  -- Code adapted from snipets of LibSpreadDiscussion-1.0
  discussion.discussionSelector = CreateFrame("Frame", nil, discussion)
  discussion.discussionSelector:SetFrameStrata("DIALOG")
  discussion.discussionSelector:SetPoint("CENTER")

  discussion.prevDiscussion = CreateFrame("Button", nil, discussion.discussionSelector);
  discussion.prevDiscussion:SetWidth(32);
  discussion.prevDiscussion:SetHeight(32);
  discussion.prevDiscussion:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
  discussion.prevDiscussion:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
  discussion.prevDiscussion:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
  discussion.prevDiscussion:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
  --TODO
  discussion.prevDiscussion:SetScript("OnClick", function() print ("Prev clicked") end)--discussion:Leaf(-1); discussion:Render(); end);
  discussion.prevDiscussion:SetPoint("LEFT", discussion.DiscussionSelector, "LEFT", 0, 0);


  discussion.nextDiscussion = CreateFrame("Button", nil, discussion.DiscussionSelector);
  discussion.nextDiscussion:SetWidth(32);
  discussion.nextDiscussion:SetHeight(32);
  discussion.nextDiscussion:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
  discussion.nextDiscussion:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
  discussion.nextDiscussion:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
  discussion.nextDiscussion:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
  discussion.nextDiscussion:SetScript("OnClick", function() print ("Next clicked") end) --discussion:Leaf(1); discussion:Render(); end);
  discussion.nextDiscussion:SetPoint("RIGHT", discussion.DiscussionSelector, "RIGHT", 0, 0);
--]]

  addon.conflicts_active_testing[prefix].conflict_ui["editwindow"] = discussion
  addon.conflicts_active_testing[prefix] = createEditBoxes(prefix)

  createButtonsBar(discussion)

  return addon.conflicts_active_testing[prefix]
end




------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
-------------------------------------- Voting stage --------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


function sendVotes( button )
  addon:sendVotes(button)
end


function createVotingButtonsBar( discussion )
  local prefix = discussion:GetName():match("Discussion(.+)")
  local buttonbar = CreateFrame("Frame", "VotingButtonBar" .. prefix, discussion.scrollframe.content)
  buttonbar:SetSize(300 ,100) -- width, height
  buttonbar:SetPoint("CENTER", discussion.scrollframe.content, "BOTTOM", 0, 0)
  local sendbutton = CreateFrame("Button", ("SendB:%s"):format(prefix), buttonbar, "UIPanelButtonTemplate")
  sendbutton:SetSize(100 ,50) -- width, height
  sendbutton:SetText("Send\n votes")
  sendbutton:SetPoint("CENTER", buttonbar, "CENTER", 0, 70)
  sendbutton:SetScript("OnClick", sendVotes)
  local abandonbutton = CreateFrame("Button", "AbandonButton2", buttonbar, "UIPanelButtonTemplate")
  abandonbutton:SetSize(100 ,50) -- width, height
  abandonbutton:SetText("Abandon\n conflict")
  abandonbutton:SetPoint("CENTER", buttonbar, "RIGHT", 0, 70)
  abandonbutton:SetScript("OnClick", function()
    print("Abandon conflict clicked")
  end)
end



function votingbutton_OnClick( button )
  if button.active then
    button:SetNormalTexture(button.normalTexture)
    button.active = false
  else
    button.normalTexture = button:GetNormalTexture()
    --button:SetNormalTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    --button:SetNormalTexture("Interface\\AddOns\\ColLabWoW\\Media\\UI-CheckBox-Highlight-take1")
    button:SetNormalTexture("Interface\\ContainerFrame\\UI-Icon-QuestBorder")
    --button:SetNormalTexture("Interface\\GMChatFrame\\UI-GMStatusFrame-Pulse")
    --button:SetNormalTexture("Interface\\SPELLBOOK\\UI-SpellbookPanel-Tab-Highlight")
    button.active = true
  end
  
end



function createVotingButtons( prefix )
  local conflict = addon.conflicts_active_testing[prefix]
  local discussion = conflict.conflict_ui.votingwindow
  -- TODO what to do with the title? conflict.conflict_ui["description"] = discussion.header

   -- Create options/solutions bar
  local option_boxes = {}
  local posneg_boxes = {}
  for option_number = 1, #(conflict.conflict_data["options"]) do
    local option = CreateFrame ("EditBox", ("opt%d:%s"): format(option_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
    option:SetHeight(15)
    option:SetWidth(200)
    option_boxes[option_number] = option 
    if (option_number == 1) then
      option:SetPoint("LEFT", discussion.scrollframe.content, "TOPLEFT", 135*2,-40)--discussion.header:GetHeight()+20) -- 175 to leave space horizontally for the stakeholders column
    else
      option:SetPoint("LEFT", option_boxes[option_number-1], "RIGHT", 15, 0)    
    end

    option:SetText(conflict.conflict_data["options"][option_number])
    option:SetTextInsets(5, 5, 2, 2)
    option:SetMultiLine(true)
    option:SetAutoFocus(false)
    option:Disable()

    -- Create positive/negative consequences indicators boxes (non editable)
    for counter = 1, 2 do
      -- Calculate column (even or odd and option number)
      local posneg_index = option_number*2
      if counter == 1 then
        posneg_index = posneg_index -1
      end
      local posneg = CreateFrame("EditBox", ("pos_neg%d:%s"):format(posneg_index, prefix), discussion.scrollframe.content, "InputBoxTemplate")
      posneg:SetHeight(15)
      posneg:SetWidth((option:GetWidth())/2)
      
      if (counter == 1) then
        posneg:SetPoint("TOPLEFT", option, "BOTTOMLEFT")
        posneg:SetPoint("TOPRIGHT", option, "BOTTOM")
      else
        posneg:SetPoint("TOPRIGHT", option, "BOTTOMRIGHT", 0, 0)
        posneg:SetPoint("TOPLEFT", option, "BOTTOM", 0, 0)
      end
      posneg:SetTextInsets(5, 5, 2, 2)
      posneg:SetText(conflict.conflict_data["posneg"][posneg_index])
      posneg:SetAutoFocus(false)
      posneg:Disable()
      posneg_boxes[posneg_index] = posneg
    end
  end -- End of creation of options boxes
  conflict.conflict_ui["options"] = option_boxes
  conflict.conflict_ui["posneg"] = posneg_boxes

  -- Create stakeholders column and interests column, plus rows of consequences
  local stakeholder_boxes = {}
  local interests_boxes = {}
  local consequences_boxes = {}
 
  for stakeholder_number=1, #(conflict.conflict_data["stakeholders_names"]) do
    local stakeholder = CreateFrame ("EditBox", ("sta%d:%s"):format(stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
    stakeholder:SetWidth(135)
    -- Height of this box depends on how many interests that stakeholder has
    stakeholder:SetHeight(140) --TODO (*#(conflict.conflict_data["stakeholders_interests_names"][stakeholder_number])))
    stakeholder_boxes[stakeholder_number] = stakeholder 
    if (stakeholder_number == 1) then
      stakeholder:SetPoint("TOPRIGHT", option_boxes[1], "LEFT", -135, 0) -- --175 to leave room for the interests column
    else
      stakeholder:SetPoint("TOP", stakeholder_boxes[stakeholder_number-1], "BOTTOM", 0, 0)    
    end

    stakeholder:SetText(conflict.conflict_data["stakeholders_names"][stakeholder_number])
    stakeholder:SetTextInsets(5, 5, 2, 2)
    stakeholder:SetAutoFocus(false)
    stakeholder:Disable()

    interests_boxes[stakeholder_number] = {}
    consequences_boxes[stakeholder_number] = {}

    -- Create boxes with the names of the interests of that stakeholder (and their values)
    for interest_number, interestlist in pairs (conflict.conflict_data["stakeholders_interests_values"][stakeholder_number]) do
      local interestbox = CreateFrame ("EditBox", ("int%d,%d:%s"):format(interest_number, stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
      interestbox:SetHeight(82)-- TODO #conflict.conflict_data["stakeholders_interests_values"][stakeholder_number][interest_number][1])
      interestbox:SetWidth(125)
      interests_boxes[stakeholder_number][interest_number] = interestbox
      if (interest_number == 1) then
        interestbox:SetPoint("LEFT", stakeholder, "RIGHT", 0, 0)
      else
        interestbox:SetPoint("TOP", interests_boxes[stakeholder_number][interest_number-1], "BOTTOM", 0, -30)    
      end
      interestbox:SetText(conflict.conflict_data["stakeholders_interests_names"][stakeholder_number][interest_number])
      interestbox:SetTextInsets(5, 5, 2, 2)
      interestbox:SetMultiLine(true)
      interestbox:SetAutoFocus(false)
      interestbox:Disable()

      consequences_boxes[stakeholder_number][interest_number] = {} -- Consequences stored by interest


      -- Create row of values for each interest
      for posneg_number, consequences_list in pairs(interestlist) do
        consequences_boxes[stakeholder_number][interest_number][posneg_number] = {}
        for consequence_number, consequence_value in pairs(consequences_list) do
          local consequencebox = CreateFrame ("Button", ("con%d,%d,%d,%d:%s"):format(consequence_number, posneg_number, interest_number, stakeholder_number, prefix), discussion.scrollframe.content, "UIPanelButtonTemplate")
          consequencebox:SetHeight(25)
          consequencebox:SetWidth(200/2)
          consequences_boxes[stakeholder_number][interest_number][posneg_number][consequence_number] = consequencebox 
          if (consequence_number == 1) then
            local distance = 5 + (posneg_number-1) * consequencebox:GetWidth() -- See how many columns wide distance to skip
            consequencebox:SetPoint("LEFT", interestbox, "RIGHT", distance, 0)
          else
            consequencebox:SetPoint("TOP", consequences_boxes[stakeholder_number][interest_number][posneg_number][consequence_number-1], "BOTTOM", 0, 0) 
          end
          consequencebox:SetText(consequence_value)
          consequencebox:SetScript("OnClick", votingbutton_OnClick)
        end
      end
    end
  
  end -- Create stakeholder boxes
  --conflict.conflict_ui["stakeholders"] = stakeholder_boxes
  --conflict.conflict_ui["interests"] = interests_boxes
  conflict.conflict_ui["consequences_boxes"] = consequences_boxes
  
  return conflict
end




function addon:startVoting( prefix )
  local conflict = addon.conflicts_active_testing[prefix]
  local discussion = conflict.conflict_ui.editwindow
  -- Hide previous window
  discussion.scrollframe:Hide()
  -- Create window with checkbuttons instead of editboxes
  --Scrollframe 
  local scrollframe = CreateFrame("ScrollFrame", nil, discussion) 
  scrollframe:SetPoint("TOPLEFT", 10, -10) 
  scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 
  discussion.scrollframe = scrollframe 

  -- Scrollbar 
  local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
  scrollbar:SetPoint("TOPLEFT", discussion, "TOPRIGHT", -20, -37) 
  scrollbar:SetPoint("BOTTOMLEFT", discussion, "BOTTOMRIGHT", 4, 16) 
  scrollbar:SetMinMaxValues(1, 100) 
  scrollbar:SetValueStep(6) 
  scrollbar.scrollStep = 1 
  scrollbar:SetValue(0) 
  scrollbar:SetWidth(16) 
  scrollbar:SetScript("OnValueChanged", function (discussion, value) discussion:GetParent():SetVerticalScroll(value) end) 
  local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
  scrollbg:SetAllPoints(scrollbar) 
  scrollbg:SetTexture(0, 0, 0, 0.4) 
  discussion.scrollbar = scrollbar 

  -- Content frame 
  local discussionContent = CreateFrame("Frame", "discussionVoteContent of" .. prefix, scrollframe) 
  discussionContent:SetSize(discussion_width, discussion_height) 
  scrollframe.content = discussionContent 
  scrollframe:SetScrollChild(discussionContent)

  addon.conflicts_active_testing[prefix].conflict_ui["votingwindow"] = discussion
  addon.conflicts_active_testing[prefix] = createVotingButtons(prefix)

  createVotingButtonsBar(discussion)

end




------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------- Summary stage --------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


function createSummaryButtons(prefix)
  local conflict = addon.conflicts_active_testing[prefix]
  local discussion = conflict.conflict_ui.summarywindow
  -- TODO what to do with the title? conflict.conflict_ui["description"] = discussion.header

   -- Create options/solutions bar
  local option_boxes = {}
  local posneg_boxes = {}
  for option_number = 1, #(conflict.conflict_data["options"]) do
    local option = CreateFrame ("EditBox", ("opt%d:%s"): format(option_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
    option:SetHeight(15)
    option:SetWidth(200)
    option_boxes[option_number] = option 
    if (option_number == 1) then
      option:SetPoint("LEFT", discussion.scrollframe.content, "TOPLEFT", 135*2,-40)--discussion.header:GetHeight()+20) -- 175 to leave space horizontally for the stakeholders column
    else
      option:SetPoint("LEFT", option_boxes[option_number-1], "RIGHT", 15, 0)    
    end

    option:SetText(conflict.conflict_data["options"][option_number])
    option:SetTextInsets(5, 5, 2, 2)
    option:SetMultiLine(true)
    option:SetAutoFocus(false)
    option:Disable()

    -- Create positive/negative consequences indicators boxes (non editable)
    for counter = 1, 2 do
      -- Calculate column (even or odd and option number)
      local posneg_index = option_number*2
      if counter == 1 then
        posneg_index = posneg_index -1
      end
      local posneg = CreateFrame("EditBox", ("pos_neg%d:%s"):format(posneg_index, prefix), discussion.scrollframe.content, "InputBoxTemplate")
      posneg:SetHeight(15)
      posneg:SetWidth((option:GetWidth())/2)
      
      if (counter == 1) then
        posneg:SetPoint("TOPLEFT", option, "BOTTOMLEFT")
        posneg:SetPoint("TOPRIGHT", option, "BOTTOM")
      else
        posneg:SetPoint("TOPRIGHT", option, "BOTTOMRIGHT", 0, 0)
        posneg:SetPoint("TOPLEFT", option, "BOTTOM", 0, 0)
      end
      posneg:SetTextInsets(5, 5, 2, 2)
      posneg:SetText(conflict.conflict_data["posneg"][posneg_index])
      posneg:SetAutoFocus(false)
      posneg:Disable()
      posneg_boxes[posneg_index] = posneg
    end
  end -- End of creation of options boxes
  conflict.conflict_ui["options"] = option_boxes
  conflict.conflict_ui["posneg"] = posneg_boxes

  -- Create stakeholders column and interests column, plus rows of consequences
  local stakeholder_boxes = {}
  local interests_boxes = {}
  local consequences_boxes = {}
 
  for stakeholder_number=1, #(conflict.conflict_data["stakeholders_names"]) do
    local stakeholder = CreateFrame ("EditBox", ("sta%d:%s"):format(stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
    stakeholder:SetWidth(135)
    -- Height of this box depends on how many interests that stakeholder has
    stakeholder:SetHeight(140) --TODO (*#(conflict.conflict_data["stakeholders_interests_names"][stakeholder_number])))
    stakeholder_boxes[stakeholder_number] = stakeholder 
    if (stakeholder_number == 1) then
      stakeholder:SetPoint("TOPRIGHT", option_boxes[1], "LEFT", -135, 0) -- --175 to leave room for the interests column
    else
      stakeholder:SetPoint("TOP", stakeholder_boxes[stakeholder_number-1], "BOTTOM", 0, 0)    
    end

    stakeholder:SetText(conflict.conflict_data["stakeholders_names"][stakeholder_number])
    stakeholder:SetTextInsets(5, 5, 2, 2)
    stakeholder:SetAutoFocus(false)
    stakeholder:Disable()

    interests_boxes[stakeholder_number] = {}
    consequences_boxes[stakeholder_number] = {}

    -- Create boxes with the names of the interests of that stakeholder (and their values)
    for interest_number, interestlist in pairs (conflict.conflict_data["stakeholders_interests_values"][stakeholder_number]) do
      local interestbox = CreateFrame ("EditBox", ("int%d,%d:%s"):format(interest_number, stakeholder_number, prefix), discussion.scrollframe.content, "InputBoxTemplate")
      interestbox:SetHeight(82)-- TODO #conflict.conflict_data["stakeholders_interests_values"][stakeholder_number][interest_number][1])
      interestbox:SetWidth(125)
      interests_boxes[stakeholder_number][interest_number] = interestbox
      if (interest_number == 1) then
        interestbox:SetPoint("LEFT", stakeholder, "RIGHT", 0, 0)
      else
        interestbox:SetPoint("TOP", interests_boxes[stakeholder_number][interest_number-1], "BOTTOM", 0, -30)    
      end
      interestbox:SetText(conflict.conflict_data["stakeholders_interests_names"][stakeholder_number][interest_number])
      interestbox:SetTextInsets(5, 5, 2, 2)
      interestbox:SetMultiLine(true)
      interestbox:SetAutoFocus(false)
      interestbox:Disable()

      consequences_boxes[stakeholder_number][interest_number] = {} -- Consequences stored by interest


      -- Create row of values for each interest
      for posneg_number, consequences_list in pairs(interestlist) do
        consequences_boxes[stakeholder_number][interest_number][posneg_number] = {}
        for consequence_number, consequence_value in pairs(consequences_list) do
          local consequencebox = CreateFrame ("Button", ("con%d,%d,%d,%d:%s"):format(consequence_number, posneg_number, interest_number, stakeholder_number, prefix), discussion.scrollframe.content, "UIPanelButtonTemplate")
          consequencebox:SetHeight(25)
          consequencebox:SetWidth(200/2)
          consequences_boxes[stakeholder_number][interest_number][posneg_number][consequence_number] = consequencebox 
          if (consequence_number == 1) then
            local distance = 5 + (posneg_number-1) * consequencebox:GetWidth() -- See how many columns wide distance to skip
            consequencebox:SetPoint("LEFT", interestbox, "RIGHT", distance, 0)
          else
            consequencebox:SetPoint("TOP", consequences_boxes[stakeholder_number][interest_number][posneg_number][consequence_number-1], "BOTTOM", 0, 0) 
          end

          local votecode = consequence_number .. "," .. posneg_number .. ",".. interest_number .. "," .. stakeholder_number

          if (conflict.summary[votecode] == nil) then
            consequencebox:SetText("0 : " .. consequence_value)
            consequencebox:Disable()
          else
            consequencebox:SetText(conflict.summary[votecode] .. " : " .. consequence_value)
          end
        end
      end
    end
  
  end -- Create stakeholder boxes
  --conflict.conflict_ui["stakeholders"] = stakeholder_boxes
  --conflict.conflict_ui["interests"] = interests_boxes
  --TODO how to store this? It is needed?
  --conflict.conflict_ui["consequences_boxes"] = consequences_boxes
  
  return conflict

end




function addon:startSummary( prefix )
  local conflict = addon.conflicts_active_testing[prefix]
  local discussion = conflict.conflict_ui.votingwindow
  -- Hide previous window
  discussion.scrollframe:Hide()
  -- Create window with editboxes and buttons for the arguments
  --Scrollframe 
  local scrollframe = CreateFrame("ScrollFrame", nil, discussion) 
  scrollframe:SetPoint("TOPLEFT", 10, -10) 
  scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 
  discussion.scrollframe = scrollframe 

  -- Scrollbar 
  local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
  scrollbar:SetPoint("TOPLEFT", discussion, "TOPRIGHT", -20, -37) 
  scrollbar:SetPoint("BOTTOMLEFT", discussion, "BOTTOMRIGHT", 4, 16) 
  scrollbar:SetMinMaxValues(1, 100) 
  scrollbar:SetValueStep(6) 
  scrollbar.scrollStep = 1 
  scrollbar:SetValue(0) 
  scrollbar:SetWidth(16) 
  scrollbar:SetScript("OnValueChanged", function (discussion, value) discussion:GetParent():SetVerticalScroll(value) end) 
  local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
  scrollbg:SetAllPoints(scrollbar) 
  scrollbg:SetTexture(0, 0, 0, 0.4) 
  discussion.scrollbar = scrollbar 

  -- Content frame 
  local discussionContent = CreateFrame("Frame", "discussionSummaryContent of" .. prefix, scrollframe) 
  discussionContent:SetSize(discussion_width, discussion_height) 
  scrollframe.content = discussionContent 
  scrollframe:SetScrollChild(discussionContent)

  addon.conflicts_active_testing[prefix].conflict_ui["summarywindow"] = discussion
  addon.conflicts_active_testing[prefix] = createSummaryButtons(prefix)

end

