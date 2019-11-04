//Alpha_Shape.ijm
//version 1.03a 20191030 - fixed variable type issue for new version of Imagej.
//version 1.03 20140831 - added progress indicators to status bar.
//version 1.02 20140713 - fixed bug that always included the first point on the left in an alpha shape
//also made alpha scaled to the current image's scale
//Jonathan Lake jil24@cornell.edu

if (selectionType() != 10) { exit("A point selection is required."); }

//pull the last-used alpha value from imageJ's preferences or use 0 as a default
alpha = call("ij.Prefs.get", "alphashapes.alpha", "0"); 
if (isNaN(alpha)) {alpha=0;} 

//ask for alpha
Dialog.create("Alpha Shape");
Dialog.addMessage("Computes a regularized two-dimensional alpha shape from a point selection.");
Dialog.addMessage("This shape will not include isolated points or edges");
Dialog.addNumber("Alpha (in scaled units):", alpha);
Dialog.show();

alpha =  Dialog.getNumber();
alpha = parseFloat(alpha);  //convert string to number

//save the alpha value for later.
call("ij.Prefs.set", "alphashapes.alpha", alpha);
toUnscaled(alpha); //modifies alpha in place for scaling.

//utility functions

function swap(a,b) {
	c = b;
	b = a;
	a = c;
}

function removeelementsbyvalue(array, i) { //might remove more than one thing
	new = newArray();
	narray = array.length;
	for (j=0;j<narray;j++){
		if (i != array[j]) {new = Array.concat(new,array[j]);}
	}
	return new;
}

function removeelementbyindex(array, i) {
	new = newArray();
	narray = array.length;
	for (j=0;j<narray;j++){
		if (i != j) {new = Array.concat(new,array[j]);}	
	}
	return new;
}

function insertintoarraybefore(array, i, value) {
	new = newArray();
	narray = array.length;
	for (j=0;j<narray;j++){
		if (i == j) {new = Array.concat(new,value);}
		new = Array.concat(new,array[j]);
	}
	return new;
}

function arraymin(input) {
	min=0;
	max=0;
	mean=0;
	stdDev=0;
	Array.getStatistics(input, min, max, mean, stdDev);
	return min;
}

function arraymax(input) {
	min=0;
	max=0;
	mean=0;
	stdDev=0;
	Array.getStatistics(input, min, max, mean, stdDev);
	return max;
}

function index(a, value) { //get an element's index by value, (first occurrence)
      for (i=0; i<a.length; i++)
          if (a[i]==value) return i;
      return -1;
} 


//geometry functions

function pnpoly(testpoint, poly) { //is a point inside a polygon?
	testx = xpoints[testpoint];
	testy = ypoints[testpoint];
	npoly = lengthOf(poly);
	polyx = newArray(poly.length);
	polyy = newArray(poly.length);
	r = npoly-1;
	c = 0;
	for (q = 0; q < npoly; q++) {
		polyx[q] = xpoints[poly[q]];
		polyy[q] = ypoints[poly[q]];
	}
	for (q = 0; q < poly.length; q++) {
		if ( ((polyy[q]>testy) != (polyy[r]>testy))) {
			if ((testx < (polyx[r]-polyx[q]) * (testy-polyy[q]) / (polyy[r]-polyy[q]) + polyx[q]) ) {
				c = !c;
			}
		}
		r = q;
	}
	return c;
}

//translated almost verbatim from line-segments-intersect.js by pgkelley4@gmail.com

function crossProduct(rx,ry,sx,sy) { //returns the scalar magnitude of the crossproduct, which projects into the z axis
	return ((rx * sy) - (ry * sx));
}

