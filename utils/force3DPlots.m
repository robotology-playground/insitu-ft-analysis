function H=force3DPlots(namesDatasets,graphName,varargin)
% This will plot the 3D force space of the wrenches. TODO: do the torque plot.
% Inputs:
% namesDatasets: Names of each data set to be plotes
% graphName: the title of the resulting figurea
% varargin: variable that should contain either the data to plot. Plotting options
% can be included but only after the datasets.
H.force=figure;
if (length(namesDatasets) <=length(varargin))    
    for n=1:length(namesDatasets)
        if ismatrix(varargin{n})
            if(length(namesDatasets)<length(varargin))
            plot3_matrix(varargin{n}(:,1:3),varargin{length(namesDatasets)+1:end}); grid on;hold on;
            else
                 plot3_matrix(varargin{n}(:,1:3)); grid on;hold on;
            end
        else
            warning('Something is wrong, a matrix was expected');
        end
    end
    legend(namesDatasets,'Location','west');
    title(strcat({'Force 3D space '},escapeUnderscores(graphName)));
    xlabel('F_{x}');
    ylabel('F_{y}');
    zlabel('F_{z}');
    pbaspect([1 1 1]);
    axis vis3d;
else
    warning('Insuficient arguments');
end


%% merge different images example
% figure,
% h=force3DPlots({'calculated'},ft,calibratedCalculated.(ft),'b') 
% hold on
% h2=force3DPlots({'refereence'},ft, dataset.ftData.(ft),'r')
% 
% L = findobj(h.force,'type','line');
% copyobj(L,findobj(h2.force,'type','axes'));