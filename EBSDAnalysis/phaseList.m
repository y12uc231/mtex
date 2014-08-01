classdef phaseList
% handles a list of phases

  properties
    phaseId = []    % index to a phase map - 1,2,3,4,....    
    allCS = {}      % list of crystal symmetries
    phaseMap = []   % phase numbers as used in the data - 0,5,10,11,...
  end
  
  properties (Dependent = true)
    phase           % phase
    CS              % crystal symmetry of one specific phase
    mineral         % mineral name of one specific phase
    allMinerals     % all mineral names
    indexedPhasesId % id's of all non empty indexed phase
    color           % color of one specific phase
  end
      
    
  methods
    
    function pL = phaseList(phases,allCS)

      if nargin == 2, pL = pL.init(phases,allCS); end
      
    end
    
    % --------------------------------------------------------------
    
    function pL = init(pL,phases,allCS)
      % extract phases
      [pL.phaseMap,~,pL.phaseId] =  unique(phases);
        
      pL.phaseMap(isnan(pL.phaseMap)) = 0;
      
      % TODO!!
      % if all phases are zero replace them by 1
      %if all(ebsd.phase == 0), ebsd.phase = ones(length(ebsd),1);end

      pL.allCS = allCS;
      
      % check number of symmetries and phases coincides
      if numel(pL.phaseMap)>1 && length(pL.allCS) == 1
          
        pL.allCS = repmat(pL.allCS,numel(pL.phaseMap),1);
          
        if pL.phaseMap(1) <= 0, pL.allCS{1} = 'notIndexed'; end
          
      elseif max([0;pL.phaseMap(:)]) < length(pL.allCS)
          
        pL.allCS = pL.allCS(pL.phaseMap+1);
          
      elseif sum(pL.phaseMap>0) == numel(pL.allCS)
          
        pL.allCS(pL.phaseMap>0) = pL.allCS;
        pL.allCS(pL.phaseMap<=0) = repcell('notIndexed',1,sum(pL.phaseMap<=0));
          
      elseif numel(pL.phaseMap) ~= length(pL.allCS)
        error('symmetry mismatch')
      end

      % apply colors
      colorOrder = getMTEXpref('EBSDColorNames');
      nc = numel(colorOrder);
      c = 1;
      
      for ph = 1:numel(pL.phaseMap)
        if isa(pL.allCS{ph},'symmetry') && isempty(pL.allCS{ph}.color)
          pL.allCS{ph}.color = colorOrder{mod(c-1,nc)+1};
          c = c+1;
        end
      end
      
    end
    
    function phase = get.phase(pL)
      phase = zeros(size(pL.phaseId));
      isIndex = pL.phaseId>0;
      phase(isIndex) = pL.phaseMap(pL.phaseId(isIndex));
    end
    
    function pL = set.phase(pL,phase)
      
      phId = zeros(size(phase));
      for i = 1:numel(pL.phaseMap)
        phId(phase==pL.phaseMap(i)) = i;
      end
      
      pL.phaseId = phId;
            
    end
    
    function id = get.indexedPhasesId(pL)
      
      id = intersect(...
        find(~cellfun('isclass',pL.allCS,'char')),...
        unique(pL.phaseId));
    
      id = id(:).';
      
    end
      
    function cs = get.CS(pL)
      
      % ensure single phase
      id = pL.indexedPhasesId;
               
      if numel(id)>1     
              
        error('MTEX:MultiplePhases',['This operatorion is only permitted for a single phase! ' ...
          'Please see ' doclink('pLModifyData','modify EBSD data')  ...
          '  for how to restrict EBSD data to a single phase.']);
      end
      cs = pL.allCS{id};
            
    end
    
    function pL = set.CS(pL,cs)
            
      if isa(cs,'symmetry')      
        % ensure single phase
        id = unique(pL.phaseId);
      
        if numel(id) == 1
          pL.allCS{id} = cs;
        else
          % TODO
        end
      elseif iscell(cs)    
        if length(cs) == numel(pL.phaseMap)
          pL.allCS = cs;
        elseif length(CS) == numel(pL.indexedPhasesId)
          pL.allCS = repcell('not indexed',1,numel(pL.phaseMap));
          pL.allCS(pL.indexedPhasesId) = cs;
        else
          error('The number of symmetries specified is less than the largest phase id.')
        end        
      else
        error('Assignment should be of type symmetry');
      end
    end
    
    function mineral = get.mineral(pL)
      
      % ensure single phase
      [~,cs] = checkSinglePhase(pL);
      mineral = cs.mineral;      
      
    end
    
    
    function pL = set.color(pL,color)
      
      pL.CS.color = color;
      
    end
    
    function c = get.color(pL)
      
      % notindexed phase should be white by default
      if all(isNotIndexed(pL))
        c = ones(1,3); 
        return
      end
      
      % ensure single phase and extract symmetry
      cs = pL.CS;
            
      % extract colormaps
      cmap = getMTEXpref('EBSDColors');
      colorNames = getMTEXpref('EBSDColorNames');
  
      if isempty(cs.color)
        c = cmap{pL.phaseId};
      elseif ischar(cs.color)
        c = cmap{strcmpi(cs.color,colorNames)};
      else
        c = cs.color;
      end
      
    end
    
    function minerals = get.allMinerals(pL)
      isCS = cellfun('isclass',pL.allCS,'symmetry');
      minerals(isCS) = cellfun(@(x) x.mineral,pL.allCS(isCS),'uniformoutput',false);
      minerals(~isCS) = pL.allCS(~isCS);
    end
    
    function [pL,cs] = checkSinglePhase(pL)

      % check only a single phase is involved
      try
  
        % restrict to indexed phases
        phases = find(cellfun(@(cs) isa(cs,'symmetry'),pL.allCS));
  
        phases = intersect(phases,unique(pL.phaseId));
  
        if numel(phases) > 1
  
          error('MTEX:MultiplePhases',['This operatorion is only permitted for a single phase! ' ...
            'Please see ' doclink('EBSDModifyData','modify EBSD data')  ...
            ' for how to restrict EBSD data to a single phase.']);
  
        elseif isempty(phases)
    
          error('MTEX:NoPhase','There are no indexed data in this variable!');
    
        end
  
        pL = subSet(pL,pL.phaseId == phases);
        cs = pL.allCS{phases};
  
        if numel(pL.phaseId) == 0
          error('MTEX:MultiplePhases','The data set is Empty!');
        end
    
      catch e
        throwAsCaller(e)
      end
    end
  end
end