function intersectSegments(px1,py1,px2,py2,qx1,qy1,qx2,qy2) { //do line segments intersect?
	rx = px2-px1;
	ry = py2-py1;
	sx = qx2-qx1;
	sy = qy2-qy1; //vector components of the line segments
	//for debug
//	setColor(floor(random()*256),floor(random()*256),floor(random()*256));
//	setLineWidth(2);
//	drawLine(px1,py1,px2,py2);
//	drawLine(qx1,qy1,qx2,qy2);
//	waitForUser("next step");

	uNumerator = crossProduct(qx1-px1,qy1-py1,rx,ry);
	denominator = crossProduct(rx,ry,sx,sy);

	if (uNumerator == 0 && denominator == 0) {
		// colinear, so do they overlap?
		return (((qx1 - px1 < 0) != (qx1 - px2 < 0)) != ((qx2 - px1 < 0) != (qx2 - px2 < 0))) || ((qy1 - py1 < 0) != (qy1 - py2 < 0) != (qy2 - py1 < 0) != (qy2 - py2 < 0));
	}

	if (denominator == 0) {
	// lines are paralell
	return 0;
	}

	u = uNumerator / denominator;
	t = crossProduct(qx1-px1,qy1-py1,sx,sy) / denominator;

	return ((t >= 0) && (t <= 1) && (u >= 0) && (u <= 1));
}

function incircle (u,v,p,q) {
	ux = xpoints[u];
	uy = ypoints[u];
	vx = xpoints[v];
	vy = ypoints[v];
	px = xpoints[p];
	py = ypoints[p];
	qx = xpoints[q];
	qy = ypoints[q];
	uxy2 = ux*ux+uy*uy;
	vxy2 = vx*vx+vy*vy;
	pxy2 = px*px+py*py;
	qxy2 = qx*qx+qy*qy;

	//to save myself a lot of work I calculated the laplace expansion of the relevant 4x4 determinant symbolically using SymPy.
	incircledet = (px*qxy2*uy) - (px*qxy2*vy) - (px*qy*uxy2) + (px*qy*vxy2) + (px*uxy2*vy) - (px*uy*vxy2) - (pxy2*qx*uy) + (pxy2*qx*vy) + (pxy2*qy*ux) - (pxy2*qy*vx) - (pxy2*ux*vy) + (pxy2*uy*vx) + (py*qx*uxy2) - (py*qx*vxy2) - (py*qxy2*ux) + (py*qxy2*vx) + (py*ux*vxy2) - (py*uxy2*vx) - (qx*uxy2*vy) + (qx*uy*vxy2) + (qxy2*ux*vy) - (qxy2*uy*vx) - (qy*ux*vxy2) + (qy*uxy2*vx);
	orderdet = (px*uy) - (px*vy) - (py*ux) + (py*vx) + (ux*vy) - (uy*vx);
//	print(incircledet * orderdet);
	return (incircledet * orderdet < 0);
}


function trixy(tri){
	tri = tri * 6; //tri id to coordinates
	coords = newArray();
	for (p = 0; p < 3; p++) {
		coords = Array.concat(coords, xpoints[tris[tri+p]], ypoints[tris[tri+p]]);
	}
	return coords;
}

function makeborderpolyconvex(newpoint) {
	oldnborderseg = borderpoly.length;
	newborderpoly = newArray();
	for(testpoint=0;testpoint<oldnborderseg;testpoint++) {
		inside = false;
		for(pone=0;pone<oldnborderseg;pone++) {
			if (pone != testpoint) {
				for(ptwo=0;ptwo<oldnborderseg;ptwo++) {
					if (ptwo != pone && ptwo != testpoint) { 
						if (newpoint != borderpoly[ptwo] && newpoint != borderpoly[pone] && newpoint != borderpoly[testpoint]) {
							enclosingtriangle = newArray(borderpoly[pone],borderpoly[ptwo],newpoint);
//							print(""+borderpoly[pone]+" "+borderpoly[ptwo]+" "+newpoint+ " " + testpoint);
							if (pnpoly(borderpoly[testpoint], enclosingtriangle) == true) {
								inside = true;
//								print("inside");
								ptwo = 1e99; pone = 1e99; //bailout								
							}
						}
					}
				}
			}
		}
		if (inside == false) {
			newborderpoly = Array.concat(newborderpoly, borderpoly[testpoint]);
		}
	}
	borderpoly = newborderpoly;
	nborderseg = borderpoly.length;
}


function regeneratebordermidpoints() {
			nborderseg = borderpoly.length;
			bordersegmx=newArray(nborderseg); //reset 
			bordersegmy=newArray(nborderseg); //reset 
			m=nborderseg-1;
			for(borderseg=0;borderseg<nborderseg;borderseg++) {
				bordersegmx[borderseg]=(xpoints[borderpoly[m]]+xpoints[borderpoly[borderseg]])/2;
				bordersegmy[borderseg]=(ypoints[borderpoly[m]]+ypoints[borderpoly[borderseg]])/2;
				m = borderseg;
			}
}

