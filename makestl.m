function makestl(name,mesh,varargin)
%MAKESTL make an *.STL file for JIGSAW.
%
%   MAKESTL(NAME,MESH);
%
%   The following entities are optionally written to "NAME.STL". Ent-
%   ities are written if they are present in the sructure MESH:
%
%   MESH.POINT.COORD - [NPxND] array of point coordinates, where ND 
%       is the number of spatial dimenions.
%
%   MESH.TRIA3.INDEX - [N3x 4] array of indexing for tria-3 elements, 
%       where INDEX(K,1:3) is an array of "points" associated with 
%       the K-TH tria, and INDEX(K,4) is an ID tag for the K-TH tria.
%
%   MESH.QUAD4.INDEX - [N4x 5] array of indexing for quad-4 elements, 
%       where INDEX(K,1:4) is an array of "points" associated with 
%       the K-TH quad, and INDEX(K,5) is an ID tag for the K-TH quad.
%
%   Note that any QUAD-4 elements are decomposed and exported as 
%   pairs of TRIA-3 elements.
%
%   MAKESTL(..., OPTS);
%
%   An additional options structure OPTS can be used to specify addi-
%   tional export options:
%
%   OPTS.FORMAT - {default='binary'} control the type of STL file ge-
%   erated, as either FORMAT='binary' or FORMAT='ascii'. 
%
%   See also READSTL, MAKEMSH, READMSH, MAKEMESH, READMESH, MAKEVTK, 
%            READVTK, MAKEOFF, READOFF
%

%---------------------------------------------------------------------
%   Darren Engwirda
%   github.com/dengwirda/jigsaw-matlab
%   24-Mar-2016
%   d_engwirda@outlook.com
%---------------------------------------------------------------------
%

%-- N.B: MATLAB//OCTAVE write as little-endian by
%   default!

    opts = struct() ;

    if (nargin >= +3), opts = varargin{1} ; end
    
    if (~ischar  (name))
        error('NAME must be a valid file-name!') ;
    end
    if (~isstruct(mesh))
        error('MESH must be a valid structure!') ;
    end
    if (~isstruct(opts))
        error('OPTS must be a valid structure!') ;
    end
    
    if (~isfield(opts,'format'))
        opts.format = 'binary';
    else
    if (~ischar (opts. format ))
        error('OPTS.FORMAT must be a string!') ;
    end
    end
    
   [path,file,fext] = fileparts(name);
   
    if(~strcmp(lower(fext),'.stl'))
        name = [name,'.stl'] ;
    end
 
    try
%-- try to write data to file
    
    ffid = fopen(name , 'w') ;
    
    switch (lower(opts.format))
        case  'ascii'
    %-- write an 'ASCII' header
        fprintf(ffid,['solid %s\n'],file) ;
        
        case 'binary'
    %-- write a 'BINARY' header   
        fprintf(ffid,'%-80s',file) ;
        
        otherwise
        error('Invalid STL file-format!') ;    
    end
    
    coord = [] ; 
    trias = [] ; 
    facet = [] ;
    
    if (meshhas(mesh,'point'))
%-- write "POINT" data
    switch (size(mesh.point.coord,2))
        case +2
        coord = mesh.point.coord(:,1:1);
        coord = [coord,zeros(size(coord,1),2)] ;
        
        case +3
        coord = mesh.point.coord(:,1:2);
        coord = [coord,zeros(size(coord,1),1)] ;
            
        case +4
        coord = mesh.point.coord(:,1:3);
            
        otherwise
        error('Unsupported dimensionality!') ;
    end
    end
    
    if (~isempty(coord))
%-- calc. "FACET" data
    if (meshhas(mesh,'tria3'))
%-- write "TRIA3" data    
        trias = [...
        trias ; mesh.tria3.index(:,[1,2,3])] ;
    end
    if (meshhas(mesh,'quad4'))
%-- write "QUAD4" data
        trias = [
        trias ; mesh.quad4.index(:,[1,2,3])] ;
        trias = [
        trias ; mesh.quad4.index(:,[1,3,4])] ;    
    end
    end
    
    if (~isempty(trias))
%-- calc. "NORMS" data
        aside = coord(trias(:,2),:) ...
              - coord(trias(:,1),:) ;
        bside = coord(trias(:,3),:) ...
              - coord(trias(:,2),:) ;

        norms = cross(aside, bside) ;
        
        nlens = ...
            sqrt(sum(norms.^2, +2)) ;  
        
        norms(:,1) = norms(:,1)./nlens ;
        norms(:,2) = norms(:,2)./nlens ;
        norms(:,3) = norms(:,3)./nlens ;
        
%-- calc. "FACET" data
        facet = [norms(:,1:3), ...
        coord(trias(:,1),1:3), ...
        coord(trias(:,2),1:3), ...
        coord(trias(:,3),1:3)]' ;      
    end
    
    if (~isempty(facet))
%-- write "FACET" data
    switch (lower(opts.format))
        case  'ascii'
    %-- write an 'ASCII' file
        fprintf(ffid,[ 'facet normal ' , ...
            '%1.8f %1.8f %1.8f\n', ...
          'outer loop\n', ...
          'vertex %1.8f %1.8f %1.8f\n' , ...
          'vertex %1.8f %1.8f %1.8f\n' , ...
          'vertex %1.8f %1.8f %1.8f\n' , ...
          'endloop\n', ...
         'endfacet\n'], facet) ;
         
        case 'binary'
    %-- write a 'BINARY' file
        bytes = typecast(...
            single(facet(:)),'uint16') ; 
        bytes = reshape (...
            bytes(:), ... 
                [12*2, size(facet,2)]) ;
        bytes(end+1,:) = +0;
    
        nface = size(facet, 2) ;
    
        fwrite(ffid, nface , 'uint32') ;
        fwrite(ffid, bytes , 'uint16') ;
        
        otherwise
        error('Invalid STL file-format!') ; 
    end
    end
    
    if (meshhas(mesh,'edge2'))
%-- write "EDGE2" data
    warning('EDGE2 elements not supported!') ;   
    end
    if (meshhas(mesh,'tria4'))
%-- write "TRIA4" data
    warning('TRIA4 elements not supported!') ;
    end
    
    if (meshhas(mesh,'hexa8'))
%-- write "HEXA8" data
    warning('HEXA8 elements not supported!') ;
    end
    
    if (meshhas(mesh,'wedg6'))
%-- write "WEDG6" data
    warning('WEDG6 elements not supported!') ;
    end
    
    if (meshhas(mesh,'pyra5'))
%-- write "PYRA5" data
    warning('PYRA5 elements not supported!') ;
    end
    
    switch (lower(opts.format))
        case  'ascii'
    %-- write an 'ASCII' footer
        fprintf(ffid,'endsolid %s \n', file) ;
        
        case 'binary'
    %-- write a 'BINARY' footer   
   
        otherwise
        error('Invalid STL file-format!') ;    
    end 
    fclose(ffid) ;
    
    catch err
    
%-- ensure that we close the file regardless!
    if (ffid>-1)
    fclose(ffid) ;
    end
    
    rethrow(err) ;
        
    end

end


