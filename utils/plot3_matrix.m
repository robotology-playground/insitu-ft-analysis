function [ output_args ] = plot3_matrix( input_args,varargin )
%PLOT3_MATRIX version of plot3 that takes an input a single matrix 
if( size(input_args,2) == 3) 
    x = input_args(:,1);
    y = input_args(:,2);
    z = input_args(:,3);
end
if( size(input_args,1) == 3) 
    x = input_args(1,:);
    y = input_args(2,:);
    z = input_args(3,:);
end
if(isempty(varargin))
    output_args = plot3(x,y,z,'.');
else
output_args = plot3(x,y,z,varargin{:});
end
end

