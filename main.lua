local suits = {"hearts", "diamonds", "clubs", "spades"}
local ranks = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"}

local cardValues = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7,
    ["8"] = 8, ["9"] = 9, ["10"] = 10 , ["J"] = 11, ["Q"] = 12, ["K"] = 13, ["A"] = 14
}

local deck = {}
local cardImages = {}
local hand = {}
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
            table.insert(deck, {name = cardName, value = cardValue})
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
    local xOffset = 20
    local yOffset = 400
    local spacing = 70
    local card
    for i = 1, 10 do
        card = table.remove(deck)
        card.x = xOffset
        card.y = yOffset
        card.originalX = xOffset
        card.originalY = yOffset
        card.width = 105
        card.height = 150
        card.xText = card.originalX + 5
        card.yText = card.originalY - 5
        table.insert(hand, card)
        xOffset = xOffset + spacing
        table.remove(card)
    end
end



function love.load()
    math.randomseed(os.time())
    loadCardImages()
    createDeck()
    shuffleDeck()
    handSet()
end

function love.update(dt)
    
end

function love.draw()
    for i, card in ipairs(hand) do
        local cardImage = cardImages[card.name]
        love.graphics.draw(cardImage, card.x, card.y, nil, 2, 2)
        love.graphics.print(card.value, card.xText, card.yText)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then

    end
end
function love.mousereleased(x, y, button)
    if button == 1 then

    end
end
