function Startup_LearningDynamics()
% Startup_LearningDynamics()
%   Adds necessary paths to the simulator

% (c) M. Zhong, JHU

%% prepare all needed folders to run the learning simulator
fprintf('Setting up paths for Learning Dynamics ...... \n');  
home_path = [pwd filesep];                                                                          % Home directory
fprintf('  Adding necessary folders to %s...', home_path);
addpath([home_path '/SOD_Evolve/']);                                                                % code to run the dynamics for obtaining observation 
addpath([home_path '/SOD_Learn/']);                                                                 % code to run the learning routines
addpath([home_path '/SOD_Utils/']);                                                                 % Utility routines shared by both simulators



addpath(genpath([home_path '/SOD_Examples/']));                                                     % code to generate the examples for specific dynamics
addpath(genpath([home_path  '/SOD_External']));                                                     % external package(s)

addpath([home_path '/Sindyutils/']);
                    % add utilies for Running SINDy code is available at faculty.washington.edu/sbrunton/sparsedynamics.zip


addpath([home_path '/Plot_Utils/']);
% visiualization results containing the convergence of trajectory prediction errors, estimator erros
                    %

fprintf('done.\n');

end
