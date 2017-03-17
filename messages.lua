
file.open("messages.txt")
while true do
	i=file.readline()
	if i==nil then break end
	print (i)
end
file.close()