function trisborderingedge(pointa,pointb) {
	//each edge borders at most 2 triangles
	twotris = newArray();
	ntri=lengthOf(tris)/6;
	for (t=0;t<ntri;t++) {
		ctri = Array.slice(tris,t*6,(t*6)+3);
		if (index(ctri,pointa) != -1) {
			if (index(ctri,pointb) != -1) {
				twotris = Array.concat(twotris,t);
				if (twotris.length == 2) {return twotris;}
			}
		}
	}
	//if we've made it through the loops that means there's only one (or no) tris bordering that edge.
	if (twotris.length==0) {return newArray(-1,-1)}; //this shouldn't happen
	twotris = Array.concat(twotris,-1);
	return twotris;
}

function trisborderingtri(tri) {
	tri = tri * 6;
	trineighbors = newArray(-1,-1,-1);
	for (s=0;s<3;s++){
		r=(3+s-1)%3; //wraparound
		edgeneighbors = trisborderingedge(tris[tri+r],tris[tri+s]);
		if ((edgeneighbors[0] * 6) == tri) { //one triangle is the input triangle
				trineighbors[s] = edgeneighbors[1];
			} else {
				trineighbors[s] = edgeneighbors[0];
			} // this will still return -1 if there's no other one :)
	}
	return trineighbors;
}

function addTri(trianglearray,j,k,l) {
	trianglearray = Array.concat(trianglearray,j,k,l,-1,-1,-1);
	return trianglearray;
}


var arraystartvalue = newArray();
arraystartvalue = Array.concat(arraystartvalue,-1);

function updatetrineighbors(tri, start) {
	//when initially invoking updatetrineighbors, start should = -1 in 1st position otherwise for recursion it has a list of already touched triangles
	print(start[0]);
	if (start[0] == -1) {
		alreadycalculated=newArray();
	} else {
		alreadycalculated=start;	
	}
	trineighbors = trisborderingtri(tri);
	tri = tri * 6; //id to array coordinate
	alreadycalculated = Array.concat(alreadycalculated,(tri/6)); //flag as touched
	for (s=0;s<3;s++){
		tris[tri+3+s]=trineighbors[s]; //update global
		//check if neighbor already knows about this tri
//		print(trineighbors[s]);
//		Array.print(alreadycalculated);
		if (trineighbors[s] != -1 && index(alreadycalculated,trineighbors[s]) == -1) {
			neighborneighbors = Array.slice(tris,trineighbors[s]*6+3,trineighbors[s]*6+6);
			if (index(neighborneighbors,tri/6) == -1) {
//				print("I am triangle " + tri/6 + " and neighbor " + trineighbors[s] + " should include me - includes:");
				Array.print(alreadycalculated);
				print("beginning recursion");
				updatetrineighbors(trineighbors[s], alreadycalculated); //recursion time
			}
//			Array.print(neighborneighbors);
		}
	}
print("made it through once");
}

function getotherpoint(tri,u,v) {
	tripoints = Array.slice(tris,tri*6,(tri*6)+3);
	for (i=0;i<3;i++) {
		if ((tripoints[i] != u) && (tripoints[i] != v)) {return tripoints[i];}
	}
}

function getedgesfromtri(tri) {
	edges = newArray();
	for (i=0;i<3;i++) {
		j=(3+i+1)%3; //next point
		//make sure edges are provided in ascending pointid order - makes searching easier
		if (tris[tri*6+i]<tris[tri*6+j]) {
			edges = Array.concat(edges,tris[tri*6+i]);
			edges = Array.concat(edges,tris[tri*6+j]);
		} else { //reverse order
			edges = Array.concat(edges,tris[tri*6+j]);
			edges = Array.concat(edges,tris[tri*6+i]);			
		}

	}
	return edges;
}

function getedgeindex(u,v) {//returns the index of the first point in an edge from the edgestack when edge is provided as two pointids in ascending order
						//returns -1 if no match
	if (u>v) {swap(u,v);} // just make sure they're in order
	edgestacklength = edgestack.length;
	for (i=0;i<edgestacklength;i=i+2) {
		if (edgestack[i] == u && edgestack[i+1] == v) {
				return i;
			}	
	}
	return -1; //if loop finishes
}

