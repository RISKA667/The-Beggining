--[[
	Promise Module
	
	Une implémentation légère du pattern Promise pour Lua/Roblox.
	Permet d'écrire du code asynchrone de manière plus propre et lisible.
	
	API:
		Promise.new(executor)
			Crée une nouvelle promesse avec un exécuteur qui reçoit resolve et reject.
		
		Promise.resolve(value)
			Crée une promesse résolue avec la valeur donnée.
		
		Promise.reject(reason)
			Crée une promesse rejetée avec la raison donnée.
		
		Promise.all(promises)
			Attend que toutes les promesses soient résolues ou qu'une soit rejetée.
		
		Promise.race(promises)
			Attend que n'importe quelle promesse soit résolue ou rejetée.
		
		Promise.delay(seconds)
			Crée une promesse qui se résout après un délai.
			
		promise:andThen(successHandler, failureHandler)
			Ajoute des gestionnaires de continuation à la promesse.
		
		promise:catch(failureHandler)
			Ajoute un gestionnaire d'erreur à la promesse.
		
		promise:finally(finallyHandler)
			Ajoute un gestionnaire qui est appelé indépendamment du résultat.
		
		promise:await()
			Attend de manière synchrone la résolution de la promesse (utiliser avec précaution).
--]]

local Promise = {}
Promise.__index = Promise

-- États de promesse
local STATUS = {
	PENDING = "pending",
	FULFILLED = "fulfilled",
	REJECTED = "rejected"
}

--- Crée une nouvelle promesse
-- @param executor Fonction qui prend (resolve, reject) comme arguments
-- @return Une nouvelle promesse
function Promise.new(executor)
	local self = setmetatable({
		_status = STATUS.PENDING,
		_value = nil,
		_reason = nil,
		_thenQueue = {},
		_finallyQueue = {}
	}, Promise)
	
	-- Fonctions pour résoudre ou rejeter la promesse
	local resolve = function(value)
		self:_resolve(value)
	end
	
	local reject = function(reason)
		self:_reject(reason)
	end
	
	-- Exécuter l'exécuteur en sécurité
	local success, err = pcall(function()
		executor(resolve, reject)
	end)
	
	-- Si l'exécuteur a généré une erreur, rejeter la promesse
	if not success then
		reject(err)
	end
	
	return self
end

--- Résout la promesse avec une valeur
-- @param value La valeur de résolution
function Promise:_resolve(value)
	if self._status ~= STATUS.PENDING then
		return
	end
	
	-- Gérer le cas où la valeur est une autre promesse
	if typeof(value) == "table" and getmetatable(value) == Promise then
		value:andThen(
			function(resolvedValue)
				self:_resolve(resolvedValue)
			end,
			function(rejectedReason)
				self:_reject(rejectedReason)
			end
		)
		return
	end
	
	self._status = STATUS.FULFILLED
	self._value = value
	self:_executeHandlers()
end

--- Rejette la promesse avec une raison
-- @param reason La raison du rejet
function Promise:_reject(reason)
	if self._status ~= STATUS.PENDING then
		return
	end
	
	self._status = STATUS.REJECTED
	self._reason = reason
	self:_executeHandlers()
end

--- Exécute les gestionnaires en attente
function Promise:_executeHandlers()
	-- Planifier l'exécution pour le prochain cycle d'événements
	spawn(function()
		if self._status == STATUS.FULFILLED then
			-- Gestionnaires then
			for _, handler in ipairs(self._thenQueue) do
				if handler.success then
					local success, result = pcall(handler.success, self._value)
					if success then
						handler.promise:_resolve(result)
					else
						handler.promise:_reject(result)
					end
				else
					handler.promise:_resolve(self._value)
				end
			end
			
			-- Gestionnaires finally
			for _, handler in ipairs(self._finallyQueue) do
				if handler.func then
					local success, result = pcall(handler.func)
					if success then
						handler.promise:_resolve(self._value)
					else
						handler.promise:_reject(result)
					end
				else
					handler.promise:_resolve(self._value)
				end
			end
		elseif self._status == STATUS.REJECTED then
			-- Gestionnaires then (failure)
			local handled = false
			for _, handler in ipairs(self._thenQueue) do
				if handler.failure then
					handled = true
					local success, result = pcall(handler.failure, self._reason)
					if success then
						handler.promise:_resolve(result)
					else
						handler.promise:_reject(result)
					end
				else
					handler.promise:_reject(self._reason)
				end
			end
			
			-- Gestionnaires finally
			for _, handler in ipairs(self._finallyQueue) do
				if handler.func then
					local success, result = pcall(handler.func)
					if success then
						handler.promise:_reject(self._reason)
					else
						handler.promise:_reject(result)
					end
				else
					handler.promise:_reject(self._reason)
				end
			end
			
			-- Si aucun gestionnaire d'erreur, avertir dans la console
			if not handled and typeof(self._reason) == "string" then
				warn("Promesse rejetée non gérée: " .. self._reason)
			elseif not handled then
				warn("Promesse rejetée non gérée")
			end
		end
		
		-- Nettoyer les files d'attente
		self._thenQueue = {}
		self._finallyQueue = {}
	end)
