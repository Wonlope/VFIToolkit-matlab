function [V, Policy]=ValueFnIter_Case1_TPath_SingleStep_no_d_raw(Vnext,n_a,n_z, a_grid, z_grid,pi_z, ReturnFn, Parameters, DiscountFactorParamNames, ReturnFnParamNames, vfoptions)

N_a=prod(n_a);
N_z=prod(n_z);

V=zeros(N_a,N_z,'gpuArray');
Policy=zeros(N_a,N_z,'gpuArray'); %first dim indexes the optimal choice for aprime rest of dimensions a,z

%%
if vfoptions.lowmemory>0
    special_n_z=ones(1,length(n_z));
    z_gridvals=CreateGridvals(n_z,z_grid,1); % The 1 at end indicates want output in form of matrix.
end
if vfoptions.lowmemory>1
    special_n_a=ones(1,length(n_a));
    a_gridvals=CreateGridvals(n_a,a_grid,1); % The 1 at end indicates want output in form of matrix.
end


% Create a vector containing all the return function parameters (in order)
ReturnFnParamsVec=CreateVectorFromParams(Parameters, ReturnFnParamNames);

DiscountFactorParamsVec=CreateVectorFromParams(Parameters, DiscountFactorParamNames);
DiscountFactorParamsVec=prod(DiscountFactorParamsVec);

if vfoptions.lowmemory==0
    
    %if vfoptions.returnmatrix==2 % GPU
    ReturnMatrix=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, 0, n_a, n_z, 0, a_grid, z_grid, ReturnFnParamsVec);
    
    % IN PRINCIPLE, WHY BOTHER TO LOOP OVER z AT ALL TO CALCULATE
    % entireRHS?? CAN IT BE VECTORIZED DIRECTLY?
    %         %Calc the condl expectation term (except beta), which depends on z but
    %         %not on control variables
    %         EV=VKronNext_j*pi_z'; %THIS LINE IS LIKELY INCORRECT
    %         EV(isnan(EV))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
    %         %EV=sum(EV,2);
    %
    %         entireRHS=ReturnMatrix+DiscountFactorParamsVec*EV*ones(1,N_a,N_z);
    %
    %         %Calc the max and it's index
    %         [Vtemp,maxindex]=max(entireRHS,[],1);
    %         V(:,:,j)=Vtemp;
    %         Policy(:,:,j)=maxindex;
    
    for z_c=1:N_z
        ReturnMatrix_z=ReturnMatrix(:,:,z_c);
        
        %Calc the condl expectation term (except beta), which depends on z but
        %not on control variables
        EV_z=Vnext.*(ones(N_a,1,'gpuArray')*pi_z(z_c,:));
        EV_z(isnan(EV_z))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV_z=sum(EV_z,2);
        
        entireRHS_z=ReturnMatrix_z+DiscountFactorParamsVec*EV_z*ones(1,N_a,1);
        
        %Calc the max and it's index
        [Vtemp,maxindex]=max(entireRHS_z,[],1);
        V(:,z_c)=Vtemp;
        Policy(:,z_c)=maxindex;
    end
    
elseif vfoptions.lowmemory==1
    for z_c=1:N_z
        z_val=z_gridvals(z_c,:);
        ReturnMatrix_z=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, 0, n_a, special_n_z, 0, a_grid, z_val, ReturnFnParamsVec);
        
        %Calc the condl expectation term (except beta), which depends on z but
        %not on control variables
        EV_z=Vnext.*(ones(N_a,1,'gpuArray')*pi_z(z_c,:));
        EV_z(isnan(EV_z))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV_z=sum(EV_z,2);
        
        entireRHS_z=ReturnMatrix_z+DiscountFactorParamsVec*EV_z*ones(1,N_a,1);
        
        %Calc the max and it's index
        [Vtemp,maxindex]=max(entireRHS_z,[],1);
        V(:,z_c)=Vtemp;
        Policy(:,z_c)=maxindex;
    end
    
elseif vfoptions.lowmemory==2
    for z_c=1:N_z
        %Calc the condl expectation term (except beta), which depends on z but
        %not on control variables
        EV_z=Vnext.*(ones(N_a,1,'gpuArray')*pi_z(z_c,:));
        EV_z(isnan(EV_z))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV_z=sum(EV_z,2);
        
        z_val=z_gridvals(z_c,:);
        for a_c=1:N_z
            a_val=a_gridvals(z_c,:);
            ReturnMatrix_az=CreateReturnFnMatrix_Case1_Disc_Par2(ReturnFn, 0, special_n_a, special_n_z, 0, a_val, z_val, ReturnFnParamsVec);
            
            entireRHS_az=ReturnMatrix_az+DiscountFactorParamsVec*EV_z;
            %Calc the max and it's index
            [Vtemp,maxindex]=max(entireRHS_az);
            V(a_c,z_c)=Vtemp;
            Policy(a_c,z_c)=maxindex;
        end
    end
    
end


end