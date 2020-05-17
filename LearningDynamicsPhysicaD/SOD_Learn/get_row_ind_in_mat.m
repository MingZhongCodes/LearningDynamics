function [row_in_NkL_mat, row_in_NkdL_mat] = get_row_ind_in_mat(Nk, l, sys_info, is_rhoLT)
% function [row_in_NkL_mat, row_in_NkdL_mat] = get_row_ind_in_mat(Nk, l, sys_info, is_rhoLT)

% (C) M. Zhong (JHU)

row_in_NkL_mat    = transpose(1 : Nk) + (l - 1) * Nk;
if is_rhoLT
  row_in_NkdL_mat = [];
else
  row_in_NkdL_mat = transpose(1 : Nk * sys_info.d) + (l - 1) * Nk * sys_info.d;
end
end