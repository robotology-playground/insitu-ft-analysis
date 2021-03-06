function [recalibratedData,offsetInForce]=recalibrateData(rawData,calibrationMatrix,varargin)
%% initial values
[numberOfSamples,inputSize]= size(rawData);
% check matrix dimensions
if (ismatrix(calibrationMatrix))
    ok=true;
    if ~(size(calibrationMatrix,2)==inputSize) % check if dimensions are correct
        ok=false;
        error('recalibrateData: matrix inserted is not the right dimensions, so is not a calibration matrix');
    end
end

if ok
    outputSize=size(calibrationMatrix,1);
end
recalibratedData=zeros(numberOfSamples,outputSize);
extraLinearVariablesNumber=0;
extraCoeff=[];
extraLinearVariables=[];
extraOffset=[];
extraCoeffDefaultValue=zeros(outputSize,1);
offset=zeros(outputSize,1);
skip=0;
isRawOffset=true;
%% varargin logic
for v=1:2:length(varargin)
    if ~skip
        if(ischar(  varargin{v}))
            tempV=varargin{v+1};
            switch varargin{v}
                case {'offsetIsInRawSpace','OffsetIsRaw','offsetisraw','OFFSETISRAW','rawOffset','isRawOffset'}
                    if islogical(tempV)
                        isRawOffset=tempV;
                    else
                        warning('recalibrateData: expected a boolean variable for option OffsetIsRaw, ignoring');
                    end
                case {'Offset','offset','OFFSET'}
                    if isvector(tempV)
                        if (sum(size(tempV)) ==(outputSize+1) && (size(tempV,1)==outputSize || size(tempV,2)==outputSize) )
                            if size(tempV,2)==outputSize
                                offset=tempV';
                            else
                                offset=tempV;
                            end
                        else
                            warning('recalibrateData: this vector is not an offset of the right dimensions, ignoring vector');
                        end
                    else
                        warning('recalibrateData: Expected a vector, using default offset value of 0.')
                    end
                case {'addVariableValue','addExtraLinearVariableValue','extraLinearVariableValue','addLinVarVal','addExtLinVarVal'}
                    if isvector(tempV)
                        if length(tempV)==numberOfSamples
                            extraLinearVariables=[extraLinearVariables tempV];
                            extraLinearVariablesNumber=extraLinearVariablesNumber+1;
                            %% check if there is previous information on this new linear variable to consider
                            tempPrevLinVar=extraCoeffDefaultValue;
                            if v+3<=length(varargin) % needs 3 more options in varargin to check this
                                vtoCheck=varargin{v+2};
                                vtoCheckValue=varargin{v+3};
                                if sum(strcmp(vtoCheck,{'variableCoefficient','ExtLinVarCoeff','LinVarCoeff','varCoeff'}))>0
                                    if isvector(vtoCheckValue)
                                        if (sum(size(vtoCheckValue)) ==(outputSize+1) && (size(vtoCheckValue,1)==outputSize || size(vtoCheckValue,2)==outputSize) )
                                            tempPrevLinVar=vtoCheckValue;
                                            skip=skip+1;
                                            % check if there is some offset
                                            % for this variable
                                            varOff=0;
                                            if v+5<=length(varargin) % needs 3 more options in varargin to check this
                                                vtoCheck2=varargin{v+4};
                                                vtoCheckValue2=varargin{v+5};
                                                if sum(strcmp(vtoCheck2,{'extVarOffset','ExtVarOffset','LinVarOff','varOff'}))>0
                                                    if length(vtoCheckValue2)==1
                                                        varOff=vtoCheckValue2;
                                                        skip=skip+1;
                                                    else
                                                        warning('recalibrateData: expected one value for the offset');
                                                    end
                                                end
                                            end
                                    else                                            
                                            warning('recalibrateData: this vector is not of the right dimensions, ignoring vector');
                                        end
                                    else
                                        warning('recalibrateData: Expected a vector, using default value of 0.')
                                    end
                                end
                            else
                                warning('recalibrateData: No coefficient available so coeff will be set to 0, the variable will have no effec in recalibrating the data.')
                            end
                            extraCoeff=[extraCoeff tempPrevLinVar];
                            extraOffset=[extraOffset varOff];
                        end
                    else
                        warning('recalibrateData: Expected a vector, using default ignoring variable.')
                    end
                otherwise
                    warning('recalibrateData: Unexpected option.')
            end
        else
            warning('recalibrateData: Unexpected option.')
        end
    else
        % since we already skipped make skip false again
        skip=skip-1;
    end
end
%extra logic
if  extraLinearVariablesNumber==0 || isempty(extraLinearVariables)
    extraLinearVariables=zeros(numberOfSamples,1);
    extraCoeff=extraCoeffDefaultValue;
    extraOffset=0;
end

if ~isRawOffset
    recalibratedData=calibrationMatrix*rawData'+offset+extraCoeff*(extraLinearVariables-extraOffset)';
else
    recalibratedData=calibrationMatrix*(rawData'+offset)+extraCoeff*(extraLinearVariables-extraOffset)';
end
recalibratedData=recalibratedData';

if isRawOffset
    offsetInForce=calibrationMatrix*offset;
else
    offsetInForce=[];
end
end