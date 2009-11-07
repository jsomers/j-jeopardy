class Questionset < ActiveRecord::Base
  def self.new_if_needed(q_ids)
    qs = Questionset.find_by_q_ids(q_ids);
    if !qs
      qs = Questionset.new(:q_ids => q_ids)
      qs.save
    end
    return qs
  end
end
