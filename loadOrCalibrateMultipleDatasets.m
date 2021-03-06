clear all
close all
clc
% add required folders for use of functions
addpath external/quadfit
addpath utils

%% read experiment related variables
% obtain data from all listed experiments, is better if all experiments
% belong to the same robot or sensors. This is not a hard constraint though

% experimentNames={ %iCubGenova04 Experiments
%     '/green-iCub-Insitu-Datasets/2018_07_10_Grid';% Name of the experiment;
%     '/green-iCub-Insitu-Datasets/2018_07_10_Grid_warm';% Name of the experiment;
%     '/green-iCub-Insitu-Datasets/2018_07_10_multipleTemperatures';% Name of the experiment;
%     };
% experimentNames={ %iCubGenova02 experiments
%    % '/icub-insitu-ft-analysis-big-datasets/2018_09_07/2018_09_07_noTz';% Name of the experiment;
%     %'/icub-insitu-ft-analysis-big-datasets/2018_09_07/2018_09_07_multipleTemperatures';% Name of the experiment;
%     %'/icub-insitu-ft-analysis-big-datasets/2018_09_07/2018_09_07_AllGeneral';% Name of the experiment;
%     };

% experimentNames={ %iCubGenova02 experiments
%     '/icub-insitu-ft-analysis-big-datasets/2018_09_07_ICRA/2018_09_07_Grid';% Name of the experiment;
% %     '/icub-insitu-ft-analysis-big-datasets/2018_09_07_ICRA/2018_09_07_left_yoga';% Name of the experiment;
% %         '/icub-insitu-ft-analysis-big-datasets/2018_09_07_ICRA/2018_09_07_right_yoga';% Name of the experiment;
%     '/icub-insitu-ft-analysis-big-datasets/2018_09_07_ICRA/2018_09_07_MixedDataSets';% Name of the experiment;
%     };

% experimentNames={ %iCubGenova04 experiments
%     '/green-iCub-Insitu-Datasets/2018_12_11/noTz';
%      '/green-iCub-Insitu-Datasets/2018_12_11/onlySupportLegs';
%       '/green-iCub-Insitu-Datasets/2018_12_11/allTogether';
%   
%      };

experimentNames={ %iCubGenova04 experiments
    '2019_08_10/grid';
  
     };


% read experiment options
readOptions = struct();
readOptions.forceCalculation=false;%false;
readOptions.raw=true;
readOptions.saveData=true;
readOptions.multiSens=true;
readOptions.matFileName='ftDataset'; % name of the mat file used for save the experiment data

readOptions.visualizeExp=false;
readOptions.printPlots=false;%true
%% Calibration related variables options
% Select sensors to calibrate the names are associated to the location of
% the sensor in the robot
% on iCub  {'left_arm','right_arm','left_leg','right_leg','right_foot','left_foot'};
% sensorsToAnalize = {'right_leg','left_leg','right_foot','left_foot'};
sensorsToAnalize = {'right_leg','left_leg'};
lambdas=[
    0;
    1;
    5;
    10;
    50;
    100;
    250;
    500;
    750;
    1000;
    2500;
    5000;
    10000;
    50000;
%     100000;
%     500000;
%     1000000
    ];
% estimation types/
% estimationTypes=[1,1,1,3,3,3,4,4,4];
% useTempBooleans=[0,1,1,0,1,1,0,1,1];
% useTempOffset  =[0,0,1,0,0,1,0,0,1];
estimationTypes=[1,1,4,4];
useTempBooleans=[0,1,0,1];
useTempOffset  =[0,1,0,1];
%lambdas=0;
% Create appropiate names for the lambda variables
lambdasNames=generateLambdaNames(lambdas);
if ~exist('estimationTypes','var')
    estimationNames={''};
else
    estimationNames=generateEstimationTypeNames(estimationTypes,useTempBooleans,useTempOffset);
end
%
combinationNumber=length(experimentNames)*length(lambdas)*length(estimationTypes);
fullNames{combinationNumber}={''};
MSEvalues(combinationNumber)=struct();
offstetValues(combinationNumber)=struct();
for staIdx=1:length(sensorsToAnalize)
    fieldName=sensorsToAnalize{staIdx};
    MSEvalues(combinationNumber).(fieldName)=[0,0,0,0,0];
    offstetValues(combinationNumber).(fieldName)=[0,0,0,0,0];
    temperatureCoeffs(combinationNumber).(fieldName)=[0;0;0;0;0];
