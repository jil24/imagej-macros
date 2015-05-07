//make binary span 16-bit values
if (bitDepth() != 16) {
		exit;
	} else {
		max =  (pow(2, bitDepth())-1);
	}

changeValues(255,max,max);
