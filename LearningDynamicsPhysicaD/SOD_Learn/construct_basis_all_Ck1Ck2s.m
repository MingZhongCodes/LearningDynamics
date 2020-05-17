function basis = construct_basis_all_Ck1Ck2s(range, sys_info, learn_info, basis_info)
% function basis = construct_basis_all_Ck1Ck2s(range, sys_info, learn_info, basis_info)

% (C) M. Zhong, M. Maggioni (JHU)

if ~isempty(basis_info)
  basis             = cell(sys_info.K);                                                             % the basis for each type
  for k1 = 1 : sys_info.K
    for k2 = 1 : sys_info.K
      basis{k1, k2} = construct_basis_Ck1Ck2(range{k1, k2}, learn_info, basis_info{k1, k2});
    end
  end
else
  basis             = [];
end
end