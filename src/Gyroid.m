classdef Gyroid
    properties
        Faces {mustBeInteger}
        Vertices {mustBeReal}
        bottom {mustBeReal}
        top {mustBeReal}
        grid
        name
    end
    methods
        function obj = Gyroid(resolution, isoValue, numCell, weights, filter)
            %GYROID Generates a gyroid for a given isovalue
            
            % Input
            
            n=resolution;                  % Increment number final mesh (reduce in case of several unit cells)
            
            % Generation of the final TPMS lattice in .STL file format
            
            x_max=numCell;          
            y_max=numCell;
            z_max=numCell;
            
            t=1/n;
            
            xi = 0:t:x_max;
            yi = 0:t:y_max;
            zi = 0:t:z_max;
            
            [x,y,z] = meshgrid(xi,yi,zi);

            obj.grid = struct("X", x, "Y", y, "Z", z);
            
            F = density(x,y,z,weights,filter);
            
            % Create the unit cells

            % isoval=13.39.*d.^6-26.83*d.^5+22.40.*d.^4-10.16.*d.^3+2.63.*d.^2+1.16.*d+0.03; % see knowledge doc for source
            
            % cut off weird edges
            F(x + y + z < t*3) = -1;
            F(x + y + z > x_max + y_max + z_max - t*3) = -1;
            
            % Combine isocaps and isosurface
            
            [fn,vn]=isosurface(x,y,z,F,0.1);
            [fc,vc,~] = isocaps(x,y,z,F,0.1);       
            [fn, vn] = combineFV(fn, vn, fc, vc);
            
            
            % Finalize
            vn(:,1)=vn(:,1)/x_max;                  % Set target size   
            vn(:,2)=vn(:,2)/y_max;
            vn(:,3)=vn(:,3)/z_max;
            
            obj.Faces = fn;
            obj.Vertices = vn;
            
            % find bottom vertices

            obj.bottom = vertsAtZIndex(x,y,z,F,1,x_max,y_max,t);

            % find top vertices

            obj.top = vertsAtZIndex(x,y,z,F,size(F,3),x_max,y_max,t);

            formatSpec = "N%dVF%0.2f%C%dPW%0.2f";
            obj.name = sprintf(formatSpec,resolution,isoValue,numCell) + "DT" + string(datetime,'yyMMddHHmmss');
        end

        function delta = optimize(obj, result,weights,filter)
            idx = findNodes(result.Mesh,"nearest",[obj.grid.X(:) obj.grid.Y(:) obj.grid.Z(:)]');
            stress = result.VonMisesStress(idx);
        
            delta = (stress .* stress) .* densityDerivative(obj.grid.X,obj.grid.Y,obj.grid.Z,weights,filter);
        end

        function show(obj, figureNo)
            fig = figure(figureNo);
            clf(fig);
            p1 = patch('Faces', obj.Faces, 'Vertices', obj.Vertices);
            set(p1,'FaceColor','red','EdgeColor','none');
            daspect([1 1 1])
            view([37.5	30]);
            camlight 
            lighting flat
        end
    end
end
