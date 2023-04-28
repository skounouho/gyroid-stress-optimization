clc
clear
% close all

%% Create Gyroid

resolution = 30;
numCell = 1;
weights = eye((resolution+1)^3)*0.16;

filter = generateFilter(resolution, numCell);

disp("Generated RBF filter")

Hmax = 0.05;

disp("Creating Gyroid")

gyroid = Gyroid(resolution,0.16,numCell,weights,filter);

finalFaces = gyroid.Faces;
finalVertices = gyroid.Vertices;

fig = figure(1);
clf(fig);
p1 = patch('Faces', gyroid.Faces, 'Vertices', gyroid.Vertices);
set(p1,'FaceColor','red','EdgeColor','none');
daspect([1 1 1])
view([37.5	30]);
camlight 
lighting flat

nearBottom = gyroid.bottom;
nearTop = gyroid.top;

%% Setting up simulation

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

% structuralBoundaryLoad(model,"Face",topFaces,"SurfaceTraction",[0 0 -10]);
topFaces = unique(nearestFace(model.Geometry,nearTop));
structuralBC(model,"Face",topFaces, "Displacement",[0;0;-0.00001]); 

%% Run FEA

disp("Generate Mesh and Solve FEA")

% mesh = analyzeConvergence(model);

[mesh,result] = stressOptimization(model, gyroid, weights, filter, Hmax, resolution, numCell);

%% Plot Geometry and Records

bNodes = findNodes(mesh,"region","Face",bottomFaces);
tNodes = findNodes(mesh,"region","Face",topFaces);

% fig = figure(1);
% fig.WindowStyle = 'docked';
% clf(fig)
% pdeplot3D(model)
% hold on
% plot3(mesh.Nodes(1,bNodes),mesh.Nodes(2,bNodes),mesh.Nodes(3,bNodes),".","Color","b") % bottom nodes
% plot3(mesh.Nodes(1,tNodes),mesh.Nodes(2,tNodes),mesh.Nodes(3,tNodes),".","Color","r") % top nodes
% title("Mesh with Constraint Nodes");

% fig = figure(2);
% fig.WindowStyle = 'docked';
% clf(fig)
% matrices = assembleFEMatrices(model, "K");
% spy(matrices.K)


% %% Create STL
% 
% if saveSTL
%     selpath = uigetdir;
%     filename = string(selpath) + "/" + gyroid.name + ".stl";
%     stlwrite(filename,gyroid.Faces,gyroid.Vertices);
% end










