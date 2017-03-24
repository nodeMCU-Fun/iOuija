--iOuija.lua
--Receives annonymous messages from a web page 
--and displays them on an OLED screen.
--Cobbled together by Tim Connolly
--

print("**iOuija.lua STARTED**")

--CUSTOMIZE THESE TO YOUR SYSTEM
routerPort=	--Router Port Number for NodeMCU
routerUsername = ""	--Router Username
routerPassword = ""	--Router Password


--CONSTANTS & VARIABLES
sda = 1 		-- OLED SDA Pin 1=D1
scl = 2 		-- OLED SCL Pin 2=D2
vars = " "		-- RAW ARGUMENTS SENT FROM WEB-PAGE
totmsg = 0		-- COUNT OF MESSAGES RECEIVED 

OLEDlines={}	-- OLED SCREEN BUFFER  (FOUR LINES FOR TEXT PRE-SET TO " ")
for j=1,4 do	
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

--TRACK TOTAL NUMBER OF MESSAGES  (Persistent between sessions)
function totalMessages()
	file.open("TotMsg.txt")
	totmsg=file.readline()
	file.close()
	file.open("TotMsg.txt", "w")
	file.writeline(totmsg+1)                                             
	file.close()
end

--WRITE DATA TO OLED DISPLAY
function write_OLED()
	--CLEAR SCREEN
	disp:firstPage()
	repeat until disp:nextPage() == false
	--DISPLAY NEW DATA
	disp:firstPage()
	repeat
		disp:drawStr(5, 10, OLEDlines[1])
		disp:drawStr(5, 22, OLEDlines[2])
		disp:drawStr(5, 34, OLEDlines[3])
		disp:drawStr(5, 46, OLEDlines[4])
		disp:drawStr(5, 56, ("Message # "..totmsg))
	until disp:nextPage() == false
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
srv:listen(routerPort,function(conn)
    conn:on("receive", function(client,request)
        local buf = ""
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP")
        
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
			print(str)
			str = string.gsub (str, "+", " ")
			--WHY THE HELL DOES function(h) return string.char(tonumber(h,16)) end) FAIL?!?
			--%21%40%23%24%25%5E%26*%28%29_%2B-%3D%7B%7D%7C%5B%5D%5C%3A%22%3B%27%3C%3E%3F%2C.%2F
			str = string.gsub (str, "%%(21)", "!") 
			str = string.gsub (str, "%%(26)", "&")
			str = string.gsub (str, "%%(22)", '"') 
			str = string.gsub (str, "%%(27)", "'") 
			str = string.gsub (str, "%%(2C)", ",") 
			str = string.gsub (str, "%%(3F)", "?") 
			str = string.gsub (str, "%%(%x%x)", " ") 
			str = string.gsub (str, "\r\n", "\n")
			
			--APPEND CURRENT MESSAGE CONTENT TO A FILE OF ALL MESSAGES
			file.open("messages.txt","a")
			file.writeline(str)
			file.close()
			youSent=str
			buf=buf..'<br>You sent: "'..youSent..'"'
			
			--SLICE THE MESSAGE UP TO FIT THE 4-LINE OLED DISPLAY  ("SMART" LINE BREAKS WASTE SCREEN SPACE IMHO)
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
			totalMessages()
			write_OLED()
			
			--CLEAR MESSAGE BUFFER
			for k=1,4 do OLEDlines[k]="" end
		end
		
		--MORE WEB PAGE CONSTRUCTION
		buf=buf..'<p>I created iOuija as an interactive electronic art installation.'
		buf=buf..'<br>What sort of 80 character messages will you send with 100% anonymity?'
		buf=buf..'<br>In iOuija, YOU become the ghost in my machine.  Enjoy!'
		buf=buf..'<br><br>Learn more about iOuija including how to build your own.'
		buf=buf..'<br><a href="https://github.com/nodeMCU-Fun/iOuija">Join iOuija on GitHub</a>'
		buf=buf..'</center>'
		buf=buf.."</html>"
		
		--RENDER THE WEB PAGE
		client:send(buf)	
        client:close()
        collectgarbage()
                
    end)
end)
