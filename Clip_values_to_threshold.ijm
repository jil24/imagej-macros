//clip all to threshold
getThreshold(lower, upper);

if (bitDepth() == 32) {
		exit;
	} else {
		max =  (pow(2, bitDepth())-1);
	}

if (lower != -1) {
	changeValues(0,lower,lower);
	changeValues(upper,max,upper);
}
