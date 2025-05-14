-- Card game with zones - full script

local suits = {"hearts", "diamonds", "clubs", "spades"}
local ranks = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"}

local cardValues = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7,
    ["8"] = 8, ["9"] = 9, ["10"] = 10 , ["J"] = 11, ["Q"] = 12, ["K"] = 13, ["A"] = 14
}

local handResult = ""

local deck = {}
local cardImages = {}
local hand = {}
local selectedSet = {}

local selectedCard = nil
local count = 0
local damage = 0

anim8 = require('libraries/anim8')
sti = require('libraries/sti')

love.graphics.setDefaultFilter("nearest", "nearest")

local lanesY = {75, 125, 175, 225}

local blobs = {}
local blobSpawnTimer = 1
local blobNextSpawnTime = 2

local gameTimer = 0
local soulCount = 0
local canSpawn = true

local zones = {
    { name = "Zone 1", zoneEnd = 60, spawnRate = {min = 2, max = 4}, zoneDeath = 5 },
    { name = "Zone 2", zoneEnd = 90, spawnRate = {min = 1, max = 3}, zoneDeath = 4 },
    { name = "Zone 3", zoneEnd = 120, spawnRate = {min = 0.5, max = 2}, zoneDeath = 3 }
}

local currentZoneIndex = 1
local currentZone = zones[currentZoneIndex]

local function loadCardImages()
    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            local cardName = rank .. suit
            cardImages[cardName] = love.graphics.newImage("sprites/cardImages/" .. cardName .. ".png")
        end
    end
end

local function createDeck()
    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            local cardName = rank .. suit
            local cardValue = cardValues[rank]
            table.insert(deck, {
                name = cardName,
                value = cardValue,
                rank = rank,
                suit = suit
            })
        end
    end
end

local function shuffleDeck()
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function handSet()
    local xOffset = 70
    local yOffset = 375
    local spacing = 85
    for i = 1, 8 do
        local card = table.remove(deck)
        card.x = xOffset
        card.y = yOffset
        card.originalX = xOffset
        card.originalY = yOffset
        card.width = 105
        card.height = 150
        table.insert(hand, card)
        xOffset = xOffset + spacing
    end
end

local function isCardInSet(card, set)
    for i, c in ipairs(set) do
        if c == card then return i end
    end
    return nil
end

local function setSelection()
    if selectedCard then
        local index = isCardInSet(selectedCard, selectedSet)
        if index then
            selectedCard.y = selectedCard.originalY
            table.remove(selectedSet, index)
            count = count - 1
        elseif count < 5 then
            selectedCard.y = selectedCard.originalY - 20
            table.insert(selectedSet, selectedCard)
            count = count + 1
        end
    end
end

local function countRanksAndSuits(cards)
    local rankCount = {}
    local suitCount = {}
    for _, card in ipairs(cards) do
        rankCount[card.rank] = (rankCount[card.rank] or 0) + 1
        suitCount[card.suit] = (suitCount[card.suit] or 0) + 1
    end
    return rankCount, suitCount
end

local function evaluateHand(cards)
    if #cards < 2 then return "Not enough cards" end
    local rankCount, suitCount = countRanksAndSuits(cards)
    local pairCount = 0
    local threeOfKind, fourOfKind = false, false

    for _, count in pairs(rankCount) do
        if count == 2 then pairCount = pairCount + 1 end
        if count == 3 then threeOfKind = true end
        if count == 4 then fourOfKind = true end
    end

    local isFlush = false
    for _, count in pairs(suitCount) do
        if count == #cards then isFlush = true break end
    end

    if fourOfKind then damage = damage + 15 return "Four of a Kind" end
    if threeOfKind and pairCount >= 1 then damage = damage + 9 return "Full House" end
    if isFlush then damage = damage + 7 return "Flush" end
    if threeOfKind then damage = damage + 5 return "Three of a Kind" end
    if pairCount == 2 then damage = damage + 4 return "Two Pair" end
    if pairCount == 1 then damage = damage + 2 return "One Pair" end
    damage = damage + 1 return "High Card"
end

local function cardDiscard()
    for i = #selectedSet, 1, -1 do
        local selected = selectedSet[i]
        for j = #hand, 1, -1 do
            if hand[j] == selected then
                local newCard = table.remove(deck)
                table.insert(deck, table.remove(hand, j))
                if newCard then
                    newCard.x = selected.originalX
                    newCard.y = selected.originalY
                    newCard.originalX = selected.originalX
                    newCard.originalY = selected.originalY
                    newCard.width = 105
                    newCard.height = 150
                    table.insert(hand, j, newCard)
                end
                break
            end
        end
    end
