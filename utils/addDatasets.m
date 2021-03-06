function [set1]=addDatasets(set1,set2)
if (isstruct(set1))
    dataFieldNames=fieldnames(set1);
    for i=1:size(dataFieldNames,1)
        if(isstruct(set1.(dataFieldNames{i})))
            set1.(dataFieldNames{i})= addDatasets(set1.(dataFieldNames{i}),set2.(dataFieldNames{i}));
        else
            if  (isnumeric(set1.(dataFieldNames{i})))
                if (ismatrix(set1.(dataFieldNames{i})))
                    if ~(size(set1.(dataFieldNames{i}),1)==6 && size(set1.(dataFieldNames{i}),2)==6)
                        set1.(dataFieldNames{i})=[set1.(dataFieldNames{i});set2.(dataFieldNames{i})];
                    end
                else
                    if (isvector(set1.(dataFieldNames{i})))
                        set1.(dataFieldNames{i})=[set1.(dataFieldNames{i});set2.(dataFieldNames{i})];
                    end
                end
            end
        end
    end
else
    if (isnumeric(set1))
        if (ismatrix(set1))
            if ~(size(set1.(dataFieldNames{i}),1)==6 && size(set1.(dataFieldNames{i}),2)==6)
                set1=set1(mask,:);
            end
        else
            if (isvector(set1))
                set1=set1(mask);
            end
        end
    end
end