--- Create Job at Runtime
--- @param name string
--- @param label string
--- @param grades table
function ESX.CreateJob(tb, label, grades, offduty)
	-- Support both table format {name = ..., label = ..., grades = ..., offduty = ...}
	-- and positional format (name, label, grades, offduty)
	if type(tb) == 'string' then
		tb = {
			name = tb,
			label = label or tb,
			grades = grades or {},
			offduty = (offduty == true or offduty == 1)
		}
	end

	if type(tb) ~= 'table' or next(tb) == nil then
		return print('[^3WARNING^7] parameter must be a table or valid arguments.')
	end
	if tb.name == nil or type(tb.name) ~= 'string' then
		return print('[^3WARNING^7] table must contain name(string) for the job name')
	end
	if tb.label == nil or type(tb.label) ~= 'string' then
		return print('[^3WARNING^7] table must contain label(string) for the job name label')
	end
	if tb.grades == nil or type(tb.grades) ~= 'table' or next(tb.grades) == nil then
		return print('[^3WARNING^7] table must contain grades(table)!')
	end
	local parameters, parameters2 = {}, {}
	local job, offdutyObj = {name = tb.name, label = tb.label, grades = {}}, {}
	if tb.offduty == true then
		offdutyObj = {name = 'off'..tb.name, label = tb.label, grades = {}}
	end
	for k,v in pairs(tb.grades) do
		job.grades[tostring(v.grade)] = {job_name = tb.name, grade = v.grade, name = v.name, label = v.label, salary = v.salary, skin_male = '{}', skin_female = '{}'}
		parameters[#parameters + 1] = { tb.name, v.grade, v.name, v.label, v.salary, '{}', '{}'}
		if tb.offduty == true then
			offdutyObj.grades[tostring(v.grade)] = {job_name = 'off'..tb.name, grade = v.grade, name = v.name, label = v.label, salary = 0, skin_male = '{}', skin_female = '{}'}
			parameters2[#parameters2 + 1] = { 'off'..tb.name, v.grade, v.name, v.label, 0, '{}', '{}'}
		end
	end
	if not ESX.DoesJobExist(tb.name, 0) then
	  MySQL.insert('INSERT IGNORE INTO jobs (name, label) VALUES (?, ?)', {tb.name, tb.label})
	  MySQL.prepare('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)', parameters)
	  ESX.Jobs[tb.name] = job
	end
	if tb.offduty == true then
		if not ESX.DoesJobExist(offdutyObj.name, 0) then
		  MySQL.insert('INSERT IGNORE INTO jobs (name, label) VALUES (?, ?)', {'off'..tb.name, 'Off-Duty'})
		  MySQL.prepare('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)', parameters2)
		  ESX.Jobs['off'..tb.name] = offdutyObj
		end
	end
end

function ESX.DeleteJob(name)
	if name == nil then
		return print('[^3WARNING^7] parameter must contain name(string) for the job name')
	end
	MySQL.update('DELETE FROM jobs WHERE name = ?', {name})
	MySQL.update('DELETE FROM job_grades WHERE job_name = ?', {name})
	ESX.Jobs[name] = nil
	local offduty = 'off'..name
	if ESX.DoesJobExist(offduty, 0) then 
		MySQL.update('DELETE FROM jobs WHERE name = ?', {offduty})
		MySQL.update('DELETE FROM job_grades WHERE job_name = ?', {offduty})
		ESX.Jobs[offduty] = nil
	end
end