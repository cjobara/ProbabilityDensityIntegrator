
% Radial Scan and Fluorescence Probability Density Calculator

    % Note: These should have alrerady been run through Pengli's image
    % preparation pipeline. They need to have the cell maksed and the
    % center point spelled out in the title. This version is for cells that
    % have already been flattened using the "Sum Slices" form.

% Get the list of files in the folder (This will take any *tif file in this
% format, you can change that if you need below):

Files=dir(fullfile(pwd, '*_max.tif')); 

[NumFiles,~]=size(Files);
    
files={Files.name};

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
    n_theta = 360/d_theta;
    
    % Preallocate the memory to hold the data
    radial_plot = zeros(n_theta,radial_length,numChannels);
    radial_plot_env = zeros(n_theta,radial_length,numChannels);
   % radial_plot_nonzero  = zeros(n_theta,radial_length,numChannels);
    
    line_temp = zeros(1, radial_length); % CJO note: not sure if this really makes any difference?
    
    % First do the nucleus channel
    j=1;
    NuclearEnvelope=zeros(n_theta,1);
    CellEdge=zeros(n_theta,1);
    
    parfor k=1:n_theta
            
        % Find the line and make sure it has correct if the ends are off in
        % length
            theta=k*d_theta;
            xi = [x x+(radial_length)*cosd(theta)];
            yi = [y y+(radial_length)*sind(theta)];
            line_temp = (improfile(imS(:,:,j),xi,yi)).';
                
                 if numel(line_temp) > radial_length
                   line_temp=line_temp(1:radial_length);
                 elseif numel(line_temp) < radial_length
                   line_temp=imresize(line_temp,[1 radial_length]);  
                 end
            
         % save the line for the raw plot        
            radial_plot(k,:,j)=line_temp;
        
           
         % Change out of bounds regions to zero  
            line_temp(~isfinite(line_temp))=0;
         % find the edge of the cell (everything outside is zero)
            MaxIndex=find(line_temp, 1, 'last');
            CellEdge(k)=MaxIndex;
           % line_nonzero=imresize(line_temp(1:MaxIndex),[1 radial_length]);
           % radial_plot_nonzero(k,:,j)=line_nonzero;
         % find the nuclear envelope (edge of the nucleus)   
            EnvIndex=find((abs(line_temp-median(line_temp(1:150)))/5<mean(line_temp(1:150))/10),1,'last');
            %Just FYI, the way this works: The edge of the nucelus is
            %calculated as the place where the signal to noise of the
            %nuclear signal is below 10:1-the noise is measured as the
            %varation around the median, the singal at that point as the
            %mean
             NuclearEnvelope(k)=EnvIndex;            
    end
    
    NuclearEnvelope=smoothdata(NuclearEnvelope,'movmean',200);
    CellEdge=smoothdata(CellEdge,'movmean',50);
    
     parfor k=1:n_theta
            line_temp=radial_plot(k,:,j);
            NuclearR=imresize(line_temp(1:round(NuclearEnvelope(k))), [1 round(radial_length/5)]);
          if CellEdge(k)>NuclearEnvelope(k)  
              CytoplasmicR=imresize(line_temp(round(NuclearEnvelope(k)):round(CellEdge(k))),[1 radial_length-round(radial_length/5)]);
          else
              CytoplasmicR=zeros(1, radial_length-round(radial_length/5));
              %Prob would be better to additionally set NuclearEnvelope(k)=CellEdge(k)
              %here, since the latter is more precisely calculated. Just
              %FYI.
          end
            radial_plot_env(k,:,j) = [NuclearR CytoplasmicR];
     end
    
    
    for j=2:4
               
        for k=1:n_theta
            
            theta=k*d_theta;
            xi = [x x+(radial_length)*cosd(theta)];
            yi = [y y+(radial_length)*sind(theta)];
            line_temp = (improfile(imS(:,:,j),xi,yi)).';
                
                 if numel(line_temp) > radial_length
                   line_temp=line_temp(1:radial_length);
                 elseif numel(line_temp) < radial_length
                   line_temp=imresize(line_temp,[1 radial_length]);  
                 end
               
            radial_plot(k,:,j)=line_temp;
            
            line_temp(~isfinite(line_temp))=0;
           % I'm not sure this normalization is really useful... 
           % MaxIndex=find(line_temp, 1, 'last');
           % line_nonzero=imresize(line_temp(1:MaxIndex),[1 radial_length]); 
           % radial_plot_nonzero(k,:,j) = line_nonzero; 
           
                      
            NuclearR=imresize(line_temp(1:round(NuclearEnvelope(k))), [1 round(radial_length/5)]);
          if CellEdge(k)>NuclearEnvelope(k)  
              CytoplasmicR=imresize(line_temp(round(NuclearEnvelope(k)):round(CellEdge(k))),[1 radial_length-round(radial_length/5)]);
          else
              CytoplasmicR=zeros(1, radial_length-round(radial_length/5));
          end
            radial_plot_env(k,:,j) = [NuclearR CytoplasmicR];
            
        end
        
    end
    
    radial_plot_finite=radial_plot;
    radial_plot_finite(~isfinite(radial_plot))=0;
    RawProbDensity=squeeze(bsxfun(@rdivide,sum(radial_plot_finite,1),sum(sum(radial_plot_finite,1),2)));
    
    StrappedProbDensity=squeeze(bsxfun(@rdivide,sum(radial_plot_env,1),sum(sum(radial_plot_env,1),2)));
    
    %Not sure how to output this
   % xlswrite(outfile,RawProbDensity(:,1),1,
    
   imD2=imD;
   imD2.DatasetName=strcat(filename(1:tag-2),'radialDensity');
   imD2.NumberOfChannels=1;
   imD2.ChannelNames= {'Channel'};
   imD2.Dimensions=[n_theta, radial_length, numChannels];
   data = single(radial_plot);
   CJOWriterTif(data,'path',pwd,'imageData',imD2,'verbose',true);
   
   imD2.DatasetName=strcat(filename(1:tag-2),'proportionalDensity');
   imD2.Dimensions=[n_theta, radial_length, numChannels];
   data=single(radial_plot_env);
   CJOWriterTif(data,'path',pwd,'imageData',imD2,'verbose',true);
   
   fig1=figure(1);
   hold off
   polarplot(CellEdge,'b');
   hold on
   polarplot(NuclearEnvelope,'r');
   saveas(fig1,strcat(filename(1:tag-2), 'Bounds.jpg'));
   
   
   fig2=figure(2);
   set(fig2,'Position', [500 200 500 1000]);
   subplot(2,1,1);
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,1),'b');
   hold on
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,2),'g');
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,3),'r');
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,4),'m');
   title('Radial Density');
   hold off
   
   subplot(2,1,2);
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,1),'b');
   hold on
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,2),'g');
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,3),'r');
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,4),'m');
   title('Proportional Density');
   hold off
   
   fig3=figure(3);
   set(fig3,'Position', [500 200 500 1000]);
   subplot(2,1,1);
   hold on
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,1),'b');
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,2),'g');
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,3),'r');
   plot(PixSize(1)*(1:radial_length),RawProbDensity(:,4),'m');
   title('Radial Density');
   ylim([0 0.006]);
   
   subplot(2,1,2);
   hold on
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,1),'b');
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,2),'g');
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,3),'r');
   plot(((1:radial_length)*125/radial_length)-25,StrappedProbDensity(:,4),'m');
   title('Proportional Density');
   ylim([0 0.006]);
   
   saveas(fig2, strcat(filename(1:tag), 'Densities.jpg'));
   
  save(strcat(filename(1:tag),'_densities'), 'RawProbDensity', 'StrappedProbDensity','-v7.3');
   
      
end

saveas(fig3, 'DensitiesOverlay.jpg');
