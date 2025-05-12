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
local blobNextSpawnTime = math.random(2, 5)

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
    local xOffset = 15
    local yOffset = 400
    local spacing = 80
    for i = 1, 9 do
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
        if c == card then
            return i
        end
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
        local rank = card.rank
        local suit = card.suit
        rankCount[rank] = (rankCount[rank] or 0) + 1
        suitCount[suit] = (suitCount[suit] or 0) + 1
    end
    return rankCount, suitCount
end

local function evaluateHand(cards)
    if #cards < 2 then return "Not enough cards" end
    local rankCount, suitCount = countRanksAndSuits(cards)
    local pairCount = 0
    local threeOfKind = false
    local fourOfKind = false

    for _, count in pairs(rankCount) do
        if count == 2 then pairCount = pairCount + 1 end
        if count == 3 then threeOfKind = true end
        if count == 4 then fourOfKind = true end
    end

    local isFlush = false
    for _, count in pairs(suitCount) do
        if count == #cards then
            isFlush = true
            break
        end
    end

    if fourOfKind then
        damage = damage + 15
        return "Four of a Kind"
    elseif threeOfKind and pairCount >= 1 then
        damage = damage + 9
        return "Full House"
    elseif isFlush then
        damage = damage + 7
        return "Flush"
    elseif threeOfKind then
        damage = damage + 5
        return "Three of a Kind"
    elseif pairCount == 2 then
        damage = damage + 3
        return "Two Pair"
    elseif pairCount == 1 then
        damage = damage + 2
        return "One Pair"
    else
        damage = damage + 1
        return "High Card"
    end
end

local function cardDiscard()
    for i = #selectedSet, 1, -1 do
        local selected = selectedSet[i]
        for j = #hand, 1, -1 do
            if hand[j] == selected then
                table.remove(hand, j)
                local newCard = table.remove(deck)
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
    cardDiscard()
end

local function setReload()
    for i in pairs(selectedSet) do
        selectedSet[i] = nil
    end
    count = 0
end

local function spawnBlob()
    local laneY = lanesY[math.random(1, #lanesY)]
    local blob = {
        x = 700,
        y = laneY,
        speed = 30,
        health = 5,
        spriteSheet = love.graphics.newImage('sprites/blob.png')
    }
    blob.grid = anim8.newGrid(32, 32, blob.spriteSheet:getWidth(), blob.spriteSheet:getHeight())
    blob.animationWalk = anim8.newAnimation(blob.grid("1-18", 1), 0.05)
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
        setPlay()
        setReload()
    end
    if key == "space" then
        cardDiscard()
    end
end

function love.update(dt)
    blobSpawnTimer = blobSpawnTimer + dt
    if blobSpawnTimer >= blobNextSpawnTime then
        spawnBlob()
        blobSpawnTimer = 0
        blobNextSpawnTime = math.random(2, 5)
    end

    for _, blob in ipairs(blobs) do
        blob.x = blob.x - blob.speed * dt
        blob.anim:update(dt)
    end

    for i = #blobs, 1, -1 do
    local blob = blobs[i]
    blob.x = blob.x - blob.speed * dt
    blob.anim:update(dt)

    if blob.x < -32 then  -- fully off the screen
        table.remove(blobs, i)
    end
end
end

function love.draw()
    love.graphics.draw(rack, 0, 320, 0, 5, 5)
    for _, card in ipairs(hand) do
        local cardImage = cardImages[card.name]
        love.graphics.draw(cardImage, card.x, card.y, nil, 2, 2)
    end

    for _, blob in ipairs(blobs) do
        blob.anim:draw(blob.spriteSheet, blob.x, blob.y, nil, 3)
    end

    love.graphics.print("SelectedIndex: " .. #selectedSet, 10 , 10)
    love.graphics.print("Hand Result: " .. handResult, 10, 30)
    love.graphics.print("Damage Dealt: " .. damage, 10, 45)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        for _, card in ipairs(hand) do
            if x >= card.x and x <= card.x + card.width and y >= card.y and y <= card.y + card.height then
                selectedCard = card
                damage = 0
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