end

local function setPlay()
    if next(selectedSet) == nil then
        handResult = "No cards selected"
        return
    end
    handResult = evaluateHand(selectedSet)
    for i = #blobs, 1, -1 do
        blobs[i].health = blobs[i].health - damage
        if blobs[i].health <= 0 then table.remove(blobs, i) end
    end
    cardDiscard()
end

local function setReload()
    for i in pairs(selectedSet) do selectedSet[i] = nil end
    count = 0
end

local function handReload()
    for i = #hand, 1, -1 do
        table.insert(deck, table.remove(hand, i))
    end
    shuffleDeck()
    handSet()
end

local function spawnBlob()
    local laneY = lanesY[math.random(1, #lanesY)]
    local blob = {
        x = 700, y = laneY, speed = 50, health = 4,
        spriteSheet = love.graphics.newImage('sprites/blob.png')
    }
    blob.grid = anim8.newGrid(32, 32, blob.spriteSheet:getWidth(), blob.spriteSheet:getHeight())
    blob.animationWalk = anim8.newAnimation(blob.grid("1-18", 1), 0.1)
    blob.anim = blob.animationWalk
    table.insert(blobs, blob)
end

function love.load()
    math.randomseed(os.time())
    loadCardImages()
    createDeck()
    shuffleDeck()
    handSet()
    rack = love.graphics.newImage("sprites/Rack.png")
end

function love.keypressed(key)
    if key == "return" then
        shuffleDeck()
        shuffleDeck()
        setPlay()
        setReload()
        damage = 0
    elseif key == "space" then
        shuffleDeck()
        shuffleDeck()
        cardDiscard()
        setReload()
    elseif key == "r" then
        handReload()
    elseif key == "z" then
        currentZoneIndex = 1
        currentZone = zones[currentZoneIndex]
        soulCount = 0
        gameTimer = 0
        handReload()
    end
end

function love.update(dt)
    gameTimer = gameTimer + dt
    blobSpawnTimer = blobSpawnTimer + dt

    if blobSpawnTimer >= blobNextSpawnTime and canSpawn then
        spawnBlob()
        blobSpawnTimer = 0
        blobNextSpawnTime = math.random(currentZone.spawnRate.min * 10, currentZone.spawnRate.max * 10) / 10
    end

    for i = #blobs, 1, -1 do
        local blob = blobs[i]
        blob.x = blob.x - blob.speed * dt
        blob.anim:update(dt)
        if blob.x < -32 then
            table.remove(blobs, i)
            soulCount = soulCount + 1
        end
    end

    if soulCount >= currentZone.zoneDeath then
        canSpawn = false
        hand = {}
        blobs = {}
    end

    if gameTimer >= currentZone.zoneEnd then
        currentZoneIndex = currentZoneIndex + 1
        if zones[currentZoneIndex] then
            currentZone = zones[currentZoneIndex]
            gameTimer = 0
            soulCount = 0
        else
            canSpawn = false
        end
    end
end

function love.draw()
    love.graphics.draw(rack, 10, 315, 0, 4, 4)
    for _, card in ipairs(hand) do
        local cardImage = cardImages[card.name]
        love.graphics.draw(cardImage, card.x, card.y, nil, 2, 2)
    end
    for _, blob in ipairs(blobs) do
        blob.anim:draw(blob.spriteSheet, blob.x, blob.y, nil, 3)
    end
    love.graphics.print("SelectedIndex: " .. #selectedSet, 10 , 10)
    love.graphics.print("Hand Result: " .. handResult, 10, 25)
    love.graphics.print("Damage Dealt: " .. damage, 10, 40)
    love.graphics.print("Timer: " .. math.floor(gameTimer), 10, 55)
    love.graphics.print("Escaped: " .. soulCount, 10, 70)
    love.graphics.print("Current Zone: " .. currentZone.name, 10, 85)
    if soulCount >= currentZone.zoneDeath then
        love.graphics.print("GAME OVER!", 325, 200, nil, 2, 2)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        for _, card in ipairs(hand) do
            if x >= card.x and x <= card.x + card.width and y >= card.y and y <= card.y + card.height then
                selectedCard = card
                break
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        setSelection()
        selectedCard = nil
    end
end
