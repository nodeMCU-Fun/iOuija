

--CONSTANTS & VARIABLES
sda = 1 		-- OLED SDA Pin 1=D1
scl = 2 		-- OLED SCL Pin 2=D2
i=0				-- MULTI-USE COUNTER
vars=" "		-- ARGUMENTS FROM WEB-PAGE
onboardLED = 4	-- PIN NUMBER OF nodeMCU DEV BOARD LED  Pin 4=D4
routerUsername = " "	--Router Username
routerPassword = " "	--Router Password

--CREATE OLED SCREEN BUFFER
OLEDlines={}
for j=1,4 do			--FOUR LINES FOR TEXT PRE-SET TO " "
	OLEDlines[j]=" "
end

--INITIALIZE THE OLED DISPLAY
function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
end

--WRITE DATA TO OLED DISPLAY
function write_OLED() -- Write Display

	--+= TOTAL MESSAGE COUNT  (Persistent between sessions)
	file.open("TotMsg.txt")
	totmsg=file.readline()
	totmsg=totmsg+1
	file.close()

	disp:firstPage()
	repeat
		disp:drawStr(5, 10, OLEDlines[1])
		disp:drawStr(5, 22, OLEDlines[2])
		disp:drawStr(5, 34, OLEDlines[3])
		disp:drawStr(5, 46, OLEDlines[4])
		disp:drawStr(5, 56, ("Message # "..totmsg))
	until disp:nextPage() == false
	
	--LOG NEW MESSAGE COUNT
	file.open("TotMsg.txt", "w")
	file.writeline(totmsg)                                             
	file.close()
   
end

----------------
--MAIN PROGRAM--
----------------

--INITIALIZE OLED
init_OLED(sda,scl)

--SET UP WIFI STATION & SERVER
wifi.setmode(wifi.STATION)
wifi.sta.config(routerUsername,routerPassword)
srv=net.createServer(net.TCP)


--SERVER CONTROL LOOP
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local buf = ""
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP")
        local iGET = {}
        
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
        end
        
        if (vars ~= nil)then
			for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                iGET[k] = v
            end
        end

		--CONSTRUCT THE WEB PAGE
		buf=buf.."<html>"
		 buf=buf.."<center><h1>iOuija - The Original Talking Screen</h1>";  
        buf=buf..'<img src="https://scontent-ort2-1.xx.fbcdn.net/v/t1.0-9/17352496_869794783185970_3446150579443806505_n.jpg?oh=c20e7db481ac0470ebba8e8156258fa6&oe=595DF747" width="300">'
        buf=buf..'<form action="" target="" method="get">'
		buf=buf..'Send a message to my iOuija screen:<br>'
		buf=buf..'<textarea maxlength="80" name="textAreaName" rows="1" cols="80"></textarea><br>'
		buf=buf..'<input type="submit" value="Send">'
		buf=buf..'</form>'
		
		        
        
        
        --IF THERE IS A NEW MESSAGE, PROCESS IT
        if (vars ~= nil) and (string.sub(vars, 1, 3)=="tex") then
			str="empty"
			str=string.sub(vars, 14)
			str = string.gsub (str, "+", " ")
			str = string.gsub (str, "%%(%x%x)", " ")  --This has to be fixed to properly render special chars
			str = string.gsub (str, "\r\n", "\n")
			strFileOutput=str
			
			--SLICE THE MESSAGE UP TO FIT THE 4-LINE OLED DISPLAY
			--SMART LINE BREAKS WASTE SCREEN SPACE IMHO
			for k=1,4 do
				j=string.len(str)
				if (j<21) then
					OLEDlines[k]=str
					break
				elseif (j>20) then
					OLEDlines[k]=string.sub(str, 1, 20)
					str=string.sub(str, 21)
				end
			end
			
					
			i=i+1
			write_OLED()
			
		--APPEND CURRENT MESSAGE TO A FILE OF MESSAGES
		file.open("messages.txt","a")
		file.writeline(strFileOutput)
		file.close()
			
			
		end
		
		--MORE WEB PAGE CONSTRUCTION
		buf=buf..'<br>I created iOuija as an interactive electronic art installation.'
		buf=buf..'<br>What sort of 80 character messages will you send with 100% anonymity?'
		buf=buf..'<br>In iOuija, YOU become the ghost in my machine.  Enjoy!'
		buf=buf..'<br><br>Learn more about iOuija including how to build your own.'
		buf=buf..'<br><a href="https://www.facebook.com/IOuija-867070323458416/">Join iOuija on Facebook</a>'
		buf=buf..'</center>'
		buf=buf.."</html>"
		
		
		
		
                
        client:send(buf)	--RENDER THE WEB PAGE
        client:close()
        collectgarbage()
                
    end)
end)
