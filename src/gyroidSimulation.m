clc
clear
% close all

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

finalFaces = gyroid.Faces;
finalVertices = gyroid.Vertices;

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

iterations = 30;

t = zeros(1,iterations);

HmaxValues = zeros(1,iterations);
vonmises = zeros(1,iterations);
displacements = zeros(1,iterations);
strains = zeros(1,iterations);
volumeFractions = zeros(1,iterations);

for i = 1:iterations
    
    Hmax = 0.5*exp((1-i) / 10);
    HmaxValues(i) = Hmax;

    tic;
    
    mesh = generateMesh(model, Hmax=Hmax);
    result = solve(model);
    
    t(i) = toc;
    vonmises(i) = max(result.VonMisesStress);
    displacements(i) = max(result.Displacement.Magnitude);
    strains(i) = max(result.Strain.ezz);
    volumeFractions(i) = volume(mesh);
    
    
    printStr = sprintf("i: %d \t Hmax %0.3f \t Max Von Mises: %0.3e \t Maximum Displacement: %0.3e \t Max Strain ZZ: %0.3e \t", ...
        i, ...
        Hmax, ...
        vonmises(i), ...
        displacements(i), ...
        strains(i)) + sprintf("Volume Fraction: %0.2f \t Time: %0.2f s", volumeFractions(i), t(i));

    disp(printStr)

end

disp("Simulations FINISHED")

%% Plot Geometry and Records

bNodes = findNodes(mesh,"region","Face",bottomFaces);
tNodes = findNodes(mesh,"region","Face",topFaces);

fig = figure(1);
clf(fig)
pdeplot3D(model)
hold on
plot3(mesh.Nodes(1,bNodes),mesh.Nodes(2,bNodes),mesh.Nodes(3,bNodes),".","Color","b") % bottom nodes
plot3(mesh.Nodes(1,tNodes),mesh.Nodes(2,tNodes),mesh.Nodes(3,tNodes),".","Color","r") % top nodes
title("Mesh with Constraint Nodes");

fig = figure(2);
clf(fig)
matrices = assembleFEMatrices(model, "K");
spy(matrices.K)

f = fit(HmaxValues', vonmises', 'exp1');

fig = figure(3);
clf(fig)
scatter(HmaxValues,vonmises)
title("Hmax vs. Von Mises Stress");

fig = figure(4);
clf(fig)
scatter(1:iterations,HmaxValues)
title("Iteration vs. Hmax");

fig = figure(5);
clf(fig)
scatter(HmaxValues,t)
title("Hmax vs. time");

% %% Create STL
% 
% if saveSTL
%     selpath = uigetdir;
%     filename = string(selpath) + "/" + gyroid.name + ".stl";
%     stlwrite(filename,gyroid.Faces,gyroid.Vertices);
% end










