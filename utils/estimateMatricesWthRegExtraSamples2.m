function [calibMatrices,fullscale,augmentedDataset]=estimateMatricesWthRegExtraSamples2(dataset,sensorsToAnalize,cMat,lambda,extraSample,offset,preCalibMat)
%% Inputs
% dataset: is the main data from de experiment.
% sensorsToAnalize: are the sensors which are required to be recalibrated
% cMat: the calibration matrix currently used in the sensor
% lambda: regularization parameter to tune between cMat and new calibration matrix
% extraSample: data coming from another experiment composed of some extra positions to be considered for calibration
% offset: offset in the raw data calculated previously on the main data contained in dataset
% preCalibMat: calibration matrix obtained without considering the extra samples
%% Outputs
% calibMatrices: calibration matrices of the sensors to be analized
%


extraSampleNames=fieldnames(extraSample);
augmentedDataset=dataset;
useFiltered=false;
for ftIdx =1:length(sensorsToAnalize)
    ft = sensorsToAnalize{ftIdx};
    % initialize stacking variables for the sensor in turn
    stackedRaw=dataset.rawData.(ft);
    stackedEstimated=dataset.estimatedFtData.(ft);
    stackedRawFiltered=dataset.rawDataFiltered.(ft);
    calibrationRequired=false;
    
    % go through all possible extra samples
    for eSampleIDNum =1:length(extraSampleNames)
        eSampleID = extraSampleNames{eSampleIDNum};
        rawData2=[];
        rawDataFiltered2=[];
        estimatedFtData2=[];
        if (~strcmp(ft,'right_arm') && ~strcmp(ft,'left_arm')) %new samples work mainly on legs
            if (strcmp(eSampleID,'right') || strcmp(eSampleID,'left' )) % if calibrating right side use samples specific for the right
                if (strcmp(ft,'right_leg') || strcmp(ft,'right_foot' )) % if calibrating right side use samples specific for the right
                    if (isstruct(extraSample.right) && strcmp(eSampleID,'right' )) %check if there is extra samples on this side
                        rawData2=extraSample.right.rawData;
                        rawDataFiltered2=extraSample.right.rawDataFiltered;
                        estimatedFtData2=extraSample.right.estimatedFtData;
                        calibrationRequired=true;
                        augmentedDataset=addDatasets(augmentedDataset,extraSample.(eSampleID));
                    end
                end
                
                if (strcmp(ft,'left_leg') || strcmp(ft,'left_foot') ) % if calibrating left side use samples specific for the left
                    if (isstruct(extraSample.left)&& strcmp(eSampleID,'right' )) %check if there is extra samples on this side
                        rawData2=extraSample.left.rawData;
                        rawDataFiltered2=extraSample.left.rawDataFiltered;
                        estimatedFtData2=extraSample.left.estimatedFtData;
                        calibrationRequired=true;
                        augmentedDataset=addDatasets(augmentedDataset,extraSample.(eSampleID));
                    end
                end
            else % if is not the right or left extra sample is should be Tz or general. Tz only to be considered in the legs
                if (isstruct(extraSample.(eSampleID))) %check if there is extra samples on this side
                    rawData2=extraSample.(eSampleID).rawData;
                    rawDataFiltered2=extraSample.(eSampleID).rawDataFiltered;
                    estimatedFtData2=extraSample.(eSampleID).estimatedFtData;
                    calibrationRequired=true;
                    augmentedDataset=addDatasets(augmentedDataset,extraSample.(eSampleID));
                end
            end
            
        else % Only general extra sample can be considered for adding info to the arms since in theory it could affect all sensors
            if (isstruct(extraSample.(eSampleID)) && strcmp(eSampleID,'general' ))
                rawData2=extraSample.(eSampleID).rawData;
                rawDataFiltered2=extraSample.(eSampleID).rawDataFiltered;
                estimatedFtData2=extraSample.(eSampleID).estimatedFtData;
                calibrationRequired=true;
                augmentedDataset=addDatasets(augmentedDataset,extraSample.(eSampleID));
            end
        end
        %% stack them
        if(isstruct(rawData2))
        stackedRaw=[stackedRaw;rawData2.(ft)];
        stackedEstimated=[stackedEstimated;estimatedFtData2.(ft)];
        stackedRawFiltered=[stackedRawFiltered;rawDataFiltered2.(ft)];
        end
    end
    
    if calibrationRequired   
        if useFiltered
            rawNoOffset=stackedRawFiltered-repmat(offset.(ft),size(stackedRaw,1),1);
        else
            rawNoOffset = stackedRaw-repmat(offset.(ft),size(stackedRaw,1),1);
        end
        [calibMatrices.(ft),fullscale.(ft)]=estimateCalibMatrixWithReg(rawNoOffset,stackedEstimated,cMat.(ft),lambda);
    else
        calibMatrices.(ft)=preCalibMat.(ft);
        
    end
    
end