function adduniqueedges(edges) { //adds unique edges to the edgestack when passed an array of edges - points in each edge should be in ascending order
	nedges = edges.length;
	for (i=0;i<nedges;i=i+2) {
//		print(getedgeindex(edges[i],edges[i+1]));
		if (getedgeindex(edges[i],edges[i+1])==-1) {
			edgestack = Array.concat(edgestack,edges[i],edges[i+1]);
		}
	}
}

function deleteedge(u,v) { //deletes an edge from the edgestack
	if (u>v) {swap(u,v);} // just make sure they're in order
	edgeindex = getedgeindex(u,v);
	before = Array.slice(edgestack,0,edgeindex);
	after = Array.slice(edgestack,edgeindex+2,edgestack.length);
	edgestack = Array.concat(before,after);
}

function edgeflipifnotld (u,v) {
//	Array.print(edgestack);
	deleteedge(u,v); //remove from the stack
	//returns 1 if an edge got flipped, 0 if no flip neccesary
	
	//this function won't check for an edge on the outside.  
	tristoreplace = trisborderingedge(u,v);
	p = getotherpoint(tristoreplace[0],u,v);
	q = getotherpoint(tristoreplace[1],u,v);
//	print(p);print(q);
	//u and v represent a currently existing edge, p and q are the other points forming the triangles
//	print(tris[tristoreplace[1]*6],tris[tristoreplace[1]*6+1],tris[tristoreplace[1]*6+2]);
//	print(u,v,p,q);
	if (incircle(u,v,p,q)) {
		//if this is true then we are non-ld
//		print("non-ld");
		//make triangle pqu
		tris[tristoreplace[0]*6+0] = p;
		tris[tristoreplace[0]*6+1] = q;
		tris[tristoreplace[0]*6+2] = u;
		//make triangle pqv
		tris[tristoreplace[1]*6+0] = p;
		tris[tristoreplace[1]*6+1] = q;
		tris[tristoreplace[1]*6+2] = v;
		
//		setColor(255,255,255);
//		drawLine(xpoints[p],ypoints[p],xpoints[q],ypoints[q]);
		
		//erase the neighbor data for neighboring triangles for each new one
		erasea = trisborderingtri(tristoreplace[0]);
		eraseb = trisborderingtri(tristoreplace[1]);
		erase = Array.concat(erasea,eraseb);
		for (i=0;i<6;i++) {
			if (erase[i] != -1) {
				tris[erase[i]*6+3] = -1;
				tris[erase[i]*6+4] = -1;
				tris[erase[i]*6+5] = -1;
			}
		}
		//regenerate neighbor data
		updatetrineighbors(tristoreplace[0], arraystartvalue);

		//make a list neighboring edges to possibly add to the edgestack
		sortedup = newArray(u,p); sortedup = Array.sort(sortedup); 
		sortedpv = newArray(p,v); sortedpv = Array.sort(sortedpv); 
		sortedvq = newArray(v,q); sortedvq = Array.sort(sortedvq); 
		sortedqu = newArray(q,u); sortedqu = Array.sort(sortedqu); 
		edgestoldtest = Array.concat(sortedup,sortedpv,sortedvq,sortedqu);
		for (i=0;i<8;i=i+2) { //test those edges - add to the edgestack if they aren't on the border of the convex hull
			j=trisborderingedge(edgestoldtest[i],edgestoldtest[i+1]);
//			Array.print(j);
			if (j[1]!=-1) { //e.g. if this edge isn't on the border of the convex hull
				edgetoadd = newArray(edgestoldtest[i],edgestoldtest[i+1]);
//				Array.print(edgetoadd);
				adduniqueedges(edgetoadd);
			}
		}
//		Array.print(edgestack);
	} else {
		//if already ld
//		setColor(255,255,255);
//		drawLine(xpoints[u],ypoints[u],xpoints[v],ypoints[v]);
	}
//	waitForUser("x");
}








//start the triangulation







setBatchMode(true);

var xpoints = newArray();
var ypoints = newArray();

