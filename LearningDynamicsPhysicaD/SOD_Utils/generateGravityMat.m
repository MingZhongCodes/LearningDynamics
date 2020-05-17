function gravity_items = generateGravityMat(learningOutput)
% function gravity_items = generateGravityMat(learningOutput)

% (c) M. Zhong (JHU)

N                       = size(learningOutput.Estimator.phiEhat, 1);
supp_k1k2               = zeros(N * (N - 1)/2, 2);
ind                     = 0;
for k1 = 1 : N
  for k2 = 1 : N
    if k2 > k1
      ind               = ind + 1;
      supp_k1k2(ind, :) = learningOutput.Estimator.Ebasis{k1, k2}.supp;  
    end
  end
end
supp                    = zeros(1, 2);
supp(1)                 = min(supp_k1k2(:, 1));
supp(2)                 = max(supp_k1k2(:, 2));
gravity_items           = generateGravityMat_by_kp(1, learningOutput);
gravity_items.supp      = supp;
end