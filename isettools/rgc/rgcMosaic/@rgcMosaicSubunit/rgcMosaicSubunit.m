classdef rgcMosaicSubunit < rgcMosaic
% @rgcMosaicLNP: a subclass of @rgcMosaic
% 
%
% 9/2015 JRG


    % Public, read-only properties.
    properties (SetAccess = private, GetAccess = public)
    end
           
    % Protected properties.
    properties (SetAccess = private, GetAccess = public)

        generatorFunction;
        nlResponse;
        spikeResponse;

        postSpikeFilter;
        couplingFilter;
        couplingMatrix;
        
        rasterResponse;
        psthResponse;
    end
    
    % Private properties. Only methods of the parent class can set these
    properties(Access = private)
    end
    
    % Public methods
    methods
        
        % Constructor
        function obj = rgcMosaicSubunit(rgc, cellTypeInd, outersegment, sensor, varargin)
            % Initialize the parent class            
            obj = obj@rgcMosaic(rgc, cellTypeInd, outersegment, sensor, varargin{:});

            % Initialize ourselves
            obj.initialize(rgc, sensor, outersegment, varargin{:});
            
            % % parse the varargin
            % for k = 1:2:numel(varargin)
            %     obj.(varargin{k}) = varargin{k+1};
            % end
        end
        
        % set function, see for details
        function obj = set(obj, varargin)
            % obj = set@rgcMosaic(obj, varargin);
            mosaicSet(obj, varargin{:});
        end
        
        % get function, see for details
        function val = get(obj, varargin)
           val = mosaicGet(obj, varargin{:});
        end
      
    end
    
    % Methods that must only be implemented (Abstract in parent class).
    methods (Access=public)
%         function obj = compute(obj, sensor, outersegment, varargin)
%             % see for details
%             % obj = mosaicCompute(obj, sensor, outersegment, varargin); 
%         end
%         function plot(obj, sensor)
%             % see for details
%             % mosaicPlot(obj, sensor);
%         end
    end    
    
    % Methods may be called by the subclasses, but are otherwise private 
    methods (Access = protected)
    end
    
    % Methods that are totally private (subclasses cannot call these)
    methods (Access = private)
        initialize(obj, sensor, outersegment, varargin);
    end
    
end