end
%calibration options
calculate=true;
calibOptions.saveMat=true;
calibOptions.estimateType=1;%0 only insitu offset, 1 is insitu, 2 is offset on main dataset, 3 is oneshot offset on main dataset, 4 is full oneshot
calibOptions.useTemperature=true;
% checking options
evaluate=true;
checkMatrixOptions.plotForceSpace=false;
checkMatrixOptions.plotForceVsTime=false;
checkMatrixOptions.secMatrixFormat=false;
%%
counter=1;
for experimentIndex=1:length(experimentNames)
    sprintf('Reading experiment %d',experimentIndex);
    [data.(strcat('e',num2str(experimentIndex))),~,input,data.(strcat('extra',num2str(experimentIndex)))]=readExperiment(experimentNames{experimentIndex},readOptions);
    
    if(calculate || evaluate)
        dataset=data.(strcat('e',num2str(experimentIndex)));
        extraSample=data.(strcat('extra',num2str(experimentIndex)));
        experimentName=experimentNames{experimentIndex};
        datasetToUse=dataset;
        if isstruct(extraSample)
            extraSampleAvailable=true;
        else
            extraSampleAvailable=false;
        end
        if extraSampleAvailable
            extraSampleNames=fieldnames(extraSample);
            for eSampleIDNum =1:length(extraSampleNames)
                eSampleID = extraSampleNames{eSampleIDNum};
                if (isstruct(extraSample.(eSampleID)))
                    for eSamples=1:length(extraSample.(eSampleID))
                        datasetToUse=addDatasets(datasetToUse,extraSample.(eSampleID)(eSamples));
                    end
                end
            end
        end
        for in=1:length(lambdas)
            lambda=lambdas(in);
            lambdaName=lambdasNames{in};
            for type=1:length(estimationTypes)
                calibOptions.estimateType=estimationTypes(type);%0 only insitu offset, 1 is shpere offset , 2 is no mean offset on main dataset, 3 is no mean offset on all dataset, 4 is oneshot
                calibOptions.useTemperature=useTempBooleans(type);                
                calibOptions.temperatureOffset=useTempOffset(type); 
                estimationName=estimationNames{type};
                disp(strcat('e',num2str(experimentIndex),estimationName,lambdaName));
                % calibrate
                if calculate
                    calibrationStep
                end
                % check performance in the data set
                if evaluate
                    somethingToCheck=true;
                    saveResults=readOptions.saveData; % for the time being save if readOption.saveData is true
                    if ~exist('calibMatrices','var')
                        if exist(strcat('data/',experimentName,'/results/results',estimationName,lambdaName,'.mat'),'file')
                            load(strcat('data/',experimentName,'/results/results',estimationName,lambdaName,'.mat'));
                            %%TODO: add checking if all sensors to analize are in the results structure
                            calibMatrices=results.calibrationMatrices;
                            offset=results.offset;
                            resultsFields=fieldnames(results);
                            if ismember('temperatureCoeff',resultsFields)
                                temperatureCoeff=results.temperatureCoeff;
                            end
                            saveResults=false;
                        else
                            fprintf('loadOrCalibrateMultipleDatasets: Nothing to do no results and no calculation done for %s %s %s',strcat('e',num2str(experimentIndex)),estimationName,lambdaName );
                            somethingToCheck=false;
                            continue;
                        end
                    end
                    if somethingToCheck
                        checkMatrixOptions.otherCoeffFirstValAsOffset= calibOptions.temperatureOffset;
                        [reCalibData,offsetInWrenchSpace,MSE,MSE_p]=checkNewMatrixPerformance(datasetToUse,sensorsToAnalize,calibMatrices,offset,checkMatrixOptions,'otherCoeff',temperatureCoeff,'varName','temperature');
                        %                     [reCalibData,offsetInWrenchSpace,MSE,MSE_p]=checkMatrixPerformance(datasetToUse,sensorsToAnalize,calibMatrices,offset,checkMatrixOptions,'otherCoeff',temperatureCoeff,'varName','temperature');
                        
                    end
                    %% Save the workspace again to include calib Matrices, scale and offset
                    %     %save recalibrated matrices, offsets, new wrenches, sensor serial
                    %     numbers
                    saveResults=false;
                    if(saveResults && evaluate)
                        results.usedDataset=datasetToUse;
                        results.calibrationMatrices=calibMatrices;
                        results.fullscale=fullscale;
                        results.offset=offset;
                        results.temperatureCoeff=temperatureCoeff;
                        results.offsetInWrenchSpace=offsetInWrenchSpace;
                        results.recalibratedData=reCalibData;
                        results.MSE=MSE;
                        results.MSE_p=MSE_p;
                        if ~exist(strcat('data/',experimentName,'/results'),'dir')
                            mkdir(strcat('data/',experimentName,'/results'));
                        end
                        save(strcat('data/',experimentName,'/results/results',estimationName,lambdaName,'.mat'),'results')
                    end
                    fullNames{counter}=strcat('e',num2str(experimentIndex),estimationName,lambdaName);
                    MSEvalues(counter)=MSE;
                    MSEvalues_p(counter)=MSE_p;
                    offsetValues(counter)=offsetInWrenchSpace;
                    calibrationMatrices(counter)=calibMatrices;
                    if ~isempty(temperatureCoeff)
                        temperatureCoeffs(counter)=temperatureCoeff;
                    end
                    counter=counter+1;
                    clear results;
                    clear calibMatrices;
                end
            end
        end
        clear dataset;
        clear reCalibData;
        clear extraSample;
        clear datasetToUse;
    end
