function spline_info = set_up_spline_info(b, n, num_basis_funs)
% spline_info = set_up_spline_info(b, n, num_basis_funs)
% sets up the necessary fields for the spline_info structure so that a
% Legedren polynomial basis can be constructed based on legendre_info
% Input:
%   b              - the right end point of the support of B-spline basis functions 
%   p              - the degree of B-spline basis functions
%   num_basis_funs - the number of basis functions needed for the learning
% Output:
%   spline_info    - the structure which contains the necessary information to construct a B-spline basis on [0, b]

% Ming Zhong
% Postdoc Research at JHU

% the left end point of the support of B-spline
spline_info.left_end_pt   = 0;
% the right end point of the support of B-spline
spline_info.right_end_pt  = b;
% the strategy to create the B-spline, it's either based on the number of basis functions or the knot vector
spline_info.how_to_create = 'num_basis_first';
% the degree of B-splines (starting from 0)
spline_info.degree        = n;
% it has to be a clamped spline
spline_info.is_clamped    = true;
% the number of basis functions
spline_info.num_basis     = num_basis_funs;
% if 'knot_vec_first' is used in how_to_create, the knot_vec has to be specfied as a partition of [0, b] 
% (non-repeated points), otherwise just set it to []
spline_info.knot_vec      = [];
end