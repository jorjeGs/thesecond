local CollectionService = game:GetService("CollectionService")

local plataformasFolder = workspace:WaitForChild("Plataformas")
local monedasFolder = workspace:WaitForChild("Monedas")
local monedaModelo = monedasFolder:WaitForChild("1")

local ALTURA_OFFSET = 3.5 -- Studs por encima de la plataforma

-- Ocultamos el modelo original del Workspace para usarlo puramente como template
monedaModelo.Parent = nil

-- Esperamos un breve momento para asegurarnos de que la clonación de plataformas haya iniciado
task.wait(0.5)

-- Función de ayuda para asegurar que la moneda clonada tenga el tag CoinTrigger
local function asegurarTagCoinTrigger(modelo)
	for _, child in modelo:GetChildren() do
		if child:IsA("BasePart") then
			if not CollectionService:HasTag(child, "CoinTrigger") then
				CollectionService:AddTag(child, "CoinTrigger")
			end
		end
	end
end

local plataformaIndex = 10
local monedaIndex = 1

while true do
	local plataformaName = tostring(plataformaIndex)
	-- Esperamos por la plataforma con un timeout de 2 segundos.
	-- Si no aparece en ese tiempo, asumimos que hemos llegado al final.
	local plataforma = plataformasFolder:WaitForChild(plataformaName, 2)
	if not plataforma then
		break
	end

	-- Obtenemos el CFrame del centro de la plataforma
	local plataformaCFrame = plataforma:GetPivot()
	-- Calculamos la posición justo en el centro de la plataforma y un poco arriba, y rotamos -90 grados en el eje Z
	local posicionMoneda = (plataformaCFrame * CFrame.new(0, ALTURA_OFFSET, 0)) * CFrame.Angles(0, 0, math.rad(-90))

	-- Clonamos el modelo de la moneda
	local nuevaMoneda = monedaModelo:Clone()
	nuevaMoneda.Name = tostring(monedaIndex)
	
	-- Nos aseguramos de que tenga la etiqueta para que CoinManager la reconozca al ser tocada
	asegurarTagCoinTrigger(nuevaMoneda)
	
	-- Posicionamos y la añadimos a la carpeta de Monedas
	nuevaMoneda:PivotTo(posicionMoneda)
	nuevaMoneda.Parent = monedasFolder

	plataformaIndex = plataformaIndex + 10
	monedaIndex = monedaIndex + 1
end

print("[ClonarMonedas] Monedas clonadas e inicializadas correctamente. Total: " .. (monedaIndex - 1))