edges = newArray(); //edges to be stored as two point ids in succession
var tris = newArray(); //three point ids in succession followed by three tri ids (that border edges) in succession or -1 if no border.
var borderpoly = newArray(); //point ids on the boundary of the expanding triangulation, in connecting order
var edgestack = newArray(); //two point ids for edges to be checked for ld at each step

Roi.getCoordinates(xpoints, ypoints);
n=lengthOf(ypoints);
if (n < 3) {
	print('<3 points, exiting.');
	exit;
	}
xranks = Array.rankPositions(xpoints);
ysorted = newArray(n);
		//sort x directly
Array.sort(xpoints);
		//sort ypoints by x coordinates
for (p=0;p<n;p++) {
	ysorted[p]=ypoints[xranks[p]];
}
ypoints = ysorted;

//add the first three points as a triangle
tris = addTri(tris,0,1,2);
borderpoly = Array.concat(borderpoly,0,1,2);
var nborderseg=lengthOf(borderpoly); //global
var bordersegmx=newArray(nborderseg); //global
var bordersegmy=newArray(nborderseg); //global

	//I think collinear "triangles" eventually get discarded by the edge flipping algo so we don't need to worry about it

	//iterate over all the rest of the points, building the triangulation.
	//all points are guaranteed to be either outside the convex hull or collinear with it (due to x-sort)
for (p=3;p<n;p++) {
//	print(p);
	//generate all borderpoly segment midpoints
	tristomake = newArray();
	regeneratebordermidpoints();
	for (testsegment=0;testsegment<nborderseg;testsegment++) {
		//shoot edges to all borderpoly segment midpoints
		lineofsight=1;
		m = nborderseg -1;
		for(borderseg=0;borderseg<nborderseg;borderseg++) {
			//check if they intersect any other edges
			if (intersectSegments(
			xpoints[borderpoly[borderseg]],
			ypoints[borderpoly[borderseg]],
			xpoints[borderpoly[m]],
			ypoints[borderpoly[m]],
			bordersegmx[testsegment],
			bordersegmy[testsegment],
			xpoints[p],
			ypoints[p])) {
				if (testsegment != borderseg) { //don't discount if we are testing to the same edge we're aiming at 
					lineofsight=0;
					borderseg=1e99; //bail out of the loop.
				}
			}
			m = borderseg;
		}
		if (lineofsight==1) {
			//if they don't, make a triangle between point and edge.
			tristomake = Array.concat(tristomake,testsegment);
			//end processing of each ray
		}
	
	}
		
	//back to processing per-point

	edgestoldtest = newArray();
	for (t=0;t<tristomake.length;t++){
		//m has changed, let's recalculate it, ensuring proper wraparound...
		m = (nborderseg + tristomake[t] - 1) % nborderseg;
		tris = addTri(tris,borderpoly[m],borderpoly[tristomake[t]],p);
		pointsintri = newArray(borderpoly[m],borderpoly[tristomake[t]],p);
		pointsintri = Array.sort(pointsintri); //sort points so recording the edges goes in order
		edgestoldtest = Array.concat(edgestoldtest,pointsintri[0],pointsintri[1],pointsintri[1],pointsintri[2],pointsintri[0],pointsintri[2]);
		//for debug
//		vc = trixy((tris.length)/6-1);
//		fillOval((vc[0]+vc[2]+vc[4])/3-4,(vc[1]+vc[3]+vc[5])/3-4,8,8);
	}
	if (tristomake.length != 0) {
//		Array.print(borderpoly);
//		print("made " + tristomake.length + " new triangles");
//		Array.print(tristomake);
		tempborderpolybefore = Array.slice(borderpoly,0,tristomake[0]);
		tempborderpolyafter = Array.slice(borderpoly,tristomake[0],nborderseg);
		borderpoly = Array.concat(tempborderpolybefore,p,tempborderpolyafter);
		makeborderpolyconvex(p);		
//		Array.print(borderpoly);
		regeneratebordermidpoints();
		updatetrineighbors(tris.length/6-1,arraystartvalue); //start a triangle update from the last triangle made
		nedgestoldtest = edgestoldtest.length;
		for (i=0;i<nedgestoldtest;i=i+2) {
			j=trisborderingedge(edgestoldtest[i],edgestoldtest[i+1]);
			if (j[1]!=-1) { //e.g. if this edge isn't on the border of the convex hull
				edgetoadd = newArray(edgestoldtest[i],edgestoldtest[i+1]);
				adduniqueedges(edgetoadd);
			}
		}
//		Array.print(bordersegmx);
//		Array.print(bordersegmy);
//		Array.print(borderpoly);

		//now do edgeflips on the edgestack every 50 added points
		if (p % 50 == 0) {
			while (edgestack.length > 0) {
				edgeflipifnotld(edgestack[0],edgestack[1]);	
//				print(edgestack.length/2);
				showStatus("Alpha Shape: Computing Delaunay Triangulation: " + round(100*p/n) + "%");
			}
		}
	}
		//end per-point processing
		 
}

