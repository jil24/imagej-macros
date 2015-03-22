Stack.getPosition(c,s,f);
Stack.getActiveChannels(cstring);

cbinary = parseInt(cstring, 2);
inversemask = pow(2,7-c) ^ parseInt("1111111", 2);
newmask = toBinary(cbinary ^ inversemask);
leadingzeros = 7-lengthOf(newmask);

for (i=0; i<leadingzeros; i++){
	newmask = "0" + newmask;
}

Stack.setActiveChannels(newmask);