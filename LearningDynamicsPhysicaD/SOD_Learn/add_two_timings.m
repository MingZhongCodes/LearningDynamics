function timing_struct3 = add_two_timings(timing_struct1, timing_struct2)
% function timing_struct3 = add_two_timings(timing_struct1, timing_struct2)

% (C) M. Zhong (JHU)

if ~isempty(timing_struct1) && ~isempty(timing_struct2)
  timing_struct3.assemble_rhs                 = timing_struct1.assemble_rhs + timing_struct2.assemble_rhs;
  timing_struct3.assemble_the_learning_matrix = timing_struct1.assemble_the_learning_matrix + timing_struct2.assemble_the_learning_matrix;
  timing_struct3.assemble_the_rhoLTM          = timing_struct1.assemble_the_rhoLTM + timing_struct2.assemble_the_rhoLTM;
else
  if ~isempty(timing_struct1), timing_struct3 = timing_struct1; end
  if ~isempty(timing_struct2), timing_struct3 = timing_struct2; end
end
end