//edgeflip again
while (edgestack.length > 0) {
			edgeflipifnotld(edgestack[0],edgestack[1]);	
//			print(edgestack.length/2);
}






// now calculate the alpha shape
showStatus("Alpha Shape: Calculating Alpha Shape...");

//functions for doing this:
function compareTri(tri,alpha) { //return 1 if entire tri is in the alpha shape
	twoalphasquared = alpha * alpha * 4;
	tri = tri * 6; //tri id to coordinates
	adx = (xpoints[tris[tri+1]] - xpoints[tris[tri]]);
	ady = (ypoints[tris[tri+1]] - ypoints[tris[tri]]);
	sideasquared = adx*adx + ady*ady;

	bdx = (xpoints[tris[tri+2]] - xpoints[tris[tri+1]]);
	bdy = (ypoints[tris[tri+2]] - ypoints[tris[tri+1]]);
	sidebsquared = bdx*bdx + bdy*bdy;

	cdx = (xpoints[tris[tri]] - xpoints[tris[tri+2]]);
	cdy = (ypoints[tris[tri]] - ypoints[tris[tri+2]]);
	sidecsquared = cdx*cdx + cdy*cdy;

	if (twoalphasquared <= sideasquared || twoalphasquared <= sidebsquared || twoalphasquared <= sidecsquared) {
		return 0;
	}
	else { return 1;}
}

function compareEdge(u,v,alpha) { //return 1 if edge is in the alpha shape
	twoalphasquared = alpha * alpha * 4;
	dx = (xpoints[u] - xpoints[v]);
	dy = (ypoints[u] - ypoints[v]);
	edgesquared = dx*dx + dy*dy;

	if (twoalphasquared <= edgesquared) {
		return 0;
	}
	else { return 1;}
}

function alphaedgeunique(n) {//count of the edge specified (by coord of first point) in edgesinalpha?
						//returns 1 if unique or 0 if not unique
	count = 0;
	u = edgesinalpha[n];
	v = edgesinalpha[n+1];
	for (i=0;i<edgesinalphalength;i=i+2) {
		if (edgesinalpha[i] == u && edgesinalpha[i+1] == v) {
				count++;
				if (count == 2) {return 0;}
			}	
	}
	return count; //if loop finishes
}

function xcoordfrompointlist(pointlist) {
	coords = newArray();
	npointlist = pointlist.length;
	for (i=0;i<npointlist;i++) {
		coords = Array.concat(coords,xpoints[pointlist[i]]);
	}
	return coords;
}

function ycoordfrompointlist(pointlist) {
	coords = newArray();
	npointlist = pointlist.length;
	for (i=0;i<npointlist;i++) {
		coords = Array.concat(coords,ypoints[pointlist[i]]);
	}
	return coords;
}


// make a list of all the triangles in the alpha shape

var edgesinalpha = newArray();
var ntri=lengthOf(tris)/6;

for (i=0;i<ntri;i++) {
	//make a list of all the edges in those triangles. (within an edge points are in ascending order)
	if (compareTri(i,alpha)==1) {
		singletriedges = getedgesfromtri(i);
		edgesinalpha = Array.concat(edgesinalpha, singletriedges);
	} 
}
	//keep edges that are unique (e.g. on the border) in a uniquealphaedgelist

var edgesinalphalength = edgesinalpha.length;
var uniquealphaedgelist = newArray();

for (i=0;i<edgesinalphalength;i=i+2) {
	if (alphaedgeunique(i)) {
		uniquealphaedgelist = Array.concat(uniquealphaedgelist,edgesinalpha[i],edgesinalpha[i+1]);
		}
}

	//if we are doing isolated edges too, remove them from the 

	
