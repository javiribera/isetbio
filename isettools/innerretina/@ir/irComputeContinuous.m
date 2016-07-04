function ir = irComputeContinuous(ir, input, varargin)
% Computes the mosaic's linear response to an input
%
%
% @JRG:  Why is there no mention of the bipolar object?
%
% The responses for each mosaic are computed one at a time. For a given
% mosaic, first the spatial convolution of the center and surround RFs are
% calculated for each RGB channel, followed by the temporal responses for
% the center and surround and each RGB channel. This results in the linear
% response.
%
% Next, the linear response is put through the generator function. The
% nonlinear response is the input to a function that computes spikes with
% Poisson statistics. 
%
% For the rgcGLM object, the spikes are computed using the recursive
% influence of the post-spike and coupling filters between the nonlinear
% responses of other cells. These computations are carried out using code
% from Pillow, Shlens, Paninski, Sher, Litke, Chichilnisky, Simoncelli,
% Nature, 2008, licensed for modification, which can be found at
%
% http://pillowlab.princeton.edu/code_GLM.html
%
% Outline:
%  * Normalize stimulus
%  * Compute linear response
%     - spatial convolution
%     - temporal convolution
%  * Compute nonlinear response
% [spiking responses are calculated by subclass versions of rgcCompute]
%
% Inputs: inner retina object, outersegment object.
%
% Outputs: the inner object with fixed linear and noisy spiking responses.
%
% Example:
%   ir.compute(identityOS);
%   irCompute(ir,identityOS);
%
% See also: rgcGLM/rgcCompute
%
% JRG (c) isetbio team

%%
p = inputParser;
p.CaseSensitive = false;

p.addRequired('ir',@(x) isequal(class(x),'ir'));
p.addRequired('input',@(x) ~isempty(validatestring(class(x),{'osIdentity','osLinear','osBioPhys'})));

%% Get the input data

