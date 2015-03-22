Stack.getPosition(c,s,f);
Stack.getActiveChannels(cstring);

cbinary = parseInt(cstring, 2);
newmask = toBinary(cbinary ^ pow(2,7-c));
leadingzeros = 7-lengthOf(newmask);

for (i=0; i<leadingzeros; i++){
	newmask = "0" + newmask;
}

Stack.setActiveChannels(newmask);