module Visualization

import vis::Figure;
import vis::Render;
import util::Resources;
import IO;
import Set;
import List;

data ResourceDuplicationTree = rdFolder(loc id, int dup, set[ResourceDuplicationTree] folders, set[ResourceDuplicationTree] files, int size) 
| rdFile(loc id, int dup, int size, list[loc] duplicatedLines)
;

void showProjectTree(loc projectLocation, loc srcLoc){
	Resource projectResource = getProject(projectLocation);
	Resource sourceCode = project(projectLocation, {});
	loc locSrc  = srcLoc;
	visit(projectResource){
		case folder(id, contents): {
										if(locSrc.path == id.path ) sourceCode = folder(id, contents);
									}
	}
	//iprintln(sourceCode);
	set[Resource] filteredResources = {};
	filteredSourceCode = top-down visit(sourceCode){
		case folder(id, contents)=>folder(id, getJavaContents(contents))
	}
	
	iprintln(filteredSourceCode);
	
	ResourceDuplicationTree projectTree = mapRDTree(filteredSourceCode);
	//iprintln(projectTree);
	
	//projectVis = mapVisDuplicationTreeFolders( {projectTree} );
	//render(hvcat(projectVis, gap(10)));
	
	projectVisFolders = mapVisDuplicationTreeOnlyFolders({projectTree});
	//iprintln(projectVisFolders);
	render(hvcat(projectVisFolders, gap(100)));
	
}


private ResourceDuplicationTree mapRDTree(folder(id, contents)) = rdFolder(id, 10, getRDTFolders(contents), getRDTFiles(contents), size(contents));
private ResourceDuplicationTree mapRDTree(file(id)) = rdFile(id, 10, 50, []);

private Figure getVisDuplicationLeaf(rdFile(id, dup, size, duplicatedLines)) = box(text(id.path), fillColor("grey"));

private list[Figure] mapVisDuplicationTreeOnlyFolders(set[ResourceDuplicationTree] folders){
	list[Figure] visFolders = [];
	for (f <- folders) {
	  if(rdFolder(id, dup, {}, _, size) := f)
	 	visFolders += box(text(id.path), fillColor("white"));
	 else if (rdFolder(id, dup, fs, _, size) := f) 
	 	visFolders += tree(box(text(id.path), fillColor("white")), mapVisDuplicationTreeOnlyFolders(fs), std(gap(20)), hcenter());
	 }
	
	return visFolders;
}

private list[Figure] mapVisDuplicationTreeFolders(set[ResourceDuplicationTree] folders) {
	list[Figure] visFolders = [];
	for (f <- folders) {
	 if(rdFolder(id, dup, {}, {}, size) := f)
	 	visFolders = visFolders + box(text(id.path), fillColor("white"));
	 else if( rdFolder(id, dup, fs, {}, size):= f) 
	 	visFolders += tree(box(text(id.path), fillColor("white")), mapVisDuplicationTreeFolders(fs), std(gap(20)));
	 else if( rdFolder(id, dup, {}, fs, size):=f)
	 	visFolders += tree(box(text(id.path), fillColor("white")), mapVisDuplicationTreeFiles(fs), std(gap(20)));
	 else if( rdFolder(id, dup, fos, fis, size):= f)
	 	visFolders += tree(box(text(id.path), fillColor("white")), (mapVisDuplicationTreeFolders(fos) + mapVisDuplicationTreeFiles(fis)), std(gap(20)));
	 }
	
	return visFolders;
}

private list[Figure] mapVisDuplicationTreeFiles(set[ResourceDuplicationTree] files) = toList(mapper(files, getVisDuplicationLeaf));


private set[ResourceDuplicationTree] getRDTFolders (contents){
	newContents = {};
	for(rc <- contents){
		if (folder(_, _) := rc) newContents += mapRDTree(rc);
	}
	return newContents;
}

private set[ResourceDuplicationTree] getRDTFiles (contents){
	newContents = {};
	for( rc <- contents){
		if(file(_) := rc ) newContents+= mapRDTree(rc);
	}
	return newContents;
}



private set[Resource] getJavaContents(contents) {
	for (rc <- contents){
		if( file(L) := rc) {
			if (/java/ !:= L.path) {
				contents = contents - {file(L)};
				//iprintln(contents);
			}
		}
	}
	return contents;
}