end

--- Ajoute des gestionnaires de continuation à la promesse
-- @param successHandler Fonction à appeler si la promesse est résolue
-- @param failureHandler Fonction à appeler si la promesse est rejetée
-- @return Une nouvelle promesse
function Promise:andThen(successHandler, failureHandler)
	local newPromise = Promise.new(function() end)
	
	table.insert(self._thenQueue, {
		success = successHandler,
		failure = failureHandler,
		promise = newPromise
	})
	
	-- Si la promesse a déjà été résolue ou rejetée, exécuter les gestionnaires
	if self._status ~= STATUS.PENDING then
		self:_executeHandlers()
	end
	
	return newPromise
end

--- Ajoute un gestionnaire d'erreur à la promesse
-- @param failureHandler Fonction à appeler si la promesse est rejetée
-- @return Une nouvelle promesse
function Promise:catch(failureHandler)
	return self:andThen(nil, failureHandler)
end

--- Ajoute un gestionnaire qui est appelé indépendamment du résultat
-- @param finallyHandler Fonction à appeler quand la promesse est résolue ou rejetée
-- @return Une nouvelle promesse
function Promise:finally(finallyHandler)
	local newPromise = Promise.new(function() end)
	
	table.insert(self._finallyQueue, {
		func = finallyHandler,
		promise = newPromise
	})
	
	-- Si la promesse a déjà été résolue ou rejetée, exécuter les gestionnaires
	if self._status ~= STATUS.PENDING then
		self:_executeHandlers()
	end
	
	return newPromise
end

--- Crée une promesse résolue avec la valeur donnée
-- @param value La valeur de résolution
-- @return Une promesse résolue
function Promise.resolve(value)
	return Promise.new(function(resolve)
		resolve(value)
	end)
end

--- Crée une promesse rejetée avec la raison donnée
-- @param reason La raison du rejet
-- @return Une promesse rejetée
function Promise.reject(reason)
	return Promise.new(function(_, reject)
		reject(reason)
	end)
end

--- Attend que toutes les promesses soient résolues
-- @param promises Une table de promesses
-- @return Une promesse qui se résout avec un tableau des résultats
function Promise.all(promises)
	if #promises == 0 then
		return Promise.resolve({})
	end
	
	return Promise.new(function(resolve, reject)
		local results = {}
		local completedCount = 0
		local expectedCount = #promises
		
		for i, promise in ipairs(promises) do
			if typeof(promise) ~= "table" or getmetatable(promise) ~= Promise then
				-- Si l'élément n'est pas une promesse, le traiter comme une valeur résolue
				results[i] = promise
				completedCount = completedCount + 1
				if completedCount == expectedCount then
					resolve(results)
				end
			else
				promise:andThen(
					function(result)
						results[i] = result
						completedCount = completedCount + 1
						if completedCount == expectedCount then
							resolve(results)
						end
					end,
					function(reason)
						reject(reason)
					end
				)
			end
		end
	end)
end

--- Attend que n'importe quelle promesse soit résolue ou rejetée
-- @param promises Une table de promesses
-- @return Une promesse qui se résout avec le résultat de la première promesse résolue
function Promise.race(promises)
	return Promise.new(function(resolve, reject)
		for _, promise in ipairs(promises) do
			promise:andThen(resolve, reject)
		end
	end)
end

--- Crée une promesse qui se résout après un délai
-- @param seconds Délai en secondes
-- @return Une promesse qui se résout après le délai
function Promise.delay(seconds)
	return Promise.new(function(resolve)
		spawn(function()
			wait(seconds)
			resolve()
		end)
	end)
end

--- Attend de manière synchrone la résolution de la promesse
-- AVERTISSEMENT: Cette méthode bloque le thread actuel et ne doit être utilisée qu'avec précaution
-- @return Le résultat ou la raison, et un booléen indiquant si la promesse a été résolue ou rejetée
function Promise:await()
	if self._status == STATUS.FULFILLED then
		return self._value, true
	elseif self._status == STATUS.REJECTED then
		return self._reason, false
	end
	
	-- Créer un événement pour attendre la résolution
	local bindable = Instance.new("BindableEvent")
	local result, success
	
	self:andThen(
		function(value)
			result = value
			success = true
			bindable:Fire()
		end,
		function(reason)
			result = reason
			success = false
			bindable:Fire()
		end
	)
	
	bindable.Event:Wait()
	bindable:Destroy()
	
	return result, success
end

return Promise
