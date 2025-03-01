--[[
	Maid Module
	
	Un module d'utilitaire pour gérer le nettoyage des objets, événements et connections.
	Utilisé pour éviter les fuites de mémoire et assurer un nettoyage propre quand des objets ne sont plus nécessaires.
	
	API:
		Maid.new()
			Crée une nouvelle instance de Maid.
		
		Maid:GiveTask(task)
			Donne une tâche à Maid qui sera nettoyée plus tard.
			Les tâches peuvent être:
				- Une fonction à appeler
				- Une RBXScriptConnection à déconnecter
				- Une instance à détruire
				- Une table avec une méthode Destroy ou destroy
				- Une autre instance de Maid
				- Une table de tâches qui seront toutes nettoyées
		
		Maid:DoCleaning()
			Nettoie toutes les tâches assignées au Maid.
		
		Maid:Destroy()
			Nettoie toutes les tâches et déréférence le Maid pour la collecte des déchets.
--]]

local Maid = {}
Maid.__index = Maid

--- Crée une nouvelle instance Maid
function Maid.new()
	return setmetatable({
		_tasks = {}
	}, Maid)
end

--- Détermine si une valeur peut être nettoyée
-- @param value La valeur à vérifier
-- @return booléen, indiquant si la valeur peut être nettoyée
function Maid:CanClean(value)
	return typeof(value) == "function"
		or typeof(value) == "RBXScriptConnection"
		or typeof(value) == "Instance"
		or typeof(value) == "table" and (value.Destroy or value.destroy or value.Disconnect or value.disconnect)
		or typeof(value) == "table" and getmetatable(value) == Maid
end

--- Ajoute une tâche au Maid
-- @param task La tâche à ajouter. Voir les types supportés dans la documentation
-- @return La tâche ajoutée
function Maid:GiveTask(task)
	if not task then
		return task
	end
	
	if typeof(task) == "table" and not (task.Destroy or task.destroy or task.Disconnect or task.disconnect or getmetatable(task) == Maid) then
		-- Si c'est une table sans méthode de destruction, supposons que c'est une liste de tâches
		for _, subtask in pairs(task) do
			if self:CanClean(subtask) then
				self:GiveTask(subtask)
			end
		end
		return task
	end
	
	-- Vérifier si la tâche peut être nettoyée, sinon retourner telle quelle
	if not self:CanClean(task) then
		return task
	end
	
	-- Ajouter la tâche à la table des tâches pour le nettoyage futur
	local taskId = #self._tasks + 1
	self._tasks[taskId] = task
	
	return task
end

--- Nettoie une tâche spécifique
-- @param task La tâche à nettoyer
function Maid:_CleanTask(task)
	if typeof(task) == "function" then
		task()
	elseif typeof(task) == "RBXScriptConnection" then
		task:Disconnect()
	elseif typeof(task) == "Instance" then
		task:Destroy()
	elseif typeof(task) == "table" then
		if getmetatable(task) == Maid then
			-- Si c'est un autre Maid
			task:Destroy()
		elseif task.Destroy then
			task:Destroy()
		elseif task.destroy then
			task:destroy()
		elseif task.Disconnect then
			task:Disconnect()
		elseif task.disconnect then
			task:disconnect()
		end
	end
end

--- Nettoie toutes les tâches assignées au Maid
function Maid:DoCleaning()
	local tasks = self._tasks
	
	-- Réinitialiser la table des tâches pour éviter des problèmes pendant le nettoyage
	self._tasks = {}
	
	-- Nettoyer chaque tâche
	for _, task in pairs(tasks) do
		self:_CleanTask(task)
	end
end

--- Détruit le Maid et nettoie toutes les tâches
function Maid:Destroy()
	self:DoCleaning()
	setmetatable(self, nil)
end

return Maid