% Possible osTypes are osIdentity, osLinear, and osBiophys
% Only osIdentity is implemented now.
osType = class(input);
switch osType
    case 'osDisplayRGB'
        % Identity means straight from the frame buffer to brain
        
        % Find properties that haven't been set and set them
        if isempty(osGet(input,'rgbData'))
            input = osSet(input, 'rgbData', rand(64,64,5));
        end
        if isempty(osGet(input,'patchSize'))
            input = osSet(input, 'patchSize', 180);
        end
        if isempty(osGet(input,'timeStep'))
            input = osSet(input,'timeStep',.01);
        end
        
        
        % Linear computation
        
        % Determine the range of the rgb input data
        spTempStim = osGet(input, 'rgbData');
        range = max(spTempStim(:)) - min(spTempStim(:));
        
        % @JRG:
        % Special case. If the ir class is rgcPhys, which we use for
        % validation. But in general, this is not the case. There is a
        % scientific question about this 10.  We need JRG and EJ to resolve
        % the spiking rate.
        % James needs to change the spatial RF and temporal weights in order to
        % make these models have the right spike rate, and the 10 is a hack to
        % approximate that.
        if isequal(class(ir),'irPhys'),   spTempStim = spTempStim./range - mean(spTempStim(:))/range;
        else                    spTempStim = 1*(spTempStim./range - mean(spTempStim(:))/range);
            %             else                    spTempStim = 10*(spTempStim./range);
        end
        
        % Looping over the rgc mosaics
        for rgcType = 1:length(ir.mosaic)
            
            % We use a separable space-time receptive field.  This allows
            % us to compute for space first and then time. Space.
            [spResponseCenter, spResponseSurround] = spConvolve(ir.mosaic{rgcType,1}, spTempStim);
            
            % For the subunit model, put each pixel "subunit" of spatial RF
            % through nonlinearity at this point
            %             if isa(ir.mosaic{rgcType},'rgcSubunit')
            %                 % Change this to get generator function
            %
            %                 modeltype = 'pixel';
            %                 % modeltype = 'surround';
            %                 [spResponseCenter, spResponseSurround] = ...
            %                     subunitPooling(spResponseCenter, spResponseSurround, 'model', modeltype);
            %
            %             end
            
            % Convolve with the temporal impulse response
            responseLinear = ...
                fullConvolve(ir.mosaic{rgcType,1}, spResponseCenter, spResponseSurround);
            
            % Store the linear response
            ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'responseLinear', responseLinear);
            
        end
        
    case {'osLinear','osBioPhys'}
        %% Linear OS
        
        % Programming TODO: Connect L, M and S cones to RGC centers and
        % surrounds appropriately
        
        % Determine the range of the cone current
        spTempStim = osGet(input, 'coneCurrentSignal');
        
        % Probably need to do this by cone type
        range = max(spTempStim(:)) - min(spTempStim(:));
        
        % Special case. If the ir class is rgcPhys, which we use for
        % validation. But in general, this is not the case. There is a
        % scientific question about this 10.  We need JRG and EJ to resolve
        % the spiking rate.
        % James needs to change the spatial RF and temporal weights in order to
        % make these models have the right spike rate, and the 10 is a hack to
        % approximate that.
        spTempStim = spTempStim./range;
        spTempStim = spTempStim - mean(spTempStim(:)/range);
        
        % Looping over the rgc mosaics
        for rgcType = 1:length(ir.mosaic)
            
            % We use a separable space-time receptive field.  This allows
            % us to compute for space first and then time. Space.
            [spResponseCenter, spResponseSurround] = spConvolve(ir.mosaic{rgcType,1}, spTempStim);
            
            % For the subunit model, put each pixel "subunit" of spatial RF
            % through nonlinearity at this point
            if isa(ir.mosaic{rgcType},'rgcSubunit')
                % Change this to get generator function
                spResponseCenter = cellfun(@exp,spResponseCenter,'uniformoutput',false);
                spResponseSurround = cellfun(@exp,spResponseSurround,'uniformoutput',false);
            end
            
            % Convolve with the temporal impulse response
            % responseLinear = ...
            %    fullConvolve(ir.mosaic{rgcType,1}, spResponseCenter, spResponseSurround);
            
            % spResponseSum = cellfun(@plus,spResponseCenter ,spResponseSurround,'uniformoutput',false);
            % spResponseVecRS = cellfun(@sum,(cellfun(@sum,spResponseSum,'uniformoutput',false)),'uniformoutput',false);
            % spResponseVec=cellfun(@squeeze,spResponseVecRS,'uniformoutput',false);
            
            % cellCtr = 0;
            spResponseVec = cell(nCells(1),nCells(2));
            nCells = size(ir.mosaic{rgcType}.cellLocation);
            for xc = 1:nCells(1)
                for yc = 1:nCells(2)
                    spResponseFull = spResponseCenter{xc,yc} + spResponseSurround{xc,yc};
                    spResponseVec{xc,yc} = squeeze(mean(mean(spResponseFull,1),2))';
                end
            end
            
            % Store the linear response
            ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'responseLinear', spResponseVec);
            
        end
        %     case {'osBioPhys'}
        %         %% Full biophysical os
        %         error('Not yet implemented');
        
    case {'bipolar'}
        
        %% Linear computation
        
        % Determine the range of the rgb input data
        spTempStimCenter = bipolarGet(input, 'responseCenter');
        spTempStimSurround = bipolarGet(input, 'responseSurround');
        
        rangeCenter = max(spTempStimCenter(:)) - min(spTempStimCenter(:));
        rangeSurround = max(spTempStimSurround(:)) - min(spTempStimSurround(:));
        
        if rangeCenter ~= 0
            spTempStimCenter = spTempStimCenter./rangeCenter - mean(spTempStimCenter(:))/rangeCenter;
        end
        if rangeSurround ~= 0
            spTempStimSurround = spTempStimSurround./rangeSurround - mean(spTempStimSurround(:))/rangeSurround;
        end
        
        %         spTempStimCenter = ieScale(spTempStimCenter);
        %         spTempStimSurround = ieScale(spTempStimSurround);
        % Looping over the rgc mosaics
        for rgcType = 1:length(ir.mosaic)
            if 1%isa(ir.mosaic{rgcType},'rgcPhys')
                
                %                 for cellNum = 1:length(ir.mosaic{rgcType}.sRFcenter)
                %                     tCenterNew{cellNum,1} = -1; tSurroundNew{cellNum,1} = 0;
                %                 end
                xNum = size(ir.mosaic{rgcType}.sRFcenter,1);
                yNum = size(ir.mosaic{rgcType}.sRFcenter,2);
                
                %                 if strcmpi(ieParamFormat(ir.mosaic{rgcType}.cellType(1:3)),'off');
                tCenterBP = -1;
                %                 else
                %                     tCenterBP = 1;
                %                 end
                tCenterNew   = cell(xNum,yNum);
                tSurroundNew = cell(xNum,yNum);
                for xcell = 1:xNum
                    for ycell = 1:yNum
                        tCenterNew{xcell,ycell} = tCenterBP; 
                        tSurroundNew{xcell,ycell} = 0;
                    end
                end
                %                 ir.mosaic{rgcType,1}.mosaicSet('tCenter',tCenterNew);
                %                 ir.mosaic{rgcType,1}.mosaicSet('tSurround',tSurroundNew);
                ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'tCenter',tCenterNew);
                ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'tSurround',tSurroundNew);
                % szRC = size(spTempStimCenter);
                
                % szspt = size(spTempStimCenter);
                % MAY NEED TO ALLOW RESIZE FOR t_rgcCascade, t_rgcPeriphery
                if 0%isa(ir.mosaic{rgcType},'rgcPhys') && (szspt(1) ~= 80 && szspt(1) ~= 40)
                    %                 spTempStimCenterRS = spTempStimCenter;
                    %                 spTempStimSurroundRS = spTempStimSurround;
                    spTempStimCenterRS = zeros(80,40,size(spTempStimCenter,3));
                    spTempStimSurroundRS = zeros(80,40,size(spTempStimCenter,3));
                    for frstim = 1:size(spTempStimCenter,3)
                        spTempStimCenterRS(:,:,frstim) =    imresize(spTempStimCenter  (:,:,frstim),[80 40],'method','nearest');
                        spTempStimSurroundRS(:,:,frstim) =  imresize(spTempStimSurround(:,:,frstim),[80 40],'method','nearest');
                    end
                    
                    clear spTempStimCenter spTempStimSurround
                    
                    spTempStimCenter = spTempStimCenterRS;
                    spTempStimSurround = spTempStimSurroundRS;
                end
            end
            
            
            % We use a separable space-time receptive field.  This allows
            % us to compute for space first and then time. Space.
            [spResponseCenter, spResponseSurround] = ...
                spConvolve(ir.mosaic{rgcType,1}, spTempStimCenter, spTempStimSurround);
            
            
            %             for cellNum = 1:length(ir.mosaic{rgcType}.sRFcenter)
            %                 linEqDiscBig(:,:,frstim) =    imresize(linEqDisc{cellNum,1}(:,:,frstim),[80 40]);
            %             end
            
            % spResponseSurround{1,1} = zeros(size(spResponseCenter{1,1}));
            % Convolve with the temporal impulse response
            responseLinear = ...
                fullConvolve(ir.mosaic{rgcType,1}, spResponseCenter, spResponseSurround);
            
            
            if isa(ir.mosaic{rgcType},'rgcPhys')
                rLinearSU = cell(length(ir.mosaic{rgcType}.sRFcenter));
                for cellNum = 1:length(ir.mosaic{rgcType}.sRFcenter)
                    %                     rLinearSU{cellNum,1,1} = 3*responseLinear{cellNum,1}./max(responseLinear{cellNum,1}) + ir.mosaic{rgcType}.tonicDrive{cellNum,1};
                    rLinearSUTemp = 8.5*(responseLinear{cellNum,1} - ir.mosaic{rgcType}.tonicDrive{cellNum,1}) + ir.mosaic{rgcType}.tonicDrive{cellNum,1};
                    %                     rLinearSUTemp = 20*(responseLinear{cellNum,1} - ir.mosaic{rgcType}.tonicDrive{cellNum,1}) + ir.mosaic{rgcType}.tonicDrive{cellNum,1};
                    % NEED TO SUBSAMPLE TO GET CORRECT SPIKE RATE
                    rLinearSU{cellNum,1,1} = rLinearSUTemp;%(1:8:end);
                end
                clear responseLinear
                responseLinear = rLinearSU;
            end
            
            % Store the linear response
            ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'responseLinear', responseLinear);
            
            % @JRG:  Why set this here?
            % BW deleted.
            % ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'response spikes', []);
            
        end
    otherwise
        error('Unknown os type %s\n',osType);
end


