function rhoLT = estimateRhoLT_old(obs_data, sys_info, obs_info)

% function rhoLT = estimateRhoLT_old(obs_data, sys_info, obs_info)
%
% finds the discretized rho_LT in three different categorizes
% IN: usual structures defining the system; the simulations used to construct the estimator
%     for \rho_L^T are obs_data.x
%       [obs_info.Rsupp]  : if provided and with nonempty .R field, it is used as support for the
%                           histograms of estimated \rho_L^T's. Should
%                           contain the fields R, dotR, xiR, each of which a 2-vector determining
%                           an interval, that are needed by the system.
% OUT:
%   rhoLT:   struct containining three different rhoLTs: rhoLTE, rhoLTA, rhoLTXi
%   rhoLTE:  struct containing empirical estimator of \rho_L^T for energy based interactions
%     histcount{k_1,k_2}  : histogram count estimator for type (k_1,k_2) of pairwise distance r
%     hist{k_1,k_2}       : probability-normalized histogram of histcount{k_1,k_2}
%     supp{k_1,k_2}       : estimated support for r for histcount{k_1,k_2}
%     histedges{k_1, k_2} : bins of r that generate histcount{k_1,k_2}
%   rhoLTA:  struct containing empirical estimator of \rho_L^T for alignment based interactions
%     histcount{k_1,k_2}  : histogram count estimator for type (k_1,k_2) of pairwise distance r and |\bv_i - \bv_{i'}|
%     hist{k_1,k_2}       : probability-normalized histogram of histcount{k_1,k_2}
%     supp{k_1,k_2}       : estimated support of r |\bv_i - \bv_{i'}| and for histcount{k_1,k_2}
%     histedges{k_1, k_2} : bins of r |\bv_i - \bv_{i'}| that generate histcount{k_1,k_2}
%     rhoTR               : marginal distribution of r, has the 4 fields as in rhoLTE
%     rhoTDR              : marginal distribution of \dot{r}, has the 4 fields as in rhoLTE
%   rhoLTXi: struct containing empirical estimator of \rho_L^T for xi based interactions
%     histcount{k_1,k_2}  : histogram count estimator for type (k_1,k_2) of pairwise distance r and |\xi_i - \xi_{i'}|
%     hist{k_1,k_2}       : probability-normalized histogram of histcount{k_1,k_2}
%     supp{k_1,k_2}       : estimated support of r and |\xi_i - \xi_{i'}| for histcount{k_1,k_2}
%     histedges{k_1, k_2} : bins of r and |\xi_i - \xi_{i'}| that generate histcount{k_1,k_2}
%     rhoTR               : marginal distribution of r, has the 4 fields as in rhoLTE
%     mrhoLTXi             : marginal distribution of \xi, has the 4 fields as in rhoLTE

% (c) M. Zhong (JHU)

rhoLT.Timings.total             = tic;

% prepare some indicators
if sys_info.ode_order == 1
    has_energy                  = 1;
    has_align                   = 0;
    has_xi                      = 0;
elseif sys_info.ode_order == 2
    if ~isempty(sys_info.phiE)
        has_energy              = 1;
    else
        has_energy              = 0;
    end
    if ~isempty(sys_info.phiA)
        has_align               = 1;
    else
        has_align               = 0;
    end
    has_xi                      = sys_info.has_xi;
end
% initialize storage
Mtrajs                          = obs_data.x;                                              % retrieve the total trajectories
M                               = size(Mtrajs, 3);
if isfield(obs_info,'Rsupp') && ~isempty(obs_info.Rsupp.R)
    min_rs  = obs_info.Rsupp.R(1);
    max_rs  = obs_info.Rsupp.R(2);
    if size(min_rs,1)<sys_info.K,   min_rs = min_rs(1)*ones(sys_info.K,sys_info.K); end
    if size(max_rs,1)<sys_info.K,   max_rs = max_rs(1)*ones(sys_info.K,sys_info.K); end
    if has_align
        min_dotrs = obs_info.Rsupp.dotR(1);
        max_dotrs = obs_info.Rsupp.dotR(2);
        if size(min_dotrs,1)<sys_info.K,   min_dotrs = min_dotrs(1)*ones(sys_info.K,sys_info.K); end
        if size(max_dotrs,1)<sys_info.K,   max_dotrs = max_dotrs(1)*ones(sys_info.K,sys_info.K); end
    end
    if has_xi
        min_xis = obs_info.Rsupp.xiR(1);
        max_xis = obs_info.Rsupp.xiR(2);
        if size(min_xis,1)<sys_info.K,   min_xis = min_xis(1)*ones(sys_info.K,sys_info.K); end
        if size(max_xis,1)<sys_info.K,   max_xis = max_xis(1)*ones(sys_info.K,sys_info.K); end
    end
else
    max_rs                          = zeros(sys_info.K, sys_info.K, M);
    min_rs                          = zeros(sys_info.K, sys_info.K, M);
    if has_align
        max_dotrs                     = zeros(sys_info.K, sys_info.K, M);
        min_dotrs                     = zeros(sys_info.K, sys_info.K, M);
    end
    if has_xi
        max_xis                       = zeros(sys_info.K, sys_info.K, M);
        min_xis                       = zeros(sys_info.K, sys_info.K, M);
    end
    % go through each Monte Carlo realization (parfor is not mandatory here)
    parfor m = 1 : M
        traj                          = squeeze(Mtrajs(:, :, m));
        output                        = find_maximums(traj, sys_info);
        max_rs(:, :, m)               = output.max_rs;
        if has_align
            max_dotrs(:, :, m)          = output.max_dotrs;
        end
        if has_xi
            max_xis(:, :, m)            = output.max_xis;
        end
    end
    % find out the maximum over all m realizations
    max_rs                          = max(max_rs, [], 3);
    if has_align
        max_dotrs                     = max(max_dotrs, [], 3);
    end
    if has_xi
        max_xis                       = max(max_xis, [], 3);
    end
end

% prepare the bins for hist count
histedgesR                        = cell(sys_info.K);
histbinwidthR                     = zeros(sys_info.K);
if has_align
    histedgesDR                   = cell(sys_info.K);
    histbinwidthDR                = zeros(sys_info.K);
else
    histedgesDR                   = [];
end
if has_xi
    histedgesXi                   = cell(sys_info.K);
    histbinwidthXi                = zeros(sys_info.K);
else
    histedgesXi                   = [];
end
for k1 = 1 : sys_info.K
    for k2 = 1 : sys_info.K
        histedgesR{k1, k2}            = linspace(0, max_rs(k1, k2), obs_info.hist_num_bins + 1);
        histbinwidthR(k1, k2)         = max_rs(k1, k2)/obs_info.hist_num_bins;
        if has_align
            histedgesDR{k1, k2}       = linspace(0, max_dotrs(k1, k2), obs_info.hist_num_bins + 1);
            histbinwidthDR(k1, k2)    = max_dotrs(k1, k2)/obs_info.hist_num_bins;
        end
        if has_xi
            histedgesXi{k1, k2}       = linspace(0, max_xis(k1, k2), obs_info.hist_num_bins + 1);
            histbinwidthXi(k1, k2)    = max_xis(k1, k2)/obs_info.hist_num_bins;
        end
    end
end
% prepare the hist counts for rhoLTE, rhoLTA and rhoLTXi
histcountR                      = cell(1, M);
if has_align
    histcountA                    = cell(1, M);
    histcountDR                   = cell(1, M);
else
    histcountA                    = [];
    histcountDR                   = [];
end
if has_xi
    jhistcountXi                  = cell(1, M);
    histcountXi                   = cell(1, M);
else
    jhistcountXi                  = [];
    histcountXi                   = [];
end

% go through each MC realization
parfor m = 1 : M
    traj                          = squeeze(Mtrajs(:, :, m));
    pdist_out                     = partition_traj(traj, sys_info);
    if ~isfield(obs_info,'Rsupp') || isempty(obs_info.Rsupp.R)
        max_rs(:, :, m)               = pdist_out.max_r;
        min_rs(:, :, m)               = pdist_out.min_r;
    end
    histcountR_m                  = cell(sys_info.K);
    if has_align
        histcountA_m                = cell(sys_info.K);
        histcountDR_m               = cell(sys_info.K);
    end
    if has_xi
        jhistcountXi_m              = cell(sys_info.K);
        histcountXi_m               = cell(sys_info.K);
    end
    if has_align
        max_dotrs(:, :, m)          = pdist_out.max_rdot;
        min_dotrs(:, :, m)          = pdist_out.min_rdot;
    end
    if has_xi
        max_xis(:, :, m)            = pdist_out.max_xi;
        min_xis(:, :, m)            = pdist_out.min_xi;
    end
    for k1 = 1 : sys_info.K
        for k2 = 1 : sys_info.K
            pdist_x_Ck1_Ck2           = pdist_out.pdist_x{k1, k2};
            if ~isempty(pdist_x_Ck1_Ck2)
                histcountR_m{k1, k2}    = histcounts(pdist_x_Ck1_Ck2(:), histedgesR{k1, k2}, 'Normalization', 'count');
            end
            if has_align
                pdist_v_Ck1_Ck2         = pdist_out.pdist_v{k1, k2};
                if ~isempty(pdist_v_Ck1_Ck2) && ~isempty(pdist_x_Ck1_Ck2)
                    histcountA_m{k1, k2}  = histcounts2(pdist_x_Ck1_Ck2(:), pdist_v_Ck1_Ck2(:), histedgesR{k1, k2}, histedgesDR{k1, k2}, 'Normalization', 'count');
                    histcountDR_m{k1, k2} = histcounts(pdist_v_Ck1_Ck2(:), histedgesDR{k1, k2}, 'Normalization', 'count');
                end
            end
            if has_xi
                pdist_xi_Ck1_Ck2        = pdist_out.pdist_xi{k1, k2};
                if ~isempty(pdist_xi_Ck1_Ck2) && ~isempty(pdist_x_Ck1_Ck2)
                    jhistcountXi_m{k1, k2} = histcounts2(pdist_x_Ck1_Ck2(:), pdist_xi_Ck1_Ck2(:), histedgesR{k1, k2}, histedgesXi{k1, k2}, 'Normalization', 'count');
                    histcountXi_m{k1, k2}  = histcounts(pdist_xi_Ck1_Ck2(:), histedgesXi{k1, k2}, 'Normalization', 'count');
                end
            end
        end
    end
    histcountR{m}                 = histcountR_m;
    if has_align
        histcountA{m}               = histcountA_m;
        histcountDR{m}              = histcountDR_m;
    end
    if has_xi
        jhistcountXi{m}             = jhistcountXi_m;
        histcountXi{m}              = histcountXi_m;
    end
end
% restruct the data in histcount
output                          = restructure_histcount(histcountR, histcountDR, histcountA, histcountXi, jhistcountXi, M, sys_info.K, sys_info.type_info, obs_info.hist_num_bins);
histcountR                      = output.histcountR;
if has_align
    histcountA                    = output.histcountA;
    histcountDR                   = output.histcountDR;
end
if has_xi
    jhistcountXi                  = output.jhistcountXi;
    histcountXi                   = output.histcountXi;
end
% post-processing the data
histcount                       = cell(sys_info.K);
hist                            = cell(sys_info.K);
supp                            = cell(sys_info.K);
histedges                       = cell(sys_info.K);
if ~isfield(obs_info,'Rsupp') || isempty(obs_info.Rsupp.R)
    max_rs                          = max(max_rs, [], 3);
    min_rs                          = min(min_rs, [], 3);
end
histcountR                      = sum(histcountR, 4);
histcount_R                     = cell(sys_info.K);
hist_R                          = cell(sys_info.K);
supp_R                          = cell(sys_info.K);
for k1 = 1 : sys_info.K
    for k2 = 1 : sys_info.K
        supp_R{k1, k2}              = [min_rs(k1, k2), max_rs(k1, k2)];
        histcount_R{k1, k2}         = squeeze(histcountR(k1, k2, :));
        hist_R{k1, k2}              = squeeze(histcountR(k1, k2, :))/(sum(histcount_R{k1, k2}) * histbinwidthR(k1, k2));
    end
end
if has_energy
    for k1 = 1 : sys_info.K
        for k2 = 1 : sys_info.K
            supp{k1, k2}              = supp_R{k1, k2};
            histcount{k1, k2}         = histcount_R{k1, k2};
            hist{k1, k2}              = hist_R{k1, k2};
        end
    end
    rhoLTE.histcount               = histcount;
    rhoLTE.hist                    = hist;
    rhoLTE.supp                    = supp;
    rhoLTE.histedges               = histedgesR;
else
    rhoLTE                         = [];
end
if has_align
    histcountA                    = sum(histcountA, 5);
    histcountDR                   = sum(histcountDR, 4);
    max_dotrs                     = max(max_dotrs, [], 3);
    min_dotrs                     = min(min_dotrs, [], 3);
    histcount_DR                  = cell(sys_info.K);
    hist_DR                       = cell(sys_info.K);
    supp_DR                       = cell(sys_info.K);
    for k1 = 1 : sys_info.K
        for k2 = 1 : sys_info.K
            supp{k1, k2}              = [min_rs(k1, k2), max_rs(k1, k2); min_dotrs(k1, k2), max_dotrs(k1, k2)];
            histcount{k1, k2}         = squeeze(histcountA(k1, k2, :, :));
            hist{k1, k2}              = squeeze(histcountA(k1, k2, :, :))/(sum(sum(histcount{k1, k2})) * histbinwidthDR(k1, k2) * histbinwidthR(k1, k2));
            histedges{k1, k2}         = [histedgesR{k1, k2}; histedgesDR{k1, k2}];
            supp_DR{k1, k2}           = [min_dotrs(k1, k2), max_dotrs(k1, k2)];
            histcount_DR{k1, k2}      = squeeze(histcountDR(k1, k2, :));
            hist_DR{k1, k2}           = squeeze(histcountDR(k1, k2, :))/(sum(histcount_DR{k1, k2}) * histbinwidthDR(k1, k2));
        end
    end
    % joint distribution of (r, \dot{r})
    rhoLTA.histcount               = histcount;
    rhoLTA.hist                    = hist;
    rhoLTA.supp                    = supp;
    rhoLTA.histedges               = histedges;
    % marginal in r
    rhoLTR.histcount               = histcount_R;
    rhoLTR.hist                    = hist_R;
    rhoLTR.supp                    = supp_R;
    rhoLTR.histedges               = histedgesR;
    % marginal in \dot{r}
    rhoLTDR.histcount              = histcount_DR;
    rhoLTDR.hist                   = hist_DR;
    rhoLTDR.supp                   = supp_DR;
    rhoLTDR.histedges              = histedgesDR;
    % package the data
    rhoLTA.rhoLTR                  = rhoLTR;
    rhoLTA.rhoLTDR                 = rhoLTDR;
else
    rhoLTA                         = [];
end
if has_xi
    jhistcountXi                  = sum(jhistcountXi, 5);
    histcountXi                   = sum(histcountXi, 4);
    max_xis                       = max(max_xis, [], 3);
    min_xis                       = min(min_xis, [], 3);
    histcount_Xi                  = cell(sys_info.K);
    hist_Xi                       = cell(sys_info.K);
    supp_Xi                       = cell(sys_info.K);
    for k1 = 1 : sys_info.K
        for k2 = 1 : sys_info.K
            supp{k1, k2}              = [min_rs(k1, k2), max_rs(k1, k2); min_xis(k1, k2), max_xis(k1, k2)];
            histcount{k1, k2}         = squeeze(jhistcountXi(k1, k2, :, :));
            hist{k1, k2}              = squeeze(jhistcountXi(k1, k2, :, :))/(sum(sum(histcount{k1, k2})) * histbinwidthR(k1, k2) * histbinwidthXi(k1, k2));
            histedges{k1, k2}         = [histedgesR{k1, k2}; histedgesXi{k1, k2}];
            supp_Xi{k1, k2}           = [min_xis(k1, k2), max_xis(k1, k2)];
            histcount_Xi{k1, k2}      = squeeze(histcountXi(k1, k2, :));
            hist_Xi{k1, k2}           = squeeze(histcountXi(k1, k2, :))/(sum(histcount_Xi{k1, k2}) * histbinwidthXi(k1, k2));
        end
    end
    % joint distribution of (r, \xi)
    rhoLTXi.histcount           = histcount;
    rhoLTXi.hist                = hist;
    rhoLTXi.supp                = supp;
    rhoLTXi.histedges           = histedges;
    % marginal in r
    rhoLTR.histcount            = histcount_R;
    rhoLTR.hist                 = hist_R;
    rhoLTR.supp                 = supp_R;
    rhoLTR.histedges            = histedgesR;
    % marginal in \dot{r}
    mrhoLTXi.histcount          = histcount_Xi;
    mrhoLTXi.hist               = hist_Xi;
    mrhoLTXi.supp               = supp_Xi;
    mrhoLTXi.histedges          = histedgesXi;
    % package the data
    rhoLTXi.rhoLTR              = rhoLTR;
    rhoLTXi.mrhoLTXi            = mrhoLTXi;
else
    rhoLTXi                     = [];
end

% package the data
rhoLT.rhoLTE                    = rhoLTE;
rhoLT.rhoLTA                    = rhoLTA;
rhoLT.rhoLTXi                   = rhoLTXi;

rhoLT.Timings.total             = toc( rhoLT.Timings.total );

return