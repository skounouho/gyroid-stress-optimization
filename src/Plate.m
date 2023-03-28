classdef Plate
    properties
        Faces {mustBeInteger}
        Vertices {mustBeReal}
        bottom {mustBeReal}
        top {mustBeReal}
    end
    methods
        function obj = Plate(thickness, height, spacing)
            % PLATE Generates a plate of a certain thickness at a certain
            % height
            
            % Setup

            x_max = 1;
            y_max = 1;
            
            xi = 0:x_max/2:x_max;
            yi = 0:y_max/2:y_max;
            zi = 0:thickness/2:thickness;
            
            % set grid
            [x, y, z] = meshgrid(xi, yi, zi);
            F = z;
            
            % adjust height and spacing
            z = z + height;

            if height > 0
                z = z + spacing;
            end

            if height < 0
                z = z - spacing;
            end
            
            % create faces and vertices
            [fn,vn]=isosurface(x,y,z,F,0);
            [fc,vc,~] = isocaps(x,y,z,F,0);       
            [fn, vn] = combineFV(fn, vn, fc, vc);

            obj.Faces = fn;
            obj.Vertices = vn;
            
            % find bottom vertices

            obj.bottom = vertsAtZIndex(x,y,z,F,1,x_max,y_max);

            % find top vertices

            obj.top = vertsAtZIndex(x,y,z,F,size(F,3),x_max,y_max);
            
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
