local plataformasFolder = workspace:WaitForChild("Plataformas")
local plataformaModelo = plataformasFolder:WaitForChild("1")

local NUM_PLATAFORMAS = 550
local ESPACIADO_X = 10

-- Obtener la posicion inicial desde la primera parte del modelo
local primeraParte = plataformaModelo:GetChildren()[1]
if not primeraParte or not primeraParte:IsA("BasePart") then
    for _, child in plataformaModelo:GetChildren() do
        if child:IsA("BasePart") then
            primeraParte = child
            break
        end
    end
end

local currentOffset = 0

-- 2. Toma en cuenta la primera plataforma (plataforma modelo)
local textLabelModelo = plataformaModelo:FindFirstChild("TextLabel", true)
if textLabelModelo and textLabelModelo:IsA("TextLabel") then
    -- 1. Ignorar los 10 studs base. Mostramos solo el extra: 0.1 Studs
    textLabelModelo.Text = string.format("%.1f Studs", 0.1)
end

-- Colorear la plataforma modelo de rojo (Hue = 0)
for _, parte in plataformaModelo:GetDescendants() do
    if parte:IsA("BasePart") then
        parte.Color = Color3.fromHSV(0, 1, 1)
    end
end

for i = 1, NUM_PLATAFORMAS do
    local clon = plataformaModelo:Clone()
    clon.Name = "" .. (i + 1)
    
    -- Recorremos desde donde empezar a agregar distancia:
    -- La plataforma 1 ya empieza con +0.1 respecto a la modelo
    local extraAEstaPlataforma = i * 0.1
    local espaciadoActual = ESPACIADO_X + extraAEstaPlataforma
    currentOffset = currentOffset + espaciadoActual
    
    -- Offset positivo para ir en direccion positiva del eje X
    local offset = Vector3.new(currentOffset, 0, 0)
    
    -- Calcular el HUE para esta plataforma clonada
    local hue = i / (NUM_PLATAFORMAS + 1)
    
    for _, parte in clon:GetDescendants() do
        if parte:IsA("BasePart") then
            parte.CFrame = parte.CFrame + offset
            parte.Color = Color3.fromHSV(hue, 1, 1)
        end
    end
    
    -- Actualizamos el TextLabel con la distancia a la siguiente plataforma
    local textLabel = clon:FindFirstChild("TextLabel", true)
    if textLabel and textLabel:IsA("TextLabel") then
        local extraSiguiente = (i + 1) * 0.1
        textLabel.Text = string.format("%.1f Studs", extraSiguiente)
    end
    
    clon.Parent = plataformasFolder
end

print("Plataformas clonadas exitosamente: " .. NUM_PLATAFORMAS)
