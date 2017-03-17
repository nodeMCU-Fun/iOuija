--BOOT INTERUPTION SAFEGUARD
--Protects against infinite loop in code of primary program "iOuija.lua"
--via 10sec delay at reset
	
	function startup()
		dofile('iOuija.lua')
	end
	
print ("to abort type: file.remove('init.lua')")
tmr.alarm(0,10000,0,startup)

