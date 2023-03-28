clc
clear
% close all
tic

%% Create Gyroid

resolution = 50;
volumeFraction = 0.2;
numCell = 1;
plateThickness = 0.02;
spacing = 0;

runFEA = true;
saveSTL = false;

disp("Creating Gyroid")

gyroid = Gyroid(resolution,volumeFraction,numCell,0);
topPlate = Plate(plateThickness, 1, spacing);
bottomPlate = Plate(plateThickness, -plateThickness, spacing);

fig = figure(1);
clf(fig);
p1 = patch('Faces', gyroid.Faces, 'Vertices', gyroid.Vertices);
p2 = patch('Faces', topPlate.Faces, 'Vertices', topPlate.Vertices);
p3 = patch('Faces', bottomPlate.Faces, 'Vertices', bottomPlate.Vertices);
set(p1,'FaceColor','red','EdgeColor','none');
set(p2,'FaceColor','blue','EdgeColor','none','FaceAlpha',0.5);
set(p3,'FaceColor','blue','EdgeColor','none','FaceAlpha',0.5);
daspect([1 1 1])
view([37.5	30]);
camlight 
lighting flat

[plateFaces, plateVertices] = combineFV(topPlate.Faces,topPlate.Vertices, bottomPlate.Faces, bottomPlate.Vertices);
[finalFaces, finalVertices] = combineFV(plateFaces, plateVertices, gyroid.Faces, gyroid.Vertices);

nearBottom = bottomPlate.bottom;
nearTop = topPlate.top;

%% Running simulation

% start model
model = createpde("structural","static-solid");
geometryFromMesh(model, finalVertices.', finalFaces.');

% display model
fig2 = figure(2);
clf(fig2);
pdegplot(model,"CellLabels","on")

disp("Applying Structural Properties and Boundary Conditions")

% specify structural properties
% for Titanium Ti-6Al-4V (Grade 5), Annealed
% Source: https://asm.matweb.com/search/SpecificMaterial.asp?bassnum=mtp641
structuralProperties(model,"YoungsModulus",113.8+09,"PoissonsRatio",0.342);

% Plate structural properties
structuralProperties(model,"YoungsModulus",250+09,"PoissonsRatio",0.342,'Cell',[1, 2]);

% apply boundary conditions and loads
bottomFaces = unique(nearestFace(model.Geometry,nearBottom));
structuralBC(model,"Face",bottomFaces,"Constraint","fixed");

topFaces = unique(nearestFace(model.Geometry,nearTop));
% structuralBoundaryLoad(model,"Face",topFaces,"SurfaceTraction",[0 0 -10]);
structuralBC(model,"Face",topFaces, "Displacement",[0;0;-0.001]); 

if ~runFEA
    return
end

disp("Generating Mesh")

% generate FEA mesh
generateMesh(model, Hmax=0.02);
fig2 = figure(2);
clf(fig2);
pdeplot3D(model)
title("Mesh with Quadratic Tetrahedral Elements");


disp("Solving FEA")

% solve
result = solve(model);

%% Plot Results

disp("Plotting Results")

fig3 = figure(3);
clf(fig3);

% stress
pdeplot3D(model,"ColorMapData",result.VonMisesStress, "Deformation",result.Displacement, ...
                 "DeformationScaleFactor",100)
title("von Mises stress")
colormap("jet")

fig4 = figure(4);
clf(fig4);

% displacement
pdeplot3D(model,"ColorMapData",result.Displacement.Magnitude,"Deformation",result.Displacement, ...
                 "DeformationScaleFactor",100)
title("Magnitude Displacement")
colormap("jet")

fig5 = figure(5);
clf(fig5);

% strain zz
pdeplot3D(model,"ColorMapData",result.Strain.ezz,"Deformation",result.Displacement, ...
                 "DeformationScaleFactor",100)
title("Strain ZZ")
colormap("jet")

%% Create STL

if saveSTL
    selpath = uigetdir;
    filename = string(selpath) + "/" + gyroid.name + ".stl";
    stlwrite(filename,gyroid.Faces,gyroid.Vertices);
end

toc










