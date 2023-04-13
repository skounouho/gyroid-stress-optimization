clc
clear
% close all
tic

%% Create Gyroid

resolution = 20;
isoValue = 0.4;
numCell = 1;
plateThickness = 0.02;
spacing = 0;

Hmax = 0.05;

runFEA = true;
saveSTL = false;

disp("Creating Gyroid")

gyroid = Gyroid(resolution,isoValue,numCell,0);

fig = figure(1);
clf(fig);
p1 = patch('Faces', gyroid.Faces, 'Vertices', gyroid.Vertices);
set(p1,'FaceColor','red','EdgeColor','none');
daspect([1 1 1])
view([37.5	30]);
camlight 
lighting flat

finalFaces = gyroid.Faces;
finalVertices = gyroid.Vertices;

nearBottom = gyroid.bottom;
nearTop = [gyroid.top];

%% Running simulation

% start model
model = createpde("structural","static-solid");
geometryFromMesh(model, finalVertices.', finalFaces.');

disp("Applying Structural Properties and Boundary Conditions")

% specify structural properties
% for Titanium Ti-6Al-4V (Grade 5), Annealed
% Source: https://asm.matweb.com/search/SpecificMaterial.asp?bassnum=mtp641
structuralProperties(model,"YoungsModulus",113.8+09,"PoissonsRatio",0.342);

% apply boundary conditions and loads
bottomFaces = unique(nearestFace(model.Geometry,nearBottom));
structuralBC(model,"Face",bottomFaces,"Constraint","fixed");

topFaces = unique(nearestFace(model.Geometry,nearTop));

% structuralBoundaryLoad(model,"Face",topFaces,"SurfaceTraction",[0 0 -10]);
structuralBC(model,"Face",topFaces, "Displacement",[0;0;-0.0001]); 

% display model
fig2 = figure(2);
clf(fig2);
pdegplot(model,"FaceLabels","on")

if ~runFEA
    return
end

disp("Generating Mesh")

% generate FEA mesh
generateMesh(model, Hmax=Hmax);
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

% % strain zz
% pdeplot3D(model,"ColorMapData",result.Strain.ezz,"Deformation",result.Displacement, ...
%                  "DeformationScaleFactor",100)
% title("Strain ZZ")
% colormap("jet")

% Sparseness Matrix
disp("Assemble FE Matrices")
matrices = assembleFEMatrices(model, "K");
spy(matrices.K)

%% Create STL

if saveSTL
    selpath = uigetdir;
    filename = string(selpath) + "/" + gyroid.name + ".stl";
    stlwrite(filename,gyroid.Faces,gyroid.Vertices);
end

toc










