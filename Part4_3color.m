
% Asymmetry Coefficient Calculator

% Get the list of files in the folder (This will take any *tif file in this
% format, you can change that if you need below):

Files=dir(fullfile(pwd, '*_max.tif')); 

[NumFiles,~]=size(Files);
    
files={Files.name};

AsymCoeff=zeros(NumFiles,3);

for i=1:NumFiles
    
    % Get the name of the file and find the coordinates
    filename=char(files(i));
    u=strfind(filename,'x=');
    v=strfind(filename, 'y=');
    tag=strfind(filename, '_max.tif');
    
    x=str2double(filename(u+2:v-2));
    y=str2double(filename(v+2:tag-1));
    
    % Open the file
    [imS, imD]=MicroscopeData.Original.ReadData(pwd, filename);
    
     % Remove unnecessary dimensions and evaluate the remaining size
    imS=squeeze(imS);
    [m,n,numChannels,numSlices,t]=size(imS);
    PixSize=imD.PixelPhysicalSize;
    
    if numSlices>1 || t>1
        str = 'The image is not a single time point projection.';
        str = [str newline 'Use "RadialProbabilityDensityCalculator.m" instead.'];
        error(str)
    end
    
     % Define how big line will be for sweeping
    radial_length = round(0.6*max([m n])); %CJO note: seems big enough so far? Can adjust if parts of cells are being missed
    
    % Derfine Step Size and Integration Bounds
    d_theta = 0.1;
    n_theta = 180/d_theta;
    
     % Preallocate the memory to hold the data
    radial_plot = zeros(n_theta,2*radial_length,numChannels);
    
    AsymValues=zeros(n_theta,numChannels);
    
    line_temp = zeros(1, 2*radial_length); % CJO note: not sure if this really makes any difference?
    
     for j=1:numChannels
          parfor k=1:n_theta
                theta=k*d_theta;
         
                xi = [x-(radial_length)*cosd(theta) x+(radial_length)*cosd(theta)];
                yi = [y-(radial_length)*sind(theta) y+(radial_length)*sind(theta)];
                line_temp = (improfile(imS(:,:,j),xi,yi)).';
                
                 if numel(line_temp) > 2*radial_length
                   line_temp=line_temp(1:2*radial_length);
                 elseif numel(line_temp) < 2*radial_length
                   line_temp=imresize(line_temp,[1 2*radial_length]);  
                 end
         
                line_temp(~isfinite(line_temp))=0; 
                radial_plot(k,:,j)=line_temp; 
                AsymValues(k,j)=abs(sum(line_temp((numel(line_temp)/2+1):numel(line_temp)))-sum(line_temp(1:numel(line_temp)/2)));
                
                
          end
     end
   
   AsymValues=bsxfun(@rdivide,AsymValues,(squeeze(sum(sum(radial_plot,2),1)))'); 
     
   imD2=imD;
   imD2.DatasetName=strcat(filename(1:u-2),'sliceDensity');
   imD2.NumberOfChannels=1;
   imD2.ChannelNames= {'Channel'};
   imD2.Dimensions=[n_theta, radial_length, numChannels];
   data = single(radial_plot);
   CJOWriterTif(data,'path',pwd,'imageData',imD2,'verbose',true);
   
   AsymCoeff(i,:)=sum(AsymValues,1);
   save(strcat(filename(1:u-2),'_AsymValues'), 'AsymValues', '-v7.3');
    
end

OutFile='AsymCoefficients.xlsx';
xlswrite(OutFile, AsymCoeff);

