function GeneralEqmConditions=HeteroAgentStationaryEqm_Case1_subfn(GEprices, n_d, n_a, n_s, l_p, pi_s, d_grid, a_grid, s_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Parameters, DiscountFactorParamNames, ReturnFnParamNames, FnsToEvaluateParamNames, GeneralEqmEqnInputNames, GEPriceParamNames, heteroagentoptions, simoptions, vfoptions)

%% 
for ii=1:l_p
    Parameters.(GEPriceParamNames{ii})=GEprices(ii);
end

[~,Policy]=ValueFnIter_Case1(n_d,n_a,n_s,d_grid,a_grid,s_grid, pi_s, ReturnFn, Parameters, DiscountFactorParamNames,ReturnFnParamNames,vfoptions);

%Step 2: Calculate the Steady-state distn (given this price) and use it to assess market clearance
StationaryDistKron=StationaryDist_Case1(Policy,n_d,n_a,n_s,pi_s,simoptions);
AggVars=EvalFnOnAgentDist_AggVars_Case1(StationaryDistKron, Policy, FnsToEvaluate, Parameters, FnsToEvaluateParamNames, n_d, n_a, n_s, d_grid, a_grid, s_grid, simoptions.parallel);

% The following line is often a useful double-check if something is going wrong.
%    AggVars

% use of real() is a hack that could disguise errors, but I couldn't find why matlab was treating output as complex
if isstruct(GeneralEqmEqns)
    AggVarNames=fieldnames(AggVars); % Using GeneralEqmEqns as a struct presupposes using FnsToEvaluate (and hence AggVars) as a stuct
    for ii=1:length(AggVarNames)
        Parameters.(AggVarNames{ii})=AggVars.(AggVarNames{ii}).Mean;
    end
    GeneralEqmConditionsVec=real(GeneralEqmConditions_Case1_v2(GeneralEqmEqns, Parameters));
else
    GeneralEqmConditionsVec=real(GeneralEqmConditions_Case1(AggVars,GEprices, GeneralEqmEqns, Parameters,GeneralEqmEqnInputNames, simoptions.parallel));
end

if heteroagentoptions.multiGEcriterion==0 %only used when there is only one price
    GeneralEqmConditions=sum(abs(heteroagentoptions.multiGEweights.*GeneralEqmConditionsVec));
elseif heteroagentoptions.multiGEcriterion==1 %the measure of market clearance is to take the sum of squares of clearance in each market 
    GeneralEqmConditions=sqrt(sum(heteroagentoptions.multiGEweights.*(GeneralEqmConditionsVec.^2)));                                                                                                         
end

GeneralEqmConditions=gather(GeneralEqmConditions);

if heteroagentoptions.verbose==1
    fprintf(' \n')
    fprintf('Current GE prices: \n')
    for ii=1:l_p
        fprintf('	%s: %8.4f \n',GEPriceParamNames{ii},GEprices(ii))
    end
    fprintf('Current aggregate variables: \n')
    if ~isstruct(AggVars)
        AggVars
    else
        for ii=1:length(AggVarNames)
            fprintf('	%s: %8.4f \n',AggVarNames{ii},AggVars.(AggVarNames{ii}).Mean)
        end
    end
    fprintf('Current GeneralEqmEqns: \n')
    if ~isstruct(GeneralEqmEqns)
        GeneralEqmConditionsVec
    else
        GeneralEqmEqnsNames=fieldnames(GeneralEqmEqns);
        for ii=1:length(GeneralEqmEqnsNames)
            fprintf('	%s: %8.4f \n',GeneralEqmEqnsNames{ii},GeneralEqmConditionsVec(ii))
        end
    end
end


end
