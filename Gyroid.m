classdef Gyroid
    properties
        Faces {mustBeInteger}
        Vertices {mustBeReal}
        bottom {mustBeReal}
        top {mustBeReal}
        name
    end
    methods
        function obj = Gyroid(resolution, volumeFraction, numCell, plateWidth)
            %GYROID Generates a gyroid of an approximate volume fraction with
            % plates above and below it.
            
            % Input
            
            n=resolution;                  % Increment number final mesh (reduce in case of several unit cells)
            d=volumeFraction;        % Target volume fraction
            
            % Generation of the final TPMS lattice in .STL file format
            
            x_max=numCell;          
            y_max=numCell;
            z_max=numCell;
            
            t=1/n;
            
            xi = 0:t:x_max;
            yi = 0:t:y_max;
            zi = 0 - plateWidth:t:z_max + plateWidth;
            
            [x,y,z] = meshgrid(xi,yi,zi);
            
            % Create the unit cells

            isoval=13.39.*d.^6-26.83*d.^5+22.40.*d.^4-10.16.*d.^3+2.63.*d.^2+1.16.*d+0.03; % see knowledge doc for source
            
            F=cos(2.*pi.*x).*sin(2.*pi.*y)+cos(2.*pi.*y).*sin(2.*pi.*z)+cos(2.*pi.*z).*sin(2.*pi.*x);
            F=-(F+isoval).*(F-isoval);

            % cut off weird edges
            F(x + y + z < isoval) = -1;
            F(x + y + z > x_max + y_max + z_max - isoval) = -1;
            
            % Create plates
            
            zPlateI  = z > z_max;
            F(zPlateI) = z_max - abs(x(zPlateI)+y(zPlateI) - x_max)+abs(x(zPlateI)-y(zPlateI)  - y_max);

            zPlateI  = z < 0;
            F(zPlateI) = abs(x(zPlateI)+y(zPlateI) - x_max)+abs(x(zPlateI)-y(zPlateI)  - y_max);
            
            % Combine isocaps and isosurface
            
            [fn,vn]=isosurface(x,y,z,F,0);
            [fc,vc,~] = isocaps(x,y,z,F,0);       
            [fn, vn] = combineFV(fn, vn, fc, vc);
            
            
            % Finalize
            vn(:,1)=vn(:,1)/x_max;                  % Set target size   
            vn(:,2)=vn(:,2)/y_max;
            vn(:,3)=vn(:,3)/z_max;
            
            obj.Faces = fn;
            obj.Vertices = vn;
            
            % find bottom vertices

            obj.bottom = vertsAtZIndex(x,y,z,F,1,x_max,y_max);

            % find top vertices

            obj.top = vertsAtZIndex(x,y,z,F,size(F,3),x_max,y_max);

            formatSpec = "N%dVF%0.2f%C%dPW%0.2f";
            obj.name = sprintf(formatSpec,resolution,volumeFraction,numCell,plateWidth) + "DT" + string(datetime,'yyMMddHHmmss');
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