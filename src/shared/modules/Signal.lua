--[[
	Signal Module
	
	Un système d'événements personnalisés pour Lua/Roblox.
	Permet de créer, connecter et déclencher des événements personnalisés.
	
	API:
		Signal.new()
			Crée un nouveau signal (événement).
		
		Signal:Connect(handler)
			Connecte une fonction au signal.
			Retourne une connexion qui peut être déconnectée.
		
		Signal:Once(handler)
			Connecte une fonction qui ne sera appelée qu'une seule fois.
			Retourne une connexion qui peut être déconnectée.
		
		Signal:Wait()
			Attend que le signal soit déclenché et retourne les arguments.
		
		Signal:Fire(...)
			Déclenche le signal avec les arguments fournis.
		
		Signal:DisconnectAll()
			Déconnecte toutes les connexions.
		
		Signal:Destroy()
			Nettoie et désactive le signal. Les connexions existantes seront invalidées.
		
		connection:Disconnect()
			Déconnecte une connexion spécifique.
--]]

local Signal = {}
Signal.__index = Signal

-- Classe pour les connexions
local Connection = {}
Connection.__index = Connection

--- Crée une nouvelle connexion
-- @param signal Le signal parent
-- @param handler La fonction à appeler
-- @return Une connexion
function Connection.new(signal, handler)
	return setmetatable({
		_signal = signal,
		_handler = handler,
		_connected = true,
        _once = false
	}, Connection)
end

--- Déconnecte la connexion
function Connection:Disconnect()
	if not self._connected then return end
	
	self._connected = false
	
	-- Trouver et supprimer cette connexion de la liste du signal
	for i, connection in ipairs(self._signal._connections) do
		if connection == self then
			table.remove(self._signal._connections, i)
			break
		end
	end
	
	-- Nettoyage des références
	self._signal = nil
	self._handler = nil
end

--- Alias pour Disconnect
function Connection:disconnect()
	return self:Disconnect()
end

--- Crée un nouveau signal
-- @return Nouvel objet Signal
function Signal.new()
	return setmetatable({
		_connections = {},
		_destroyed = false,
		_yieldingThreads = {}
	}, Signal)
end

--- Connecte une fonction au signal
-- @param handler Fonction à appeler quand le signal est déclenché
-- @return Une connexion
function Signal:Connect(handler)
	assert(typeof(handler) == "function", "Handler doit être une fonction")
	assert(not self._destroyed, "Signal a été détruit")
	
	local connection = Connection.new(self, handler)
	table.insert(self._connections, connection)
	
	return connection
end

--- Alias pour Connect
function Signal:connect(handler)
	return self:Connect(handler)
end

--- Connecte une fonction qui ne sera appelée qu'une seule fois
-- @param handler Fonction à appeler quand le signal est déclenché
-- @return Une connexion
function Signal:Once(handler)
	assert(typeof(handler) == "function", "Handler doit être une fonction")
	assert(not self._destroyed, "Signal a été détruit")
	
	-- Wrapper la fonction pour qu'elle se déconnecte après utilisation
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		handler(...)
	end)
    
    -- Marquer cette connexion comme once pour clarté
    connection._once = true
	
	return connection
end

--- Alias pour Once
function Signal:once(handler)
	return self:Once(handler)
end

--- Attend que le signal soit déclenché
-- @return Les arguments du signal
function Signal:Wait()
	assert(not self._destroyed, "Signal a été détruit")
	
	-- Créer un fil d'attente pour ce thread
	local thread = coroutine.running()
	table.insert(self._yieldingThreads, thread)
	
	-- Suspendre le thread jusqu'à ce que le signal soit déclenché
	local results = {coroutine.yield()}
	
	-- Confirmer que nous avons été réanimés par le signal
	-- Si le fil est dans la table, il a été réanimé par quelque chose d'autre
	for i, yieldingThread in ipairs(self._yieldingThreads) do
		if yieldingThread == thread then
			table.remove(self._yieldingThreads, i)
			break
		end
	end
	
	return unpack(results)
end

--- Alias pour Wait
function Signal:wait()
	return self:Wait()
end

--- Déclenche le signal avec les arguments fournis
-- @param ... Arguments à passer aux gestionnaires
function Signal:Fire(...)
	assert(not self._destroyed, "Signal a été détruit")
	
	-- Copier les connexions pour éviter les problèmes de modification pendant l'itération
	local connections = {}
	for _, connection in ipairs(self._connections) do
		table.insert(connections, connection)
	end
	
	-- Appeler chaque gestionnaire connecté
	for _, connection in ipairs(connections) do
		if connection._connected then
			spawn(function()
				connection._handler(...)
			end)
		end
	end
	
	-- Réanimer les threads en attente
	for _, thread in ipairs(self._yieldingThreads) do
		coroutine.resume(thread, ...)
	end
	self._yieldingThreads = {}
end

--- Alias pour Fire
function Signal:fire(...)
	return self:Fire(...)
end

--- Déclenche le signal immédiatement (pas dans un nouveau thread)
-- Attention: Les exceptions dans les gestionnaires ne sont pas attrapées
-- @param ... Arguments à passer aux gestionnaires
function Signal:FireSync(...)
	assert(not self._destroyed, "Signal a été détruit")
	
	-- Copier les connexions pour éviter les problèmes de modification pendant l'itération
	local connections = {}
	for _, connection in ipairs(self._connections) do
		table.insert(connections, connection)
	end
	
	-- Appeler chaque gestionnaire connecté
	for _, connection in ipairs(connections) do
		if connection._connected then
			connection._handler(...)
		end
	end
	
	-- Réanimer les threads en attente
	for _, thread in ipairs(self._yieldingThreads) do
		coroutine.resume(thread, ...)
	end
	self._yieldingThreads = {}
end

--- Alias pour FireSync
function Signal:fireSync(...)
	return self:FireSync(...)
end

--- Déconnecte toutes les connexions
function Signal:DisconnectAll()
	for _, connection in ipairs(self._connections) do
		connection._connected = false
		connection._signal = nil
		connection._handler = nil
	end
	
	self._connections = {}
	
	-- Réanimer les threads en attente avec aucune valeur
	for _, thread in ipairs(self._yieldingThreads) do
		coroutine.resume(thread)
	end
	self._yieldingThreads = {}
end

--- Détruit le signal
function Signal:Destroy()
	if self._destroyed then return end
	
	self:DisconnectAll()
	self._destroyed = true
end

--- Alias utilitaire pour compatibilité avec Maid
function Signal:destroy()
	return self:Destroy()
end

return Signal