end
if (evaluate)
    % convert to matrix for applying math operations
    mseValuesArray=struct2array(MSEvalues);
    mseValues=reshape(mseValuesArray,length(sensorsToAnalize)*6,length(mseValuesArray)/(length(sensorsToAnalize)*6));
    mseValues=mseValues'; % each 6 columns is a sensor
    
    mseValuesArray_p=struct2array(MSEvalues_p);
    mseValues_p=reshape(mseValuesArray_p,length(sensorsToAnalize)*6,length(mseValuesArray_p)/(length(sensorsToAnalize)*6));
    mseValues_p=mseValues_p'; % each 6 columns is a sensor
    
    offsetValuesArray=struct2array(offsetValues);
    offsetValuesArray=offsetValuesArray';
    OffsetValues=offsetValuesArray(1:length(sensorsToAnalize):end,:);
    for sa=2:length(sensorsToAnalize)
        OffsetValues=[OffsetValues offsetValuesArray(sa:length(sensorsToAnalize):end,:)];
    end
    % each 6 columns is a sensor
    
    
    fullNames=fullNames';
    saveResults=readOptions.saveData; % for the time being save if readOption.saveData is true
    if(saveResults )
        allResults.fullNames=fullNames;
        for sta=1:length(sensorsToAnalize)
            sensor=sensorsToAnalize{sta};
            allResults.MSEvalues.(sensor)=mseValues(:,(sta-1)*6+1:sta*6);
            allResults.MSEvalues_p.(sensor)=mseValues_p(:,(sta-1)*6+1:sta*6);
            allResults.offsetValues.(sensor)=OffsetValues(:,(sta-1)*6+1:sta*6);
        end
        
        %     allResults.MSEvalues=MSEvalues;
        %     allResults.offsetValues=offsetValues;
        allResults.estimationTypes=estimationTypes;
        allResults.useTempBooleans=useTempBooleans;
        allResults.useTempOffset  =useTempOffset;
        allResults.lambdas=lambdas;
        allResults.experimentNames=experimentNames;
        allResults.calibrationMatrices=calibrationMatrices;
        allResults. temperatureCoeffs= temperatureCoeffs;
        if ~exist(strcat('data/generalResults'),'dir')
            mkdir(strcat('data/generalResults'));
        end
        save(strcat('data/generalResults/results_',date,'_',input.robotName,'.mat'),'allResults')
    end
end

% checking the difference in mse values
%difference=mseValues(2:2:end,:)-mseValues(1:2:end,:)
