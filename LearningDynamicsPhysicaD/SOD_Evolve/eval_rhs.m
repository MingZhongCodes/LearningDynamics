function rhs = eval_rhs(y, sys_info)
% function rhs = eval_rhs(y, sys_info)
%   evaluates the right handside of the dynamics y_dot = f(t, y) based on the system information
%   regarding the dynamics
% IN:
%   y        : the state variable of the whole system
%   sys_info : the system information struct which contains vital information for the dynamics
% OUT:
%   rhs      : the right handside, f(t, y) at time t, implicit dependency on t

% (c) M. Zhong, M. Maggioni, JHU

% prepare x, v, xi and pdist_mat (contains the pairwise distance, |x_i - x_i'|
state_vars               = partition_sys_var(y, sys_info); 
x = state_vars.x; v = state_vars.v; xi = state_vars.xi;                                                
one_block                = sys_info.d * sys_info.N;
agent_info               = getAgentInfo(sys_info);
pdist_data               = get_phi_feature_map(x, v, xi, agent_info, sys_info);
pdiff_data               = get_phi_weight(x, v, xi, sys_info);
rhs                      = zeros(size(y));

% evaluate f(t, y) based on the order of the ODE
if sys_info.ode_order == 1            
  phiE_force             = get_collective_change(x, v, xi, pdist_data{1}, pdiff_data{1}, agent_info, ...
    sys_info, 'energy');% \sum_{i' = 1}^N \phi^E_{K_i, K_i'}(H^E_{K_i, K_i'}(x, v, xi))(x_i' - x_i)
  if isfield(sys_info, 'Fx') && ~isempty(sys_info.Fx)                                               % non-collective change on x
    Fx                   = sys_info.Fx(x, xi);
  else
    Fx                   = sparse(one_block, 1);
  end
  rhs(1 : one_block)     = Fx + phiE_force;
  if isfield(sys_info, 'phiXi') && ~isempty(sys_info.phiXi)
    phiXi_force          = get_collective_change(x, v, xi, pdist_data{2}, pdiff_data{2}, agent_info, ...
      sys_info, 'xi'); % \sum_{i' = 1}^N \phi^\xi_{K_i, K_i'}(H^\xi_{K_i, K_i'}(x, v, xi))P(xi_i' - xi_i)
    ind1                 = one_block + 1;
    ind2                 = one_block + sys_info.N;
    if isfield(sys_info, 'Fxi') && ~isempty(sys_info.Fxi)                                           % non-collective change on xi
      Fxi                = sys_info.Fxi(x, xi);
    else
      Fxi                = sparse(sys_info.N, 1);
    end
    rhs(ind1 : ind2)     = Fxi + phiXi_force; 
  end
elseif sys_info.ode_order == 2
  rhs                = zeros(size(y));                                                              % y = (x, v, xi)
  rhs(1 : one_block) = reshape(v, [one_block, 1]);                                                  % \dot{x} = v
  if isfield(sys_info, 'phiE') && ~isempty(sys_info.phiE)                                           
    phiE_force       = get_collective_change(x, v, xi, pdist_data{1}, pdiff_data{1}, agent_info, ...
      sys_info, 'energy');  % \sum_{i' = 1}^N \phi^E_{K_i, K_i'}(H^E_{K_i, K_i'}(x, v, xi))(x_i' - x_i)                                                
  else
    phiE_force       = sparse(one_block, 1);                                                        % sparse zero matrix of size (d * N, 1)
  end                                                   
  if isfield(sys_info, 'phiA') && ~isempty(sys_info.phiA)                                           
    phiA_force       = get_collective_change(x, v, xi, pdist_data{2}, pdiff_data{2}, agent_info, ...
      sys_info, 'alignment'); % \sum_{i' = 1}^N \phi^A_{K_i, K_i'}(H^A_{K_i, K_i'}(x, v, xi))(v_i' - v_i)
  else
    phiA_force       = sparse(one_block, 1);                                                       % sparse zero matrix of size (d * N, 1)
  end                                             
  if isfield(sys_info, 'Fv') && ~isempty(sys_info.Fv)
    Fv               = sys_info.Fv(x, v, xi);                                                       % \sum_{i' = 1}^N \phi^\xi_{K_i, K_i'}(H^\xi_{K_i, K_i'}(x, v, xi))P(xi_i' - xi_i)
  else
    Fv               = sparse(one_block, 1);
  end
  mass_vec           = kron(sys_info.agent_mass, ones(sys_info.d, 1));                          
  ind1               = one_block + 1;
  ind2               = 2 * one_block;
  rhs(ind1 : ind2)   = (Fv + phiE_force + phiA_force)./mass_vec;                                    % m_i\dot{v}_i = F^v + F^E + F^A
  if isfield(sys_info, 'phiXi') && ~isempty(sys_info.phiXi)                                         % if the system has xi, calculate the udpate to xi
    phiXi_force      = get_collective_change(x, v, xi, pdist_data{3}, pdiff_data{3}, agent_info, ...
      sys_info, 'xi'); % collective change from energy based influence    
    if isfield(sys_info, 'Fxi') && ~isempty(sys_info.Fxi)
      Fxi            = sys_info.Fxi(x, v, xi);                                                      % the non-collective influence on xi
    else
      Fxi            = sparse(sys_info.N, 1);
    end
    ind1             = 2 * one_block + 1;
    ind2             = 2 * one_block + sys_info.N;
    rhs(ind1 : ind2) = Fxi + phiXi_force;                                                           % \dot{xi}_i = F^\xi + F^xi
  end
end
end