//Array.print(edgesinalpha);
//Array.print(uniquealphaedgelist); 

	//	starting from the first edge (u,v) in uniquealphaedgelist (remember point u for later), 
	//  run through the other edges to find the one whose u or v
	//  matches v of current edge, then make that the current edge
	//  adding the second point from each edge to a polygon (remove from uniqueedgelist) until no matches found
	// 	then start a new edgelist for a new polygon

currentpoint = 0;
if (uniquealphaedgelist.length != 0) {
currentpoly = newArray();
Array.concat(currentpoly,uniquealphaedgelist[currentpoint]);
u = uniquealphaedgelist[currentpoint];
v = uniquealphaedgelist[currentpoint+1];
endpoint = u;
}
polycount = 0;

if (isOpen("ROI Manager")) {
     selectWindow("ROI Manager");
     run("Close");
}
//	Array.print(uniquealphaedgelist);
//	Array.print(currentpoly);
while (uniquealphaedgelist.length != 0) {
//	Array.print(uniquealphaedgelist);
	currentpoly = Array.concat(currentpoly,v);
	uniquealphaedgelist = removeelementbyindex(uniquealphaedgelist, currentpoint);
	uniquealphaedgelist = removeelementbyindex(uniquealphaedgelist, currentpoint);
	//remove both points from the list
	//now find the first instance of v left in the list
	nextedge = floor(index(uniquealphaedgelist,v)/2)*2; //always return the coord of the first point in the edge - negative 1 becomes negative 2 in this case
//	print(nextedge);
	if (nextedge != -2) { //if we found a next edge
		currentpoint = nextedge; //set the next one to delete
		if (v == uniquealphaedgelist[nextedge]) {
			//found edge in in forward order
			u = uniquealphaedgelist[nextedge];
			v = uniquealphaedgelist[nextedge+1];
		} else {
			//found edge is in reverse order
			v = uniquealphaedgelist[nextedge];
			u = uniquealphaedgelist[nextedge+1];
		}
	} else { //no next edge, add poly to RoiManager and start a new polygon!
//		Array.print(currentpoly);
			currentpolyx = xcoordfrompointlist(currentpoly);
			currentpolyy = ycoordfrompointlist(currentpoly);

			
			makeSelection("polygon",currentpolyx,currentpolyy);
			roiManager("add");
			polycount++;
			
			//restore the point selection so it can be remembered
			run("Restore Selection");
			
			
		if (uniquealphaedgelist.length != 0) {
			currentpoly = newArray();
			u = uniquealphaedgelist[0];
			v = uniquealphaedgelist[1];
		}
	}
}


if (polycount != 0) {
	roiManager("XOR");
	roiManager("reset");
} else {
	toScaled(alpha);
	exit("alpha value of " + alpha + " produces an empty alpha shape.")
}

setBatchMode(false);
showStatus("Done.");









//debugging functions and commands to draw the entire triangulation and alpha shape
function drawTri(tri) {
	tri = tri * 6; //tri id to coordinates
	drawLine(xpoints[tris[tri]],ypoints[tris[tri]],xpoints[tris[tri+1]],ypoints[tris[tri+1]]);
	drawLine(xpoints[tris[tri+1]],ypoints[tris[tri+1]],xpoints[tris[tri+2]],ypoints[tris[tri+2]]);
	drawLine(xpoints[tris[tri+2]],ypoints[tris[tri+2]],xpoints[tris[tri]],ypoints[tris[tri]]);
	
}

function fillTri(tri) {
	tri = tri * 6; //tri id to coordinates
	xs = Array.concat(xpoints[tris[tri]],xpoints[tris[tri+1]],xpoints[tris[tri+2]]);
	ys = Array.concat(ypoints[tris[tri]],ypoints[tris[tri+1]],ypoints[tris[tri+2]]);
	makeSelection("polygon",xs,ys);
	fill();
	run("Restore Selection");
}

//setColor(0,0,0);
//run("Select None");
//fill();
//run("Restore Selection");

//setColor(128,128,128);

//edgeflipifnotld(3,4);

//for (z=0;z<ntri;z++) {
//	drawTri(z);
//	if (compareTri(z,alpha)==1) {
//		fillTri(z);
//	}
//}