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
love.graphics.setDefaultFilter("nearest", "nearest")

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
    local xOffset = 5
    local yOffset = 400
    local spacing = 110
    local card
    for i = 1, 7 do
        card = table.remove(deck)
        card.x = xOffset
        card.y = yOffset
        card.originalX = xOffset
        card.originalY = yOffset
        card.width = 105
        card.height = 150
        table.insert(hand, card)
        xOffset = xOffset + spacing
        table.remove(card)
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
        return "Four of a Kind"
    elseif threeOfKind and pairs >= 1 then
        return "Full House"
    elseif isFlush then
        return "Flush"
    elseif threeOfKind then
        return "Three of a Kind"
    elseif pairCount == 2 then
        return "Two Pair"
    elseif pairCount == 1 then
        return "One Pair"
    else
        return "High Card"
    end
end

local function setPlay()
    if next(selectedSet) == nil then
        handResult = "No cards selected"
    else
        handResult = evaluateHand(selectedSet)
    end
end

function love.load()
    math.randomseed(os.time())
    loadCardImages()
    createDeck()
    shuffleDeck()
    handSet()
end

function love.keypressed(key)
    if key == "return" then  -- Press Enter to evaluate hand
        setPlay()
    end
end

function love.update(dt)
    
end

function love.draw()
    for i, card in ipairs(hand) do
        local cardImage = cardImages[card.name]
        love.graphics.draw(cardImage, card.x, card.y, nil, 2, 2)
    end
    love.graphics.print("SelectedIndex: " .. #selectedSet, 10 , 10)
    love.graphics.print("Hand Result: " .. handResult, 10, 30)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        for i, card in ipairs(hand) do
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
